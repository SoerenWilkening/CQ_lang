#!/usr/bin/env python3
"""Prove `cq-opt` is observationally identical to stock `opt` on every fixture.

WHY THIS GATE EXISTS. ir-pass-lit no longer runs stock `opt`; it runs `cq-opt`,
a purpose-built driver that links only the LLVM components the pass needs and so
pays 0.124s of fixed per-spawn cost instead of `opt`'s 0.238s (MEASURED; the pass
itself is ~5ms, so almost all of it is process startup either way).

That swap is only safe while the two are INDISTINGUISHABLE, and "indistinguishable"
here is stricter than "same IR". 575 negative fixtures pipe stderr into FileCheck
and assert on the DIAGNOSTIC TEXT, and every fixture depends on the exit code
(lit's `not` inverts it). So this compares all three:

    stdout   -- the lowered module
    stderr   -- the diagnostics, character for character (Rule 12)
    exit code

A pass change that made cq-opt and opt diverge -- a diagnostic printed through a
different channel, a pipeline that stopped registering an analysis cq-opt does
not link, an ordering that depends on a cl::opt only `opt` defines -- would
otherwise be invisible: the suite would stay green while testing a tool that is
no longer the tool. That is the verify-clean silent-miscompile shape, one level
up, so it gets a gate rather than a comment.

Exits non-zero on the first divergence with a readable report.
"""
import argparse
import glob
import multiprocessing
import os
import subprocess
import sys

_ARGS = None


def _init(argv):
    """Pool initializer. macOS defaults to the 'spawn' start method, so a global
    assigned in main() does NOT reach workers -- they must be seeded explicitly."""
    global _ARGS
    _ARGS = argv


def _compare(f):
    """-> (path, why, ref, new) on divergence, else None. Runs in a pool worker."""
    a = _ARGS
    ref = subprocess.run(
        [a.opt, "-load-pass-plugin", a.plugin, "-passes=cq-lowering", "-S", f],
        capture_output=True)
    new = subprocess.run(
        [a.cq_opt, "-passes=cq-lowering", "-S", f],
        capture_output=True)
    why = []
    if ref.returncode != new.returncode:
        why.append("exit %d != %d" % (ref.returncode, new.returncode))
    if ref.stdout != new.stdout:
        why.append("stdout differs")
    if ref.stderr != new.stderr:
        why.append("stderr differs")
    if not why:
        return None
    # keep only what the report prints; Popen objects do not pickle well
    return (f, "; ".join(why), ref.stderr[:300], new.stderr[:300])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--opt", required=True, help="stock opt (the reference)")
    ap.add_argument("--cq-opt", required=True, help="the purpose-built driver")
    ap.add_argument("--plugin", required=True, help="libCQPass.so, for the reference")
    ap.add_argument("--fixtures", required=True, help="directory of *.ll fixtures")
    ap.add_argument("--limit", type=int, default=0, help="stop after N (debugging)")
    ap.add_argument("--jobs", type=int, default=0, help="worker processes (0 = auto)")
    ap.add_argument(
        "--stride", type=int, default=1,
        help="check every Nth fixture (1 = all). The full sweep spawns 2 procs "
             "per fixture and costs ~658s of CPU -- MORE than the cq-opt swap "
             "saves -- so the routine ctest entry samples with a stride and the "
             "full sweep is run on demand. The sample is deterministic and "
             "sorted, so it spreads across the whole corpus rather than "
             "clustering on one prefix.")
    args = ap.parse_args()

    files = sorted(glob.glob(os.path.join(args.fixtures, "*.ll")))
    if not files:
        print("cq_opt_equivalence: no fixtures found in %s" % args.fixtures)
        return 1
    total = len(files)
    if args.stride > 1:
        files = files[::args.stride]
    if args.limit:
        files = files[:args.limit]
    if len(files) != total:
        # Never let a sampled run read as full coverage.
        print("cq_opt_equivalence: SAMPLING %d of %d fixtures (stride=%d). "
              "Run with --stride 1 for the full sweep."
              % (len(files), total, args.stride))

    # Parallel: this spawns 2 processes per fixture (~2050 total) and each pays
    # its own fixed startup, so serially it costs ~370s of CPU -- more than the
    # whole rest of the suite. The work is embarrassingly parallel and every
    # invocation is independent, so a pool is free correctness-wise.
    # argparse.Namespace pickles fine; seed each worker through the initializer.
    workers = args.jobs or min(8, (os.cpu_count() or 4))
    with multiprocessing.Pool(workers, initializer=_init, initargs=(args,)) as pool:
        results = pool.map(_compare, files, chunksize=8)
    mismatches = [r for r in results if r is not None]

    print("cq_opt_equivalence: compared %d fixtures, %d mismatch(es)"
          % (len(files), len(mismatches)))
    for f, why, ref_err, new_err in mismatches[:10]:
        print("\n  FAIL %s -- %s" % (os.path.basename(f), why))
        if ref_err != new_err:
            print("    opt    stderr: %r" % ref_err)
            print("    cq-opt stderr: %r" % new_err)
    return 1 if mismatches else 0


if __name__ == "__main__":
    sys.exit(main())
