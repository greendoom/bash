#!/bin/bash
date_year=$(date +"%Y")
date_month=$(date +"%m")
DIR_YEAR=/mnt/nas/"$date_year"/
DIR_MONTH=/mnt/nas/"$date_year"/"$date_month"/
now=$(date +%d-%m-%Y)

function conflbackup {

    mkdir -p /mnt/nas/"$date_year"/"$date_month"/"$now"/
        if [[ $? != 0 ]]; then
              echo -e "From: confluence@mycompany.com\nSubject: Confluence backuped FAILED\nConfluence backup FAILED on nas on $now. Can't create subdirectory." | /usr/sbin/sendmail sysadmin@mycompany.com      
              exit
        else
                cp /mnt/data/production/atlassian/application-data/confluence/backups/*.zip /mnt/nas/"$date_year"/"$date_month"/"$now"/ && rm -f /mnt/data/production/atlassian/application-data/confluence/backups/*.zip
                if [[ $? != 0 ]]; then
                                echo -e "From: confluence@mycompany.com\nSubject: Confluence backuped FAILED\nConfluence backup FAILED on nas on $now. Can't backup confluence zip-backups." | /usr/sbin/sendmail sysadmin@mycompany.com
                fi
                pg_dump --dbname=postgresql://confluser:conflpassword@127.0.0.1:1234/confluencedb > /mnt/nas/"$date_year"/"$date_month"/"$now"/confluencedb.sql && pg_dump --dbname=postgresql://confluser:conflpassword@127.0.0.1:1234/confdb > /mnt/nas/"$date_year"/"$date_month"/"$now"/confdb.sql
                if [[ $? != 0 ]]; then 
                                echo -e "From: confluence@mycompany.com\nSubject: Confluence backuped FAILED\nConfluence backup FAILED on nas on $now. Can't backup postgresql databases." | /usr/sbin/sendmail sysadmin@mycompany.com
                fi
                cp -r /mnt/data/homeconf /mnt/nas/"$date_year"/"$date_month"/"$now"/homeconf && zip -r /mnt/nas/"$date_year"/"$date_month"/"$now"/homeconf.zip /mnt/nas/"$date_year"/"$date_month"/"$now"/homeconf && rm -rf /mnt/nas/"$date_year"/"$date_month"/"$now"/homeconf
                if [[ $? != 0 ]]; then 
                                echo -e "From: confluence@mycompany.com\nSubject: Confluence backuped FAILED\nConfluence backup FAILED on nas on $now. Can't copy home dir of confluence." | /usr/sbin/sendmail sysadmin@mycompany.com
                fi
                  
    umount /mnt/nas
    echo -e "From: confluence@mycompany.com\nSubject: Success backup for confluence\nConfluence was successfully backuped on nas on $now." | /usr/sbin/sendmail sysadmin@mycompany.com        
        
        fi   
 
}


mount -t nfs 192.168.100.107:/volume/backups/confluence /mnt/nas
STATUS=$?

if [[ $STATUS != 0 ]]; then
echo -e "From: confluence@mycompany.com\nSubject: Backup for confluence FAILED\nConfluence backup FAILED on nas on $now. Can't mount nas." | /usr/sbin/sendmail sysadmin@mycompany.com 

else

        if [ -d "$DIR_YEAR" ]; then
                if [ -d "$DIR_MONTH" ]; then
                        conflbackup    
                else 
                        mkdir /mnt/nas/"$date_year"/"$date_month"/
                        conflbackup
                fi
        else 
        mkdir -p /mnt/nas/"$date_year"/"$date_month"/
        conflbackup
        fi

fi