#!/bin/bash

function error {
  echo "Error: $@"
  echo
  exit 1
}

function warning {
  echo "Warning: $@"
}

#
# Create vmail user and group
#
if grep -qE '^vmail:' /etc/group; then 
  if ! grep -qE '^vmail:x:400:' /etc/group; then
    error "There is already a vmail group, but its gid is not 400."
  else
    echo "The vmail group exists."
  fi
else
  groupadd -r -g 400 vmail
fi
if grep -qE '^vmail:' /etc/passwd; then 
  if ! grep -qE '^vmail:x:400:400:' /etc/passwd; then
    error "There is already a vmail user, but its uid and gid are not 400."
  else
    echo "The vmail user exists."
  fi
else
  useradd -r -u 400 -g vmail -d /var/vmail -s /bin/false vmail
fi

#
# Add postfix and dovecot into the vmail group
#
usermod -a -G vmail postfix
usermod -a -G vmail dovecot

#
# Check filewall rules
#
if [ ! -f /etc/sysconfig/iptables ]; then
  error "The iptables configuration file is missing."
fi
for P in 25 110 143 587 993 995; do
  if ! grep -qE ' --dport '$P' ' /etc/sysconfig/iptables; then
    N="$N $P"
  fi
done
if [ -n "$N" ]; then
  warning "The firewall does not include rules for required ports."
  for P in $N; do
    echo "-A Firewall -m tcp -p tcp --dport $P -j ACCEPT"
  done
  echo
fi
