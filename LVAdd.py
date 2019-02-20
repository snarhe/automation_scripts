#Script Name: BOT Code
#Version: V1.0
#Developer: Sunil Narhe<sunil.narhe@capgemini.com>
#Description: This script perform LVM Disk Utility 

#Load Python lib
import paramiko, argparse, glob, os, subprocess, re
from time import strftime
import smtplib
from os import path
from socket import gethostname

#Input Section
smtp_server = "192.168.208.219"
smtp_port = 25
email_bot_from_address = "noreply@seq.com"
email_bot_to_address = "hpoperations.in@capgemini.com"
bot_execution_id = "Test001"
USER = "root"
ssh_port = 22
ssh_key = paramiko.RSAKey.from_private_key_file("/root/.ssh/id_rsa")


#BOT_CODE_PART_1
script_start_dt = strftime("%Y-%m-%d %H:%M:%S")
script_file_nm = path.basename(__file__).split(".")[0]
server_nm = gethostname()
email_bot_subject = "AUR-"+str(script_file_nm)

#Getting argument passed to script
def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-s','--server', help='Server IP/Hostname', required=True)
    parser.add_argument('-v','--volume', help='Volume group name', required=False)
    parser.add_argument('-l','--lvolume', help='Logical volume name', required=False)
    parser.add_argument('-o','--operation', help="LV operation add/extend", required=True)
    parser.add_argument('-ls','--lsize', type=int, help="Logical Volume Size in GB", required=True)
    arguments = parser.parse_args()
    HOST = arguments.server
    VOLUME = arguments.volume
    LVOLUME = arguments.lvolume
    OPERATION = arguments.operation
    LSIZE = arguments.lsize
    return HOST, VOLUME, LVOLUME, OPERATION, LSIZE
HOST, VOLUME, LVOLUME, OPERATION, LSIZE = get_args()

def disk_util():
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname=HOST,port=ssh_port,username=USER,pkey=ssh_key)
        def disk_scan():
            stdin, stdout, stderr = ssh.exec_command("ls /sys/class/scsi_host/ | wc -l")
            SCSICOUNT = int(stdout.read().decode("utf-8"))
            stdin, stdout, stderr = ssh.exec_command("for((i=0;i<${};i=i+1));do `echo $i >> /tmp/path.txt`;done".format(SCSICOUNT))
            stdin, stdout, stderr = ssh.exec_command('for SPATH in `cat /tmp/path.txt`; do `echo "/sys/class/scsi_host/host$SPATH/scan";echo "- - -"  > /sys/class/scsi_host/host$SPATH/scan`;done')
            stdin, stdout, stderr = ssh.exec_command("for NEW in `lsblk -f | awk '$2 ~ /^[ ]*$/ {print $1}'`; do blkid | grep $NEW > /dev/null ; if [ `echo $?` -ne 0 ] ; then echo $NEW; fi; done")
            NEWDISK = stdout.read().rstrip().decode("utf-8")
            stdin, stdout, stderr = ssh.exec_command("uname -r | awk -F'.' '{print $(NF-1)}'")
            OSRELEASE = stdout.read().rstrip().decode("utf-8")
            return NEWDISK, OSRELEASE
        def lv_add():
            NEWDISK, OSRELEASE = disk_scan()
            print "DISK:{}\nOS:{}".format(NEWDISK,OSRELEASE)
            stdin, stdout, stderr = ssh.exec_command("fdisk -l /dev/{} | grep Disk | cut -d' ' -f3".format(NEWDISK))
            NDISKS = int(stdout.read().decode("utf-8"))
            LSIZEM = (LSIZE * 1024) - 1024
            if LSIZEM >= LSIZE:
                stdin, stdout, stderr = ssh.exec_command("pvcreate /dev/{}".format(NEWDISK))
                PVMESSAGE = stdout.read().rstrip().decode("utf-8")
                print PVMESSAGE
                stdin, stdout, stderr = ssh.exec_command("vgcreate {} /dev/{}".format(VOLUME,NEWDISK))
                VGMESSAGE = stdout.read().rstrip().decode("utf-8")
                print VGMESSAGE
                stdin, stdout, stderr = ssh.exec_command("lvcreate -L +{}M -n {} {}".format(LSIZEM,LVOLUME,VOLUME))
                LVMESSAGE = stdout.read().rstrip().decode("utf-8")
                print LVMESSAGE
                stdin, stdout, stderr = ssh.exec_command("mkdir /{}".format(LVOLUME))
                if OSRELEASE == 'el7':
                    stdin, stdout, stderr = ssh.exec_command("mkfs.xfs /dev/mapper/{}-{}".format(VOLUME,LVOLUME))
                    stdin, stdout, stderr = ssh.exec_command('echo -E "/dev/mapper/{}-{}   /{}                       xfs     defaults        0 0" >> /etc/fstab'.format(VOLUME,LVOLUME,LVOLUME))
                elif OSRELEASE == 'el6':
                    stdin, stdout, stderr = ssh.exec_command("mkfs.ext4 /dev/mapper/{}-{}".format(VOLUME,LVOLUME))
                    stdin, stdout, stderr = ssh.exec_command('echo -E "/dev/mapper/{}-{}   /{}                       ext4     defaults        0 0" >> /etc/fstab'.format(VOLUME,LVOLUME,LVOLUME))
                else:
                    print "OS version not supported"
                    stdin, stdout, stderr = ssh.exec_command("rmdir /{}".format(LVOLUME))
                    stdin, stdout, stderr = ssh.exec_command("lvremove -f /dev/mapper/{}-{}".format(LVOLUME,VOLUME))
                    stdin, stdout, stderr = ssh.exec_command("vgremove {}".format(VOLUME))
                    stdin, stdout, stderr = ssh.exec_command("pvremove /dev/{}".format(NEWDISK))
                stdin, stdout, stderr = ssh.exec_command("mount -a")
                MOUNTMESSAGE = stdout.read().decode("utf-8")
                print MOUNTMESSAGE
            else:
                print "Required Space not available on Disk"
        lv_add()    
#        MOUNTNAME = stdout.read().splitlines()
#        print MOUNTNAME
#        if MOUNTNAME:
#            LVPATH = MOUNTNAME[0].split()[0]
#            FILEFORMAT = MOUNTNAME[0].split()[2]
#            stdin, stdout, stderr = ssh.exec_command("lvdisplay {}".format(LVPATH))
#            LVDETAILS = stdout.read().splitlines()
#            LVNAME = LVDETAILS[2].split()[2]
#            VGNAME = LVDETAILS[3].split()[2]
#            stdin, stdout, stderr = ssh.exec_command("vgs --noheadings {}".format(VGNAME))
#            FREEVG = stdout.read().split()[6].rstrip('g')
#            if int(FREEVG) > EXTEND:
#                
#            print LVNAME
#            print VGNAME
#            print FREEVG
#        else:
#            print "Mount point not available on server"
#Enable below lines only if Python 3.3 anb above
#    except TimeoutError as err:
#        print "Unable to connect {}".format(Host)
    except paramiko.AuthenticationException as error:
        print "{} Authentication failed".format(Host)
disk_util()

