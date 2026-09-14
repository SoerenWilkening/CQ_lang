#!/usr/bin/env python3
"""Track F corpus sweep: ORACLE vs SUBJECT over every .ll the tree and this
session can offer. A row is (exit code, FULL stderr bytes, md5 of lowered IR).

⚠ It deliberately does NOT use the shared corpus.sh tag regex. PROTOCOL S3
records that that regex renders the whole `cq_measure_<sfx>` family as an empty
`D:`, so a decline->decline STRING change inside it is invisible; comparing the
full stderr byte-for-byte closes that hole. Lowered-IR md5s are compared WITHIN a
row only (the temp ModuleID differs across sweeps, S3 again) — here both binaries
read the SAME input path, so the ModuleID is identical and the md5 is comparable.
"""
import hashlib, subprocess, sys, os, glob
ORACLE="/Users/sorenwilkening/Desktop/CQ_lang/build"
SUBJ  ="/Users/sorenwilkening/Desktop/CQ_f2phi/build"
def run(bd, f):
    r=subprocess.run([bd+"/ir-pass/cq-opt","-load-pass-plugin",bd+"/ir-pass/libCQPass.so",
                      "-passes=cq-lowering","-S",f,"-o","-"],capture_output=True,text=True)
    return r.returncode, r.stderr, hashlib.md5(r.stdout.encode()).hexdigest()
files=[]
for pat in sys.argv[1:]:
    files += sorted(glob.glob(pat, recursive=True))
files=[f for f in files if os.path.getsize(f)>0]
mv=[]
for f in files:
    a=run(ORACLE,f); b=run(SUBJ,f)
    if a!=b: mv.append((f,a,b))
print(f"corpus sweep: {len(files)} modules, {len(mv)} mover(s)")
for f,a,b in mv:
    ta=(a[1].split("lowering: ")[1].split(" under")[0] if "lowering: " in a[1] else ("ACCEPT" if a[0]==0 else "?"))
    tb=(b[1].split("lowering: ")[1].split(" under")[0] if "lowering: " in b[1] else ("ACCEPT" if b[0]==0 else "?"))
    same_ir = "IR-same" if a[2]==b[2] else "IR-DIFFERS"
    print(f"  {os.path.basename(f):<64} {ta!r} -> {tb!r}  exit {a[0]}->{b[0]}  {same_ir}")
