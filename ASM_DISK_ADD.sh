#!/bin/bash

DATE=`date +%Y-%m-%d`
DATACHECKFILE=/tmp/datacheck_$DATE.txt
NEWDISKINFO=/tmp/new_disk_details_$DATE.txt
MULTIPATHCONF=/etc/multipath.conf
TEMPMULTIPATHCONF=/tmp/newmultipath.conf


HELP(){
    echo -e "sh $0 disk_details.csv"
	echo -e "disk_details.csv should contain below parameter with blank space separator"
	echo -e "WWID,ALIAS"
	echo -e "Below is the example of date"
	echo -e "WWID --> 6ac61751004ce7d050208e2900000146"
	echo -e "ALIAS --> OCS_ARCHIVE_006"
	#echo -e "DISK_ID --> 124"
	#echo -e "SIZE --> 50 (All size considers as GB only)"
}

MULTIPATH_CONFIG(){
    if [[ $# == 0 ]]
    then
        echo "[ERROR] Input file required as manadatory"
        HELP
        exit 0
    elif [ $1 == '--help' ]
    then
        HELP
        exit 0
    else
        rm -rf $DATACHECKFILE
        if [[ ! -f $DATACHECKFILE ]] && [[ ! -s $DATACHECKFILE ]]
        then
            awk -F" " '{if (NF != 2) print $1}' $1 >> $DATACHECKFILE
            if [[ -s $DATACHECKFILE ]]
            then
                for LUN in `ls /sys/class/scsi_host/`
                do
                    echo " - - - " > /sys/class/scsi_host/$LUN/scan
                done
                while read WWID ALIAS
                do
                    if [[ `multipath -ll | grep $WWID &> /dev/null; echo $?` == 0 ]]
                    then
                        WWID_STATUS=0
                    else
                        echo -e "[ERROR] $WWID exist in multipath"
                    fi
                    if [[ `multipath -ll | grep $ALIAS &> /dev/null; echo $?` == 0 ]]
                    then
                        ALIAS_STATUS=0
                    else
                        echo -e "[ERROR] $ALIAS exist in multipath"
                    fi
                    if [[ $WWID_STATUS == 0 ]] && [[ $ALIAS_STATUS == 0 ]]
                    then
                        echo -e " multipath {\n\t\twwid  $WWID\n\t\talias  $ALIAS\n\t}" >> /tmp/newmultipath.conf
                    fi
                done < $1
                cp $MULTIPATHCONF /etc/multipath_conf_$DATE
                sed -i '/^$/d' $MULTIPATHCONF      #Removing empty lines from config files
                sed -i '${/}/d;}' $MULTIPATHCONF    #Removing last special character
                cat $TEMPMULTIPATHCONF >> $MULTIPATHCONF
                echo "}" >> /etc/multipath.conf
                rm -rf $TEMPMULTIPATHCONF
            else
                echo -e "[ERROR] Input data not okay, please check input data for below WWID/s"
                cat $DATACHECKFILE
                exit 0
            fi
        else
            echo -e "Data check file exist $DATACHECKFILE, please re-execute script"
            rm -rf $DATACHECKFILE
            exit 0
        fi
    fi
}



SERVICE_RESTART(){
    PID_BEFORE_RELOAD=`ps -ef | grep multipathd | grep -v grep | awk '{print $2}'`
	sleep 5
	service multipathd reload &> /dev/null
	sleep 5
	PID_AFTER_RELOAD=`ps -ef | grep multipathd | grep -v grep | awk '{print $2}'`
	if [[ $PID_BEFORE_RELOAD == $PID_AFTER_RELOAD ]]
	then
	    echo "[INFO] Service multipath reload successfully"
	else
	    echo "[ERROR] Service multipath not running on server"
		exit 0
	fi
}

CREATE_DISK(){
    while read WWID ALIAS
	do
	    NEWDISKNM=`echo "$ALIAS p1" | tr -d " "`
		echo ";" /dev/mapper/$ALIAS &> /dev/null
		ll /dev/mapper/$NEWDISKNM >> $NEWDISKINFO
	done < $1
}

MULTPATH_CONFIG
SERVICE_RESTART
CREATE_DISK

