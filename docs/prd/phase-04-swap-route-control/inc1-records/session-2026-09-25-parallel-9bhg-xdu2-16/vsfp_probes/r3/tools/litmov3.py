#!/usr/bin/env python3
"""litmov3.py ABFILE : split lit and e2e/multi movers of an ab.py file into files this
branch touched since main (own_since_main.txt) and files it did NOT touch."""
import pathlib
import re
import sys

V = pathlib.Path(__file__).parent
own = set()
for l in (V / 'own_since_main.txt').read_text().splitlines():
    l = l.strip()
    if not l:
        continue
    if re.match(r'^[ MADR?]{2} ', l):
        l = l[3:].split(' -> ')[-1]
    own.add(pathlib.Path(l).name)
cm = pathlib.Path('/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/tests/e2e/CMakeLists.txt').read_text()
for l in open(sys.argv[1]):
    if l.startswith(('denominator', 'summary')):
        continue
    k, p = l.split('\t')[:2]
    n = p.split('/')[-1]
    if '/ir-pass/test/' in p:
        print(('OWN' if n in own else 'UNTOUCHED'), k, 'lit', n)
    elif n.startswith(('E_', 'M_')):
        name = n[2:].replace('.s1.ll', '')
        m = re.search(r'add_test\(NAME ' + re.escape(name) + r'\s.*?\)', cm, re.S)
        srcs = re.findall(r'/([\w.]+\.c)"', m.group(0)) if m else []
        libs = re.findall(r'([\w.]+\.c)', m.group(0)) if m else []
        touched = any(pathlib.Path(x).name in own for x in srcs + libs)
        print(('OWN' if touched else 'UNTOUCHED'), k, n[:2], name, srcs)
