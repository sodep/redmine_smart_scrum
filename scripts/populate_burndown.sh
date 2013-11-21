#!/bin/bash

POPFILE=populate_burndown.sql
POPDIR=/srv/www/redmine/vendor/plugins/redmine_smart_scrum/scripts
POPSQL=$POPDIR/$POPFILE
DB=redmine
PASS=toor

if [ ! -d $POPDIR ]; then
   echo "ERROR: Directory for redmine_smart_scrum scripts does not exits. Directory: $POPDIR"
   exit 2
fi
command=' '
if [ -z "$1" ] || [ "$1" == 'mysql' ]; then
   echo "Using Postgres"
   command=`mysql -u root -p$PASS $DB < $POPSQL`
else
   if [ "$1" == 'postgres' ] || [ "$1" == 'postgresql' ]; then
    echo "Using MySQL"
    command=`sudo -u postgres psql -A -t -F"." -p '$PASS' -d $DB < $POPSQL` 
  fi
fi

if [ "$command" == ' ' ]; then
   echo "ERROR: Could not parse command to access database $DB"
fi
# echo "DEBUG: $command"
echo "== Database: $DB == "
for OUTPUT in "$command"; do
   echo "${OUTPUT}"
done

