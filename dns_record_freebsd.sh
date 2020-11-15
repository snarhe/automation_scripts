#!/usr/local/bin/bash
#set -x
# ######################################################################################################################
# 
#      Name : dns_record.sh
#      Version : 1.0
#      Description : This script add/remove DNS 'A' records to fzone and rzone files.
#      Author : Sunil Narhe
#      Author Email : virtumentor@gmail.com
#      Author WhatsApp: https://wa.me/message/YXAIWEERBSVLA1
#
#      Requirement :
#            1. GNU bash, version 5.0.18
#
#      Test Environment:
#            1. FreeBsd 12.1
#      
#      Silent feature:
#            1. Backup existing files before changes
#            2. Do not allow to add duplicates
#            3. No need to follow argument sequence but value must be followed by argument
#            4. Keeping logs with timestamp
#
#      Example:
#            1. bash dns_record.sh --name test1 --ip 1.2.3.4 --add
#            2. bash dns_record.sh --name test1 --ip 1.2.3.4 --remove 
#      
#
######################################################################################################################

#Configure DIR path and FILES
DIR="/usr/local/etc/namedb/working"
BDIR="/usr/local/etc/namedb/working/backup"
FZONE="mkzone"
RZONE="230.186.136.in-addr.arpa"
log_file="/tmp/dns_record.log"

#Date
DT=`date +%Y-%b-%d`

#Print Help menu
HELP()
{
echo -e "\t--name: name to add/remove";
echo -e "\t--ip: IP to add/remove for DNS";
echo -e "\t--refresh (optional): Refresh the records to immediately updates changes";
echo -e "\t--add: To add a record";
echo -e "\t--remove: To remove a record";
echo -e "\t--help: To print this help menu";
echo ""
echo -e "\tExample:"
echo -e "\t   $sh dns_record.sh --add --name test1 --ip 1.1.1.1";
}

log() {
    local message=$1
    local timestamp=$(date +'%d %b %Y %T')
    echo "[${timestamp}]        $message"
    echo "[${timestamp}]        $message" >> $log_file
}

#Read the content provided by user
IndexOf()    {
    local i=1 S=$1; shift
    while [ $S != $1 ]
    do    ((i=$i+1)); shift
        [ -z "$1" ] && { i=0; break; }
    done
    echo "`expr $i + 1`"
}

backup_files()
{
    log "Creating backup"
    `cp $DIR/$FZONE $BDIR/$FZONE$DT`
    `cp $DIR/$RZONE $BDIR/$RZONE$DT`
}

add_record()
{
    local addr=$1 addip=$2;
    if [ `grep -w -E "$addr|$addip" $DIR/$FZONE > /dev/null; echo $?` != 0 ]
    then
        backup_files
        log "Adding Record"
        echo "$addr    A    $addip" >> $DIR/$FZONE
        echo "$addr    A    $addip" >> $DIR/$RZONE
        log "DNS record added"
    else
        log "Name OR IP already exist"
        exit
    fi
}

remove_record()
{
    local remover=$1 removeip=$2;
    backup_files
    log "Removing Record"
    `sed -iBAK '/$remover    A    $removeip/d' "$DIR/$FZONE"`
    `sed -iBAK '/$remover    A    $removeip/d' "$DIR/$RZONE"`
    log "DNS record removed"
}

service_refresh()
{
    `service named reload`
    if [ `echo $?` == 0 ]
    then
        log "Service refresh sucessfully"
    else
        log "ERROR: Issue to refresh service"
    fi
}

fname_value()
{
    name_index=`IndexOf '--name' ${parameter_list[@]}`
    name_value=`echo $parameter_list | cut -d" " -f$name_index`
}

fip_value()
{
    ip_index=`IndexOf '--ip' ${parameter_list[@]}`
    ip_value=`echo $parameter_list | cut -d" " -f$ip_index`
}

#Main body of script
if [ $# == 0 ]
then
    log "Error: At least one parameter is manadatory. Use 'sh $0 --help'";
elif [ $1 == '--help' ]
then
    HELP
else
    parameter_list=$@
    if [ `echo $parameter_list | grep -e '--add' > /dev/null; echo $?` == 0 ] && [ `echo $parameter_list | grep -e '--remove' > /dev/null; echo $?` != 0 ]
    then
        if [ `echo $parameter_list | grep -e '--name' > /dev/null; echo $?` == 0 ] && [ `echo $parameter_list | grep -e '--ip' > /dev/null; echo $?` == 0 ]
        then
            if [ $# == 5 ]
            then
                fname_value
                fip_value
                add_record $name_value $ip_value
                service_refresh
            else
                log "ERROR: Parameter value required"
            fi
        else
            log "--name or --ip parameter manadatory"
        fi
    elif [ `echo $parameter_list | grep -e '--remove' > /dev/null; echo $?` == 0 ] && [ `echo $parameter_list | grep -e '--add' > /dev/null; echo $?` != 0 ]
        then
        if [ `echo $parameter_list | grep -e '--name' > /dev/null; echo $?` == 0 ] && [ `echo $parameter_list | grep -e '--ip' > /dev/null; echo $?` == 0 ]
        then
            if [ $# == 5 ]
            then
                fname_value
                fip_value
                remove_record $name_value $ip_value
                service_refresh
            else
                log "ERROR: Parameter value required"
            fi
        else
            log "--name or --ip parameter manadatory"
        fi
    else
        log "One operation at a time is manadatory (--add) OR (--remove)"
    fi
fi
