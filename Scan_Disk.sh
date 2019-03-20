
for Disk in `ls /sys/class/scsi_host/`
do
   echo "- - -" > /sys/class/scsi_host/$Disk/scan
done

