#!/bin/bash
date_year=$(date +"%Y")
date_month=$(date +"%m")
DIR_YEAR=/var/opt/gitlab/backups/$date_year
DIR_MONTH=/var/opt/gitlab/backups/$date_year/$date_month

function gitbackup {

        #gitlab-backup create STRATEGY=copy > /scripts/Gitlab_nas_backup.log 2>&1
        gitlab-backup create > /scripts/Gitlab_nas_backup.log 2>&1
                if [[ $? != 0 ]]; then
                   echo "Gitlab backup FAILED to nas at $(date +"%H:%M-%d.%m.%Y"). Can't create backup." | mail -r "gitlab_backup@mycompany.com" -s "Gitlab backuped FAILED" sysadmin@mycompany.com     
                   exit
                fi
        zip /scripts/Gitlab_backup_log.zip /scripts/Gitlab_nas_backup.log
        echo "Gitlab has been succesfully backuped to nas at $(date +"%H:%M-%d.%m.%Y")." | mail -r "gitlab_backup@mycompany.com" -s "Gitlab backuped to nas" -a /scripts/Gitlab_backup_log.zip sysadmin@mycompany.com

        ############ Backup to second nas 192.168.100.108########################
        rsync -lrcvzO --stats /var/opt/gitlab/backups/*.tar admin@192.168.100.108:/share/MD0_DATA/Backups/Git > /scripts/Gitlab_transfer.log 2>&1 && ssh admin@192.168.100.108 'ls -t /share/MD0_DATA/Backups/Git/*.tar | tail -n+6 | xargs rm'
                if [[ $? != 0 ]]; then
                    echo "Gitlab backup FAILED to second nas at $(date +"%H:%M-%d.%m.%Y"). Can't rsync backup." | mail -r "gitlab_backup@mycompany.com" -s "Gitlab backup to second nas FAILED" sysadmin@mycompany.com    
                else
                    mail -r "gitlab_backup@mycompany.com" -s "Gitlab backup to second nas check" sysadmin@mycompany.com < /scripts/Gitlab_transfer.log
                fi

        mv /var/opt/gitlab/backups/*.tar /var/opt/gitlab/backups/$date_year/$date_month/
        umount /var/opt/gitlab/backups

}


mount -t nfs 192.168.100.107:/volume/backups/gitlab /var/opt/gitlab/backups && chmod 777 /var/opt/gitlab/backups
STATUS=$?

if [[ $STATUS != 0 ]]; then
echo "Gitlab backup FAILED to nas at $(date +"%H:%M-%d.%m.%Y"). Can't mount nas." | mail -r "gitlab_backup@mycompany.com" -s "Gitlab backuped FAILED" sysadmin@mycompany.com

else

        if [ -d "$DIR_YEAR" ]; then
                if [ -d "$DIR_MONTH" ]; then
                        gitbackup    
                else 
                        mkdir /var/opt/gitlab/backups/$date_year/$date_month
                        gitbackup
                fi
        else 
        mkdir -p /var/opt/gitlab/backups/$date_year/$date_month
        gitbackup
        fi

fi

