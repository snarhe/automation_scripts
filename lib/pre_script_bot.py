import smtplib
from time import strftime
#from os import path
from socket import gethostname
def pre_bot():
    smtp_server = "127.0.0.1"
    smtp_port = int(25)
    script_start_dt = strftime("%Y-%m-%d %H:%M:%S")
    #script_file_nm = path.basename(__file__).split(".")[0]
    #bot_execution_id = "Test001"
    server_nm = gethostname()
    email_bot_from_address = "no-reply@capgemini.com"
    email_bot_to_address = "s.narhe@yahoo.in"
    #email_bot_subject = "AUR-"+str(script_file_nm)
    return smtp_server smtp_port script_start_dt server_nm email_bot_from_address email_bot_to_address
