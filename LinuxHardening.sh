#!/bin/bash
#Date : 14th Oct 2016
#Author : Sunil Narhe
#Purpose : Perform the Hardening

#Hardening Phase I

dt=`date +%Y-%m-%d`
logfile=/var/log/hardening_$dt.log
echo -e "Hardening Phase I initiated" >> $logfile

##Creating temp file for Hardening
mkdir -p /root/hardening
echo -e "Temporary log directory created successfully" >> $logfile
tdir="/root/hardening"

##Creating backup dir for Hardening
mkdir -p $bdir
echo -e "Backup log directory created successfully" >> $logfile
bdir="$bdir"

command_status(){
if [ `echo $?` == 0 ]
then
echo -e "..Command successfull"
else
echo -e "..Command unsuccessfull"
fi
}

##File Check
check_file(){
local fnm=$1
if [ -f $fnm ]
then
echo -e "..$fnm file created sucessfully"
else
echo -e "..$fnm file not created"
exit 0
fi
}

###Creating required files###
##Creating patch Check scipt
echo -e "Creating Patch check script" >> $logfile
#echo -E "patch=\$1" > $tdir/patch_check.sh
echo -Ee "patch=\$1\ncd $tdir\nrpm -qa | grep \$patch > \$patch\nif [ `echo $?` == 0 ]\nthen\necho -e 'Package \$patch check file created' >> $logfile\nfi\ncd" > $tdir/patch_check.sh
fnm=$tdir/patch_check.sh
check_file $fnm >> $logfile

###Creating package list file to erase Package##
echo -e "Creating Package list file" >> $logfile
echo -e "rsh-server\nrhs\nypbind\nypserv\ntftp\ntftp-server\ntalk\ntalk-server\ndhcp" > $tdir/patch_list.txt
fnm=$tdir/patch_list.txt
check_file $fnm >> $logfile

###Creting file Changing Ownership
echo -e "Creating File list in which we are changing Owner's" >> $logfile
echo -e "anacrontab\ngrub.conf\npasswd\nshadow\ngshadow\ngroup" > $tdir/owner_change.txt
fnm=$tdir/owner_change.txt
check_file $fnm >> $logfile

###Creating File Changing Permission
echo -e "Creating File list in which we are changing Permission" >> $logfile
echo -e "grub.conf\nanacrontab" > $tdir/perm_change.txt
fnm=$tdir/perm_change.txt
check_file $fnm >> $logfile

###Creating file for disabling service
echo -e "Creating file list in which we are disabling service" >> $logfile
echo -e "chargen-dgram\nchargen-stream\ndaytime-dgram\ndaytime-stream\necho-dgram\necho-stream\ntcpmux-server\navahi-daemon\ncups" > $tdir/disable_serv.txt
fnm=$tdir/disable_serv.txt
check_file $fnm >> $logfile

##Changing patch_check.sh persmission
chmod +x $tdir/patch_check.sh 2>> $logfile

####Erasing Unwanted package
##Checking and errasing Package
echo -e "##Erasing Unwated Packages" >> $logfile
for pkg in `cat $tdir/patch_list.txt`
do
sh $tdir/patch_check.sh $pkg
if [ -s $tdir/$pkg ]
then
echo -e "..Errasing $pkg" >> $logfile
rpm -e --nodeps `cat $tdir/$pkg` 2>> $logfile
#echo `cat $tdir/$pkg` >> $logfile
command_status >> $logfile
else
echo -e "..$pkg package not installed" >> $logfile
fi
done

###Changing Ownership and Permission
##Changing Ownership
echo -e "Changing Ownership" >> $logfile
for _chown in `cat $tdir/owner_change.txt`
do
echo -e ".Changing Ownership for $_chown" >> $logfile
chown root:root /etc/$_chown 2>> $logfile
#echo "chmod ----" >> $logfile
command_status >> $logfile
done
##Changing Permission
echo -e "Changing Permission" >> $logfile
for _chmod in `cat $tdir/perm_change.txt`
do
echo -e ".Changing Permission for $_chmod" >> $logfile
chmod og-rwx /etc/$_chmod 2>> $logfile
#echo "chmod-----" >> $logfile
command_status >> $logfile
done

###Disabling service on boot
echo -e "Disable services form boot" >> $logfile
for _disavle_serv in `cat $tdir/disable_serv.txt`
do
echo -e ".Disabling $_disavle_serv from boot" >> $logfile
chkconfig $_disavle_serv off 2>> $logfile
#echo -e ".Disables" >> $logfile
command_status >> $logfile
done

##Changing Permission for sshd_config file
echo -e "Changing Permission for sshd_config file" >> $logfile
cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config_$dt 2>> $logfile
echo -e "File Backup completed" >> $logfile
chmod 600 /etc/ssh/sshd_config 2>> $logfile
command_status >> $logfile 

