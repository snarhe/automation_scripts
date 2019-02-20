#!/usr/bin/python
import argparse
import paramiko
USER = 'root'
PORT = 22
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
                    print("User '{}' exist on {}".format(User,Host))
                elif OPERATION == 'del':
                    stdin, stdout, stderr = ssh.exec_command('sed -i "/^{}/d" /etc/sudoers'.format(User))
                    stdin, stdout, stderr = ssh.exec_command('userdel -r ' + str(User))
                    print "User '{}' deleted on {}".format(User,Host)
            else:
                if OPERATION == 'add':
                    stdin, stdout, stderr = ssh.exec_command('useradd ' + str(User))
		    print "User '{}' added on {}".format(User,Host)
                    if PERMISSION == 1:
                        stdin, stdout, stderr = ssh.exec_command('echo "{}  ALL=(ALL)       ALL" >> /etc/sudoers'.format(User))
                        print "Sudo rights granted to '{}' on {}".format(User,Host)
                elif OPERATION == 'del':
                    print "User '{}' does not exist".format(User)
        except TimeoutError as err:
                print "Unable to connect {}".format(Host)
        except paramiko.AuthenticationException as error:
                print "{} Authentication failed".format(Host)

"""
#Print Values
for Host in HOST:
    for User in NEWUSER:
        print "User is {}".format(User)
    print "Host is {}".format(Host)
print "Operation is {}".format(OPERATION)
print "Permission is {}".format(PERMISSION)
"""

