#!/bin/sh
set -x
set -e
cd $(dirname $0)


myuser=root
mydb=isu4_qualifier
myhost=127.0.0.1
myport=3306

echo  'mysql -h ${myhost} -P ${myport} -u ${myuser} -e "DROP DATABASE IF EXISTS ${mydb}; CREATE DATABASE ${mydb}"'
mysql -h ${myhost} -P ${myport} -u ${myuser} -e "DROP DATABASE IF EXISTS ${mydb}; CREATE DATABASE ${mydb}"
echo 'mysql -h ${myhost} -P ${myport} -u ${myuser} ${mydb} < sql/schema.nama.sql'
mysql -h ${myhost} -P ${myport} -u ${myuser} ${mydb} < sql/schema.nama.sql
echo 'mysql -h ${myhost} -P ${myport} -u ${myuser} ${mydb} < sql/dummy_users_nama.sql'
mysql -h ${myhost} -P ${myport} -u ${myuser} ${mydb} < sql/dummy_users_nama.sql
echo 'mysql -h ${myhost} -P ${myport} -u ${myuser} ${mydb} < sql/dummy_log.sql'
mysql -h ${myhost} -P ${myport} -u ${myuser} ${mydb} < sql/dummy_log.sql

BUNDLE_GEMFILE=./Gemfile ruby -rbundler/setup ./init.redis.nama.rb