##Set Deamon Umask
echo -e "Set Deamon Umask" >> $logfile
cp -p /etc/sysconfig/init /etc/sysconfig/init_$dt 2>> $logfile
echo -e "File Backup completed" >> $logfile
echo -E "umask 027" >> /etc/sysconfig/init
command_status >> $logfile

##Changing Permission 644 
echo -e "Chnging Permission for passwd file" >> $logfile
cp -p /etc/passwd /etc/passwd_$dt 2>> $logfile
chmod 644 /etc/passwd 2>> $logfile
command_status >> $logfile
echo -e "Changing Permission for gshadow" >> $logfile
cp -p /etc/gshadow /etc/gshadow_$dt 2>> $logfile
chmod 644 /etc/gshadow 2>> $logfile
command_status >> $logfile
echo -e "Changing Permission for group file" >> $logfile
cp -p /etc/group /etc/group_$dt 2>> $logfile
chmod 644 /etc/group 2>> $logfile
command_status >> $logfile

##Remove unwanted TTY 
echo -e "Remove unwanted TTY from securetty file" >> $logfile
echo -e ".Backup securetty file" >> $logfile
cp /etc/securetty /etc/securetty_bkp_$dt 2>> $logfile
command_status >> $logfile
echo -e ".Hashing Unwanted tty's" >> $logfile
sed 's/^/#/g' /etc/securetty_bkp_$dt > /etc/securetty
command_status >> $logfile
echo -e "Enabling required TTY's" >> $logfile
echo "tty1" >> /etc/securetty
echo "tty2" >> /etc/securetty
command_status >> $logfile

##User Modification
echo -e "Lock unwanted users and set nologin shell" >> $logfile
echo -e ".Backup passwd file" >> $logfile
cp -p /etc/passwd /etc/passwd_mod_$dt 2>> $logfile
command_status >> $logfile
for user in `awk -F: '$3<499 {print $1}' /etc/passwd`
do
if [ $user != root ]
then
echo -e ".Locking $user" >> $logfile
usermod -L $user 2>> $logfile
command_status >> $logfile
if [[ $user != "root" && $user != "sync" && $user != "shutdown" && $user != "halt" ]]
then
echo -e "Setting nologin shell for $user" >> $logfile
usermod -s /sbin/nologin $user 2>> $logfile
command_status >> $logfile
fi
fi
done

echo -e "Hardening Phase I completed" >> $logfile

##End of Phase 1

#Hardening Phase II

echo -e "Hardening Phase II initiated" >> $logfile

## Erase Telnet Package
#Checking For package
echo -e "Checking Telnet Package" >> $logfile
rpm -qa | grep telnet &>> $logfile
if [ `echo $?` == 0 ]
then
if [ `ps -ef | grep telnet | grep -v grep; echo $?` == 1 ]
then
echo -e "Errasing Telnet Package" >> $logfile
rpm -e --nodeps telnet 2>> $logfile
command_status >> $logfile
else
echo -e "Telnet service is getting used" >> $logfile
fi
else
echo -e "Telnet is not installed" >> $logfile
fi

echo -e "Checking DHCP Package" >> $logfile
rpm -qa | grep dhcp &>> $logfile
if [ `echo $?` == 0 ]
then
if [ `ps -ef | grep dhcp | grep -v grep; echo $?` == 1 ]
then
echo -e "Errasing DHCP Package" >> $logfile
rpm -e --nodeps dhcp 2>> $logfile
rpm -e --nodeps dhcp-common 2>> $logfile
command_status >> $logfile
else
echo -e "DHCP service is getting used" >> $logfile
fi
else
echo -e "DHCP is not installed" >> $logfile
fi

echo -e "Checking DNS(NAMED) Package" >> $logfile
rpm -qa | grep named &>> $logfile
if [ `echo $?` == 0 ]
then
if [ `ps -ef | grep named | grep -v grep; echo $?` == 1 ]
then
echo -e "Errasing named Package" >> $logfile
rpm -e --nodeps named 2>> $logfile
command_status >> $logfile
else
echo -e "DNS(NAMED) service is getting used" >> $logfile
fi
else
echo -e "DNS(NAMED) is not installed" >> $logfile
fi

echo -e "Checking Dovecot Package" >> $logfile
rpm -qa | grep dovecot &>> $logfile
if [ `echo $?` == 0 ]
then
if [ `ps -ef | grep dovecot | grep -v grep; echo $?` == 1 ]
then
echo -e "Errasing dovecot Package" >> $logfile
rpm -e --nodeps dovecot 2>> $logfile
command_status >> $logfile
else
echo -e "Dovecot service is getting used" >> $logfile
fi
else
echo -e "Dovecot is not installed" >> $logfile
fi


