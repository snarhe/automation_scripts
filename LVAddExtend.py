#Script Name: LV Disk Utility
#Version: V1.0
#Developer: Sunil Narhe<sunil.narhe@mailserver.com>
#Description: This script perform LVM Disk Utility 

#Load Python lib
import paramiko, argparse, glob, os, subprocess, re
from time import strftime
import smtplib
from os import path
from socket import gethostname

#Input Section
smtp_server = "localhost"
smtp_port = 25
email_bot_from_address = "noreply@mailserver.com"
email_bot_to_address = "hpoperations.in@mailserver.com"
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
            SCSICOUNT = int(stdout.read().rstrip().decode("utf-8"))
            for SCANCOUNT in range(SCSICOUNT):
                stdin, stdout, stderr = ssh.exec_command('echo "- - -" > /sys/class/scsi_host/host{}/scan'.format(SCANCOUNT))
            stdin, stdout, stderr = ssh.exec_command("for NEW in `lsblk -f | awk '$2 ~ /^[ ]*$/ {print $1}'`; do blkid | grep $NEW > /dev/null ; if [ `echo $?` -ne 0 ] ; then echo $NEW | grep -v sr0; fi; done")
            NEWDISK = stdout.read().rstrip().decode("utf-8")
            stdin, stdout, stderr = ssh.exec_command("uname -r | awk -F'.' '{print $(NF-1)}'")
            OSRELEASE = stdout.read().rstrip().decode("utf-8")
            return NEWDISK, OSRELEASE
        def lv_add():
            NEWDISK, OSRELEASE = disk_scan()
            def file_format(OS,VG,LV):
                if OS == 'el7':
                    stdin, stdout, stderr = ssh.exec_command("mkfs.xfs /dev/mapper/{}-{}".format(VG,LV))
                    stdin, stdout, stderr = ssh.exec_command('echo -E "/dev/mapper/{}-{}   /{}                       xfs     defaults        0 0" >> /etc/fstab'.format(VG,LV,LV))
                    stdin, stdout, stderr = ssh.exec_command("mount -a")
                elif OS == 'el6':
                    stdin, stdout, stderr = ssh.exec_command("mkfs.ext4 /dev/mapper/{}-{}".format(VOLUME,LVOLUME))
                    stdin, stdout, stderr = ssh.exec_command('echo -E "/dev/mapper/{}-{}   /{}                       ext4     defaults        0 0" >> /etc/fstab'.format(VG,LV,LV))
                    stdin, stdout, stderr = ssh.exec_command("mount -a")
                else:
                    return "False"
            stdin, stdout, stderr = ssh.exec_command("vgs {} --separator , --units m --noheadings | grep -o '[^,]*$'".format(VOLUME))
            SVOLUME = stdout.read().decode("utf-8")
            if SVOLUME:
                FSVOLUME = float(SVOLUME.replace('m',"").rstrip())
                if (FSVOLUME - 512.00) >= (LSIZE * 1024):
                    stdin, stdout, stderr = ssh.exec_command("lvcreate -L {}M -n {} {}".format(LSIZE * 1024,LVOLUME,VOLUME))
                    SLVMESSAGE = stdout.read().decode("utf-8")
                    print SLVMESSAGE
                    stdin, stdout, stderr = ssh.exec_command("mkdir /{}".format(LVOLUME))
                    FILEOUT = file_format(OSRELEASE,VOLUME,LVOLUME)
                    if FILEOUT == "False":
                        print "OS version not supported"
                        stdin, stdout, stderr = ssh.exec_command("rmdir /{}".format(LVOLUME))
                        stdin, stdout, stderr = ssh.exec_command("lvremove -f /dev/mapper/{}-{}".format(VOLUME,LVOLUME))
                elif NEWDISK:
                    print "Checking in New Disk"
                    stdin, stdout, stderr = ssh.exec_command("pvcreate /dev/{}".format(NEWDISK))
                    PVMESSAGE = stdout.read().rstrip().decode("utf-8")
                    print PVMESSAGE
                    stdin, stdout, stderr = ssh.exec_command("vgextend {} /dev/{}".format(VOLUME,NEWDISK))
                    VGMESSAGE = stdout.read().rstrip().decode("utf-8")
                    print VGMESSAGE
                    stdin, stdout, stderr = ssh.exec_command("vgs {} --separator , --units m --noheadings | grep -o '[^,]*$'".format(VOLUME))
                    HDVOLUME = stdout.read().decode("utf-8")
                    FHDVOLUME = float(HDVOLUME.replace('m',"").rstrip())
                    if float(FHDVOLUME - 512.00) >= (LSIZE * 1024):
                       stdin, stdout, stderr = ssh.exec_command("lvcreate -L {}M -n {} {}".format(LSIZE * 1024,LVOLUME,VOLUME))
                       SLVMESSAGE = stdout.read().decode("utf-8")
                       print SLVMESSAGE
                       stdin, stdout, stderr = ssh.exec_command("mkdir /{}".format(LVOLUME))
                       FILEOUT = file_format(OSRELEASE,VOLUME,LVOLUME)
                       if FILEOUT == "False":
                           print "OS version not supported"
                           stdin, stdout, stderr = ssh.exec_command("rmdir /{}".format(LVOLUME))
                           stdin, stdout, stderr = ssh.exec_command("lvremove -f /dev/mapper/{}-{}".format(VOLUME,LVOLUME))
                    stdin, stdout, stderr = ssh.exec_command("mount -a")
                else:
                    print "Required space not available on existing VG"
            elif NEWDISK:
                stdin, stdout, stderr = ssh.exec_command("fdisk -l /dev/{} | grep Disk | cut -d' ' -f3".format(NEWDISK))
                NDISKS = int(stdout.read().decode("utf-8"))
                LSIZEM = (LSIZE * 1024) - 512
                if LSIZEM <= NDISKS:
                    stdin, stdout, stderr = ssh.exec_command("pvcreate /dev/{}".format(NEWDISK))
                    PVMESSAGE = stdout.read().rstrip().decode("utf-8")
                    print PVMESSAGE
                    stdin, stdout, stderr = ssh.exec_command("vgcreate {} /dev/{}".format(VOLUME,NEWDISK))
                    VGMESSAGE = stdout.read().rstrip().decode("utf-8")
                    print VGMESSAGE
                    stdin, stdout, stderr = ssh.exec_command("lvcreate -L +{}M -n {} {}".format(LSIZE * 1024,LVOLUME,VOLUME))
                    LVMESSAGE = stdout.read().rstrip().decode("utf-8")
                    print LVMESSAGE
                    stdin, stdout, stderr = ssh.exec_command("mkdir /{}".format(LVOLUME))
                    FILEOUT = file_format(OSRELEASE,VOLUME,LVOLUME)
                    if FILEOUT == "False":
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
            else:
                 print "Disk not attached to machine"
        def lv_extend():
            NEWDISK, OSRELEASE = disk_scan()
            stdin, stdout, stderr = ssh.exec_command("df | grep -w {} | cut -d' ' -f1".format(LVOLUME))
            LVNAME = stdout.read().rstrip().decode("utf-8")
            print LVNAME
            stdin, stdout, stderr = ssh.exec_command("lvs --noheadings {} | cut -d' ' -f4".format(LVNAME))
            VGNAME = stdout.read().rstrip().decode("utf-8")
            stdin, stdout, stderr = ssh.exec_command("vgs {} --separator , --units m --noheadings | grep -o '[^,]*$'".format(VGNAME))
            VGSIZE = stdout.read().decode("utf-8")
            MVGSIZE = float(VGSIZE.replace('m',"").rstrip())
            def os_lvextend(OS,LV):
                stdin, stdout, stderr = ssh.exec_command("lvextend -L +{}M {}".format(LSIZE * 1024,LV))
                LVEXTENDM = stdout.read().rstrip().decode("utf-8")
                print LVEXTENDM
                if OS == 'el7':
                    print "Perfroming xfs grow for {}".format(LV)
                    stdin, stdout, stderr = ssh.exec_command("xfs_growfs {}".format(LV))
                elif OS == 'el6':
                    stdin, stdout, stderr = ssh.exec_command("resize2fs {}".format(LV))
                    print "Performing resize of {}".format(LV)
                else:
                    print "OS version not supported"
            if (MVGSIZE - 512.00) >= (LSIZE * 1024):
                print "Extending from existing VG"   
                os_lvextend(OSRELEASE,LVNAME)
            elif NEWDISK:
                print "Extending from New Disk"
                stdin, stdout, stderr = ssh.exec_command("pvcreate /dev/{}".format(NEWDISK))
                stdin, stdout, stderr = ssh.exec_command("vgextend {} /dev/{}".format(VGNAME,NEWDISK))
                stdin, stdout, stderr = ssh.exec_command("vgs {} --separator , --units m --noheadings | grep -o '[^,]*$'".format(VGNAME))
                HDVOLUME = stdout.read().decode("utf-8")
                FHDVOLUME = float(HDVOLUME.replace('m',"").rstrip())
                if float(FHDVOLUME - 512.00) >= (LSIZE * 1024):
                    os_lvextend(OSRELEASE,LVNAME)
                else:
                    print "Required space not available on New Disk"
            else:
                print "Required space not available on existing VG"
        if OPERATION == "add":
            lv_add()
        elif OPERATION == "extend":
            lv_extend()
        else:
            print "Operation not permitted. Use add/extend only"
#Enable below lines only if Python 3.3 anb above
#    except TimeoutError as err:
#        print "Unable to connect {}".format(Host)
    except paramiko.AuthenticationException as error:
        print "{} Authentication failed".format(Host)
disk_util()

#BOT_CODE_PART_2
script_end_dt = strftime("%Y-%m-%d %H:%M:%S")
email_message = """From:{}
To:{}
Subject:{}
##AUR_START##
AutomationName:{}
EndPointName:{}
StartTime:{}
DurationToFinish:{}
StatusOfRun:Success
ExecutionID:{}
InputType:Email
##AUR_END##""".format(email_bot_from_address,email_bot_to_address,email_bot_subject,script_file_nm,server_nm,script_start_dt,script_end_dt,bot_execution_id)

#Sending Email
try:
    smtpObj = smtplib.SMTP(smtp_server,smtp_port)
    smtpObj.sendmail(email_bot_from_address,email_bot_to_address,email_message)
    print "Mail Sent"
except smtplib.SMTPException:
    print "Unable to sent email"

#End of Section
