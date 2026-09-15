#!/usr/bin/env python3
"""Resume half of the Track F' corpus sweep (2026-09-15).

Same row format and same two warnings as `corpus_sweep.py` (full stderr, never a
tag regex — PROTOCOL S3; md5s compared only WITHIN a row). Two differences, both
forced by measurement rather than taste:
  * it RESUMES from `corpus_done.txt`, because the box was running at load 200+
    under cross-track contention and a sweep that cannot be resumed is a sweep
    whose cost is paid again every time it is interrupted;
  * it orders `ir-pass/test/*.ll` FIRST, because the shipped-fixture flip count
    is the number the landing is judged on and the probe corpora are large
    stage-1/stage-2 dumps that dominate the wall clock.
"""
import subprocess, sys, os, hashlib, glob
from concurrent.futures import ThreadPoolExecutor
ORC="/Users/sorenwilkening/Desktop/CQ_lang"; SUB="/Users/sorenwilkening/Desktop/CQ_F"
def run(root, ll, out):
    p=subprocess.run([f"{root}/build/ir-pass/cq-opt","-load-pass-plugin",
        f"{root}/build/ir-pass/libCQPass.so","-passes=cq-lowering","-S",ll,"-o",out],
        capture_output=True,text=True)
    if p.returncode==0:
        try: d=open(out,"rb").read()
        except OSError: return "A:<unreadable>"
        d=b"\n".join(l for l in d.split(b"\n")
                     if not l.startswith(b"; ModuleID") and not l.startswith(b"source_filename"))
        return "A:"+hashlib.md5(d).hexdigest()[:8]
    return "D:"+" ".join(p.stderr.split())
def one(a):
    i,f=a
    if os.path.getsize(f)==0: return f"{os.path.relpath(f,SUB)}|EMPTY|EMPTY"
    return f"{os.path.relpath(f,SUB)}|{run(ORC,f,f'/tmp/_r_o{i%20}.ll')}|{run(SUB,f,f'/tmp/_r_s{i%20}.ll')}"
def main():
    out=sys.argv[1]; donef=sys.argv[2]
    done=set(l.split("|")[0] for l in open(donef)) if os.path.exists(donef) else set()
    files=sorted(glob.glob(f"{SUB}/ir-pass/test/*.ll"))
    base=f"{SUB}/docs/prd/phase-04-swap-route-control/inc1-records"
    probes=[]
    for d in sorted(glob.glob(f"{base}/session-*/**/",recursive=True)):
        if "probes" in d: probes+=sorted(glob.glob(d+"*.ll"))
    files=[f for f in files if os.path.relpath(f,SUB) not in done] + \
          [f for f in sorted(set(probes)) if os.path.relpath(f,SUB) not in done]
    print(f"resuming: {len(done)} already done, {len(files)} to go",flush=True)
    n=0
    with open(out,"w") as fh, ThreadPoolExecutor(max_workers=20) as ex:
        for row in ex.map(one,enumerate(files)):
            fh.write(row+"\n"); fh.flush(); n+=1
            if n%200==0: print(f"... {n}/{len(files)}",flush=True)
    print("RESUME DONE",flush=True)
main()
