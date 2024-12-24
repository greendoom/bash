#!/bin/bash
now=$(date +%d-%m-%Y)
mkdir -p /mnt/backup/VM\ -\ 192.168.100.110/"$now"/
virsh suspend VM
qemu-img convert -p -O qcow2 /mnt/data/vm/VM.qcow2 /mnt/backup/VM\ -\ 192.168.100.110/"$now"/VM.qcow2
virsh dumpxml VM > /mnt/backup/VM\ -\ 192.168.100.110/"$now"/VM.xml
virsh resume VM