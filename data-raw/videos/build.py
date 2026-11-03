import json,sys
name=sys.argv[1]; tl=open(f'{name}.timeline.js').read()
txt={}
import glob,os
for f in glob.glob('*.txt'): txt[os.path.splitext(f)[0]]=open(f).read().rstrip('\n')
tl=tl.replace('__TXT__',json.dumps(txt))
open(f'{name}.html','w').write(open('player.html').read().replace('__DATA__',tl))
