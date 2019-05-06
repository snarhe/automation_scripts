#Script Name: Reset Root Password
#Version: V1.0
#Developer: Sunil Narhe<sunil.narhe@mailserver.com>
#Description: This script perform root password reser activity

#Load Python lib
import paramiko, argparse, glob, os, subprocess
from time import strftime
import smtplib
from os import path
from socket import gethostname

#Input Section
smtp_server = "smtp.mailserver.com"
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
    parser.add_argument('-s','--server', help='Server IP/Hostname(Multiple values with comma separated)', nargs='+', required=False)
    parser.add_argument('-f','--filename', help='Server list filename with one hostname/IP in a line')
    parser.add_argument('-p', '--password', help='New root password')
    arguments = parser.parse_args()
    HOST = arguments.server
    PASSWORD = arguments.password
    FILENAME = arguments.filename
    return HOST, FILENAME, PASSWORD

HOST, FILENAME, PASSWORD = get_args()

def reset_password():
    def reset_pass(Host):
        try:
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh.connect(hostname=Host,port=ssh_port,username=USER,pkey=ssh_key)
            stdin, stdout, stderr = ssh.exec_command("echo '{}' | passwd sun1 --stdin > /dev/null; echo $?".format(PASSWORD))
            STATUS = stdout.read().decode("utf-8")
            if int(STATUS) == 0:
                print "Root passsword reset on {}".format(Host)
            else:
                print "Root passwd not reset on {}".format(Host) 
        except TimeoutError as err:
            return "Unable to connect {}".format(Host)
        except paramiko.AuthenticationException as error:
            return "{} Authentication failed".format(Host)
    if HOST:
        HOSTS = HOST[0].split(",")
        for host in HOSTS:
            reset_pass(host)
    elif FILENAME:
        with open(FILENAME, 'r') as f:
            for host in f.readlines():
                reset_pass(host)
    else:
        print "Script need at least two values Hostname/FileName and New passwd"

reset_password()


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
    return True
except smtplib.SMTPException:
    return False

#End of Section
