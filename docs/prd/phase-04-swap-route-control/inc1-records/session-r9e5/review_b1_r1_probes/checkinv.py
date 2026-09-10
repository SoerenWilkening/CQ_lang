# checkinv.py (review_b1_r1) — the mechanical form of 1b-B.1's central promise:
# NO non-diagonal gate ever lands on a user register. For every %r that is arg 0 of a
# `cqrt_ry_*` in a lowered module, report any cqrt_x(%r), cqrt_free(%r), cqrt_cswap naming %r,
# cqrt_cnot with %r in the TARGET slot, any `_unc` naming %r, and any ODD count of cnot CONTROL
# uses of %r (the mint/strip must pair).
# USAGE: run from a directory holding `out/*.POST.s2.ll` (the stage-2 modules of the probe
# corpus, e.g. produced by a variant of run_corpus.sh that keeps them). Round 1 measured
# 58 modules, 0 violations.
import re,sys,glob,os
# For each accepted POST s2 module: find every cq/cqrt rail that is a cq_theta_i1 result
# (identified as the arg0 of cqrt_ry_i1 emitted right after cqrt_alloc_i1 with a ry),
# then report any cqrt_x / cqrt_free / _unc / cqrt_ry_..._controlled naming it,
# and check cqrt_cnot(rail, f) pairing.
bad=[]
for f in sorted(glob.glob("out/*.POST.s2.ll")):
    txt=open(f).read()
    # user registers = SSA values produced by cqrt_alloc_i1/i32/... that carry a cqrt_ry_
    ry=set(re.findall(r'call void @cqrt_ry_\w+\(i32 (%[\w.]+),', txt))
    if not ry: continue
    for r in sorted(ry):
        rr=re.escape(r)
        xs=re.findall(r'call void @cqrt_x\(i32 '+rr+r'\)', txt)
        fr=re.findall(r'call void @cqrt_free\(i32 '+rr+r'\)', txt)
        unc=re.findall(r'call void @[\w]*_unc\([^)]*'+rr+r'\b', txt)
        cn0=re.findall(r'call void @cqrt_cnot\(i32 '+rr+r', i32 (%[\w.]+)\)', txt)
        cn1=re.findall(r'call void @cqrt_cnot\(i32 (%[\w.]+), i32 '+rr+r'\)', txt)
        cs=re.findall(r'call void @cqrt_cswap\([^)]*'+rr+r'\b', txt)
        msg=[]
        if xs: msg.append("cqrt_x x%d"%len(xs))
        if fr: msg.append("cqrt_FREE x%d"%len(fr))
        if unc: msg.append("_unc:%s"%unc)
        if cn1: msg.append("cnot TARGET x%d"%len(cn1))
        if cs: msg.append("cswap")
        # cnot control pairing
        from collections import Counter
        c=Counter(cn0)
        odd=[k for k,v in c.items() if v%2]
        if odd: msg.append("unpaired cnot ctrl -> %s"%odd)
        if msg: bad.append("%s %s: %s"%(os.path.basename(f), r, "; ".join(msg)))
print("\n".join(bad) if bad else "NO VIOLATION of {no x / no free / no _unc / no cswap / paired cnot} on any rail carrying a cqrt_ry")
print("modules scanned:", len(glob.glob("out/*.POST.s2.ll")))
