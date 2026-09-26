#!/usr/bin/env python3
"""sdist.py FILE N BIN:MODE... — per config, N runs: distribution of (rc, sha256[:10]
of stdout with the ModuleID line dropped). MODE via polenv: system | lifo | nofree |
rb8-<policy> (r1B's independent interposer). Prints which hash is the no-reuse
reference if a `REF=BIN:MODE` env is given."""
import hashlib, os, subprocess, sys
from collections import Counter
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import polenv
T = os.path.dirname(os.path.abspath(__file__))
f, n = sys.argv[1], int(sys.argv[2])


def run(spec):
    b, m = spec.rsplit(":", 1)
    r = subprocess.run([f"{T}/cq-opt.{b}", "-passes=cq-lowering", "-S", f, "-o", "-"],
                       env=polenv.env_for(m), capture_output=True, text=True)
    body = "\n".join(l for l in r.stdout.splitlines() if not l.startswith("; ModuleID"))
    return r.returncode, hashlib.sha256(body.encode()).hexdigest()[:10]


for spec in sys.argv[3:]:
    c = Counter(run(spec) for _ in range(n))
    print(f"{spec:26s} " + "  ".join(f"{v}x(rc={k[0]},{k[1]})" for k, v in c.most_common()))
