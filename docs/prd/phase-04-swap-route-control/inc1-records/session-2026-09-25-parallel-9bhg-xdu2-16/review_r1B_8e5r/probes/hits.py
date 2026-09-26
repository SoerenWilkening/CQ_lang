#!/usr/bin/env python3
"""hits.py — review r1B_8e5r: run the PRIVATE positive-control build (subject +
probes/posctl_counter.patch) over a module list with CQ_SCRUB_STATS=1 and record
per module the three counters (query_hits: a count/find/lookup that the
self-cleaning container answered 'absent' for a DEAD address where a raw table
answered 'present'; iter_skips: a dead key an iteration would have yielded;
revives: an insert at a dead address). Denominator printed; a module whose
counter line is MISSING is reported (a crash or a passthrough early-out)."""
import os, re, subprocess, sys, json
from concurrent.futures import ThreadPoolExecutor
B, mode, lst, out = sys.argv[1:5]
files = [l.strip() for l in open(lst) if l.strip()]
def one(f):
    env = dict(os.environ, CQ_SCRUB_STATS="1"); env.pop("DYLD_INSERT_LIBRARIES", None)
    if mode == "sys": env.pop("CQ_OPT_DEBUG_ALLOC", None)
    else: env["CQ_OPT_DEBUG_ALLOC"] = mode
    r = subprocess.run([B, "-passes=cq-lowering", "-S", f, "-o", "/dev/null"], env=env, capture_output=True)
    m = re.search(rb"query_hits=(\d+) iter_skips=(\d+) revives=(\d+)", r.stderr)
    return (f, r.returncode, tuple(int(x) for x in m.groups()) if m else None)
with ThreadPoolExecutor(int(os.environ.get("J", "5"))) as ex:
    res = list(ex.map(one, files))
json.dump(res, open(out, "w"))
miss = [r for r in res if r[2] is None]
q = [r for r in res if r[2] and r[2][0]]; it = [r for r in res if r[2] and r[2][1]]; rv = [r for r in res if r[2] and r[2][2]]
anyh = [r for r in res if r[2] and any(r[2])]
print(f"{os.path.basename(B)} mode={mode}: denominator {len(files)}; counter line missing {len(miss)}; "
      f"modules with query_hits>0: {len(q)}, iter_skips>0: {len(it)}, revives>0: {len(rv)}, any: {len(anyh)}")
