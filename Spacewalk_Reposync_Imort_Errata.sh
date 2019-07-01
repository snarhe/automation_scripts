#!/bin/bash
#Purpose: Sync Repositories and Import Errata for RHEL6 and RHEL7 channels
#Date: 23th May 2017
#Author: Sunil Narhe <sunil.narhe@mydomain.com>
#Modify<01> : 15th Jun 2017 -- Add Carbon coy to 'DL Global Group IT Unix' -- Sunil Narhe

dt1=`date`
dt=`date +%Y-%b-%d`
logfile=/var/log/reposync_$dt
#Backup log files
cd /var/log/rhn/reposync/

#Backup RHEL6 reposync log file
echo -e "Backup RHEL6 reposync log file" >> $logfile
tar zcvf rhel6_base_log_$dt.tgz rhel6_base.log
if [ `echo $?` == 0 ]
then
echo -e "Backup RHEL6 reposync log file completed" >> $logfile
else
echo -e "Issue to backup RHEL6 reposync log file" >> $logfile
exit
fi

#Backup CentOS6 reposync log file
echo -e "Backup CentOS7 reposync log file" >> $logfile
tar zcvf centos_6_8_log_$dt.tgz centos_6.8.log
if [ `echo $?` == 0 ]
then
echo -e "Backup CentOS6 reposync log file completed" >> $logfile
else
echo -e "Issue to backup CentOS reposync log file" >> $logfile
exit
fi


#Backup CentOS7 reposync log file
echo -e "Backup CentOS7 reposync log file" >> $logfile
tar zcvf centos_7_log_$dt.tgz centos_7.log
if [ `echo $?` == 0 ]
then
echo -e "Backup CentOS7 reposync log file completed" >> $logfile
else
echo -e "Issue to backup CentOS7 reposync log file" >> $logfile
exit
fi

#Backup RHEL7 reposync log file
echo -e "Backup RHEL7 reposync log file" >> $logfile
tar zcvf rhel7_base_log_$dt.tgz rhel7_base.log
if [ `echo $?` == 0 ]
then
echo -e "Backup RHEL7 reposync log file completed" >> $logfile
else
echo -e "Issue to backup RHEL7 reposync log file" >> $logfile
exit
fi

cd

#Sync RHEL6 Repositories
echo -e "Initializing RHEL6 repo sync to Channel" >> $logfile
spacewalk-repo-sync --channel rhel6_base --sync-kickstart
if [ `echo $?` == 0 ]
then
echo -e "Sync of RHEL6 repository completed find below logs" >> $logfile
echo -e "--------------------------------------------" >> $logfile
tail -5 /var/log/rhn/reposync/rhel6_base.log >> $logfile
echo -e "--------------------------------------------" >> $logfile
else 
echo -e "Issue to Sync RHEL6 repository find below logs" >> $logfile
echo -e "--------------------------------------------" >> $logfile
tail -5 /var/log/rhn/reposync/rhel6_base.log >> $logfile
echo -e "--------------------------------------------" >> $logfile
exit
fi

#Sync RHEL7 Repositories
echo -e "Initializing RHEL7 repo sync to Channel" >> $logfile
spacewalk-repo-sync --channel rhel7_base --sync-kickstart
if [ `echo $?` == 0 ]
then
echo -e "Sync of RHEL7 repository completed find below logs" >> $logfile
echo -e "--------------------------------------------" >> $logfile
tail -5 /var/log/rhn/reposync/rhel7_base.log >> $logfile
echo -e "--------------------------------------------" >> $logfile
else 
echo -e "Issue to Sync RHEL7 repository find below logs" >> $logfile
echo -e "--------------------------------------------" >> $logfile
tail -5 /var/log/rhn/reposync/rhel7_base.log >> $logfile
echo -e "--------------------------------------------" >> $logfile
exit
fi


