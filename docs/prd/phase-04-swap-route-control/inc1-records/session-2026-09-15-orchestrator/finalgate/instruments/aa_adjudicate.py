#!/usr/bin/env python3
"""Adjudicate every A->A (stream-moved) corpus mover: is the delta PAIRING-ONLY
(added _unc / cqrt_free discharges) or does it touch the forward GATE stream?"""
import subprocess, sys, os, tempfile, shutil, re, collections
SUBJ="/Users/sorenwilkening/Desktop/CQ_VERIFY"; ORC="/Users/sorenwilkening/Desktop/CQ_lang"
LLVM="/usr/local/opt/llvm@19/bin"
rels=[l.split("\t")[1].strip() for l in open(sys.argv[1]) if l.startswith("A->A")]
print(f"A->A movers to adjudicate: {len(rels)}")
CALL=re.compile(r'call [^@]*@([A-Za-z0-9_]+)\(')
def calls(path):
    c=collections.Counter()
    for ln in open(path):
        m=CALL.search(ln)
        if m and (m.group(1).startswith("cqrt_") or m.group(1).startswith("cq_template_")):
            c[m.group(1)]+=1
    return c
buckets=collections.Counter(); details=[]
for rel in rels:
    f=os.path.join(SUBJ,rel); td=tempfile.mkdtemp()
    try:
        s1=os.path.join(td,"s1.ll")
        if f.endswith(".c"):
            if subprocess.run([f"{LLVM}/clang",f"-I{SUBJ}/include","-include","CQ.h","-O1","-g",
                               "-emit-llvm","-S",f,"-o",s1],capture_output=True).returncode:
                buckets["CLANGERR"]+=1; continue
        else: shutil.copy(f,s1)
        oo=os.path.join(td,"o.ll"); ss=os.path.join(td,"s.ll")
        for root,out in ((ORC,oo),(SUBJ,ss)):
            subprocess.run([f"{root}/build/ir-pass/cq-opt","-load-pass-plugin",
                            f"{root}/build/ir-pass/libCQPass.so","-passes=cq-lowering",
                            "-S",s1,"-o",out],capture_output=True)
        co,cs=calls(oo),calls(ss)
        added={k:cs[k]-co.get(k,0) for k in cs if cs[k]>co.get(k,0)}
        removed={k:co[k]-cs.get(k,0) for k in co if co[k]>cs.get(k,0)}
        # PAIRING-ONLY: every change is a DISCHARGE (_unc adjoint or cqrt_free), added only.
        def discharge(k): return k.endswith("_unc") or k=="cqrt_free"
        if not added and not removed:
            buckets["NO-CALL-DELTA (declare/order only)"]+=1
        elif removed:
            buckets["*** FORWARD GATE REMOVED ***"]+=1
            details.append((rel,"REMOVED",removed,added))
        elif all(discharge(k) for k in added):
            buckets["PAIRING-ONLY (+_unc/+cqrt_free)"]+=1
        else:
            buckets["*** NON-DISCHARGE ADDED ***"]+=1
            details.append((rel,"ADDED-NONDISCHARGE",removed,added))
    finally: shutil.rmtree(td,ignore_errors=True)
for k,v in buckets.most_common(): print(f"  {v:4d}  {k}")
for rel,kind,rem,add in details:
    print(f"\nFINDING [{kind}] {rel}\n   removed={rem}\n   added={add}")
