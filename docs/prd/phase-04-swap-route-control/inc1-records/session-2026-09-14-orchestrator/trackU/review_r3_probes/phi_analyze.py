#!/usr/bin/env python3
"""Track U R3 — classify the three-verdict phi-injection sweep."""
import os, glob, re, sys, collections, hashlib
OUT='/tmp/cqu_r3_out'
def rd(p):
    try: return open(p, errors='replace').read()
    except Exception: return None
def strip_hdr(s):
    return '\n'.join(l for l in s.split('\n')
                     if not l.startswith('; ModuleID') and not l.startswith('source_filename'))
TAG = re.compile(r'(cq [a-z][^\n]*?)(?: under quantum control)?$', re.M)
def msg(err):
    m = re.search(r'((?:cq|LLVM ERROR|PHI node)[^\n]*)', err or '')
    return m.group(1).strip() if m else (('<empty>' if not (err or '').strip() else (err or '').strip().split('\n')[0]))
names = sorted(os.path.basename(p)[:-6] for p in glob.glob(OUT+'/*.Ou.rc'))
cls = collections.Counter(); blast = collections.Counter(); bad = []
moved = 0; accepts_su = 0; undef_gate = []
for n in names:
    rc = {t: (rd(f'{OUT}/{n}.{t}.rc') or '').strip() for t in ('Ou','Su','Oz')}
    err= {t: rd(f'{OUT}/{n}.{t}.err') for t in ('Ou','Su','Oz')}
    ir = {t: rd(f'{OUT}/{n}.{t}.ll')  for t in ('Ou','Su','Oz')}
    v  = lambda t: 'A' if rc[t]=='0' else ('D' if rc[t]=='1' else 'X'+rc[t])
    blast[f'{v("Ou")}->{v("Su")}'] += 1
    if v('Ou') != v('Su') or (v('Ou')==v('Su')=='D' and msg(err['Ou'])!=msg(err['Su'])): moved += 1
    if v('Su')=='A': accepts_su += 1
    # THE CLAIM: S_u == O_z
    if rc['Su'] != rc['Oz']:
        cls['RC_DIFF'] += 1; bad.append((n,'RC', rc['Su'], rc['Oz'], msg(err['Su']), msg(err['Oz']))); continue
    if rc['Su'] != '0':
        if (err['Su'] or '') == (err['Oz'] or ''): cls['EQ_decline'] += 1
        else: cls['MSG_DIFF'] += 1; bad.append((n,'MSG','','',msg(err['Su']),msg(err['Oz'])))
        continue
    a, b = strip_hdr(ir['Su'] or ''), strip_hdr(ir['Oz'] or '')
    if a == b: cls['EQ_accept'] += 1
    else:
        cls['IR_DIFF'] += 1; bad.append((n,'IR','','','',''))
    # undef reaching an emitted gate operand on the SUBJECT
    for line in (ir['Su'] or '').split('\n'):
        if re.search(r'call [^@]*@(cqrt_|cq_template_)', line) and re.search(r'\b(undef|poison)\b', line):
            undef_gate.append((n, line.strip()))
print(f"fixtures with a theta-carrying phi, MUTATED and swept : {len(names)}")
print(f"  moved by the rule (O_u != S_u, incl. message change): {moved}")
print(f"  SUBJECT accepts                                     : {accepts_su}")
print(f"\nTHE CLAIM  S_u == O_z : {dict(cls)}")
print(f"blast radius O_u -> S_u: {dict(blast)}")
print(f"\nundef/poison in a SUBJECT-emitted gate operand: {len(undef_gate)}")
for n,l in undef_gate[:10]: print('   ', n, '|', l[:110])
print(f"\nDIVERGENCES ({len(bad)}):")
for r in bad[:40]: print('   ', r)