echo -e "Checking SAMBA Package" >> $logfile
rpm -qa | grep samba &>> $logfile
if [ `echo $?` == 0 ]
then
if [ `ps -ef | grep smb | grep -v grep; echo $?` == 1 ]
then
echo -e "Errasing samba Package" >> $logfile
rpm -e --nodeps samba 2>> $logfile
command_status >> $logfile
else
echo -e "SAMBA service is getting used" >> $logfile
fi
else
echo -e "SAMBA is not installed" >> $logfile
fi


echo -e "Checking FTP Package" >> $logfile
rpm -qa | grep vsftpd &>> $logfile
if [ `echo $?` == 0 ]
then
ftpstat=`ps -ef | grep 'vsftpd' | awk '{print $8}'| grep -v 'grep' | head -1 ; echo $?`
if [[ $ftpstat == 1 ]]
then
echo -e "Errasing vsftpd Package" >> $logfile
rpm -e --nodeps vsftpd 2>> $logfile
command_status >> $logfile
else
echo -e "FTP service is getting used" >> $logfile
fi
else
echo -e "FTP is not installed" >> $logfile
fi



echo -e "Checking SQUID Package" >> $logfile
rpm -qa | grep squid &>> $logfile
if [ `echo $?` == 0 ]
then
if [ `ps -ef | grep squid | grep -v grep; echo $?` == 1 ]
then
echo -e "Errasing squid Package" >> $logfile
rpm -e --nodeps squid 2>> $logfile
command_status >> $logfile
else
echo -e "SQUID service is getting used" >> $logfile
fi
else
echo -e "SQUID is not installed" >> $logfile
fi


## Configuring Logrotate
#Backup the required files
echo -e "Backup rsyslog file" >> $logfile
mv /etc/logrotate.d/rsyslog $bdir 2>> $logfile
command_status >> $logfile
echo -e "Creating file for logrotate" >> $logfile
echo -e "/var/log/maillog\n/var/log/maillog\n/var/log/secure\n{\n    rotate 30\n    daily\n    missingok\n    notifempty\n    sharedscripts\n    compress\n    delaycompress\n            /bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> /dev/null || true\n    endscript\n}" > /etc/logrotate.d/rsyslog
command_status >> $logfile
check_file /etc/logrotate.d/rsyslog >> $logfile
echo -e "Restart rsyslog service" >> $logfile
/etc/init.d/rsyslog restart &>> $logfile
command_status >> $logfile

## Configuration HTTP Logrotate
echo -e "Checking HTTP service" >> $logfile
ps -ef | grep httpd | grep -v 'grep' | head -1 &>> $logfile
if [ `echo $?` == 0 ]
then
#Backup the required files
echo -e "HTTP service running on server\nBackup http logrotate file" >> $logfile
mv /etc/logrotate.d/http* $bdir 2>> $logfile
command_status >> $logfile
echo -e "Creating file for logrotate" >> $logfile
echo -e "/var/log/httpd/*log {\n    rotate 30\n    daily\n    missingok\n    notifempty\n    sharedscripts\n    compress\n    delaycompress\n    postrotate\n        /sbin/service httpd reload > /dev/null 2>/dev/null || true\n    endscript\n}" > /etc/logrotate.d/http
command_status >> $logfile
check_file /etc/logrotate.d/http >> $logfile
else
echo -e "Server is not runing with HTTP" >> $logfile
fi

echo -e "Hardening Phase II completed" >> $logfile

#End of Phase II


# Hardening Phase III
echo -e "Hardening Phase III initiated" >> $logfile

#Set nodev and nosuid option for /tmp Partition
echo -e "Setting nodev, noexec and nosuid options to /tmp" &>> $logfile
mount -o remount,nodev,nosuid,noexec /tmp &>> $logfile
command_status &>> $logfile
echo -e "Setting nodev and nosuid options to /tmp on System Boot" &>> $logfile
echo -E "mount -o remount,nodev,nosuid,noexec /tmp" >> /etc/rc.local
command_status &>> $logfile

#Set nodev and nosuid option for /var/tmp Partition
echo -e "Setting nodev, noexec and nosuid options to /var/tmp" &>> $logfile
mount -o remount,nodev,nosuid,noexec /var/tmp &>> $logfile
command_status &>> $logfile
echo -e "Setting nodev and nosuid options to /var/tmp on System Boot" &>> $logfile
echo -E "mount -o remount,nodev,nosuid,noexec /var/tmp" >> /etc/rc.local
command_status &>> $logfile

#Bind Mount the /var/tmp directory to /tmp
echo -e "Bind Mount the /var/tmp directory to /tmp" &>> $logfile
mount --bind /tmp /var/tmp
command_status &>> $logfile
echo -e "Bind Mount the /var/tmp directory to /tmp on System Boot" &>> $logfile
echo -E "mount --bind /tmp /var/tmp" >> /etc/rc.local
command_status &>> $logfile

