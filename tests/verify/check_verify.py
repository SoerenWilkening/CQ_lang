#!/usr/bin/env python3
"""Acceptance test of cq-w0-verify (the structural verifier, NORTHSTAR principle 4).

1. spec.lock holds (tools/spec_lock.py).
2. Every reference `examples/*/*.lowered.ll` of the pinned corpus (counted from the directory) is
   accepted by `opt -passes=cq-verify` and by `opt -passes='cq-verify<reference>'`.
3. Every module in tests/verify/mutants/ gives its expected verdict. Its first line says
   `; EXPECT: accept` or `; EXPECT: <check>`: opt must then exit non-zero with
   `LLVM ERROR: cq: verify:` and a line naming <check>. Every named check has at least one mutant.

Usage: check_verify.py --plugin build/pass/libCQLower.so [--opt OPT] [--spec DIR]
Exit 0 only when every check holds; every failure is printed.
"""
import argparse
import concurrent.futures
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
CHECKS = [
    "free-without-unc",
    "use-after-free",
    "inplace-on-frozen",
    "unc-operand-mismatch",
    "handle-in-classical-op",
    "classical-control-on-taint",
    "unwritten-measurement",
]
EXPECT = re.compile(r"^; EXPECT: (\S+)$")

failures = []


def fail(msg):
    failures.append(msg)
    print("FAIL:", msg)


def run_verify(opt, plugin, path, reference=False):
    passes = "cq-verify<reference>" if reference else "cq-verify"
    return subprocess.run(
        [opt, f"-load-pass-plugin={plugin}", f"-passes={passes}", "-disable-output", str(path)],
        capture_output=True, text=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", default="/usr/local/opt/llvm@19/bin/opt")
    ap.add_argument("--spec", default=str(ROOT.parent / "CQ_spec"))
    args = ap.parse_args()

    lock = subprocess.run([sys.executable, str(ROOT / "tools" / "spec_lock.py")], cwd=ROOT,
                          capture_output=True, text=True)
    if lock.returncode != 0:
        fail(f"spec.lock: {lock.stdout.strip()} {lock.stderr.strip()}")

    examples = sorted(p for p in Path(args.spec, "examples").iterdir() if p.is_dir())
    refs = []
    for d in examples:
        found = sorted(d.glob("*.lowered.ll"))
        if len(found) != 1:
            fail(f"{d.name}: expected one .lowered.ll, found {len(found)}")
        refs += found

    jobs = [(r, ref) for r in refs for ref in (False, True)]
    with concurrent.futures.ThreadPoolExecutor() as ex:
        results = list(ex.map(lambda j: (j, run_verify(args.opt, args.plugin, *j)), jobs))
    accepted = {False: 0, True: 0}
    for (path, ref), res in results:
        mode = "cq-verify<reference>" if ref else "cq-verify"
        if res.returncode == 0:
            accepted[ref] += 1
        else:
            fail(f"{path.parent.name}: rejected by {mode}:\n{res.stderr.strip()}")
    print(f"corpus: {len(examples)} examples; cq-verify accepted {accepted[False]}/{len(refs)}, "
          f"cq-verify<reference> accepted {accepted[True]}/{len(refs)}")

    mutants = sorted(HERE.glob("mutants/*.ll"))
    covered = set()
    passed = 0
    for m in mutants:
        first = m.read_text().splitlines()[0]
        mt = EXPECT.match(first)
        if not mt:
            fail(f"{m.name}: first line is not '; EXPECT: <accept|check>'")
            continue
        want = mt.group(1)
        res = run_verify(args.opt, args.plugin, m)
        if want == "accept":
            if res.returncode != 0:
                fail(f"{m.name}: expected accept, got:\n{res.stderr.strip()}")
                continue
        else:
            if want not in CHECKS:
                fail(f"{m.name}: unknown check {want}")
                continue
            if res.returncode == 0 or "LLVM ERROR: cq: verify:" not in res.stderr or \
                    not re.search(rf"^  {re.escape(want)}: ", res.stderr, re.M):
                fail(f"{m.name}: expected rejection by {want}, got exit {res.returncode}:\n{res.stderr.strip()}")
                continue
            covered.add(want)
        passed += 1
    print(f"mutants: {passed}/{len(mutants)} as expected")
    for c in CHECKS:
        if c not in covered:
            fail(f"no mutant rejected by {c}")

    if failures:
        print(f"{len(failures)} failure(s)")
        return 1
    print("ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
