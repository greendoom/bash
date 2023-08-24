#!/bin/bash
now=$(date +"%d-%m-%Y")
nginx_container_id=`docker ps -a | grep nginx | cut -f1 -d ' '`
mariadb_container_id=`docker ps -a | grep mariadb | cut -f1 -d ' '`

function nginxbackup {

        mkdir -p /mnt/nas/"$now"/nginx/
        docker commit -p $nginx_container_id nginx:$now
        docker save -o /mnt/nas/"$now"/nginx/nginx_$now.tar nginx:$now
        docker rmi nginx:$now
        cd /srv && tar -czvf /mnt/nas/"$now"/nginx/volumes.tar.gz ./nginx

}

function mariadbbackup {
        
        mkdir -p /mnt/nas/"$now"/mariadb/
        docker commit -p $mariadb_container_id mariadb:$now
        docker save -o /mnt/nas/"$now"/mariadb/mariadb_$now.tar mariadb:$now
        docker rmi mariadb:$now

for i in `docker exec $mariadb_container_id /usr/bin/mysql -uroot -pPASSWORD -e "show databases;" | grep -v information_schema | grep -v performance_schema | grep -v Database`;
    do
	docker exec $mariadb_container_id /usr/bin/mysqldump -uroot -pPASSWORD $i > /mnt/nas/"$now"/mariadb/mysql_$i;
    done

}

mount -t nfs 192.168.100.107:/volume/backups/dockers/docker.mycompany.com /mnt/nas
STATUS=$?

if [[ $STATUS != 0 ]]; then

        echo -e "From: docker@mycompany.com\nSubject: Backup for docker FAILED\nDocker backup FAILED to nas on $now. Can't mount nas." | /usr/sbin/sendmail sysadmin@mycompany.com 

else

        mkdir -p /mnt/nas/"$now"/
        nginxbackup
        mariadbbackup
        umount /mnt/nas
        echo -e "From: docker@mycompany.com\nSubject: Success backup for docker\nDocker containers were successfully backuped to nas on $now." | /usr/sbin/sendmail sysadmin@mycompany.com 
fi