#Add nodev Option to /home
echo -e "Add nodev Option to /home" &>> $logfile
mount -o remount,nodev /home &>> $logfile
command_status &>> $logfile
echo -e "Add nodev Option to /home on System Boot" &>> $logfile
echo -E "mount -o remount,nodev /home" >> /etc/rc.local
command_status &>> $logfile

#Add nodev, noexec and nosuid Option to /dev/shm Partition
echo -e "Add nodev, noexec and nosuid Option to /dev/shm Partition" &>> $logfile
mount -o remount,nodev,noexec,nosuid /dev/shm &>> /$logfile
command_status &>> $logfile
echo -e "Add nodev, noexec and nosuid Option to /dev/shm Partition on System Boot" &>> $logfile
echo -E "mount -o remount,nodev,noexec,nosuid /dev/shm" >> /etc/rc.local
command_status &>> $logfile

#Disable Mounting of cramfs Filesystems
echo -e "Disable Mounting of cramfs Filesystems" &>> $logfile
if [ -f /etc/modprobe.d/blacklist.conf ]
then
echo -e "  blacklist.conf file exist. Now Disabling cramfs FS" &>> $logfile
echo -E "blacklist cramfs" >> /etc/modprobe.d/blacklist.conf
cat /etc/modprobe.d/blacklist.conf | grep 'blacklist cramfs' &> /dev/null
command_status &>> $logfile
else
echo -e "Creating blacklist.conf file and disabling cramfs FS" &>> $logfile
echo -E "blacklist cramfs" >> /etc/modprobe.d/blacklist.conf
cat /etc/modprobe.d/blacklist.conf | grep 'blacklist cramfs' &> /dev/null
command_status &>> $logfile
fi

#Disable Mounting of jfss2 Filesystems
echo -e "Disable Mounting of jfss2 Filesystems" &>> $logfile
if [ -f /etc/modprobe.d/blacklist.conf ]
then
echo -e "  blacklist.conf file exist. Now Disabling jfss2 FS" &>> $logfile
echo -E "blacklist jfss2" >> /etc/modprobe.d/blacklist.conf
cat /etc/modprobe.d/blacklist.conf | grep 'blacklist jfss2' &> /dev/null
command_status &>> $logfile
else
echo -e "Creating blacklist.conf file and disabling jfss2 FS" &>> $logfile
echo -E "blacklist jfss2" >> /etc/modprobe.d/blacklist.conf
cat /etc/modprobe.d/blacklist.conf | grep 'blacklist jfss2' &> /dev/null
command_status &>> $logfile
fi

#Disable Mounting of squashfs Filesystems
echo -e "Disable Mounting of squashfs Filesystems" &>> $logfile
if [ -f /etc/modprobe.d/blacklist.conf ]
then
echo -e "  blacklist.conf file exist. Now Disabling squashfs FS" &>> $logfile
echo -E "blacklist squashfs" >> /etc/modprobe.d/blacklist.conf
cat /etc/modprobe.d/blacklist.conf | grep 'blacklist squashfs' &> /dev/null
command_status &>> $logfile
else
echo -e "Creating blacklist.conf file and disabling squashfs FS" &>> $logfile
echo -E "blacklist squashfs" >> /etc/modprobe.d/blacklist.conf
cat /etc/modprobe.d/blacklist.conf | grep 'blacklist squashfs' &> /dev/null
command_status &>> $logfile
fi

#Disable Mounting of vfat Filesystems
echo -e "Disable Mounting of vfat Filesystems" &>> $logfile
if [ -f /etc/modprobe.d/blacklist.conf ]
then
echo -e "  blacklist.conf file exist. Now Disabling vfat FS" &>> $logfile
echo -E "blacklist vfat" >> /etc/modprobe.d/blacklist.conf
cat /etc/modprobe.d/blacklist.conf | grep 'blacklist vfat' &> /dev/null
command_status &>> $logfile
else
echo -e "Creating blacklist.conf file and disabling vfat FS" &>> $logfile
echo -E "blacklist vfat" >> /etc/modprobe.d/blacklist.conf
cat /etc/modprobe.d/blacklist.conf | grep 'blacklist vfat' &> /dev/null
command_status &>> $logfile
fi


