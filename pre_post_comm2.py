import difflib
File1 = 'linux-client_2019_01_25_13_16_pre.json'
File2 = 'linux-client_2019_01_25_17_06_post.json'
with open(File1) as f1:
    f1_text = f1.read()
with open(File2) as f2:
    f2_text = f2.read()
for line in difflib.unified_diff(f1_text, f2_text, fromfile=File1, tofile=File2, lineterm=''):
    print line
