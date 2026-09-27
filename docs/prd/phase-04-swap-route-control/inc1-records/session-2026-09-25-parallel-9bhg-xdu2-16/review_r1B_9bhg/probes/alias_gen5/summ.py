import re,sys
for line in sorted(open(sys.argv[1]), key=lambda l:int(re.match(r'[a-z]+(\d+)',l).group(1))):
    name=line.split()[0]
    ref=re.search(r'REF\[(\d+) ([0-9a-f]+);?\]',line)
    subj=line.split('SUBJ',1)[1].split('||')[0]
    outs=re.findall(r'(\d+) (\d+) ([0-9a-f]+);',subj)
    bad=sum(int(c) for c,rc,h in outs if rc=='0' and h!=ref.group(2))
    good=sum(int(c) for c,rc,h in outs if rc=='0' and h==ref.group(2))
    dec=sum(int(c) for c,rc,h in outs if rc!='0')
    flag = 'WRONG!' if bad else ('flaky' if dec and good else '')
    print(f"{name:10} ref_rc={ref.group(1)} subj: correct={good} WRONG={bad} nonzero={dec} {flag} ||{line.split('||')[1].strip()}")