#Set SSH Banner
#Creating SSH banner file
echo -e "+-----------------------------------------------------------------+" >> /tmp/ssh_banner
echo -e "| This system is for the use of authorized users only.            |" >> /tmp/ssh_banner
echo -e "| Individuals using this computer system without authority, or in |" >> /tmp/ssh_banner
echo -e "| excess of their authority, are subject to having all of their   |" >> /tmp/ssh_banner
echo -e "| activities on this system monitored and recorded by system      |" >> /tmp/ssh_banner
echo -e "| personnel.                                                      |" >> /tmp/ssh_banner
echo -e "|                                                                 |" >> /tmp/ssh_banner
echo -e "| In the course of monitoring individuals improperly using this   |" >> /tmp/ssh_banner
echo -e "| system, or in the course of system maintenance, the activities  |" >> /tmp/ssh_banner
echo -e "| of authorized users may also be monitored.                      |" >> /tmp/ssh_banner
echo -e "|                                                                 |" >> /tmp/ssh_banner
echo -e "| Anyone using this system expressly consents to such monitoring  |" >> /tmp/ssh_banner
echo -e "| and is advised that if such monitoring reveals possible         |" >> /tmp/ssh_banner
echo -e "| evidence of criminal activity, system personnel may provide the |" >> /tmp/ssh_banner
echo -e "| evidence of such monitoring to law enforcement officials.       |" >> /tmp/ssh_banner
echo -e "|                                                                 |" >> /tmp/ssh_banner
echo -e "|               If you have any questions or need support         |" >> /tmp/ssh_banner
echo -e "|               Please e-mail Group IT ServiceDesk                |" >> /tmp/ssh_banner
echo -e "|               E-mail: ithelp.global@domainname.com         	   |" >> /tmp/ssh_banner
echo -e "|                                                                 |" >> /tmp/ssh_banner
echo -e "+-----------------------------------------------------------------+" >> /tmp/ssh_banner

echo -e "Copy SSH Banner file" &>> $logfile
cp /tmp/ssh_banner /etc/ssh/ &>> $logfile
command_status &>> $logfile
echo -e "Updating config file" &>> $logfile
echo -E "Banner /etc/ssh/ssh_banner" >> /etc/ssh/sshd_config
command_status &>> $logfile
echo -e "Change owner permission of banner file" &>> $logfile
chown root:root /etc/ssh/ssh_banner &>> $logfile
command_status &>> $logfile
echo -e "Change access permission of banner file" &>> $logfile
chmod 644 /etc/ssh/ssh_banner &>> $logfile
command_status &>> $logfile
echo -e "Restarting SSH service" &>> $logfile
/etc/init.d/sshd restart &>> $logfile
echo -e "Enable SSH service on Boot" &>> $logfile
chkconfig sshd on &>> $logfile
command_status &>> $logfile

#Set Default umask for Users
echo -e "Set Default umask for Users except 'Oracle'" &>> $logfile
for _file in `locate bashrc | egrep -v '(oracle|etc)'`
do
echo -E "UMASK=077" >> $_file
echo -e "Updated umask in $_file" &>> $logfile
done

#Disable SSH X11 Forwarding
echo -e "Disable SSH X11 Forwarding" &>> $logfile
echo -E "X11Forwarding no" >> /etc/ssh/sshd_config
command_status &>> $logfile

#Check User Dot File Permissions
echo -e "Checking (dot) files and remove write permission" &>> $logfile
for _dfile in `ls -ld $HOME/.[A-Za-z0-9]* | awk '{print $NF}'`
do
chmod go-w $_dfile &>> $logfile
echo -e "Write access revoked for $_dfile" &>> $logfile
done

echo -e "Hardening Phase III completed" >> $logfile
#End of Hardening Phase III

#Hardening Phase IV initiated

echo -e "Hardening Phase IV initiated" >> $logfile

#Backup sysctl.conf and limits.conf files
echo -e "Backup sysctl.conf file" &>> $logfile
cp /etc/sysctl.conf /root/sysctl.conf_$dt
command_status &>> $logfile
echo -e "Backup limits.conf file" &>> $logfile
cp /etc/security/limits.conf /root/limits.conf_$dt
command_status &>> $logfile

#Disable interactive Boot
echo -e "Disable interactive Boot" &>> $logfile
sed -i.bkp 's/^PROMPT=yes/PROMPT=no/' /etc/sysconfig/init &>> $logfile
command_status &>> $logfile

#Disable Send Packet Redirects
echo -e "Disable Send Packet Redirects" &>> $logfile
echo -E "#Disable Send Packet Redirects" >> /etc/sysctl.conf
echo -E "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf
command_status &>> $logfile
echo -E "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf
command_status &>> $logfile
echo >> /etc/sysctl.conf

#Disable ICMP Redirect Acceptance
echo -e "Disable ICMP Redirect Acceptance" &>> $logfile
echo -E "#Disable ICMP Redirect Acceptance" >> /etc/sysctl.conf
echo -E "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
command_status &>> $logfile
echo -E "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.conf
command_status &>> $logfile
echo >> /etc/sysctl.conf