#Sync Centos6 Repositories
echo -e "Initializing Centos6 repo sync to Channel" >> $logfile
spacewalk-repo-sync --channel centos_6.8
if [ `echo $?` == 0 ]
then
echo -e "Sync of CENTOS6 repository completed find below logs" >> $logfile
echo -e "--------------------------------------------" >> $logfile
tail -5 /var/log/rhn/reposync/centos_6.8.log >> $logfile
echo -e "--------------------------------------------" >> $logfile
else 
echo -e "Issue to Sync CENTOS6 repository find below logs" >> $logfile
echo -e "--------------------------------------------" >> $logfile
tail -5 /var/log/rhn/reposync/centos_6.8.log >> $logfile
echo -e "--------------------------------------------" >> $logfile
exit
fi


#Sync CENTOS7 Repositories
echo -e "Initializing CentOS7 repo sync to Channel" >> $logfile
spacewalk-repo-sync --channel centos_7
if [ `echo $?` == 0 ]
then
echo -e "Sync of CentOS7 repository completed find below logs" >> $logfile
echo -e "--------------------------------------------" >> $logfile
tail -5 /var/log/rhn/reposync/centos_7.log >> $logfile
echo -e "--------------------------------------------" >> $logfile
else 
echo -e "Issue to Sync CentOS7 repository find below logs" >> $logfile
echo -e "--------------------------------------------" >> $logfile
tail -5 /var/log/rhn/reposync/centos_7.log >> $logfile
echo -e "--------------------------------------------" >> $logfile
exit
fi

#download required files for errata
cd /tmp
wget -N http://nlpckt01.sgti.nl/RepoDownloads/updateinfo.rhel6.xml
wget -N http://nllrhel7.corp.mydomain.com/RepoDownloads/updateinfo.rhel7.xml
wget -N http://www.redhat.com/security/data/oval/com.redhat.rhsa-all.xml.bz2 1>/dev/null 2>&1
bunzip2 -f /tmp/com.redhat.rhsa-all.xml.bz2

#Import Errata for RHEL6 channel
SPACEWALK_PASS=password SPACEWALK_USER='sunil.narhe@mydomain.com' /opt/tools/errata-import.pl --server localhost --errata updateinfo.rhel6.xml --include-channels=rhel6_base --rhsa-oval=/tmp/com.redhat.rhsa-all.xml --publish 1>/dev/null
if [ "$?" == 0 ]
then
echo -e "RHEL6 errata published successfully" >> $logfile
else
echo "It seems like there was a problem while publishing RHEL6 recent errata..." >> $logfile
exit
fi

#Import Errata for RHEL7 channel
SPACEWALK_PASS=password SPACEWALK_USER='sunil.narhe@mydomain.com' /opt/tools/errata-import.pl --server localhost --errata updateinfo.rhel7.xml --include-channels=rhel7_base --rhsa-oval=/tmp/com.redhat.rhsa-all.xml --publish 1>/dev/null
if [ "$?" == 0 ]
then
echo -e "RHEL7 errata published successfully" >> $logfile
else
echo "It seems like there was a problem while publishing RHEL7 recent errata..." >> $logfile
exit
fi


rm -rf updateinfo.rhel6.xml updateinfo.rhel7.xml com.redhat.rhsa-all.xml
echo "Errase garbage files" >> $logfile
cd





















###Mail body and email
echo -e "
Hello,

Repositories Sync and Errata update to Channels execution completed sucessfully.

Find below script logs:\n\n
Start Date : $dt1
----------------------------------------------
`cat $logfile`
----------------------------------------------
End Date : `date`

For more details please log on to\n\n https:spacewalk.mydomain.com\nOR\nCheck logs on server.\n\n



Thanks & Regards,
_______________________________________________________________________
ITICS Unix Team | Group IT

Capgemini India | Mumbai – Airoli

Address: Building No.8, MindSpace, Thane-Belapur Road, Airoli,Navi Mumbai 400708, India.
www.mydomain.com
People matter, results count.
_______________________________________________________________________
Connect with us on

NOTE :: “Please contact NE, ITICS Unix Team for faster response

" | mail -r spacewalk@mydomain.com -s "[North]Spacewalk Errata Sync Status `date +%d-%b-%Y`" groupitunix.global@mydomain.com


#EOF

