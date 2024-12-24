#!/bin/bash
date_year=$(date +"%Y")
date_month=$(date +"%m")
DIR_YEAR=/mnt/nas/"$date_year"/
DIR_MONTH=/mnt/nas/"$date_year"/"$date_month"/
now=$(date +%d-%m-%Y)

function jirabackup {

        mkdir -p /mnt/nas/"$date_year"/"$date_month"/"$now"/
           if [[ $? != 0 ]]; then               
              echo -e "From: jira@mycompany.com\nSubject: Backup for jira FAILED\nJira backup FAILED on nas on $now. Can't create subdirectory." | /usr/sbin/sendmail sysadmin@mycompany.com 
              exit
        else
                mv /var/atlassian/application-data/jira/export/*.zip /mnt/nas/"$date_year"/"$date_month"/"$now"/
                        if [[ $? != 0 ]]; then
                                echo -e "From: jira@mycompany.com\nSubject: Backup for jira FAILED\nJira backup FAILED on nas on $now. Can't backup jira zip-backups" | /usr/sbin/sendmail sysadmin@mycompany.com                   
                        fi
                /usr/pgsql/bin/pg_dump -U postgres jiradb > /mnt/nas/"$date_year"/"$date_month"/"$now"/jiradb.dump && /usr/pgsql/bin/pg_dump -U postgres postgres > /mnt/nas/"$date_year"/"$date_month"/"$now"/postgres.dump
                        if [[ $? != 0 ]]; then 
                                echo -e "From: jira@mycompany.com\nSubject: Backup for jira FAILED\nJira backup FAILED on nas on $now. Can't backup postgresql databases." | /usr/sbin/sendmail sysadmin@mycompany.com
                        fi
                cp -r /var/atlassian/application-data/jira/data /home/backupjira/data && zip -r /home/backupjira/data.zip /home/backupjira/data && mv /home/backupjira/data.zip /mnt/nas/"$date_year"/"$date_month"/"$now"/ && rm -rf /home/backupjira/data
                        if [[ $? != 0 ]]; then 
                                echo -e "From: jira@mycompany.com\nSubject: Backup for jira FAILED\nJira backup FAILED on nas on $now. Can't copy home dir of jira." | /usr/sbin/sendmail sysadmin@mycompany.com
                        fi

        umount /mnt/nas
        echo -e "From: jira@mycompany.com\nSubject: Success backup for jira\nJira was successfully backuped to nas on $now." | /usr/sbin/sendmail sysadmin@mycompany.com 
           fi
}


mount -t nfs 192.168.100.107:/volume/backups/jira /mnt/nas
STATUS=$?

if [[ $STATUS != 0 ]]; then
echo -e "From: jira@mycompany.com\nSubject: Backup for jira FAILED\nJira backup FAILED on nas on $now. Can't mount nas." | /usr/sbin/sendmail sysadmin@mycompany.com 

else

        if [ -d "$DIR_YEAR" ]; then
                if [ -d "$DIR_MONTH" ]; then
                        jirabackup    
                else 
                        mkdir /mnt/nas/"$date_year"/"$date_month"/
                        jirabackup
                fi
        else 
        mkdir -p /mnt/nas/"$date_year"/"$date_month"/
        jirabackup
        fi

fi
