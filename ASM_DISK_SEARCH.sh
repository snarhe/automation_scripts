#!/bin/bash
# Sunil Narhe
# sunil.narhe@capgemini.com
# script uses to search ASM disk attached to server and send email
###############################################
# All actions performed by the script will be logged for audit purposes
# V 1
# Mar 28, 2019
################################################
#################################################################################
###To be at first line of the Main Code to capture the start time of the script###
##################################################################################
emailBotStartTimeOfScript=`date +%Y-%m-%d' '%H:%M:%S`
emailBotFileName=`echo "$0" | sed -e 's/\//\n/g' | tail -1`
#You can have the $endpointName as the endpoints of the server which this script touches as an [String.Array] object or leave as is if the endpoint is this server itself.
endpointName=`hostname` # File name should be of the format '<Geo Prefix><Customer Prefix>_<Tower Prefix>_<Request Portal ID>_<Script/Other Automation type>_Short Name' example NLAHR_WIN_2002_Script_Check Exchange Mail Store Status "Register the script at ""https://troom.capgemini.com/sites/cis-automation/program and development/automation/lists/automation requests/allitems.aspx" and use the same name
emailBotFromAddress="no_reply@capgemini.com" # your from address
emailBotToAddress="hpoperations.in@capgemini.com" # please don't change this
emailBotExecutionID="Test" # link to raise execution ID as well to register the Script "https://troom.capgemini.com/sites/cis-automation/program and development/automation/lists/automation requests/allitems.aspx"
emailBotSubject="AUR-$emailBotFileName"
HOSTNAME=`hostname`
DATE=`date +%Y-%m-%d`
LOGFILE=/tmp/ASM_DISK_Data_$DATE.csv
EMAILTOATTACH=sunil.narhe@capgemini.com

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


#####################Put this in the end of the file/script#####################
################################################################################
emailBotEndTimeOfScript=`date +%Y-%m-%d' '%H:%M:%S`
emailBotBody=`/usr/bin/printf "##AUR_START##\nAutomationName:$emailBotFileName\nEndPointName:$emailBotHostName\nStartTime:$emailBotStartTimeOfScript\nDurationToFinish:$emailBotEndTimeOfScript\nStatusOfRun:Success\nExecutionID:$emailBotExecutionID\nInputType:Email\n##AUR_END##\n"`
/usr/sbin/sendmail -t << !
To: $emailBotToAddress
Subject: $emailBotSubject
Content-Type: text

"$emailBotBody"
.
!
####################################################################################
