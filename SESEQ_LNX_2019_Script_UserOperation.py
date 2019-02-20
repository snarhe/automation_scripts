#Script Name: User Operation like Add and Delete
#Version: V1.0
#Developer: Sunil Narhe<sunil.narhe@capgemini.com>
#Description: This script add/delete system user
#Note: This script is comaptible with Python 2.7.x


#Load Python lib
import smtplib, argparse, paramiko
from time import strftime
from os import path
from socket import gethostname


#Input Section
smtp_server = "192.168.208.219"
smtp_port = 25
script_start_dt = strftime("%Y-%m-%d %H:%M:%S")
script_file_nm = path.basename(__file__).split(".")[0]
bot_execution_id = "Test001"
server_nm = gethostname()
email_bot_from_address = "noreply@seq.com"
email_bot_to_address = "hpoperations.in@capgemini.com"
email_bot_subject = "AUR-"+str(script_file_nm)

#BOT_CODE_PART_1
script_start_dt = strftime("%Y-%m-%d %H:%M:%S")
script_file_nm = path.basename(__file__).split(".")[0]
server_nm = gethostname()
email_bot_subject = "AUR-"+str(script_file_nm)

#Variable Section
USER = 'root'
PORT = 22
key = paramiko.RSAKey.from_private_key_file("/root/.ssh/id_rsa")


#Get script parameters
def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-s','--server', help='Server IP/Hostname(Multiple values with comma separated)', required=True, nargs='+')
    parser.add_argument('-u','--users', help='User name(Multiple values with comma separated)', required=True, nargs='+')
    parser.add_argument('-o','--operation', type=str, help='Operation add/del', required=True)
    parser.add_argument('-p','--permission', type=int, help='Add sudo rights 1 to enable', required=False)
    arguments = parser.parse_args()
    HOST = arguments.server[0].split(",")
    NEWUSER = arguments.users[0].split(",")
    OPERATION = arguments.operation
    PERMISSION = arguments.permission
    return HOST, NEWUSER, OPERATION, PERMISSION

HOST, NEWUSER, OPERATION, PERMISSION = get_args()


#Performing User operations per host
def useroperation():
    for Host in HOST:
        for User in NEWUSER:
            try:
                ssh = paramiko.SSHClient()
                ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
                ssh.connect(hostname=Host,port=PORT,username=USER,pkey=key)
                stdin, stdout, stderr = ssh.exec_command("cat /etc/passwd | grep -w {} | cut -d':' -f1".format(User))
                UserSearch = stdout.read().decode("utf-8")
                if User in UserSearch:
                    if OPERATION == 'add':
                        print "User '{}' exist on {}".format(User,Host)
                    elif OPERATION == 'del':
                        stdin, stdout, stderr = ssh.exec_command('sed -i "/^{}/d" /etc/sudoers'.format(User))
                        stdin, stdout, stderr = ssh.exec_command('userdel -r ' + str(User))
                        print "User '{}' deleted on {}".format(User, Host)
                else:
                    if OPERATION == 'add':
                        stdin, stdout, stderr = ssh.exec_command('useradd ' + str(User))
                        stdin, stdout, stderr = ssh.exec_command('echo welcome1234 | passwd {} --stdin'.format(User))
                        stdin, stdout, stderr = ssh.exec_command('chage -d0 ' + str(User))
                        print "User '{}' added on {}".format(User, Host)
                        if PERMISSION == 1:
                            stdin, stdout, stderr = ssh.exec_command('echo "{}  ALL=(ALL)       ALL" >> /etc/sudoers'.format(User))
                            print "Sudo rights granted to '{}' on {}".format(User, Host)
                    elif OPERATION == 'del':
                        print "User '{}' does not exist".format(User)
            except TimeoutError as err:
                print "Unable to connect {}".format(Host)
            except paramiko.AuthenticationException as error:
                print "{} Authentication failed".format(Host)



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