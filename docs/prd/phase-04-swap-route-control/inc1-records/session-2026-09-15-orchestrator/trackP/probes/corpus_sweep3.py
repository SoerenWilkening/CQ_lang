#!/usr/bin/env python3
"""Track P' — the THREE-WAY corpus sweep (2026-09-15).

Why three ways and not two. This track is based on Track F''s branch, not on
`main`, so a two-way ORACLE-vs-SUBJECT row cannot say WHOSE change moved a
module (bd `test_C_libtooling-hlhh`: the F' x P' composition is through the
VERDICT, not through shared code). Each row therefore carries all three:

    <relpath> | <ORACLE> | <BASE> | <SUBJECT>

  ORACLE  = main 74eabd2c          (/Users/sorenwilkening/Desktop/CQ_lang/build)
  BASE    = 3637fdd2 = Track F'    (a verified copy of CQ_F's binary; see GATES.md)
  SUBJECT = this worktree

and the attribution is read straight off it:
    ORACLE != BASE == SUBJECT   -> F''s mover, inherited, not mine
    ORACLE == BASE != SUBJECT   -> MINE
    ORACLE != BASE != SUBJECT   -> both touched it; inspect
    ORACLE == SUBJECT != BASE   -> a REVERSION; inspect (this must not happen)

PROTOCOL S3 is obeyed twice over: decline rows carry the FULL stderr, never a tag
regex (a decline->decline string change inside the `cq_measure_<sfx>` family is
invisible to the shared corpus.sh regex); and accept rows carry an md5 of the
lowered IR that is only ever compared WITHIN a row, never across sweeps (the temp
`ModuleID` differs), which is why the header lines are stripped before hashing.
A 0-byte module is scored EMPTY, never ACCEPT (the passthrough vacuity trap).
"""
import subprocess, sys, os, hashlib, glob
from concurrent.futures import ThreadPoolExecutor

SUB = "/Users/sorenwilkening/Desktop/CQ_P"
ROOTS = {
    "ORACLE": ("/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt",
               "/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/libCQPass.so"),
    "BASE":   (os.environ.get("CQ_BASE_DIR", "") + "/cq-opt",
               os.environ.get("CQ_BASE_DIR", "") + "/libCQPass.so"),
    "SUBJECT": (f"{SUB}/build/ir-pass/cq-opt", f"{SUB}/build/ir-pass/libCQPass.so"),
}

def run(binp, plug, ll, out):
    p = subprocess.run([binp, "-load-pass-plugin", plug, "-passes=cq-lowering",
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

def one(a):
    i, f = a
    rel = os.path.relpath(f, SUB)
    if os.path.getsize(f) == 0:
        return f"{rel}|EMPTY|EMPTY|EMPTY"
    cells = [run(*ROOTS[r], f, f"/tmp/_p3_{r}{i%16}.ll") for r in ("ORACLE", "BASE", "SUBJECT")]
    return rel + "|" + "|".join(cells)

def main():
    out = sys.argv[1]
    if not os.environ.get("CQ_BASE_DIR"):
        sys.exit("CQ_BASE_DIR must point at the directory holding the BASE cq-opt")
    for r, (b, p) in ROOTS.items():
        if not os.path.exists(b):
            sys.exit(f"{r}: no binary at {b}")
    files = sorted(glob.glob(f"{SUB}/ir-pass/test/*.ll"))
    base = f"{SUB}/docs/prd/phase-04-swap-route-control/inc1-records"
    probes = []
    for d in sorted(glob.glob(f"{base}/session-*/**/", recursive=True)):
        if "probes" in d:
            probes += sorted(glob.glob(d + "*.ll"))
    files += sorted(set(probes))
    extra = sorted(glob.glob(os.environ.get("CQ_EXTRA_GLOB", "/nonexistent/*.ll")))
    files += extra
    print(f"{len(files)} modules x 3 binaries", flush=True)
    n = 0
    with open(out, "w") as fh, ThreadPoolExecutor(max_workers=12) as ex:
        for row in ex.map(one, enumerate(files)):
            fh.write(row + "\n"); fh.flush(); n += 1
            if n % 250 == 0:
                print(f"... {n}/{len(files)}", flush=True)
    print("DONE", flush=True)

main()
