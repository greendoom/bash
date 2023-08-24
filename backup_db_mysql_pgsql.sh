#!/bin/bash


for i in `mysql -uroot -pPASSWORD -e "show databases;" | grep -v information_schema | grep -v performance_schema | grep -v phpmyadmin | grep -v Database`;
    do
	mysqldump -uroot -pPASSWORD --add-locks $i > /var/backup/databases/mysql_$i;
    done

for i in `psql -l | awk '{ print $1}' | grep -vE '^-|^List|^Name|template[0|1]|\(|\:'`;
    do
	pg_dump $i > /var/backup/databases/postgresql_$i.dump;
    done