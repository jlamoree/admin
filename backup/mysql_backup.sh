#!/bin/sh

############################################################################
# MySQL Backup Script
#
# This script will use mysqldump to create an SQL script that could
# be used to restore the database on this, or another server. The SQL
# scripts are compressed and organized by date.
#
# To install, set the BU_DIR directory.
# Create the BU_PASS file.
#
# author: Joseph Lamoree <joseph@lamoree.com>
# date: 2002/03/12 18:15:59
# version: 1.1
############################################################################

BU_USER=root
BU_PASS=`cat /root/.mysqlpass`
BU_DIR="/root/backups/mysql/`date +%Y.%m.%d`"
BU_OVERWRITE=0

BU_MAIL=0
BU_MAILTO=root
BU_MAILSUBJECT="MySQL backup on `date "+%d %b %Y"`"

umask 077

# Verify backup location
if [ ! -d `dirname $BU_DIR` ]; then
  echo "$0: Backup directory '`dirname $BU_DIR`' does not exist."
  exit 1
fi
if [ -d $BU_DIR ]; then
  if [ $BU_OVERWRITE -eq 0 ]; then
    echo "$0: Backup directory '$BU_DIR' already exists, and BU_OVERWRITE is off."
    exit 1
  else
    rm -rf $BU_DIR
  fi
fi

# Optionally, specify database name as argument
if [ $# -gt 0 ]; then
  BU_METHOD=single
  BU_DBLIST="$1"
else
  BU_METHOD=all
  BU_DBLIST=`echo "show databases" | /usr/bin/mysql --user=$BU_USER --password=$BU_PASS`
  BU_DBLIST=`echo $BU_DBLIST | cut -d' ' -f2- | sort`
fi

# Create the backup directory
mkdir $BU_DIR

# For each database, run mysqldump
for BU_DB in $BU_DBLIST; do
  /usr/bin/mysqldump --user=$BU_USER --password=$BU_PASS \
                     --flush-logs --lock-tables \
                     --databases $BU_DB \
                     --complete-insert --all \
  | gzip -c9 > "$BU_DIR/$BU_DB.dump.`date +%Y.%m.%d`.gz"
done

# Send an e-mail
if [ $BU_MAIL -gt 0 ]; then
  BU_BODY="MySQL Database Backup Summary\n\n"
  BU_BODY="${BU_BODY}Database List:          $BU_DBLIST\n"
  BU_BODY="${BU_BODY}Backup Directory:       $BU_DIR\n"
  BU_BODY="${BU_BODY}Backup Files:\n\n`ls -l $BU_DIR`"
  echo -e "$BU_BODY" | mail $BU_MAILTO -s "$BU_MAILSUBJECT"
fi
