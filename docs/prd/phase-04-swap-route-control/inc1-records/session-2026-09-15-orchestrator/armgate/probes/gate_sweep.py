#!/usr/bin/env python3
"""ARM group gate — the ONE corpus sweep on the COMBINED binary (2026-09-15).

Two columns are MEASURED here (ORACLE, MERGED); the per-track attribution is
JOINED from the Rule-13 round's four-binary file rather than re-derived, because
re-deriving it would mean rebuilding BASE_F and P_ALONE for no new information:

    review_r13_armclassify/probes/sweep4_3bb2fd4d.txt
        <relpath>|ORACLE|BASE_F|P_ALONE|SUBJ_P

⚠ THE CELL FORMAT IS sweep4.sh's, CHARACTER-FOR-CHARACTER, which is what makes
the join legal. An accept cell is `A:` + md5 of the lowered IR with `; ModuleID`
and `source_filename` lines stripped — a hash over a NORMALISED text, so it IS
comparable across sweeps for the same input file (PROTOCOL S3's warning is about
md5s of UN-normalised output, where the temp `ModuleID` moves). A decline cell is
`D<rc>:` + md5 of the FULL stderr with the `Stack dump` / `Program arguments` /
frame / `PLEASE submit` argv noise normalised away — never a tag regex, which
renders the whole `cq_measure_<sfx>` family as an empty `D:` and hides a
decline->decline string change inside it.

A 0-byte module is scored EMPTY, never ACCEPT (the passthrough vacuity trap,
bd memory `empty-module-accepts-vacuity-trap`).

Usage: gate_sweep.py <out.txt> [--fixtures-only]
"""
import glob
import hashlib
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

ROOT = "/Users/sorenwilkening/Desktop/CQ_ARM"
BINS = {
    "ORACLE": "/Users/sorenwilkening/Desktop/CQ_lang/build",
    "MERGED": f"{ROOT}/build",
}
NOISE = re.compile(
    r"Stack dump|Program arguments|^ *#[0-9]|PLEASE submit|^0x|^[0-9]+\.", re.M)


def cell(build, ll, out):
    p = subprocess.run(
        [f"{build}/ir-pass/cq-opt", "-load-pass-plugin",
         f"{build}/ir-pass/libCQPass.so", "-passes=cq-lowering", "-S", ll,
         "-o", out],
        capture_output=True, text=True)
    if p.returncode == 0:
        try:
            data = open(out, "rb").read()
        except OSError:
            return "A:<unreadable>"
        keep = b"\n".join(l for l in data.split(b"\n")
                          if not l.startswith(b"; ModuleID")
                          and not l.startswith(b"source_filename"))
        # sweep4.sh pipes through `grep -v` then `md5 -q`; grep output always
        # ends in a newline, so reproduce that byte exactly or the join breaks.
        if not keep.endswith(b"\n"):
            keep += b"\n"
        return "A:" + hashlib.md5(keep).hexdigest()
    err = "\n".join(l for l in p.stderr.split("\n") if not NOISE.match(l))
    if not err.endswith("\n"):
        err += "\n"
    return f"D{p.returncode}:" + hashlib.md5(err.encode()).hexdigest()


def one(arg):
    i, f = arg
    rel = os.path.relpath(f, ROOT)
    if os.path.getsize(f) == 0:
        return f"{rel}|EMPTY|EMPTY"
    cells = [cell(BINS[r], f, f"/tmp/_armgate_{r}_{i % 24}.ll")
             for r in ("ORACLE", "MERGED")]
    return rel + "|" + "|".join(cells)


def main():
    out = sys.argv[1]
    files = sorted(glob.glob(f"{ROOT}/ir-pass/test/*.ll"))
    if "--fixtures-only" not in sys.argv:
        base = f"{ROOT}/docs/prd/phase-04-swap-route-control/inc1-records"
        probes = []
        for d in sorted(glob.glob(f"{base}/session-*/**/", recursive=True)):
            if "probes" in d:
                probes += sorted(glob.glob(d + "*.ll"))
        files += sorted(set(probes))
    print(f"{len(files)} modules x 2 binaries", flush=True)
    n = 0
    with open(out, "w") as fh, ThreadPoolExecutor(max_workers=5) as ex:
        for row in ex.map(one, enumerate(files)):
            fh.write(row + "\n")
            fh.flush()
            n += 1
            if n % 400 == 0:
                print(f"... {n}/{len(files)}", flush=True)
    print("DONE", flush=True)


main()
