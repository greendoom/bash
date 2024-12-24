#!/bin/bash
date=$(date +"%Y.%m.%d-%H:%M:%S")
notify_email=it@mycompany.com
exec > >(tee -a /svn/svn_mirror_logs/"$date".log) 2>&1

check=$(curl -s -w "%{http_code}\n" -L "https://svn.mycompany.com:443" -o /dev/null)
if [[ $check == 200 || $check == 403 || $check == 401 ]]
then
    # SVN is online
    echo "SVN server is online"
	for i in $(ls /svn | grep -v svn_mirror_logs | grep -v lost+found); do	
	
		echo "******************************Mirroring /svn/"$i"**************************"
		svnsync synchronize --source-username svnusername --source-password svnpassword --sync-username svnusername --sync-password svnpassword file:///svn/$i https://svn.mycompany.com/$i
		if [[ $? != 0 ]]; then
			echo "******************************Sync for /svn/"$i" FAILED**************************************"
			mail -s "Can't sync SVN repo" $notify_email <<< "Sync for /svn/$i FAILED"
		fi
		
	done

	mail -A /svn/svn_mirror_logs/"$date".log -s "SVN sync completed" $notify_email <<< "SVN mirroring is complete. Look log file in attachement."
	exit 0
else
    # SVN is offline or not working correctly
    echo "SVN server is offline or not working correctly"
	mail -A /svn/svn_mirror_logs/"$date".log -s "SVN is offline" $notify_email <<< "Can't sync SVN. SVN is not available. Look log file in attachement."
    exit 1
fi
