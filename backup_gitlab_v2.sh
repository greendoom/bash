#!/bin/bash
date_year=$(date +"%Y")
date_month=$(date +"%m")
log_date=$(date +"%Y.%m.%d")
DIR_YEAR=/var/opt/gitlab/backups/$date_year
DIR_MONTH=/var/opt/gitlab/backups/$date_year/$date_month
DIR_DAY=/var/opt/gitlab/backups/$date_year/$date_month/$log_date
notify_email=it@mycompany.com
zabbix_ip=192.168.1.101
exec > >(tee -a /scripts/gitlab_backup_logs/"$log_date".log) 2>&1

function gitbackup {

        echo "########################Clean everything except the current year directory inside the root backup directory################################"
        cd /var/opt/gitlab/backups/ && ls | grep -v $date_year | xargs rm -rfv

        echo "########################Clean everything except the current month directory inside the current year directory##############################"
        cd $DIR_YEAR && ls | grep -v $date_month | xargs rm -rfv

        echo "########################Clean everything except the current day directory inside the current month directory###############################"
        cd $DIR_MONTH && ls | grep -v $log_date | xargs rm -rfv


        
        gitlab-backup create
                if [[ $? != 0 ]]; then
                   echo "- backup.job.result `date +%s` 0" | zabbix_sender -z $zabbix_ip -c /etc/zabbix/zabbix_agentd.conf -T -i -     
                   mail -s "Gitlab backuped FAILED" $notify_email <<< "Gitlab backup FAILED at $(date +"%H:%M-%d.%m.%Y"). Can't create backup."                      
                   exit
                fi         

        mv /var/opt/gitlab/backups/*.tar /var/opt/gitlab/backups/$date_year/$date_month/$log_date/
        cp /etc/gitlab/{gitlab.rb,gitlab-secrets.json} /var/opt/gitlab/backups/$date_year/$date_month/$log_date/

        echo "########################Start synchronization to GCP bucket###############################"
        gsutil -m rsync -r $DIR_DAY gs://backups/gitlab/$date_year/$date_month/$log_date/
                if [[ $? != 0 ]]; then
                   echo "- backup.job.result `date +%s` 0" | zabbix_sender -z $zabbix_ip -c /etc/zabbix/zabbix_agentd.conf -T -i -
                   mail -s "Gitlab backuped FAILED" $notify_email <<< "Gitlab backup FAILED at $(date +"%H:%M-%d.%m.%Y"). Can't rsync to bucket."                    
                   exit
                fi        

        echo "- backup.job.result `date +%s` 1" | zabbix_sender -z $zabbix_ip -c /etc/zabbix/zabbix_agentd.conf -T -i -
        mail -A /scripts/gitlab_backup_logs/"$log_date".log -s "Gitlab backuped SUCCESS" $notify_email <<< "Gitlab has been succesfully backuped to GCP bucket."


}

if [ -d "$DIR_YEAR" ]; then
        if [ -d "$DIR_MONTH" ]; then
		if [ -d "$DIR_DAY" ]; then
			gitbackup
		else
			mkdir /var/opt/gitlab/backups/$date_year/$date_month/$log_date/
                	gitbackup
		fi    
        else 
                mkdir -p /var/opt/gitlab/backups/$date_year/$date_month/$log_date/
                gitbackup
        fi
else 
mkdir -p /var/opt/gitlab/backups/$date_year/$date_month/$log_date/
gitbackup
fi