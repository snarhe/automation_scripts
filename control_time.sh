#!/bin/bash
# ######################################################################################################################
# ----------------------------------------------------------------------------------------------------------------------
# Author : Sunil Narhe (sunil.narhe@capgemini.com) 
# Date of last commit: 2019-05-14
# ----------------------------------------------------------------------------------------------------------------------
#      script created by Sunil Narhe - 2019-05-14 (YYYY-MM-DD)
#
#      PURPOSE: Email Date-Time for respective servers.
#
#      
#      LAST UPDATES (YYYY-MM-DD): NA
#
######################################################################################################################

templog=/tmp/date-time-log
SCRIPTFOLDER=/root/script/
EMAIL="s.narhe@yahoo.in"


function HTML_EMAIL(){
    /usr/sbin/sendmail -t << !
To: $EMAIL
Subject: ControlTime Systems date
Content-Type: text/html


`cat $SCRIPTFOLDER/control_time.html`
.
!
}

function DATE(){
for SERVER in 192.168.40.208
do
    RHOSTNAME=`ssh $SERVER "hostname"`
    RSYSDATE=`ssh $SERVER "date"`
    RSYSSECONDS=`ssh $SERVER "date +%s"`
    echo "$RHOSTNAME $RSYSSECONDS $RSYSDATE" >> $templog
done
}

DATE

function EMAIL_NOTIFY(){
echo -e "<html><style>
        body {
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
</style><body><p>Hello Team,<br /> <br />Please find servers date time information<table><tr><th>Host</th><th>Date & Time</th></tr>" > $SCRIPTFOLDER/control_time.html
FIRSTHOST=`cat $templog | head -1 | cut -d" " -f1`
FIRSTDATE=`cat $templog | head -1 | cut -d" " -f2`
#for DATE in `cat $templog`
while read SysHost SysSeconds SysDay SysMonth SysDate SysTime SysZone SysYear
do
        if [[ `expr $SysSeconds - $FIRSTDATE` -ge 5 ]]
	then
	echo -e "<tr style='background-color:red; color:white;'><td>$SysHost</td><td>$SysDay $SysMonth $SysDate $SysTime $SysZone $SysYear</td></tr>" >> $SCRIPTFOLDER/control_time.html
	else
	echo -e "<tr><td>$SysHost</td><td>$SysDay $SysMonth $SysDate $SysTime $SysZone $SysYear</td></tr>" >> $SCRIPTFOLDER/control_time.html
	fi
done < $templog
echo -e "</table><p><br/><br/> <br />Regards,<br/>Unix Team.<br/>Email: sunil.narhe@capgemini.com</p></body></html>" >> $SCRIPTFOLDER/control_time.html
rm -rf $templog
HTML_EMAIL
#cat $SCRIPTFOLDER/control_time.html | mail -s "$(echo -e "ControlTime Systems date\nContent-Type: text/html")" $EMAIL
}

EMAIL_NOTIFY

