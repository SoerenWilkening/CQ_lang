#!/usr/bin/env python3
"""Vacuous-negative check — Track W (bd `test_C_libtooling-wx8g`).

⚠ THE INHERITED SCRIPT REPORTED `checked 0` ON THIS BATCH, WHICH PROTOCOL.md S3
CALLS A HOLE, NOT A PASS. `$PREV/trackM/probes/impl/vacuity.py` matches only
`; NOX-NOT: … (i32 %handle)` — a negative naming an SSA HANDLE — and every
negative in this batch names a SYMBOL instead (`cq_template_`, `@cqrt_x(`,
`@cqrt_cswap(`). Its question was "does the module define the handle this -NOT
names?"; the same question for a symbol negative is asked in two halves:

  (V1) DOES IT MATCH THE MODULE'S OWN HEADER? bd `qta2`: a bare `-NOT: <word>`
       can match the `; ModuleID = …` / `source_filename = …` path line, which
       makes the fixture RED for a reason that has nothing to do with the
       lowering — or, if the path happens not to contain it today, makes it
       silently path-dependent. Reported as a FINDING either way.
  (V2) IS THE CONSTRUCT REACHABLE AT ALL? A `-NOT` naming a symbol this compiler
       can never emit is vacuous the way `NOX-NOT: %h99` is: it passes for the
       wrong reason. Checked against the union of every OTHER fixture's lowered
       output in the corpus given on the command line after `--universe`.
"""
import re, subprocess, sys, os
REPO='/Users/sorenwilkening/Desktop/CQ_wx8g'

def lower(f):
    o=subprocess.run([f'{REPO}/build/ir-pass/cq-opt','-load-pass-plugin',
        f'{REPO}/build/ir-pass/libCQPass.so','-passes=cq-lowering','-S',f],
        capture_output=True,text=True)
    return o.stdout if o.returncode==0 else None

args=sys.argv[1:]
uni=[]
if '--universe' in args:
    i=args.index('--universe'); uni=args[i+1:]; args=args[:i]

universe=''
for f in uni:
    t=lower(f)
    if t: universe+=t

bad=0; tot=0; handles=0
for f in args:
    txt=open(f).read()
    out=lower(f)
    if out is None:
        print(f"  SKIP (declines) {os.path.basename(f)}"); continue
    header='\n'.join(l for l in out.splitlines()
                     if l.startswith('; ModuleID') or l.startswith('source_filename'))
    defined=set(re.findall(r'^\s*(%[\w.]+) = ', out, re.M))
    for line in txt.splitlines():
        m=re.match(r';\s*([A-Za-z0-9_]+)-NOT:\s*(.+?)\s*$', line)
        if not m: continue
        pfx,pat=m.group(1),m.group(2)
        tot+=1
        # (V1)
        if pat in header:
            bad+=1; print(f"  VACUOUS/HEADER {os.path.basename(f)}: `{pat}` matches the module header  |  {line.strip()}")
            continue
        # the handle form the inherited script checked, kept
        h=re.search(r'\((?:i32 )?(%[\w.]+)\)', pat)
        if h:
            handles+=1
            if h.group(1) not in defined:
                bad+=1; print(f"  VACUOUS/HANDLE {os.path.basename(f)}: {h.group(1)} is never defined  |  {line.strip()}")
                continue
        # (V2) ⚠ WITH ONE EXCLUSION, AND IT IS A REAL DISTINCTION RATHER THAN A
        #      CONVENIENCE. A `-NOT` naming a FRONT-END intrinsic (`@cq_theta_`,
        #      `@cq_phi_`, `@cq_measure_`) pins the PASS'S OWN POSTCONDITION —
        #      `declineSurvivingIntrinsicCalls` makes "no `@cq_*` survives" a
        #      checked, LOUD property (Rule 1) — so it appears in NO lowered
        #      module BY CONSTRUCTION and its absence from the universe is the
        #      thing it asserts, not evidence that it is vacuous. Every OTHER
        #      symbol negative must name something this compiler can emit.
        if pat.startswith('@cq_theta_') or pat.startswith('@cq_phi_') or pat.startswith('@cq_measure_'):
            continue
        if universe and pat not in universe:
            bad+=1; print(f"  VACUOUS/UNREACHABLE {os.path.basename(f)}: `{pat}` appears in no lowered module of the universe  |  {line.strip()}")
print(f"checked {tot} named negatives ({handles} handle-form) across {len(args)} accept fixtures "
      f"against a universe of {len(uni)} modules: {bad} VACUOUS")
