#!/usr/bin/env python3
"""corpus A/B sweep — every ir-pass/test/*.ll through ORACLE and SUBJECT.
Prints one row per MOVER: name, oracle verdict+first diagnostic, subject verdict+first diagnostic.
Every row carries the two cq-opt hashes (PROTOCOL F-11)."""
import subprocess, sys, os, hashlib, concurrent.futures as cf
L="/usr/local/opt/llvm@19/bin"
O="/Users/sorenwilkening/Desktop/Projects/CQ_lang"
W="/Users/sorenwilkening/Desktop/Projects/cq-wt-zujr"
def h(p): return hashlib.sha256(open(p,'rb').read()).hexdigest()[:8]
HO, HS = h(f"{O}/build/ir-pass/cq-opt"), h(f"{W}/build/ir-pass/cq-opt")
def run(plugin, f):
    try:
        r = subprocess.run([f"{L}/opt","-load-pass-plugin",plugin,"-passes=cq-lowering","-S",f,"-o","/dev/null"],
                           capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        return ("TIMEOUT","")
    d=""
    for line in r.stderr.splitlines():
        if line.startswith("error"):
            d=line.split("): ",1)[-1]; break
    if not d:
        for line in r.stderr.splitlines():
            if line.startswith("warning"):
                d="WARN:"+line.split("): ",1)[-1]; break
    return ("ACCEPT" if r.returncode==0 else f"DECLINE({r.returncode})", d)
files=sorted(f"{W}/ir-pass/test/{x}" for x in os.listdir(f"{W}/ir-pass/test") if x.endswith(".ll"))
def one(f):
    a=run(f"{O}/build/ir-pass/libCQPass.so", f)
    b=run(f"{W}/build/ir-pass/libCQPass.so", f)
    return (os.path.basename(f), a, b)
rows=[]
with cf.ThreadPoolExecutor(max_workers=6) as ex:
    for r in ex.map(one, files): rows.append(r)
mov=[r for r in rows if r[1]!=r[2]]
print(f"# oracle={HO} subject={HS}  files={len(rows)}  movers={len(mov)}")
for n,a,b in mov:
    print(f"{n}\n    ORACLE  {a[0]:12s} {a[1]}\n    SUBJECT {b[0]:12s} {b[1]}")
