import paramiko, argparse, json 
from time import strftime

DT = strftime("%Y_%m_%d_%H_%M")
USER = "root"
ssh_port = 22
ssh_key = paramiko.RSAKey.from_private_key_file("/root/.ssh/id_rsa")


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


def get_health(Host):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname=Host,port=ssh_port,username=USER,pkey=ssh_key)
        stdin, stdout, stderr = ssh.exec_command("hostname")
        HOSTNAME = stdout.read().rstrip().decode("utf-8")
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
        Services = {'servicearray': []}
        for Serv in SERVICES:
            service , listen = Serv.rstrip(';').split()
            Services['servicearray'].append(dict(service = service, listen = listen))
        Disks = {'diskarray': []}
        for Disk in DISK_INFO:
            Filesystem, Size, Used, Avail, Mountedon = Disk.rstrip(';').split()
            Disks['diskarray'].append(dict(Filesystem = Filesystem, Size = Size, Used = Used, Avail = Avail, Mountedon = Mountedon))
        IPDetails = {'iparray': []}
        for IP in IPDETAIL:
            device, ip, subnet = IP.rstrip(';').split()
            IPDetails['iparray'].append(dict(device = device, ip = ip, subnet = subnet))
        Fstab = {'fstabarray': []}
        for fstab in FSTAB:
            mountpoint, mounton, filesystem, permission, dump, fsck = fstab.rstrip(';').split()
            Fstab['fstabarray'].append(dict(mountpoint= mountpoint, mounton = mounton, filesystem = filesystem, permission = permission, dump = dump, fsck = fsck))
        Routes = {'routearray': []}
        for routen in ROUTE:
            Destination, Gateway, Genmask, Flags, Metric, Ref, Use, Iface = routen.rstrip(';').split()
            Routes['routearray'].append(dict(Destination = Destination, Gateway = Gateway, Genmask = Genmask, Flags = Flags, Metric = Metric, Ref = Ref, Use = Use, Iface = Iface))
        machine_info = {}
        machine_info['Hostname'] = '{}'.format(HOSTNAME)
        machine_info['Kernel_Version'] = '{}'.format(KERNEL_Version)
        machine_info['Last_Boot'] = '{}'.format(LAST_BOOT)
        machine_info['OS_Version'] = '{}'.format(RELEASE)
        machine_info['Services'] = '{}'.format(Services)
        machine_info['Disks'] = '{}'.format(Disks)
        machine_info['IPDetails'] = '{}'.format(IPDetails)
        machine_info['Fstab'] = '{}'.format(Fstab)
        machine_info['Routes'] = '{}'.format(Routes)
        if CHECK == 'pre':
            JSON_FNM = '{}_{}_pre.json'.format(HOSTNAME,DT)
            with open(JSON_FNM, 'w') as f:
                json.dump(machine_info, f)
        elif CHECK == 'post':
            JSON_FNM = '{}_{}_post.json'.format(HOSTNAME,DT)
            with open(JSON_FNM, 'w') as f:
                json.dump(machine_info, f)
        #elif CHECK == 'comp':
        #    pre_check_fnm = '{}_*_pre.json'.format(HOSTNAME)
        #    post_check_fnm = '{}_*_post.json'.format(HOSTNAME)
        #print "{} {}".format(pre_check_fnm,post_check_fnm)
        if RESTART == 1:
            stdin, stdout, stderr = ssh.exec_command("init 6")
        if SHUTDOWN == 1:
            stdin, stdout, stderr = ssh.exec_command("init 0")
    except TimeoutError as err:
        print "Unable to connect {}".format(Host)
    except paramiko.AuthenticationException as error:
        print "{} Authentication failed".format(Host)

for host in HOST:
    get_health(host)