#Disable Secure ICMP Redirect Acceptance
echo -e "Disable Secure ICMP Redirect Acceptance" &>> $logfile
echo -E "#Disable Secure ICMP Redirect Acceptance" >> /etc/sysctl.conf
echo -E "net.ipv4.conf.all.secure_redirects = 0" >> /etc/sysctl.conf
command_status &>> $logfile
echo -E "net.ipv4.conf.default.secure_redirects = 0" >> /etc/sysctl.conf
command_status &>> $logfile
echo >> /etc/sysctl.conf

#Log Suspicious Packets
echo -e "Log Suspicious Packets" &>> $logfile
echo -E "#Log Suspicious Packets" >> /etc/sysctl.conf
echo -E "net.ipv4.conf.all.log_martians = 1" >> /etc/sysctl.conf
command_status &>> $logfile
echo -E "net.ipv4.conf.default.log_martians = 1" >> /etc/sysctl.conf
command_status &>> $logfile
echo >> /etc/sysctl.conf

#Disable IPv6 Router Advertisements
echo -e "Disable IPv6 Router Advertisements" &>> $logfile
echo -E "#Disable IPv6 Router Advertisements" >> /etc/sysctl.conf
echo -E "net.ipv6.conf.all.accept_ra = 0" >> /etc/sysctl.conf
command_status &>> $logfile
echo -E "net.ipv6.conf.default.accept_ra = 0" >> /etc/sysctl.conf
command_status &>> $logfile
echo >> /etc/sysctl.conf

#Disable IPv6 Redirect Acceptance
echo -e "Disable IPv6 Redirect Acceptance" &>> $logfile
echo -E "#Disable IPv6 Redirect Acceptance" >> /etc/sysctl.conf
echo -E "net.ipv6.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
command_status &>> $logfile
echo -E "net.ipv6.conf.default.accept_redirects = 0" >> /etc/sysctl.conf
command_status &>> $logfile
echo >> /etc/sysctl.conf

#Restrict Core Dumps
echo -e "Restrict Core Dumps in sysctl.conf" &>> $logfile
echo -E "#Restrict Core Dumps" >> /etc/sysctl.conf
echo -E "fs.suid_dumpable = 0" >> /etc/sysctl.conf
command_status &>> $logfile
echo >> /etc/sysctl.conf
echo -e "Restrict Core Dump in limits.conf" &>> $logfile
echo -E "#Restrict Core Dump" >> /etc/security/limits.conf
echo -E "* hard core 0" >> /etc/security/limits.conf
command_status &>> $logfile

#Configure ExecShield
echo -e "Configure ExecShield" &>> $logfile
echo -E "#Configure ExecShield" >> /etc/sysctl.conf
echo -E "kernel.exec-shield = 1" >> /etc/sysctl.conf
command_status &>> $logfile
echo >> /etc/sysctl.conf

#Enable Randomized Virtual Memory Region Placement
echo -e "Enable Randomized Virtual Memory Region Placement" &>> $logfile
echo -E "#Enable Randomized Virtual Memory Region Placement" >> /etc/sysctl.conf
echo -E "kernel.randomize_va_space = 2" >> /etc/sysctl.conf
command_status &>> $logfile
echo >> /etc/sysctl.conf

#Disable IP Forwarding
echo -e "Disable IP Forwarding" &>> $logfile
echo -E "#Disable IP Forwarding" >> /etc/sysctl.conf
echo -E "net.ipv4.ip_forward = 0" >> /etc/sysctl.conf
command_status &>> $logfile
echo >> /etc/sysctl.conf

#Disable Source Routed Packet Acceptance
echo -e "Disable Source Routed Packet Acceptance" &>> $logfile
echo -E "#Disable Source Routed Packet Acceptance" >> /etc/sysctl.conf
echo -E "net.ipv4.conf.all.accept_source_route = 0" >> /etc/sysctl.conf
command_status &>> $logfile
echo -E "net.ipv4.conf.default.accept_source_route = 0" >> /etc/sysctl.conf
command_status &>> $logfile
echo >> /etc/sysctl.conf

#Enable Ignore Broadcast Requests
echo -e "Enable Ignore Broadcast Requests" &>> $logfile
echo -E "#Enable Ignore Broadcast Requests" >> /etc/sysctl.conf
echo -E "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> /etc/sysctl.conf
command_status &>> $logfile
echo >> /etc/sysctl.conf

#Enable Bad Error Message Protection
echo -e "Enable Bad Error Message Protection" &>> $logfile
echo -E "#Enable Bad Error Message Protection" >> /etc/sysctl.conf
echo -E "net.ipv4.icmp_ignore_bogus_error_responses = 1" >> /etc/sysctl.conf
command_status &>> $logfile
echo >> /etc/sysctl.conf

#Enable TCP SYN Cookies
echo -e "Enable TCP SYN Cookies" &>> $logfile
echo -E "#Enable TCP SYN Cookies" >> /etc/sysctl.conf
echo -E "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
command_status &>> $logfile
#echo >> /etc/sysctl.conf

