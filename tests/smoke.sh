#!/usr/bin/env bash
# smoke test non-root: stub system tools, jalankan status+diag+wizard + backup
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/.."
export TKJ_STATE=/tmp/tkj-runtime/state
export TKJ_BACKUPS=/tmp/tkj-runtime/backups
export TKJ_LOG=/tmp/tkj-runtime/log/tkj.log
export BIND_CONF=/tmp/tkj-runtime/named.conf.local
export BIND_DIR=/tmp/tkj-runtime/bind
export FTP_CONF=/tmp/tkj-runtime/vsftpd.conf
export DHCP_CONF=/tmp/tkj-runtime/dhcpd.conf
export DHCP_DEFAULT=/tmp/tkj-runtime/dhcp-default
export WEB_SITES=/tmp/tkj-runtime/web-sites
export WEB_EN=/tmp/tkj-runtime/web-en
export SSH_CONF=/tmp/tkj-runtime/ssh.conf
export TKJ_INPUTS=/tmp/tkj-runtime/inputs.txt
mkdir -p "$BIND_DIR" "$WEB_SITES" "$WEB_EN"
: >"$TKJ_INPUTS"

STUB=/tmp/tkj-bin
mkdir -p "$STUB"
cat >"$STUB/dpkg-query" <<'E'
#!/bin/bash
case "$*" in *bind9*) echo "install ok installed";; *) echo "deinstall ok config-files";; esac
E
cat >"$STUB/systemctl" <<'E'
#!/bin/bash
case "$1" in
  restart) echo "RESTART $2" >>/tmp/tkj-runtime/restarts.log; exit 0;;
  is-active) exit 0;;
  is-failed) exit 1;;
esac
exit 0
E
cat >"$STUB/ss" <<'E'
#!/bin/bash
echo "tcp LISTEN 0 128 127.0.0.53:53"
E
cat >"$STUB/id" <<'E'
#!/bin/bash
echo "uid=0(root) gid=0(root)"
E
cat >"$STUB/ip" <<'E'
#!/bin/bash
if [[ "$1" == route ]]; then echo "default via 10.0.0.1 dev eth0"; exit 0; fi
if [[ "$1" == -4 ]]; then echo "inet 10.10.10.1/24 scope global eth0"; exit 0; fi
exit 0
E
cat >"$STUB/named-checkconf" <<'E'
#!/bin/bash
exit 0
E
cat >"$STUB/named-checkzone" <<'E'
#!/bin/bash
exit 0
E
cat >"$STUB/dig" <<'E'
#!/bin/bash
echo "10.10.10.1"
E
for b in sshd dhcpd apache2ctl a2ensite a2enmod ss curl; do
cat >"$STUB/$b" <<'E'
#!/bin/bash
exit 0
E
done
cat >"$STUB/getent" <<'E'
#!/bin/bash
echo "user:x:1000:1000::/home/user:/bin/bash"
E
cat >"$STUB/whiptail" <<'E'
#!/bin/bash
if [[ "$1" == --inputbox ]]; then
  if [[ -s "$TKJ_INPUTS" ]]; then
    IFS= read -r line <"$TKJ_INPUTS"
    sed -i '1d' "$TKJ_INPUTS"
    echo "$line"
  else
    if [[ "$2" == *IP* ]]; then echo "10.10.10.1"; else echo "lab.tkj"; fi
  fi
  exit 0
fi
if [[ "$1" == --yesno || "$1" == --msgbox ]]; then exit 0; fi
if [[ "$1" == --menu ]]; then echo "0"; exit 0; fi
exit 0
E
chmod +x "$STUB"/*
PATH="$STUB:$PATH"
export TKJ_UI=whiptail

source ./lib/core.sh
for m in dns ftp dhcp web ssh diag; do source "./lib/modules/$m.sh"; done

echo "root=$(id -u)"
echo "dns=$(dns_status)"
echo "dhcp=$(dhcp_status)"

# wizard DNS
printf '%s\n' "lab.tkj" "10.10.10.1" "lab.tkj" "10.10.10.1" >"$TKJ_INPUTS"
dns_configure
echo "--- named.conf.local ---"; cat "$BIND_CONF"
echo "--- restarts ---"; cat /tmp/tkj-runtime/restarts.log
# uji fungsi dns_test (stub dig -> 10.10.10.1)
printf '%s\n' "lab.tkj" "10.10.10.1" >"$TKJ_INPUTS"
dns_test

# backup/restore
echo old > /tmp/tkj-runtime/test.conf
bak=$(backup_create /tmp/tkj-runtime/test.conf)
echo new | atomic_write /tmp/tkj-runtime/test.conf
backup_restore "$bak"
echo "restored=$(cat /tmp/tkj-runtime/test.conf)"

# FTP (user -> lab.tkj)
printf '%s\n' "lab.tkj" >"$TKJ_INPUTS"
ftp_configure
echo "--- vsftpd.conf ---"; cat "$FTP_CONF" 2>/dev/null || cat /tmp/tkj-runtime/vsftpd.conf

# DHCP: iface, subnet, netmask, gw, dns, domain, r1, r2, mac, ip
printf '%s\n' "eth0" "10.10.10.0" "255.255.255.0" "10.10.10.1" "10.10.10.1" "lab.tkj" "10.10.10.100" "10.10.10.200" "aa:bb:cc:dd:ee:ff" "10.10.10.50" >"$TKJ_INPUTS"
dhcp_configure
echo "--- dhcpd.conf ---"; cat /tmp/tkj-runtime/dhcpd.conf
echo "--- dhcp default ---"; cat /tmp/tkj-runtime/dhcp-default

# Web: domain, root
printf '%s\n' "lab.tkj" "/tmp/tkj-runtime/www" >"$TKJ_INPUTS"
web_configure
echo "--- web conf ---"; cat "$WEB_SITES/lab.tkj.conf" 2>/dev/null; ls -l /tmp/tkj-runtime/www

# SSH: port + key + user (yes/no -> yes, key opsional)
printf '%s\n' "2222" "ssh-rsa fakekey" "lab.tkj" >"$TKJ_INPUTS"
ssh_configure
echo "--- ssh conf ---"; cat /tmp/tkj-runtime/ssh.conf

# diag_show non-interaktif
diag_show > /tmp/tkj-runtime/diag.txt
head -20 /tmp/tkj-runtime/diag.txt

echo "SMOKE OK"
