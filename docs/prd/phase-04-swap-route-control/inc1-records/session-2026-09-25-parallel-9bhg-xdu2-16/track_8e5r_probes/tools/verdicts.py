#!/usr/bin/env python3
"""verdicts.py N FILE... -- BINS from env VBINS (space-separated BIN:MODE specs, BIN
relative to $T as cq-opt.<name>). For each module x binary: N runs, distribution
of (rc, first error line)."""
import os, subprocess, sys
from collections import Counter
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import polenv
T = os.path.dirname(os.path.abspath(__file__))
n = int(sys.argv[1]); files = sys.argv[2:]
specs = os.environ.get("VBINS", "oracle:system subj4:system oracle_ba80:system fin:system").split()
for f in files:
    for spec in specs:
        b, m = spec.rsplit(":", 1)
        c = Counter()
        for _ in range(n):
            r = subprocess.run([f"{T}/cq-opt.{b}", "-passes=cq-lowering", "-S", f, "-o", "/dev/null"],
                               env=polenv.env_for(m), capture_output=True, text=True)
            e = next((l for l in r.stderr.splitlines() if "error:" in l), "")
            c[(r.returncode, e.split("error:", 1)[-1].strip()[:150])] += 1
        print(f"{os.path.basename(f):40s} {spec:22s} " + " | ".join(f"{v}x rc={k[0]} {k[1]}" for k, v in c.items()))
