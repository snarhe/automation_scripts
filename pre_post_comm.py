import json
file1 = 'linux-client_2019_01_25_13_16_pre.json'
file2 = 'linux-client_2019_01_25_17_06_post.json'
with open(file1) as f1:
    f1_text = json.load(f1)
with open(file2) as f2:
    f2_text = json.load(f2)

#json_diff f2_text f1_text -i 2 
if f1_text == f2_text:
    print "Both file same"
else:
    print "Both file not same"
