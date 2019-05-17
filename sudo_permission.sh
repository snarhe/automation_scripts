#!/bin/bash
######################################################################################################################
# ----------------------------------------------------------------------------------------------------------------------
# Author of last commit: Sunil Narhe(sunil.narhe@capgemini.com)
# Date : 2019-05-17
# ----------------------------------------------------------------------------------------------------------------------
#      
#      PURPOSE: Check server sudo permission 
#
#     
#      LAST UPDATES (YYYY-MM-DD): 
#
######################################################################################################################

#This script required input file as a parameter
#with servername username and password column
while read server localuser password
do
    /usr/bin/expect sudo_permission.expect $localuser $password $server
done < $1
