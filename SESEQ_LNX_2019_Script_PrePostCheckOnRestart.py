#Script Name: BOT Code
#Version: V1.0
#Developer: Sunil Narhe<sunil.narhe@capgemini.com>
#Description: This script perform the Pre and Post check of server

#Load Python lib
import paramiko, argparse, glob, os, subprocess
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



#Variable
DT = strftime("%Y_%m_%d_%H_%M")


#Getting argument passed to script
def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-s','--server', help='Server IP/Hostname(Multiple values with comma separated)', required=True, nargs='+')
    parser.add_argument('-rs','--restart', type=int, help='Restart server After Checks', required=False)
    parser.add_argument('-sd','--shutdown', type=int, help='ShutDown server after Checks', required=False)
    parser.add_argument('-ch','--check', type=str, help='Check action pre/post', required=True)
    arguments = parser.parse_args()
    HOST = arguments.server[0].split(",")
    RESTART = arguments.restart
    SHUTDOWN = arguments.shutdown
    CHECK = arguments.check
    return HOST, RESTART, SHUTDOWN, CHECK

HOST, RESTART, SHUTDOWN, CHECK = get_args()

#Get health details of server
def get_health(Host):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname=Host,port=ssh_port,username=USER,pkey=ssh_key)
        stdin, stdout, stderr = ssh.exec_command("hostname")
        HOSTNAME = stdout.read().rstrip().decode("utf-8")
        if CHECK == 'pre' or CHECK == 'post':
            stdin, stdout, stderr = ssh.exec_command("uname -r")
            KERNEL_Version = stdout.read().rstrip().decode("utf-8")
            stdin, stdout, stderr = ssh.exec_command("who -b | awk '{print $3,$4}'")
            LAST_BOOT = stdout.read().rstrip().decode("utf-8")
            stdin, stdout, stderr = ssh.exec_command("lsof -Pnl +M -i4 | awk '$NF ~ /(LISTEN)/ {print $1,$(NF-1)}'")
            SERVICES = stdout.read().splitlines()
            stdin, stdout, stderr = ssh.exec_command("df -h | grep -v '^Filesystem' | awk '{print $1, $2, $3, $4, $6}'")
            DISK_INFO = stdout.read().splitlines()
            stdin, stdout, stderr = ssh.exec_command("ifconfig -a | grep -A1 flag | paste -d ' ' - - - | awk '{print $1,$6,$8}'")
            IPDETAIL = stdout.read().splitlines()
            stdin, stdout, stderr = ssh.exec_command("cat /etc/redhat-release")
            RELEASE = stdout.read().decode("utf-8")
            stdin, stdout, stderr = ssh.exec_command("cat /etc/fstab | grep -v '^#' | sed '/^$/d'")
            FSTAB = stdout.read().splitlines()
            stdin, stdout, stderr = ssh.exec_command("route -n | grep -v '^Kernel'")
            ROUTE = stdout.read().splitlines()
            FileName = "{}_{}_{}.txt".format(HOSTNAME, DT, CHECK)
            with open(FileName, 'w') as f:
                f.write("[HOSTNAME]\n{}\n".format(HOSTNAME))
                f.write("[KERNEL_V]\n{}\n".format(KERNEL_Version))
                f.write("[LAST_BOOT]\n{}\n".format(LAST_BOOT))
                f.write("[Services]\n")
                for Serv in SERVICES:
                    f.write("{}\n".format(Serv))
                f.write("[Disks]\n")
                for Disk in DISK_INFO:
                    f.write("{}\n".format(Disk))
                f.write("[IPDetails]\n")
                for IP in IPDETAIL:
                    f.write("{}\n".format(IP))
                f.write("[Fstab]\n")
                for fstab in FSTAB:
                    f.write("{}\n".format(fstab))
                f.write("[Routes]\n")
                for routen in ROUTE:
                    f.write("{}\n".format(routen))
            if RESTART == 1 and CHECK == 'pre':
                stdin, stdout, stderr = ssh.exec_command("init 6")
            else:
                pass
            if SHUTDOWN == 1 and CHEC == 'pre':
                stdin, stdout, stderr = ssh.exec_command("init 0")
            else:
                pass
        elif CHECK == 'comm':
            list_of_files_pre = glob.glob('{}_*_pre.txt'.format(HOSTNAME))
            latest_file_pre = max(list_of_files_pre, key=os.path.getctime)
            list_of_files_post = glob.glob('{}_*_post.txt'.format(HOSTNAME))
            latest_file_post = max(list_of_files_post, key=os.path.getctime)
            subprocess.Popen(["diff",latest_file_pre, latest_file_post])
    except TimeoutError as err:
        print "Unable to connect {}".format(Host)
    except paramiko.AuthenticationException as error:
        print "{} Authentication failed".format(Host)


#Ececuting health for every host provided in argument
for host in HOST:
    get_health(host)


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
    print "True"
except smtplib.SMTPException:
    print "False"

#End of Section
