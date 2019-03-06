#Script Name: multipath remove
#Version: V1.0
#Developer: Sunil Narhe (sunil.narhe@capgemini.com)
#Description: This script is used to check for the Post Validation of patching

#!/bin/bash 

##AUR BOT##To be at first line of the Main Code to capture the start time of the script###
##################################################################################
emailBotStartTimeOfScript=`date +%Y-%m-%d' '%H:%M:%S`
emailBotFileName=`echo "$0" | sed -e 's/\//\n/g' | tail -1`
#You can have the $endpointName as the endpoints of the server which this script touches as an [String.Array] object or leave as is if the endpoint is this server itself.
endpointName=`hostname` # File name should be of the format '<Geo Prefix><Customer Prefix>_<Tower Prefix>_<Request Portal ID>_<Script/Other Automation type>_Short Name' example NLAHR_WIN_2002_Script_Check Exchange Mail Store Status "Register the script at ""https://troom.capgemini.com/sites/cis-automation/program and development/automation/lists/automation requests/allitems.aspx" and use the same name
emailBotFromAddress="no_reply@capgemini.com" # your from address
emailBotToAddress="hpoperations.in@capgemini.com" # please don't change this
emailBotExecutionID="20185303" # link to raise execution ID as well to register the Script "https://troom.capgemini.com/sites/cis-automation/program and development/automation/lists/automation requests/allitems.aspx"
emailBotSubject="AUR-$emailBotFileName"
#########################################################################

if [[ ! -z "$1" ]] 
then 
    #Reading the content from input file 
    while read DskDe 
    do 
        IDV=`echo $DskDe | awk '{print $1}'` 
        DSKNM=`echo $DskDe |awk '{print $2}'` 
            #Checking pvdisply 
            if [[ `pvdisplay | grep -w $DSKNM ; echo $?` != 0 ]] 
            then 
                #Executing Multipath for Disk 
                multipath -ll $DSKNM > /tmp/$DSKNM 
                if [[ -s "/tmp/$DSKNM" ]] 
                then 
                    IDMV=`grep $DSKNM /tmp/$DSKNM | awk '{print $2}' | sed 's/[()]//g'` 
                    if [[ $IDV == $IDMV ]] 
                    then 
                        #echo -e "Below disk need to be remove from $DSKNM" 
                        multipath -f $DSKNM 
                        echo -e "Removed mpath $DSKNM" 
                        for DISK in `grep "active ready running" /tmp/$DSKNM | awk '{print $3}'` 
                        do 
                            echo 1 > /sys/block/$DISK/device/delete 
                            echo -e "Removed disk $DISK from $DSKNM" 
                        done 
                    else 
                        echo "LUN Id not matching" 
                    fi 
                else 
                    echo -e "LUN does not have disk assocoated" 
                fi 
            else 
                echo -e "$DSKNM is in PV, hence cannot remove" 
            fi 
    done < $1 
else 
    echo -e "Please pass Disk Name and Id file" 
fi

##AUR BOT CODE##############
emailBotEndTimeOfScript=`date +%Y-%m-%d' '%H:%M:%S`
emailBotBody=`/usr/bin/printf "##AUR_START##\nAutomationName:$emailBotFileName\nEndPointName:$emailBotHostName\nStartTime:$emailBotStartTimeOfScript\nDurationToFinish:$emailBotEndTimeOfScript\nStatusOfRun:Success\nExecutionID:$emailBotExecutionID\nInputType:Email\n##AUR_END##\n"`

