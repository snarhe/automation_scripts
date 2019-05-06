URL_PREFIX="https://www.team-cymru.org/Services/Bogons"
SCRIPTFOLDER=/root/scripts
MAINLOG="/var/log/bogon-acl.log"
TEMPLOG="/tmp/temp_check.log"
DATE=`date +%Y-%m-%d`
#BINDSERVER=""
BINDSERVER="192.168.40.145"
ACLFILEDIR=/var/named/chroot/etc
EMAIL="sunil.narhe@mailserver.com"

function SCRIPT_DOWNLOAD(){
echo "Downloading Updated IP file" >> $MAINLOG
mv $SCRIPTFOLDER/bogon-bn-agg.txt  $SCRIPTFOLDER/bogon-bn-agg.txt-$DATE
wget -O $SCRIPTFOLDER/bogon-bn-agg.txt $URL_PREFIX/bogon-bn-agg.txt --no-check-certificate 2> /dev/null
if [ $? -eq 0 ]; then
	echo "Updated IP file downloaded successfully" >> $MAINLOG
else
	echo "Failed to download the updated IP file. Please check network access and retry." >> $MAINLOG
	exit 1
fi
}

function URL_CHECK(){
wget -S --spider $URL_PREFIX --no-check-certificate &> $TEMPLOG
grep 'HTTP/1.1 200 OK' $TEMPLOG > /dev/null
if [[ `echo $?` == 0 ]] ; then
	SCRIPT_DOWNLOAD
	SCRIPT_DOWNLOAD_STATUS=0
else
	echo "URL is not accessible. Please check network access and retry." >> $MAINLOG
	return 1;
fi
}

URL_CHECK

function SCRIPT_COPY(){
scp root@$BINDSERVER:$ACLFILEDIR/bogon_acl.conf $SCRIPTFOLDER/bogon_acl_$DATE.conf
#cp $ACLFILEDIR/bogon_acl.conf $SCRIPTFOLDER/bogon_acl_$DATE.conf
if [ $? -eq 0 ]; then
	echo "Latest ACL file copied successfully" >> $MAINLOG
        chmod 755 $SCRIPTFOLDER/bogon_acl_$DATE.conf
else
	echo "Failed to copy ACL file. Please check network access and retry." >> $MAINLOG
	exit 1
fi
}

function COPY_CHECK(){
ncat -i 0.4 $BINDSERVER 22 &> $TEMPLOG
grep 'SSH' $TEMPLOG > /dev/null
if [[ `echo $?` == 0 ]] ; then
	SCRIPT_COPY
	SCRIPT_COPY_STATUS=0
else
	echo "BIND Server is not accessible. Please check network access and retry." >> $MAINLOG
	exit 1
fi
}

COPY_CHECK

function EMAIL_NOTIFY(){
echo -e "<html><style>
        body { background-color:#E5E4E2;
                   font-family:"sans-serif";
                   font-size:10pt; }
        td, th { border:0px solid black;
                         border-collapse:collapse;
                         white-space:pre; }
        th { color:white;
                 background-color:lightblue; }
        table, tr, td, th { padding: 2px; margin: 0px ;white-space:pre; }
        tr:nth-child(odd) {background-color: lightgray}
        table { width:25%;margin-left:5px; margin-bottom:20px;}
</title><body><p>Hello Team,<br /> <br />Please find below newly added IP's in ACL<table><tr><th>New IP</th></tr>" > $SCRIPTFOLDER/bogon_acl.html
for IP in `cat /tmp/NEWIP.txt`
do
	echo -e "<tr><td>$IP</td></tr>" >> $SCRIPTFOLDER/bogon_acl.html
done
echo -e "</table><p><br/><br/> <br />Regards,<br/>Unix Team.<br/>Email: sunil.narhe@mailserver.com</p></body></html>" >> $SCRIPTFOLDER/bogon_acl.html
rm -rf /tmp/NEWIP.txt
cat $SCRIPTFOLDER/bogon_acl.html | mail -s "$(echo -e "[GEFCO-BOGON]NEW IP LIST\nContent-Type: text/html")" $EMAIL
}

function BIND_MODIFY(){
if [[ $SCRIPT_COPY_STATUS == 0 ]] && [[ $SCRIPT_DOWNLOAD_STATUS == 0 ]]; then
	while read IP
	do
		grep -v ^/ $SCRIPTFOLDER/bogon_acl_$DATE.conf | grep $IP
		if [[ `echo $?` == 0 ]] ; then
			echo "$IP exist in config file" >> $MAINLOG
		else
			sed -i '/};/i\'"$IP;"'' $SCRIPTFOLDER/bogon_acl_$DATE.conf
			echo "New IP $IP added in config file" >> $MAINLOG
			echo $IP >> /tmp/NEWIP.txt
                fi
	done < "$SCRIPTFOLDER/bogon-bn-agg.txt"
        EMAIL_NOTIFY
        #scp $SCRIPTFOLDER/bogon_acl_$DATE.conf root@$BINDSERVER:$ACLFILEDIR/bogon_acl.conf
else
	echo "[Failed] Please check logs under $MAINLOG for error"
fi
}

BIND_MODIFY

