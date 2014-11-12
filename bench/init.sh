#!/bin/sh
set -x
set -e
cd $(dirname $0)


myuser=root
mydb=isu4_qualifier
myhost=127.0.0.1
myport=3306

usercnt="$(mysql -u ${myuser} -e 'select count(1) from isu4_qualifier.users'|grep -v count)"
if [ "_${usercnt}" != "_200000" ]; then
  mysql -h ${myhost} -P ${myport} -u ${myuser} -e "DROP DATABASE IF EXISTS ${mydb}; CREATE DATABASE ${mydb}"
  mysql -h ${myhost} -P ${myport} -u ${myuser} ${mydb} < sql/schema.sql
  mysql -h ${myhost} -P ${myport} -u ${myuser} ${mydb} < sql/dummy_users.sql
  mysql -h ${myhost} -P ${myport} -u ${myuser} ${mydb} < sql/dummy_log.sql
fi

BUNDLE_GEMFILE=/home/isucon/webapp/ruby/Gemfile ruby -rbundler/setup /home/isucon/webapp/init.redis.rb
