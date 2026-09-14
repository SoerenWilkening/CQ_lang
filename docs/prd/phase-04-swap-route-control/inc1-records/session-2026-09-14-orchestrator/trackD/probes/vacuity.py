#!/usr/bin/env python3
"""Vacuous-negative check: every SSA name a pure-negative prefix mentions must
actually be DEFINED in the fixture's lowered output. A `-NOT` naming a handle the
module does not have is VACUOUS — it passes for the wrong reason, exactly like the
bare `NOT: phi` that matched the module path."""
import re, subprocess, sys, os
REPO="/Users/sorenwilkening/Desktop/CQ_3d8q"
bad=0; tot=0
for f in sys.argv[1:]:
    t=open(f).read()
    o=subprocess.run([f'{REPO}/build/ir-pass/cq-opt','-load-pass-plugin',
        f'{REPO}/build/ir-pass/libCQPass.so','-passes=cq-lowering','-S',f],
        capture_output=True,text=True)
    if o.returncode!=0: continue
    defined=set(re.findall(r'^\s*(%[\w.]+) = ', o.stdout, re.M))
    for line in t.splitlines():
        m=re.match(r';\s*(NOX|NOFREE|NOQ|ACNT|RCNT)-NOT:.*\(i32 (%[\w.]+)\)', line)
        if not m: continue
        tot+=1
        if m.group(2) not in defined:
            bad+=1; print(f"  VACUOUS  {os.path.basename(f)}: {m.group(2)} is never defined  |  {line.strip()}")
print(f"checked {tot} named negatives across {len(sys.argv)-1} accept fixtures: {bad} VACUOUS")
