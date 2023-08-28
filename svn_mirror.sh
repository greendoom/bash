#!/bin/bash
date=$(date +"%Y.%m.%d-%H:%M:%S")
exec > >(tee -a /scripts/svn_mirror_logs/"$date".log) 2>&1
scp root@192.168.100.133:/var/lib/submin/conf/authz /data/authz_serv
cp /data/authz_serv /data/authz
sed -i 's/= rw/= r/g' /data/authz
chown www-data:www-data /data/authz

echo "******************************Mirroring /data/svn/reponame**************************************"
svnsync synchronize --source-username svnusername --source-password svnpassword --sync-username svnusername file:///data/svn/reponame



######### How to create svn mirror server ##########

# 1. svnadmin create /data/svn/storage
# 2. chown -R www-data:www-data /data/svn
# 3. svnsync init --source-username svnusername --source-password svnpassword --sync-username svnusername file:///data/svn/storage https://svn.mycompany.com/repository/storage