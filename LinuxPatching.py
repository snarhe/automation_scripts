#Script Name: Linux Patching
#Version: V1.0
#Python Version: 2.7.x
#Developer: Sunil Narhe<sunil.narhe@mailserver.com>
#Description: This script perform LVM Disk Utility 

#Load Python lib
import paramiko, argparse, glob, os, subprocess, re
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
#script_folder = "/root/scripts"
script_folder = "/root/automation"
new_repo_file = "/etc/yum.repos.d/custom.repo"
pre_post_check_script = "SESEQ_LNX_2019_Script_PrePostCheckOnRestart.py"
patch_date = strftime("%b %d")

#BOT_CODE_PART_1
script_start_dt = strftime("%Y-%m-%d %H:%M:%S")
script_file_nm = path.basename(__file__).split(".")[0]
server_nm = gethostname()
email_bot_subject = "AUR-"+str(script_file_nm)

#Getting argument passed to script
def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-s','--server', help='Server IP/Hostname', required=True, nargs='+')
    arguments = parser.parse_args()
    HOST = arguments.server
    return HOST
HOST = get_args()

fileexist = os.path.isfile('{}/{}'.format(script_folder, pre_post_check_script))
if fileexist:
    for Host in HOST:
        try:
            ssh = paramiko.SSHClient()
	    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh.connect(hostname=Host,port=ssh_port,username=USER,pkey=ssh_key)
	    stdin, stdout, stderr = ssh.exec_command("uname -r | awk -F'.' '{print $(NF-1)}'")
	    OSRELEASE = stdout.read().rstrip().decode("utf-8")
	    pre_check = "python {}/{} -s {} -ch pre".format(script_folder, pre_post_check_script, Host)
            pre_check_status = os.system(pre_check)
	    def Repo_Add():
	        stdin, stdout, stderr = ssh.exec_command("ifconfig -a | grep -w inet | awk '/192.168/ {print $2}'")
		DMZIP = stdout.read().decode("utf-8")
		if OSRELEASE == 'el6':
		    SERVERVERSION = 6
                    if DMZIP:
                        REPOSERVER = "gerdcwrepopas01"
		    else:
		        REPOSERVER = "gerdcwdmzgpas01"
		elif OSRELEASE == 'el7':
		    SERVERVERSION = 7
		    if DMZIP:
           	        REPOSERVER = "gerdcwrepopas01"
		    else:
		        REPOSERVER = "gerdcwdmzgpas01"
		else:
		    print "Unknow OS version on {}".format(HOST)
                if SERVERVERSION and REPOSERVER:
                    with open("/tmp/custom.repo","w") as repo:
                        repo.write("[custom]\nname=custom\nenabled=1\ngpgcheck=0\nbaseurl=http://{}/mirror/rhel/{}/{}server/x86_64/os\n".format(REPOSERVER,SERVERVERSION,SERVERVERSION))
                    FNULL = open(os.devnull, 'w')
                    repocopy = subprocess.Popen(["scp", "/tmp/custom.repo", "{}@{}:/etc/yum.repos.d".format(USER,Host)], stdout=FNULL, stderr=subprocess.STDOUT)
                    repocopy_sts = os.waitpid(repocopy.pid, 0)
                else:
                    print "RepoServer and ServerVersion not have values"
	    stdin, stdout, sstderr = ssh.exec_command("df -hT /boot | awk '{print $5}' | tail -1")
	    OSBootSize = stdout.read().decode("utf-8")
	    BootSizeValue = re.findall(r'[A-Za-z]|-?\d+\.\d+|\d+', OSBootSize)
	    stdin, stdout, sstderr = ssh.exec_command("df -hT /var | awk '{print $5}' | tail -1")
	    OSVarSize = stdout.read().decode("utf-8")
	    VarSizeValue = re.findall(r'[A-Za-z]|-?\d+\.\d+|\d+', OSVarSize)
	    if ('M' in BootSizeValue and int(BootSizeValue[0]) > 70) or 'G' in BootSizeValue:
	        BootMSize = BootGSize = True
	    else:
	        BootMSize = BootGSize = False
	    if 'G' in VarSizeValue and float(VarSizeValue[0]) > 1.5:
	        VarGSize = True
	    else:
	        VarGSize = False
            if (BootMSize or BootGSize) and VarGSize:
	        print "[INFO] {} Space: Enough space available on /boot and /var".format(Host)
	        stdin, stdout, stderr = ssh.exec_command("mkdir -p /root/repos; mv /etc/yum.repos.d/* /root/repos/ *> /dev/null")
                print "[INFO] {} Repo: Backup old repo files".format(Host)
	        Repo_Add()
		stdin, stdout, stderr = ssh.exec_command("rm -rf /var/cache/yum ; yum clean all &> /dev/null")
		stdin, stdout, stderr = ssh.exec_command("yum repolist &> /tmp/repolist.log ; grep ^custom /tmp/repolist.log | awk '{print $NF}'")
		REPO_LIST_STATUS = int(stdout.read().decode("utf-8"))
		if REPO_LIST_STATUS != 0:
		    stdin, stdout, stderr = ssh.exec_command("yum update -y 2> /var/log/{}yum_update_err.log".format(Host))
		    stdin, stdout, stderr = ssh.exec_command("rm -rf /etc/yum.repos.d/{}".format(new_repo_file))
		    sftp = pysftp.Connection(host = '{}', private_key = '/root/.ssh/id_rsa').format(Host)
                    try:
                        print(sftp.stat('/var/log/{}yum_update_err.log'.format(Host)))
                        sftp.put('/var/log/{}_yum_update_err.log'.format(Host),'{}/yumlog/'.format(script_folder))
                        print "[ERROR] {} Patch: patching faild check logs in {}/yumlog/".format(Host,script_folder)
                    except IOError:
                        stdin, stdout, stderr = ssh.exec_command("grep ^{} /var/log/yum.log >> /var/log/{}_yum_update_success.log".format(patch_date,Host))
                        sftp.put('/var/log/{}_yum_update_success.log','{}/yumlog/'.format(patch_date,script_folder))
                        stdin, stdout, stderr = ssh.exec_command("init 6")
                        print "[INFO] {} Patch: patching successful, server rebooted".format(Host)
		else:
                    print "[ERROR] {} Repo: New repo not working".format(Host)
            else:
                print "[ERROR] {} Size: Check the /boot or /var size"
        except Exception:
            print "Unable to connect {}".format(Host)
        except paramiko.AuthenticationException as error:
            print "{} Authentication failed".format(Host)
else:
    print "Pre-Post Check script '{}' not present on base/jump server".format(pre_post_check_script)


