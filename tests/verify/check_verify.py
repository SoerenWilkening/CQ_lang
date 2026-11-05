#!/usr/bin/env python3
"""Acceptance test of cq-w0-verify (the structural verifier, NORTHSTAR principle 4).

1. spec.lock holds (tools/spec_lock.py).
2. Every reference `examples/*/*.lowered.ll` of the pinned corpus (counted from the directory) is
   accepted by `opt -passes='cq-verify<reference>'`. Under plain `cq-verify` (our output) the
   measurement provenance marker (cq-arch V1, `!cq.measure`) is required: a reference with a
   cqrt_measure call is rejected naming unwritten-measurement, one without is accepted, and every
   reference is accepted once the marker is added to its cqrt_measure calls (a copy in a temporary
   directory; nothing is written into CQ_spec).
3. Every module in tests/verify/mutants/ gives its expected verdict in both modes. Its first line
   says `; EXPECT: accept` or `; EXPECT: <check>` for `cq-verify`; an optional second line
   `; EXPECT<reference>: accept|<check>` gives the `cq-verify<reference>` verdict, which otherwise is
   the same. A rejection must exit non-zero with `LLVM ERROR: cq: verify:` and a line naming
   <check>. Every named check has at least one mutant.

Usage: check_verify.py --plugin build/pass/libCQLower.so [--opt OPT] [--spec DIR]
Exit 0 only when every check holds; every failure is printed.
"""
import argparse
import concurrent.futures
import re
import subprocess
import sys
import tempfile
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
EXPECT_REF = re.compile(r"^; EXPECT<reference>: (\S+)$")
MEASURE_CALL = re.compile(r"^(\s*(?:%\S+ = )?(?:tail |musttail |notail )?call [^;]*@cqrt_measure_\w+\([^;]*?)"
                          r"(\s*;.*)?$")

failures = []


def fail(msg):
    failures.append(msg)
    print("FAIL:", msg)


def mark_measures(text):
    """`text` with `!cq.measure !N` (`!N = !{}`) on every cqrt_measure call: the V1 marker."""
    lines = text.splitlines()
    n = max([int(x) for x in re.findall(r"!(\d+)\b", text)], default=-1) + 1
    marked = 0
    for i, l in enumerate(lines):
        m = MEASURE_CALL.match(l)
        if m:
            lines[i] = f"{m.group(1).rstrip()}, !cq.measure !{n}"
            marked += 1
    if marked:
        lines.append(f"!{n} = !{{}}")
    return "\n".join(lines) + "\n", marked


def rejected_by(res, check):
    return res.returncode != 0 and "LLVM ERROR: cq: verify:" in res.stderr and \
        re.search(rf"^  {re.escape(check)}: ", res.stderr, re.M) is not None


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

    tmp = tempfile.TemporaryDirectory(prefix="cq-verify-marked-")
    marked = {}
    for r in refs:
        text, k = mark_measures(r.read_text())
        dst = Path(tmp.name, r.parent.name + ".ll")
        dst.write_text(text)
        marked[r] = (dst, k)
    jobs = [(r, mode) for r in refs for mode in ("reference", "plain", "marked")]

    def run_job(job):
        r, mode = job
        path = marked[r][0] if mode == "marked" else r
        return job, run_verify(args.opt, args.plugin, path, reference=(mode == "reference"))

    with concurrent.futures.ThreadPoolExecutor() as ex:
        results = list(ex.map(run_job, jobs))
    tmp.cleanup()
    good = {"reference": 0, "plain": 0, "marked": 0}
    with_measure = sum(1 for r in refs if marked[r][1])
    for (r, mode), res in results:
        name = r.parent.name
        if mode == "plain" and marked[r][1]:
            if rejected_by(res, "unwritten-measurement"):
                good[mode] += 1
            else:
                fail(f"{name}: cq-verify must reject an unmarked cqrt_measure (unwritten-measurement), "
                     f"got exit {res.returncode}:\n{res.stderr.strip()}")
        elif res.returncode == 0:
            good[mode] += 1
        else:
            what = {"reference": "cq-verify<reference>", "plain": "cq-verify",
                    "marked": "cq-verify (cqrt_measure marked)"}[mode]
            fail(f"{name}: rejected by {what}:\n{res.stderr.strip()}")
    print(f"corpus: {len(examples)} examples, {with_measure} with a cqrt_measure call; "
          f"cq-verify<reference> accepted {good['reference']}/{len(refs)}; "
          f"cq-verify as expected {good['plain']}/{len(refs)} "
          f"(rejects unmarked measurements, accepts the rest); "
          f"cq-verify with the marker added accepted {good['marked']}/{len(refs)}")

    mutants = sorted(HERE.glob("mutants/*.ll"))
    covered = set()
    passed = 0
    for m in mutants:
        lines = m.read_text().splitlines()
        mt = EXPECT.match(lines[0]) if lines else None
        if not mt:
            fail(f"{m.name}: first line is not '; EXPECT: <accept|check>'")
            continue
        mr = EXPECT_REF.match(lines[1]) if len(lines) > 1 else None
        wants = {False: mt.group(1), True: mr.group(1) if mr else mt.group(1)}
        ok = True
        for reference, want in wants.items():
            mode = "cq-verify<reference>" if reference else "cq-verify"
            res = run_verify(args.opt, args.plugin, m, reference=reference)
            if want == "accept":
                if res.returncode != 0:
                    fail(f"{m.name}: expected accept by {mode}, got:\n{res.stderr.strip()}")
                    ok = False
            elif want not in CHECKS:
                fail(f"{m.name}: unknown check {want}")
                ok = False
            elif not rejected_by(res, want):
                fail(f"{m.name}: expected rejection by {mode} naming {want}, got exit "
                     f"{res.returncode}:\n{res.stderr.strip()}")
                ok = False
            elif not reference:
                covered.add(want)
        passed += ok
    print(f"mutants: {passed}/{len(mutants)} as expected in both modes")
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
