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
    parser.add_argument('-p','--partition', help='Mounted partition full path', required=True)
    parser.add_argument('-e','--extend', type=int, help='Size to be extend', required=True)
    arguments = parser.parse_args()
    HOST = arguments.server
    PARTITION = arguments.partition
    EXTEND = arguments.extend
    return HOST, PARTITION, EXTEND
HOST, PARTITION, EXTEND = get_args()

def extend_disk():
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname=HOST,port=ssh_port,username=USER,pkey=ssh_key)
        stdin, stdout, stderr = ssh.exec_command("grep -w {} /etc/fstab".format(PARTITION))
        MOUNTNAME = stdout.read().splitlines()
        print MOUNTNAME
        if MOUNTNAME:
            LVPATH = MOUNTNAME[0].split()[0]
            FILEFORMAT = MOUNTNAME[0].split()[2]
            stdin, stdout, stderr = ssh.exec_command("lvdisplay {}".format(LVPATH))
            LVDETAILS = stdout.read().splitlines()
            LVNAME = LVDETAILS[2].split()[2]
            VGNAME = LVDETAILS[3].split()[2]
            stdin, stdout, stderr = ssh.exec_command("vgs --noheadings {}".format(VGNAME))
            FREEVG = stdout.read().split()[6].rstrip('g')
            if int(FREEVG) > EXTEND:
                
            print LVNAME
            print VGNAME
            print FREEVG
        else:
            print "Mount point not available on server"
#Enable below lines only if Python 3.3 anb above
#    except TimeoutError as err:
#        print "Unable to connect {}".format(Host)
    except paramiko.AuthenticationException as error:
        print "{} Authentication failed".format(Host)

extend_disk()

