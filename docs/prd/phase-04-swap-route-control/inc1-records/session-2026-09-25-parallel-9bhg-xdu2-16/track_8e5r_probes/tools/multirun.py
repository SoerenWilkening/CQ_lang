#!/usr/bin/env python3
"""multirun.py LISTFILE N OUT.tsv BIN:MODE [BIN:MODE ...]
For each module, runs every BIN:MODE N times and records the distribution of
(rc, sha256(stdout)[:12]). The REFERENCE for a module is the output of the FIRST
config's FIRST run (pass the no-reuse reference first). Reports, per config,
how many modules produced ANY run differing from the reference ("wrong"), how
many crashed at least once, and the total wrong-run count — with denominators."""
import hashlib, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import polenv
from collections import Counter
from concurrent.futures import ThreadPoolExecutor

def run(spec, f):
    b, mode = spec.rsplit(":", 1)
    env = polenv.env_for(mode)
    r = subprocess.run([b, "-passes=cq-lowering", "-S", f, "-o", "-"], env=env,
                       capture_output=True)
    return (r.returncode, hashlib.sha256(r.stdout).hexdigest()[:12])

def main():
    lst, n, out, *cfgs = sys.argv[1:]
    n = int(n)
    files = [l.strip() for l in open(lst) if l.strip()]
    print(f"denominator: {len(files)} modules x {len(cfgs)} configs x {n} runs", flush=True)
    jobs = [(f, c, i) for f in files for c in cfgs for i in range(n)]
    with ThreadPoolExecutor(10) as ex:
        res = list(ex.map(lambda j: (j, run(j[1], j[0])), jobs))
    dist = {}
    for (f, c, i), r in res:
        dist.setdefault((f, c), []).append(r)
    ref = {f: dist[(f, cfgs[0])][0] for f in files}
    with open(out, "w") as o:
        for f in files:
            row = [os.path.relpath(f, os.path.dirname(os.path.dirname(f))), f"ref={ref[f][0]}:{ref[f][1]}"]
            for c in cfgs:
                cnt = Counter(dist[(f, c)])
                row.append(c.split('/')[-1] + "=" + ";".join(f"{v}x{k[0]}:{k[1]}" for k, v in cnt.items()))
            o.write("\t".join(row) + "\n")
    for c in cfgs:
        wrong_mods = sum(1 for f in files if any(r != ref[f] for r in dist[(f, c)]))
        crash_mods = sum(1 for f in files if any(r[0] not in (0, 1) for r in dist[(f, c)]))
        wrong_runs = sum(1 for f in files for r in dist[(f, c)] if r != ref[f])
        print(f"{c.split('/')[-1]:28s} modules-with-any-non-reference-run={wrong_mods}/{len(files)}  "
              f"modules-with-a-crash={crash_mods}/{len(files)}  non-reference-runs={wrong_runs}/{len(files)*n}")

main()
