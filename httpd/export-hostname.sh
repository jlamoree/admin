#!/bin/sh

CFGFILE=/etc/sysconfig/httpd

if `grep HOSTNAME $CFGFILE`; then
  echo "Error: Looks like $CFGFILE is already patched."
  exit 1
fi

cat >> $CFGFILE <<'EOF'

# Export server's hostname for use in HTTP headers
# to identify a real server in the cluster.
export HOSTNAME=`hostname`
EOF

echo "Done!"
