#Script Name: sudopermission
#Version: V1.0
#Developer: Sunil Narhe<sunil.narhe@capgemini.com>
#Description: This script help to generate script execution count

#Load Python lib
import smtplib, argparse, paramiko
from time import strftime
from os import path
from socket import gethostname


#Input Section
smtp_server = "192.168.208.219"
smtp_port = 25
script_start_dt = strftime("%Y-%m-%d %H:%M:%S")
bot_execution_id = "Test001"

#BOT_CODE_PART_1
script_start_dt = strftime("%Y-%m-%d %H:%M:%S")
script_file_nm = path.basename(__file__).split(".")[0]
server_nm = gethostname()
email_bot_subject = "AUR-"+str(script_file_nm)

#Variable Section
script_file_nm = path.basename(__file__)
server_nm = gethostname()
email_bot_from_address = "noreply@seq.com"
email_bot_to_address = "hpoperations.in@capgemini.com"
email_bot_subject = "AUR-"+str(script_file_nm)
USER = 'root'
PORT = 22

#Getting script parameter
def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-s','--server', help='Server IP/Hostname(Multiple values with comma separated)', required=True, nargs='+')
    parser.add_argument('-u','--users', help='User name(Multiple values with comma separated)', required=True, nargs='+')
    parser.add_argument('-o','--operation', type=str, help='Operation add/del', required=True)
    arguments = parser.parse_args()
    HOST = arguments.server[0].split(",")
    NEWUSER = arguments.users[0].split(",")
    OPERATION = arguments.operation
    return HOST, NEWUSER, OPERATION

HOST, NEWUSER, OPERATION = get_args()

#Performing User operations per host
for Host in HOST:
    for User in NEWUSER:
        try:
            key = paramiko.RSAKey.from_private_key_file("/root/.ssh/id_rsa")
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh.connect(hostname=Host,port=PORT,username=USER,pkey=key)
            stdin, stdout, stderr = ssh.exec_command("cat /etc/passwd | grep -w {} | cut -d':' -f1".format(User))
            UserSearch = stdout.read().decode("utf-8")
            if User in UserSearch:
                if OPERATION == 'add':
                    stdin, stdout, stderr = ssh.exec_command('echo "{}  ALL=(ALL)       ALL" >> /etc/sudoers'.format(User))
                    print "Sudo rights granted to {} on {}".format(User,Host)
                elif OPERATION == 'del':
                    stdin, stdout, stderr = ssh.exec_command('sed -i "/^{}/d" /etc/sudoers'.format(User))
                    print "Sudo rights revoked for {} on {}".format(User,Host)
            else:
                print "'{}' User does not exist on {}".format(User,Host)
        except TimeoutError as err:
            print "Unable to connect {}".format(Host)
        except paramiko.AuthenticationException as error:
            print "{} Authentication failed".format(Host)
        except socket.gaierror as error:
            print("Invalid hostname '{}'".format(Host))
            

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