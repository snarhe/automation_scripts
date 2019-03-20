#!/bin/bash

HELP()
{
	echo -e "Script '$0' accept mount-point name and size to be extend in GB only"
	echo -e "--mount		Mount point name which need to extend"
	echo -e "--size 		Size in GB to get extend"
	echo -e "--help			Print this help menu"
	echo -e "Ex $0 --mount /u02/ECFHOM/datafiles --size 2"
	exit 0
}

if [[ $1 == '--help' ]] || [[ $# -eq 0 ]]
then
    HELP
elif [[ $1 == '--mount' ]]  && [[ $3 == '--size' ]] &&  [[ $# == 4 ]]
then
    MNAME=$2
    ESIZE=$4
elif [[ $1 == '--size' ]] && [[ $3 == '--mount' ]] && [[ $# -eq 4 ]]
then
    MNAME=$4
    ESIZE=$2
else
    echo -e "[ERROR]Incorrect parameter passed to script"
    HELP
fi

echo -e "MNAME: $MNAME\nESIZE: $ESIZE"
DMNAME=`df | grep -w $MNAME | awk '{print $NF}'`
echo -e "DMNAME: $DMNAME"

if [[ $DMNAME == $MNAME ]]
then
    LVNAME=`df | grep -w $MNAME | cut -d' ' -f1`
    VGNAME=`lvs --noheadings $LVNAME | cut -d' ' -f4`
    if [[ -n $VGNAME ]]
    then
	DPATH=`pvs | awk -v vgname="$VGNAME" '$2 ~ /vgname/ {print $1}' | cut -d'/' -f3`
	DNAME=`powermt display dev=$DPATH | awk '$5 ~ /active/ {print $3}'`
	echo -e "VG Name: $VGNAME\nDisk Path: $DPATH"
	#Scan Disk
	for DEVICE in $DNAME
	do
            echo "echo 1 > /sys/block/$DEVICE/device/rescan"
	    echo 1 > /sys/block/$DEVICE/device/rescan
	done
	echo "#Reload Multipath"
	#sfdisk -R /dev/$DPATH
	echo "#Rezise PV"
	#pvresize /dev/$DPATH
	#lvextend -L +$ESIZE $LVNAME
    else
	echo "No LV found, Resize to $DPATH"
	#resize2fs /dev/$DPATH
    fi
else
    echo -e "Mount point not found on server"
    exit 0
fi

