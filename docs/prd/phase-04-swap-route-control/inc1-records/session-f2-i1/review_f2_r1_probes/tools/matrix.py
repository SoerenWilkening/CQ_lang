#!/usr/bin/env python3
"""Injection matrix over the state-prep ACCEPT fixtures on the narrowed binary.

For each accept fixture: run cq-opt, then apply each mutation to the OUTPUT and
re-run every FileCheck prefix the fixture declares.  MISSED = no prefix fails.
"""
import re, subprocess, sys, os, tempfile, glob
FC="/usr/local/opt/llvm@19/bin/FileCheck"
OPT="/Users/sorenwilkening/Desktop/CQ_f2/build/ir-pass/cq-opt"
PASS="/Users/sorenwilkening/Desktop/CQ_f2/build/ir-pass/libCQPass.so"
T="/Users/sorenwilkening/Desktop/CQ_f2/ir-pass/test"

def prefixes(src):
    out=set()
    for line in open(src):
        m=re.search(r'--check-prefix=(\S+)', line)
        if m: out.add(m.group(1))
        if re.search(r'%filecheck %s <', line) and '--check-prefix' not in line: out.add('CHECK')
    return sorted(out) or ['CHECK']

def mutants(text):
    """return list of (name, mutated_text)"""
    ms=[]
    lines=text.split('\n')
    # find the free of the flag and the controlled gate
    ifree=next((i for i,l in enumerate(lines) if 'cqrt_free(' in l), None)
    ictl=next((i for i,l in enumerate(lines) if '_controlled(' in l), None)
    ialloc=next((i for i,l in enumerate(lines) if 'cqrt_alloc_' in l), None)
    # the condition register handle: first alloc's result name
    hcond=None
    if ialloc is not None:
        m=re.search(r'%(\S+) = call i32 @cqrt_alloc_', lines[ialloc])
        if m: hcond='%'+m.group(1)
    if ifree is not None and hcond:
        ms.append(('extra_ry_on_cond', lines[:ifree+1]+[f'  call void @cqrt_ry_i32({hcond}, double 1.000000e-01)']+lines[ifree+1:]))
        ms.append(('extra_free', lines[:ifree+1]+[f'  call void @cqrt_free({hcond})']+lines[ifree+1:]))
        ms.append(('extra_x', lines[:ifree+1]+[f'  call void @cqrt_x({hcond})']+lines[ifree+1:]))
    if ictl is not None:
        # make the arm gate UNCONDITIONAL: drop the flag operand
        l=lines[ictl]
        m=re.match(r'(\s*)call void @(cqrt_(?:ry|rz)_\w+)_controlled\(i32 (\S+), i32 (\S+), (double [^)]+)\)', l)
        if m:
            ms.append(('uncontrolled_arm', lines[:ictl]+[f'{m.group(1)}call void @{m.group(2)}(i32 {m.group(4)}, {m.group(5)})']+lines[ictl+1:]))
        # duplicate the controlled gate
        ms.append(('dup_ctl_gate', lines[:ictl+1]+[lines[ictl]]+lines[ictl+1:]))
    if ialloc is not None:
        # change the SEED literal
        l=lines[ialloc]
        m=re.search(r'cqrt_alloc_(\w+)\((i\d+|i1) ([^)]*)\)', l)
        ms.append(('seed_literal', lines[:ialloc]+[re.sub(r'(cqrt_alloc_\w+\((?:i\d+) )([^)]*)\)', lambda mm: mm.group(1)+('7' if mm.group(2) not in ('true',) else 'false')+')', l)]+lines[ialloc+1:]))
    return [(n,'\n'.join(v)) for n,v in ms]

def run(src):
    p=subprocess.run([OPT,'-load-pass-plugin',PASS,'-passes=cq-lowering','-S',src],capture_output=True,text=True)
    if p.returncode!=0: return None
    return p.stdout

res={}
for src in sorted(sys.argv[1:]):
    base=os.path.basename(src)
    out=run(src)
    if out is None: 
        print(f"{base}: DECLINES - skipped"); continue
    pfx=prefixes(src)
    with tempfile.TemporaryDirectory() as d:
        clean=os.path.join(d,'c.ll'); open(clean,'w').write(out)
        ok=True
        for p in pfx:
            r=subprocess.run([FC,src,'--check-prefix='+p,'--input-file',clean],capture_output=True,text=True)
            if r.returncode!=0: ok=False; print(f"{base}: CLEAN-FAIL prefix {p}"); print(r.stdout[:300])
        if not ok: continue
        for name,mt in mutants(out):
            f=os.path.join(d,'m.ll'); open(f,'w').write(mt)
            caught=[]
            for p in pfx:
                r=subprocess.run([FC,src,'--check-prefix='+p,'--input-file',f],capture_output=True,text=True)
                if r.returncode!=0: caught.append(p)
            res.setdefault(name,{'c':0,'m':0})
            if caught: res[name]['c']+=1
            else:
                res[name]['m']+=1
                print(f"MISSED {base} <- {name}")
print("\n=== summary ===")
for k,v in sorted(res.items()): print(f"{k:22s} caught={v['c']} MISSED={v['m']}")
