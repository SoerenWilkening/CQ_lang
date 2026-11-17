#!/usr/bin/env python3
"""seq_locals.py FILE.ll ...: make the unnamed local numbering of a hand-written lowering sequential per function (LLVM
refuses gaps or reordering: 'instruction expected to be numbered %N'). Arguments keep their numbers; every later `%N =`
definition gets the next number in textual order and its uses are renamed; `; IR:` / `; C:` comments are left untouched
(they name the .O1.ll values). Run renumber_locals.py afterwards (it also checks the result against opt)."""
import re, sys
for p in sys.argv[1:]:
    L = open(p).read().split('\n'); out = []; infn = False; mp = {}; nxt = 0
    for l in L:
        m = re.match(r'define .*?\((.*)\) \{', l)
        if m:
            infn = True; mp = {}; nargs = len([a for a in m.group(1).split(',') if a.strip()]); nxt = nargs + 1; out.append(l); continue
        if l.startswith('}'): infn = False; out.append(l); continue
        if infn:
            code, sep, cm = l.partition('    ; ')
            if re.match(r'^\d+:', code.strip()):   # a numbered block label takes a number too
                mp['%' + code.strip().split(':')[0]] = '%%%d' % nxt; code = '%d:' % nxt; nxt += 1
            d = re.match(r'\s*(%\d+) =', code)
            if d: mp[d.group(1)] = '%%%d' % nxt; nxt += 1
            code = re.sub(r'%(\d+)\b', lambda m: mp.get(m.group(0), m.group(0)), code)
            l = code + sep + cm
        out.append(l)
    open(p, 'w').write('\n'.join(out)); print(p, 'sequential')