#Enabling all parameters
echo -e "sysctl parameters" &>> $logfile
echo -e "*******************************" &>> $logfile
sysctl -p &>> $logfile
echo -e "*******************************" &>> $logfile
sysctl -p &>> $logfile

echo -e "Hardening Phase IV completed" &>> $logfile
#End of Hardening Phase IV


##Server configuration##

##Configure APAC Repository
ls /etc/yum.repos.d/my.repo &> /dev/null
if [ `echo $?` == 0 ]
then
echo -e "Repo file available"
else
echo -e "[MYREPO]" >> /etc/yum.repos.d/my.repo
echo -e "name=Red Hat Enterprise Linux" >> /etc/yum.repos.d/my.repo
echo -e "baseurl=http://10.102.17.250/YUMUPDATE64Bit63/" >> /etc/yum.repos.d/my.repo
echo -e "enabled=1" >> /etc/yum.repos.d/my.repo
echo -e "gpgcheck=1" >> /etc/yum.repos.d/my.repo
echo -e "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release" >> /etc/yum.repos.d/my.repo
echo -e "Repo file configured successfull" &>> $logfile
fi

##User configuration: confusr and sysadmin
/usr/bin/passwd -x 99999 confusr &>> $logfile
/usr/sbin/useradd sysadmin &>> $logfile
echo 'Service@123' | passwd sysadmin --stdin &>> $logfile
/usr/bin/passwd -x 99999 sysadmin &>> $logfile

#Grant confusr root previledges
echo -e "Granting confusr root previledges" &>> $logfile
echo -e "confusr	ALL=(ALL)       ALL" >> /etc/sudoers
command_status &>> $logfile

echo -e "Granting sysadmin root previledges" &>> $logfile
echo -e "sysadmin	ALL=(ALL)       ALL" >> /etc/sudoers
command_status &>> $logfile

##Remove temp files/Dir
echo -e "Remove temporary files and directory" &>> $logfile
rm -rf /root/hardening
command_status &>> $logfile
echo -e "Temporary files removed" &>> $logfile

##Hardening Phase V
echo -e "Hardening Phase V initiated" &>> $logfile

#Remove default repository file
echo -e "Removing default repository file redhat.repo" &>> logfile
mv /etc/yum.repos.d/redhat.repo $bdir
command_status &>> $logfile

#Add AIDE check in crontab
echo -e "Add aide periodic check" &>> $logfile
echo -E "0 5 * * * root /usr/sbin/aide --check" >> /etc/crontab
command_status &>> $logfile

#Set ASLR kernel parameter in sysctl
echo -e "Changing ASLR kernel parameter in sysctl.conf" &>> $logfile
/bin/sed -i.bkp 's/kernel.randomize_va_space \= 1/kernel.randomize_va_space \= 2/' /etc/sysctl.conf
command_status &>> $logfile
echo &>> $logfile

#Uninstall prelink 
echo -e "Uninstall prelink if exist in server" &>> $logfile
rpm -q prelink &>> logfile
if [ `echo $?` == 0 ]
then
	echo -e "..Removing prelink package from server" &>> $logfile
	prelink -ua &>> $logfile
	yum remove prelink -y &>> $logfile
else
	echo -e "..Prelink not installed on server" &>> $logfile
fi

#Disable xinetd service from onboot
echo -e "Disable xinetd service from onboot" &>> $logfile
chkconfig off xinetd &>> $logfile
command_status &>> $logfile

#Modify ntp.conf parameter restrict -4
echo -e "Add restrict -4 parameter to ntp.conf" &>> $logfile
/bin/sed -i.bkp 's/restrict default kod nomodify notrap nopeer noquery/restrict \-4 default kod nomodify notrap nopeer noquery/' /etc/ntp.conf
command_status &>> $logfile

#Add grep FileCreateMode 0640 in rsyslog.conf
echo -e "Define rsyslog default file permission" &>> $logfile
grep ^\$FileCreateMode /etc/rsyslog.conf
if [ `echo $?` == 0 ]
then
	echo -e "rsyslog default file permission already defined" &>> /$logfile
else
	echo -E "$FileCreateMode 0640" >> /etc/rsyslog.conf
	command_status &>> $logfile
fi

#Setting permission to all log files under /var/log/
echo -e "Setting permission to all log files under /var/log" &>> $logfile
find /var/log -type f -exec chmod g-wx,o-rwx {} +
command_status &>> $logfile

#set ownership and permission to /etc/crontab file
echo -e "Set permission and ownership of /etc/crontab file" &>> $logfile
chmod og-rwx /etc/crontab &>> $logfile;  chown root:root /etc/crontab &>> $logfile
command_status &>> $logfile

