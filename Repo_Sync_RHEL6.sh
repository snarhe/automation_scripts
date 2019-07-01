#!/bin/bash
#Purpose : Download updated Packages and create repository
#Date : 30th Sep 2016
#Author : Sunil Narhe <sunil.narhe@capgemini.com>
#Modify<01>: 23rd May 2017 -- Add Errata download screipt -- Sunil Narhe
#Modify<02>: 23rd May 2017 -- Move old repodata xml file to archive -- Sunil Narhe

dt=`date +%Y-%m-%d`
dt1=`date`
logfile=/var/log/reposync/reposync.log
#Checking for log file
if [ -s $logfile ]
then
mv /var/log/reposync/reposync.log /var/log/reposync/reposync.log_$dt
echo -e "$dt1" >> $logfile
echo -e "Logfile backup completed " >> $logfile

#Checking avaiblity of repoid
repo_id=`yum repolist | grep "rhel-6-server-rpms" | awk '{print $1}'`

if [ $repo_id == "rhel-6-server-rpms" ]
then
echo -e "Repoid: $repo_id exist...\nInitiating package downloading....." >> $logfile
#Reposync 
reposync --gpgcheck -l --repoid=rhel-6-server-rpms --download_path=/repodownloads/ --downloadcomps --download-metadata >> $logfile
#Command status
repo_status=`echo $?`
if [ $repo_status == 0 ]
then
echo -e "Package downloading completed....\nCreating repo indexing" >> $logfile
#backup existing repodata directory
mv /repodownloads/repodata /repodownloads/archive/repodata_$dt
echo -e "Repodata indexing Backup successfull\nNew repo index creating..." >> $logfile
cd /repodownloads
createrepo -v /repodownloads >> $logfile
echo -e "Indexing created Successfully " >> $logfile
else
echo -e "Issue in downloding packages " >> $logfile
fi

else
echo -e "Repo id mismatched.\nPackages will not download with $repo_id repo id" >> $logfile
fi


else
echo -e "Some error occured during updating reposotiry" >> $logfile
fi

chmod 644 /repodownloads/repodata/*
chmod -R 644 /repodownloads/rhel-6-server-rpms/Packages/*
chmod 755 /repodownloads/repodata

#Download Errata Script
sh /root/scripts/download-errata.sh

chmod 755 updateinfo.rhel6.xml

###Mail body and email 
echo -e "
Hello,

Reposync script execution completed sucessfully.

Find below script logs:
==============================================
Start Date : $dt1
----------------------------------------------
`egrep -v '(Loaded|rhel-6-server-rpms:|Worker|metadata|DBs|db|.rpm)' /var/log/reposync/reposync.log`\n\nFor more details check server log file.\n\n
----------------------------------------------


End Date : `date`

==============================================


Thanks & Regards,
_______________________________________________________________________
ITICS Unix Team | Group IT

Capgemini India | Mumbai – Airoli

Address: Building No.8, MindSpace, Thane-Belapur Road, Airoli,Navi Mumbai 400708, India.
www.capgemini.com
People matter, results count.
_______________________________________________________________________
Connect with us on

NOTE :: “Please contact NE, ITICS Unix Team for faster response

" | mail -r spacewalk@capgemini.com -s "[North]RHEL-6 Reposysnc Status `date +%d-%b-%Y`" groupitunix.global@capgemini.com > /var/log/reposync_mail.log



