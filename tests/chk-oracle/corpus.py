#!/usr/bin/env python3
"""corpus.py [NN_name ...] [-j N]: every example's .O1.ll under the C oracle on the fixture samples.

Per example: samples run, failures (each with its reason), outcomes, and whether site, trip and ret
events occurred. A failed sample, an example whose oracle build fails, an example with loops but no
trip event, or one with no site event exits 1. --sampleset runs chk-drivers' sampling.sample_set
instead of the fixture's stress set.
"""
from __future__ import annotations

import argparse
import collections
import concurrent.futures as cf
import subprocess
import functools
import sys

print = functools.partial(print, flush=True)  # noqa: A001  (progress visible when redirected)
import traceback

import fixture as fx
from cqcheck import oracle


def _init(ss: bool) -> None:
    global SAMPLESET
    SAMPLESET = ss


def one(name: str):
    o1 = fx.o1_of(name)
    try:
        spec = fx.spec_of(name)
        samples = fx.sampling.sample_set(spec, fx.example_dir(name)).samples if SAMPLESET \
            else fx.samples(name, spec)
        runs = oracle.run_samples(o1, spec, samples)
    except Exception as e:  # an oracle build error is a failure of this example, never a skip
        return name, 0, None, f"{type(e).__name__}: {e}"
    return name, len(samples), runs, None


SAMPLESET = False


def loops_in(o1) -> bool:
    p = subprocess.run([oracle._tool("opt"), "-passes=print<loops>", "-disable-output", str(o1)],
                       capture_output=True, text=True)
    return "Loop at depth" in p.stderr


def main() -> int:
    global SAMPLESET
    ap = argparse.ArgumentParser()
    ap.add_argument("names", nargs="*")
    ap.add_argument("-j", type=int, default=oracle._jobs_cap())   # $CQCHECK_JOBS when set
    ap.add_argument("--sampleset", action="store_true", help="run chk-drivers' SampleSet instead of the stress set")
    a = ap.parse_args()
    SAMPLESET = a.sampleset
    names = a.names or fx.names()
    bad = 0
    totals = collections.Counter()
    with cf.ProcessPoolExecutor(max(1, min(a.j, oracle._jobs_cap())), initializer=_init, initargs=(SAMPLESET,)) as ex:
        for name, n, runs, err in ex.map(one, names):
            if err:
                bad += 1
                print(f"{name}: BUILD-ERROR {err.splitlines()[0][:300]}")
                for l in err.splitlines()[1:6]:
                    print("    " + l[:300])
                continue
            has_loop = loops_in(fx.o1_of(name))
            fails = [r for r in runs if r.failed]
            outc = collections.Counter(r.outcome or "FAILED" for r in runs)
            evs = collections.Counter(e["ev"] for r in runs for e in r.events)
            totals["samples"] += n
            totals["failed"] += len(fails)
            problems = []
            if fails:
                problems.append(f"{len(fails)} failed")
            if not evs["site"]:
                problems.append("no site event")
            if not evs["ret"] and outc.get("ret"):
                problems.append("no ret event")
            if has_loop and not evs["trip"] and not any(r.loops for r in runs):
                problems.append("loop but no trip event")   # a sample cut at K has no exit (cq-8ay)
            if problems:
                bad += 1
            print(f"{name}: {n} samples, outcomes {dict(outc)}, events {dict(evs)}"
                  + (f"  PROBLEM: {'; '.join(problems)}" if problems else ""))
            for r in fails[:5]:
                print(f"    sample {r.index} {r.sample}: {r.reason} notes={r.notes}")
    print(f"TOTAL examples {len(names)}, with problems {bad}, samples {totals['samples']}, "
          f"failed samples {totals['failed']}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
