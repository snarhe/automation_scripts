#Script Name: multipath remove
#Version: V1.0
#Developer: Sunil Narhe (sunil.narhe@mailserver.com)
#Description: This script is used to remove multipath from server

#!/bin/bash 


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
