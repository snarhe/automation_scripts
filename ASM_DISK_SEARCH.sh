#!/bin/bash
# Sunil Narhe
# sunil.narhe@mailserver.com
# script uses to search ASM disk attached to server and send email
###############################################
# All actions performed by the script will be logged for audit purposes
# V 1
# Mar 28, 2019
################################################
#################################################################################
###To be at first line of the Main Code to capture the start time of the script###
##################################################################################
HOSTNAME=`hostname`
DATE=`date +%Y-%m-%d`
LOGFILE=/tmp/ASM_DISK_Data_$DATE.csv
EMAILTOATTACH=sunil.narhe@mailserver.com

if [[ ! -z $1 ]]
then
    while read WWID
    do
        ASMDISK=`multipath -l | grep $WWID | awk '{print $1}'`
	    echo "$ASMDISK $LUN" >> $LOGFILE
    done < $1
else
    echo -e "Please provide file name which contain WWID"
fi

#SENDING EMAIL
if [[ -s $LOGFILE ]]
then
    echo -e "Hello,\nPlease find attached file with Disk details\n\nRegards,\nUnix Team" | mailx -s "[$HOSTNAME]ASM Disk Details" $EMAILTOATTACH -A $LOGFILE
fi


