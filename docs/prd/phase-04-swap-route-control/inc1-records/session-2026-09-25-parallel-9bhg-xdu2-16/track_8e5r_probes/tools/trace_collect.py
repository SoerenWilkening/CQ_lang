#!/usr/bin/env python3
"""trace_collect.py LIST OUT — run the trace build over every module of LIST with
CQ_SCRUB_TRACE=1; every trace is a TaintSet key deleted WITHOUT an explicit
scrub. Attribute each to the first `cq::` frame (not `cq::scrub::`) via atos,
and print: attributed site -> events, modules. Denominator printed first."""
import os, subprocess, sys
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor

T = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/t8e5r"
BIN = f"{T}/trace_build/ir-pass/cq-opt"
lst, out = sys.argv[1], sys.argv[2]
files = [l.strip() for l in open(lst) if l.strip()]
print(f"denominator: {len(files)} modules", flush=True)

def one(f):
    r = subprocess.run([BIN, "-passes=cq-lowering", "-S", f, "-o", "/dev/null"],
                       env=dict(os.environ, CQ_SCRUB_TRACE="1"), capture_output=True, text=True)
    return f, r.returncode, [l.split()[2:] for l in r.stderr.splitlines() if l.startswith("SCRUB-TRACE")]

with ThreadPoolExecutor(10) as ex:
    res = list(ex.map(one, files))
addrs = sorted({a for _, _, trs in res for t in trs for a in t})
print(f"trace events: {sum(len(t) for _, _, t in res)}  modules with >=1 event: {sum(1 for _, _, t in res if t)}  unique frame addresses: {len(addrs)}", flush=True)
sym = {}
for i in range(0, len(addrs), 400):
    chunk = addrs[i:i + 400]
    r = subprocess.run(["atos", "-o", BIN] + chunk, capture_output=True, text=True)
    for a, s in zip(chunk, r.stdout.splitlines()):
        sym[a] = s
def site(t):
    for a in t:
        s = sym.get(a, "?")
        if "cq::" in s and "cq::scrub::" not in s and "cqScrubTrace" not in s:
            return s.split(" (in ")[0][:150], s
    return "(no cq:: frame)", ""
ev = Counter(); mods = defaultdict(set); loc = {}
for f, rc, trs in res:
    for t in trs:
        k, full = site(t)
        ev[k] += 1; mods[k].add(os.path.basename(f)); loc[k] = full
with open(out, "w") as o:
    for k, n in ev.most_common():
        line = f"{n}\t{len(mods[k])}\t{k}\t{loc[k].split(') (')[-1] if ') (' in loc[k] else ''}\t{','.join(sorted(mods[k])[:3])}"
        o.write(line + "\n")
        print(line)
