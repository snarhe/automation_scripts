#Script Name: BOT Code
#Version: V1.0
#Developer: Sunil Narhe<sunil.narhe@capgemini.com>
#Description: This script help to generate script execution count

#Load Python lib
import smtplib
from time import strftime
from os import path
from socket import gethostname
 

#Input Section
smtp_server = "192.168.208.219"
smtp_port = 25
email_bot_from_address = "noreply@seq.com"
email_bot_to_address = "hpoperations.in@capgemini.com"
bot_execution_id = "Test001"


#BOT_CODE_PART_1
script_start_dt = strftime("%Y-%m-%d %H:%M:%S")
script_file_nm = path.basename(__file__).split(".")[0]
server_nm = gethostname()
email_bot_subject = "AUR-"+str(script_file_nm)

#####
##Script Code
#####


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
