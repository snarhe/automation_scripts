#!/bin/bash
#
# ######################################################################################################################
# ----------------------------------------------------------------------------------------------------------------------
# Author : Sunil Narhe (snarhe@domain.com) 
# ----------------------------------------------------------------------------------------------------------------------
#      script created by Sunil Narhe - 2020-12-14 (YYYY-MM-DD)
#
#      PURPOSE: Check server connectivity and Read only status
#
#      
#      LAST UPDATES (YYYY-MM-DD): NA
#
######################################################################################################################

#Purpose: 

pingcheck(){
	local server=$1
    pingstatus=`sudo ping $server -c1 >/dev/null; echo $?`
}

sshcheck(){
	local server=$1
	sshstatus=`timeout 5 bash -c "</dev/tcp/$server/22"; echo $?`
}

filesystemcheck(){
	local server=$1
	local username=$2
	local password=$3
        local action=$4
        case $action in
            create)
                filesystemstatus=`sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no $username@$server 'touch filesyscheck.txt' ; echo $?`
                ;;
            delete)
                `sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no $username@$server 'rm -rf filesyscheck.txt'`
                ;;
        esac
}

validate_tools(){
    tools=(sshpass)
    for t in "${tools[@]}"
    do
        if type "$t" > /dev/null 2>&1
        then
             pass=0
        else
            `yum install -y $t &> /dev/null`
            if [ `echo $?` != 0 ]
            then
                echo -e "\e[1;31m Unable to install $t \e[0m"
                exit
            fi
        fi
    done
}

echo "Welcome to Server status"
validate_tools
read -p "File name which contain server list: " FILENAME
read -p "Server user name: " USER
read -s -p "Server Password: " PASSWORD
echo

if [[ ! -z $FILENAME && ! -z $USER && ! -z $PASSWORD ]]
then
    for SERVER in `cat $FILENAME`
    do
        pingcheck $SERVER
        if [[ $pingstatus == 0 ]]
        then
            sshcheck $SERVER
            if [[ $sshstatus == 0 ]]
            then
                filesystemcheck $SERVER $USER $PASSWORD "create"
                if [[ $filesystemstatus == 0 ]]
                then
                    echo -e "$SERVER:\e[1;32m PING:OK, SSH:OK, FILESYSTEM:OK \e[0m"
                    filesystemcheck $SERVER $USER $PASSWORD "delete"
                else
                    echo -e "$SERVER:\e[1;32m PING:OK, SSH:OK,\e[1;31m FILESYSTEM:KO \e[0m"
                fi
            else
                echo -e "$SERVER:\e[1;32m PING:OK,\e[0m \e[1;31m SSH:KO,\e[0m \e[1;33m FILESYSTEM:PENDING \e[0m"
            fi
        else
            echo -e "$SERVER:\e[1;31m PING:KO,\e[0m \e[1;33m SSH:PENDING, FILESYSTEM:PENDING \e[0m"
        fi
    done
else
    echo "Filename, User and Password are mandatory fields"
fi
