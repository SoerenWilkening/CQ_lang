#!/usr/bin/env python3
"""polrun.py — review r1B_8e5r harness: run cq-lowering on modules under allocator
policies, N times, record (rc, sha256(stdout), first stderr line) per run.
Policies: sys (no interposer), lifo/fifo/lifo2/nofree via rb8_interpose.dylib
(independent instrument), dbg:<mode> = the SUBJECT's CQ_OPT_DEBUG_ALLOC=<mode>
(only meaningful for cq-opt-debugalloc binaries).
Prints one line per (binary, module, policy) with the outcome multiset and
ALWAYS the denominator. Exit 0; analysis is by the caller.
usage: polrun.py --n N --pol sys,lifo --bin L=path [--bin ...] --jobs J [--json out] modules...
"""
import argparse, collections, concurrent.futures as cf, hashlib, json, os, subprocess, sys
S = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad"
DYL = S + "/rB8/rb8_interpose.dylib"

def run1(binp, mod, pol):
    env = dict(os.environ)
    env.pop("CQ_OPT_DEBUG_ALLOC", None); env.pop("RB8_ALLOC", None); env.pop("DYLD_INSERT_LIBRARIES", None)
    if pol.startswith("dbg:"):
        env["CQ_OPT_DEBUG_ALLOC"] = pol[4:]
    elif pol != "sys":
        env["DYLD_INSERT_LIBRARIES"] = DYL; env["RB8_ALLOC"] = pol
    p = subprocess.run([binp, "-passes=cq-lowering", "-S", mod], env=env, capture_output=True, timeout=300)
    err = p.stderr.decode(errors="replace").strip().splitlines()
    first = next((l for l in err if "error:" in l or "warning:" not in l), err[0] if err else "")
    h = hashlib.sha256(p.stdout).hexdigest()[:10] if p.stdout else "EMPTY"
    return (p.returncode, h, first[:160])

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=5); ap.add_argument("--pol", default="sys")
    ap.add_argument("--bin", action="append", required=True); ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--json"); ap.add_argument("mods", nargs="+")
    a = ap.parse_args()
    bins = [b.split("=", 1) for b in a.bin]; pols = a.pol.split(",")
    tasks = [(L, B, m, p, i) for (L, B) in bins for m in a.mods for p in pols for i in range(a.n)]
    res = collections.defaultdict(list)
    with cf.ThreadPoolExecutor(a.jobs) as ex:
        futs = {ex.submit(run1, B, m, p): (L, m, p) for (L, B, m, p, i) in tasks}
        for f in cf.as_completed(futs):
            res[futs[f]].append(f.result())
    out = {}
    for (L, B) in bins:
        for m in a.mods:
            for p in pols:
                r = res[(L, m, p)]
                c = collections.Counter((rc, h) for rc, h, _ in r)
                s = " ".join(f"rc{rc}/{h}x{n}" for (rc, h), n in sorted(c.items()))
                print(f"{L}\t{os.path.basename(m)}\t{p}\tN={len(r)}\t{s}")
                out[f"{L}|{m}|{p}"] = r
    if a.json:
        json.dump(out, open(a.json, "w"))

if __name__ == "__main__":
    main()
