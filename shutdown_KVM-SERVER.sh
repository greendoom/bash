#!/bin/bash

echo "############################$(date +"%d.%m.%Y")##############################" >> /scripts/shutdown.log

############## shutdown Vm's on Server
for OUTPUT in $(virsh list --all | grep running | awk '{ print $2}')
do
echo "Shutdown $OUTPUT at $(date +"%H:%M:%S")" >> /scripts/shutdown.log
	virsh shutdown $OUTPUT
done
sleep 70

############## shutdown Server
echo "Shutdown Server at $(date +"%H:%M:%S")" >> /scripts/shutdown.log
shutdown