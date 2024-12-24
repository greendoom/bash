#!/bin/bash
exec > >(tee -a /scripts/svn_dumps.log) 2>&1
now=$(date +%d-%m-%Y)

function reposbackup {

mkdir -p /mnt/nas/"$now"/
        if [[ $? != 0 ]]; then
              echo "Can't create subdirectory. SVN repositories backup FAILED to nas on $now" | mailx -s "FAILED backup for SVN REPOS" -v sysadmin@mycompany.com
              umount /mnt/nas      
              exit
        else

                cp /var/lib/submin/conf/authz /mnt/nas/"$now"/authz

                echo "******************************Dumping /data/svn/reponame**************************************"
                svnadmin dump /data/svn/reponame | gzip -9 > /mnt/nas/"$now"/reponame.dump.gz

                cd /scripts && tar -cjvf ./svn_dumps_log.tar.bz2 ./svn_dumps.log
                mv /scripts/svn_dumps_log.tar.bz2 /mnt/nas/"$now"/svn_dumps_log.tar.bz2
                rm -r /scripts/svn_dumps*

                umount /mnt/nas
                echo "SVN repositories were successfully backuped to nas on $now" | mailx -s "SUCCESS backup for SVN REPOS" -v sysadmin@mycompany.com
                # restore command: gunzip -c dumpfile.gz | svnadmin load ~/svn/New_Repo

        fi

}


mount -t nfs 192.168.100.108:/volume/backups/svn /mnt/nas
STATUS=$?

if [[ $STATUS != 0 ]]; then
echo "Can't mount nas. SVN repositories backup FAILED to nas on $now" | mailx -s "FAILED backup for SVN REPOS" -v sysadmin@mycompany.com

else
    reposbackup
fi