#!/usr/bin/env python3
"""ORACLE-vs-SUBJECT corpus sweep for Track F' (2026-09-15).

A row is  <rel path>|<oracle verdict>|<subject verdict>  where a verdict is
  A:<md5-8 of the lowered IR, ModuleID/source_filename stripped>   on exit 0
  D:<FULL stderr, whitespace-collapsed>                            on a decline

⚠ The FULL stderr is compared, not a tag regex. PROTOCOL S3: the shared
corpus.sh regex renders the whole `cq_measure_<sfx>` family as an empty `D:`, so
a decline->decline STRING change inside it would be INVISIBLE.
⚠ md5s of lowered IR are NOT comparable ACROSS sweeps (the temp ModuleID
changes); this script only ever compares WITHIN a row, which is why it strips
those two lines and why both binaries are given the SAME input file.
⚠ Rows are written INCREMENTALLY and each worker uses its OWN temp output path.
The first spelling of this script buffered everything and wrote at the end,
which meant 25 minutes of work under cross-track load with ZERO observable
progress and nothing recoverable if it had to be stopped. A long measurement
that cannot be observed is one you cannot decide about.
⚠ A 0-byte module ACCEPTS through the pass's passthrough early-out
(bd memory `empty-module-accepts-vacuity-trap`), so empty files are scored EMPTY
rather than A:.
"""
import subprocess, sys, os, hashlib, glob
from concurrent.futures import ThreadPoolExecutor
ORC = "/Users/sorenwilkening/Desktop/CQ_lang"
SUB = "/Users/sorenwilkening/Desktop/CQ_F"

def run(root, ll, out):
    p = subprocess.run([f"{root}/build/ir-pass/cq-opt", "-load-pass-plugin",
                        f"{root}/build/ir-pass/libCQPass.so", "-passes=cq-lowering",
                        "-S", ll, "-o", out], capture_output=True, text=True)
    if p.returncode == 0:
        try:
            d = open(out, "rb").read()
        except OSError:
            return "A:<unreadable>"
        d = b"\n".join(l for l in d.split(b"\n")
                       if not l.startswith(b"; ModuleID")
                       and not l.startswith(b"source_filename"))
        return "A:" + hashlib.md5(d).hexdigest()[:8]
    return "D:" + " ".join(p.stderr.split())

def one(arg):
    i, f = arg
    if os.path.getsize(f) == 0:
        return f"{os.path.relpath(f, SUB)}|EMPTY|EMPTY"
    o = run(ORC, f, f"/tmp/_sw_o{i%16}.ll")
    s = run(SUB, f, f"/tmp/_sw_s{i%16}.ll")
    return f"{os.path.relpath(f, SUB)}|{o}|{s}"

def main():
    outpath = sys.argv[1]
    files = sorted(glob.glob(f"{SUB}/ir-pass/test/*.ll"))
    base = f"{SUB}/docs/prd/phase-04-swap-route-control/inc1-records"
    for d in sorted(glob.glob(f"{base}/session-*/**/", recursive=True)):
        if "probes" in d:
            files += sorted(glob.glob(d + "*.ll"))
    files = sorted(set(files))
    done = 0
    with open(outpath + ".part", "w") as fh, ThreadPoolExecutor(max_workers=10) as ex:
        for row in ex.map(one, enumerate(files)):
            fh.write(row + "\n"); fh.flush()
            done += 1
            if done % 250 == 0:
                print(f"... {done}/{len(files)}", flush=True)
    rows = [r.rstrip("\n") for r in open(outpath + ".part")]
    open(outpath, "w").write("\n".join(rows) + f"\nTOTAL {len(rows)}\n")
    os.remove(outpath + ".part")
    mv = [r for r in rows if r.count("|") == 2 and r.split("|")[1] != r.split("|")[2]]
    print(f"files={len(files)} MOVERS={len(mv)}")
    for m in mv:
        print("MOVER " + m[:300])
main()
