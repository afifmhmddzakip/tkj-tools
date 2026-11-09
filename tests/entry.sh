#!/usr/bin/env bash
# uji entry point + navigation menu (non-root, stub)
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/.."
export TKJ_STATE=/tmp/tkj-runtime/state
export TKJ_BACKUPS=/tmp/tkj-runtime/backups
export TKJ_LOG=/tmp/tkj-runtime/log/tkj.log
export TKJ_CONFIG=/tmp/tkj-runtime/config.conf
export BIND_CONF=/tmp/tkj-runtime/named.conf.local
export BIND_DIR=/tmp/tkj-runtime/bind
export FTP_CONF=/tmp/tkj-runtime/vsftpd.conf
export DHCP_CONF=/tmp/tkj-runtime/dhcpd.conf
export DHCP_DEFAULT=/tmp/tkj-runtime/dhcp-default
export WEB_SITES=/tmp/tkj-runtime/web-sites
export WEB_EN=/tmp/tkj-runtime/web-en
export SSH_CONF=/tmp/tkj-runtime/ssh.conf
export TKJ_INPUTS=/tmp/tkj-runtime/inputs.txt
export TKJ_MENUS=/tmp/tkj-runtime/menus.txt
export TKJ_MENU=0
mkdir -p "$BIND_DIR" "$WEB_SITES" "$WEB_EN" /tmp/tkj-runtime
: >"$TKJ_MENUS"

STUB=/tmp/tkj-bin
mkdir -p "$STUB"
# stub minimal utk core call
for b in dpkg-query systemctl ss id ip named-checkconf named-checkzone dig sshd dhcpd apache2ctl a2ensite a2enmod ss curl getent; do
cat >"$STUB/$b" <<E
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
if [[ "$*" == *--inputbox* ]]; then
  if [[ -s "$TKJ_INPUTS" ]]; then
    IFS= read -r line <"$TKJ_INPUTS"
    sed -i '1d' "$TKJ_INPUTS"
    echo "$line"
  else
    echo "lab.tkj"
  fi
  exit 0
fi
if [[ "$*" == *--yesno* || "$*" == *--msgbox* || "$*" == *--textbox* || "$*" == *--scrolltext* ]]; then exit 0; fi
if [[ "$*" == *--menu* ]]; then
  # ui_menu baca dari stdout (> file sementara)
  if [[ -s "$TKJ_MENUS" ]]; then
    IFS= read -r line <"$TKJ_MENUS"
    sed -i '1d' "$TKJ_MENUS"
    echo "$line"; exit 0
  fi
  echo "${TKJ_MENU:-0}"; exit 0
fi
exit 0
E
chmod +x "$STUB"/*
PATH="$STUB:$PATH"

# menu bertingkat: main "1"(DNS) -> service "back" -> main "0"(keluar)
printf '%s\n' "1" "back" "0" >"$TKJ_MENUS"
timeout 10 bash bin/tkj-tools
echo "entry exit=$?"
# tak ada core dump / stuck (exit 124 = timeout = stuck)
[ $? -eq 0 ] && echo "NAVIGATION OK"

# skenario diag (6) + log&backup (7) -> sub back -> main 0
printf '%s\n' "6" "7" "back" "0" >"$TKJ_MENUS"
timeout 10 bash bin/tkj-tools
echo "diag exit=$?"
[ $? -eq 0 ] && echo "DIAG OK"