#Setting cron and at files restrictions
echo -e "Setting cron and at files restrictions" &>> $logfile
#Createing .allow files
echo -e "Creating cron.allow and at.allow files" &>> $logfile
touch /etc/cron.allow /etc/at.allow
command_status &>> $logfile

#Removing cron.deny file
echo -e "Removing cron.deny" &>> $logfile
rm -rf /etc/cron.deny &>> $logfile
command_status &>> $logfile

#Removing at.deny file
echo -e "Removing at.deny" &>> $logfile
rm -rf /etc/at.deny &>> $logfile
command_status &>> $logfile

#Changing File permission for cron.allow
echo -e "Changing File permission for cron.allow" &>> $logfile
chmod og-rwx /etc/cron.allow &>> $logfile
command_status &>> $logfile

#Changing File permission for at.allow
echo -e "Changing File permission for at.allow" &>> $logfile
chmod og-rwx /etc/at.allow &>> $logfile
command_status &>> $logfile

#Changing File owner for cron.allow
echo -e "Changing File owner for cron.allow" &>> $logfile
chown root:root /etc/cron.allow &>> $logfile
command_status &>> $logfile

#Changing File owner for at.allow
echo -e "Changing File owner for at.allow" &>> $logfile
chown root:root /etc/at.allow &>> $logfile
command_status &>> $logfile
echo -e "cron and at file configuration complete" &>> $logfile\nfi\ncd


#Changing File permission for /etc/ssh/sshd_config
echo -e "Changing File permission for sshd_config" &>> $logfile
chmod og-rwx /etc/ssh/sshd_config &>> $logfile
command_status &>> $logfile

#Changing File owner for sshd_config
echo -e "Changing File owner for sshd_config" &>> $logfile
chown root:root /etc/ssh/sshd_config &>> $logfile
command_status &>> $logfile

#Enabling log level for sshd_config
echo -e "Enabling log level for sshd_config" &>> $logfile
echo -E "LogLevel INFO" >> /etc/ssh/sshd_config
command_status &>> $logfile

#Disable PermitEmptyPasswords to no
echo -e "Disable PermitEmptyPasswords to no" &>> $logfile
echo -E "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
command_status &>> $logfile

#Enabling ciphers for sshd_config
echo -e "Enabling ciphers for sshd_config" &>> $logfile
echo -E "Ciphers aes256-ctr,aes192-ctr,aes128-ctr" >> /etc/ssh/sshd_config
command_status &>> $logfile

#Enabling client alive for sshd_config
echo -e "Enabling client alive interval for sshd_config" &>> $logfile
echo -E "ClientAliveInterval 300" >> /etc/ssh/sshd_config
command_status &>> $logfile

echo -e "Enabling client alive count for sshd_config" &>> $logfile
echo -E "ClientAliveCountMax 3" >> /etc/ssh/sshd_config
command_status &>> $logfile

echo -e "Enabling LoginGraceTime for sshd_config" &>> $logfile
echo -E "LoginGraceTime 60" >> /etc/ssh/sshd_config
command_status &>> $logfile

echo -e "Setting default user umask in bashrc" &>> $logfile
echo -E "umask 027" >> /etc/bashrc
command_status &>> $logfile

echo -e "Setting default user umask in profile" &>> $logfile
echo -E "umask 027" >> /etc/profile
command_status &>> $logfile

#Ensure permissions on /etc/passwd
echo -e "Changing /etc/passwd permission" &>> $logfile
chmod 644 /etc/passwd &>> $logfile
command_status &>> $logfile

#Ensure owner of /etc/passwd
echo -e "Changing /etc/passwd owner" &>> $logfile
chown root:root /etc/passwd &>> $logfile
command_status &>> $logfile

#Ensure permissions on /etc/shadow
echo -e "Changing /etc/shadow permission" &>> $logfile
chmod 644 /etc/shadow &>> $logfile
command_status &>> $logfile

#Ensure owner of /etc/shadow
echo -e "Changing /etc/shadow owner" &>> $logfile
chown root:root /etc/shadow &>> $logfile
command_status &>> $logfile

#Ensure permissions on /etc/group
echo -e "Changing /etc/group permission" &>> $logfile
chmod 644 /etc/group &>> $logfile
command_status &>> $logfile

#Ensure owner of /etc/group
echo -e "Changing /etc/group owner" &>> $logfile
chown root:root /etc/group &>> $logfile
command_status &>> $logfile

#Ensure permissions on /etc/gshadow
echo -e "Changing /etc/gshadow permission" &>> $logfile
chmod 644 /etc/gshadow &>> $logfile
command_status &>> $logfile

#Ensure owner of /etc/gshadow
echo -e "Changing /etc/gshadow owner" &>> $logfile
chown root:root /etc/gshadow &>> $logfile
command_status &>> $logfile

