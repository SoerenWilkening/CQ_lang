# -*- coding: utf-8 -*-
"""Injection matrix: mutate the LOWERED stream of each ACCEPT fixture, re-run
every FileCheck prefix the fixture declares, and report MISSED / DIRTY."""
import subprocess, re, glob, os, sys, tempfile
SUBJ="/Users/sorenwilkening/Desktop/CQ_l4x4"
FC="/usr/local/opt/llvm@19/bin/FileCheck"
T=SUBJ+"/ir-pass/test/"
def lower(f):
    p=subprocess.run([SUBJ+"/build/ir-pass/cq-opt","-load-pass-plugin",
                      SUBJ+"/build/ir-pass/libCQPass.so","-passes=cq-lowering","-S",f],
                     capture_output=True)
    return p.returncode, p.stdout.decode()
def prefixes(f):
    s=open(f,encoding='utf-8').read()
    out=[]
    for m in re.finditer(r'--check-prefix=(\w+)', s): out.append(m.group(1))
    if re.search(r'^; RUN: %filecheck %s < ', s, re.M): out.insert(0,"CHECK")
    return out
def fc(f, pfx, text):
    with tempfile.NamedTemporaryFile('w',suffix='.ll',delete=False,encoding='utf-8') as t:
        t.write(text); p=t.name
    args=[FC,f,"--input-file",p]
    if pfx!="CHECK": args+=["--check-prefix="+pfx]
    r=subprocess.run(args,capture_output=True)
    os.unlink(p)
    return r.returncode==0

# --- mutations on the lowered text -----------------------------------------
def first_rail(text):
    m=re.search(r'(%\w+) = call i32 @cqrt_alloc_i1\(', text)
    return m.group(1) if m else None
def m_x_on_rail(t):
    b=first_rail(t)
    if not b: return None
    return re.sub(r'(  call void @cqrt_ry_\w+_controlled\()', "  call void @cqrt_x(i32 %s)\n\\1"%b, t, count=1)
def m_extra_free(t):
    b=first_rail(t)
    if not b: return None
    return re.sub(r'(  call void @cqrt_ry_\w+_controlled\([^\n]*\n)', "\\1  call void @cqrt_free(i32 %s)\n"%b, t, count=1)
def m_swap_ctl(t):
    m=re.search(r'  call void @cqrt_ry_(\w+)_controlled\(i32 (%\w+), i32 (%\w+), (.*?)\)\n', t)
    if not m: return None
    return t[:m.start()]+"  call void @cqrt_ry_%s_controlled(i32 %s, i32 %s, %s)\n"%(m.group(1),m.group(3),m.group(2),m.group(4))+t[m.end():]
def m_drop_controlled(t):
    m=re.search(r'  call void @cqrt_ry_(\w+)_controlled\(i32 (%\w+), i32 (%\w+), (.*?)\)\n', t)
    if not m: return None
    return t[:m.start()]+"  call void @cqrt_ry_%s(i32 %s, %s)\n"%(m.group(1),m.group(3),m.group(4))+t[m.end():]
def m_extra_ry_on_rail(t):
    b=first_rail(t)
    if not b: return None
    return re.sub(r'(  call void @cqrt_ry_\w+_controlled\([^\n]*\n)', "\\1  call void @cqrt_ry_i1(i32 %s, double 7.000000e-01)\n"%b, t, count=1)
def m_drop_uncond_twin(t):
    # the negated shape's unconditional Ry(theta) immediately before the controlled gate
    m=re.search(r'(  call void @cqrt_ry_\w+\(i32 %\w+, double [-0-9.e+]+\)\n)(  call void @cqrt_ry_\w+_controlled\()', t)
    if not m: return None
    return t[:m.start(1)]+t[m.end(1):]
def m_cswap(t):
    b=first_rail(t)
    if not b: return None
    return re.sub(r'(  call void @cqrt_ry_\w+_controlled\()', "  call void @cqrt_cswap(i32 %s, i32 %s, i32 %s)\n\\1"%(b,b,b), t, count=1)
MUTS=[("x_on_rail",m_x_on_rail),("extra_free",m_extra_free),("swap_ctl_tgt",m_swap_ctl),
      ("drop_controlled",m_drop_controlled),("extra_ry_on_rail",m_extra_ry_on_rail),
      ("drop_uncond_twin",m_drop_uncond_twin),("cswap",m_cswap)]

files=sorted(f for f in glob.glob(T+"control_inplace_ry_rail_*.ll")+glob.glob(T+"control_inplace_ry_stateprep_rail*.ll")
             if "reject" not in os.path.basename(f))
files=sorted(set(files))
nmiss=nna=ndirty=0; total=0
for f in files:
    rc,low=lower(f)
    if rc!=0: print("SKIP (declines):",os.path.basename(f)); continue
    pfx=prefixes(f)
    dirty=[p for p in pfx if not fc(f,p,low)]
    if dirty:
        ndirty+=1; print("DIRTY %-58s clean stream fails %s"%(os.path.basename(f),dirty))
    for name,fn in MUTS:
        mut=fn(low)
        if mut is None or mut==low:
            nna+=1; continue
        total+=1
        caught=[p for p in pfx if not fc(f,p,mut)]
        if not caught:
            nmiss+=1; print("MISSED %-52s %s"%(os.path.basename(f),name))
print("\nfixtures=%d mutations=%d MISSED=%d DIRTY=%d n/a=%d"%(len(files),total,nmiss,ndirty,nna))
