#!/usr/bin/env python3
"""Track P vacuity check over the NEW fixtures, TWO questions:

(a) PATH COLLISION (bd `qta2`): does any `-NOT` pattern match the pass output's own
    `; ModuleID = '<path>'` / `source_filename` line? Such a negative passes for the
    wrong reason forever.
(b) NAMED-HANDLE VACUITY: a `-NOT` naming an SSA handle the lowered module never
    defines pins nothing.

Reports counts, never "n/a" (a harness that reports n/a is a HOLE, PROTOCOL S3)."""
import re, subprocess, sys, os
REPO = os.environ.get('REPO', os.getcwd())
BUILD = os.environ.get('BUILD', REPO + '/build')
pathbad = namebad = pat_tot = name_tot = 0
files = sys.argv[1:]
for f in files:
    txt = open(f).read()
    o = subprocess.run([f'{BUILD}/ir-pass/cq-opt', '-load-pass-plugin',
                        f'{BUILD}/ir-pass/libCQPass.so', '-passes=cq-lowering', '-S', f],
                       capture_output=True, text=True)
    if o.returncode != 0:
        continue  # decline fixture: its property is the `not` inversion (Rule 12(b))
    out = o.stdout
    idlines = [l for l in out.splitlines() if l.startswith('; ModuleID') or l.startswith('source_filename')]
    defined = set(re.findall(r'^\s*(%[\w.]+) = ', out, re.M))
    for line in txt.splitlines():
        m = re.match(r';\s*([A-Z0-9]+)-NOT:\s*(.+?)\s*$', line)
        if not m:
            continue
        pat_tot += 1
        raw = m.group(2)
        lit = re.sub(r'\{\{.*?\}\}', '', raw)          # strip FileCheck regexes
        lit = lit.replace('%[[', '').replace(']]', '')
        probe = lit.strip()
        if probe and any(probe in il for il in idlines):
            pathbad += 1
            print(f"  PATH-COLLISION  {os.path.basename(f)}: {line.strip()}")
        for h in re.findall(r'\(i32 (%[\w.]+)\)', raw):
            name_tot += 1
            if h not in defined:
                namebad += 1
                print(f"  VACUOUS-NAME  {os.path.basename(f)}: {h} never defined | {line.strip()}")
print(f"vacuity_p: {len(files)} fixture(s); {pat_tot} negative pattern(s) checked for path collision "
      f"({pathbad} bad); {name_tot} named handle(s) checked ({namebad} vacuous)")
