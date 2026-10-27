"""The cqcheck CLI of cq-arch (module chk-report). Run as `python3 -m cqcheck` from checker/.

  run <NN_name…|--all> [--ours DIR] [--oracle ref|c|both] [--json OUT]
      One Verdict per example (report.evaluate). Without --ours, our lowering is the example's
      .O1.ll through `opt -passes=cq-lower` at K = 4. Every verdict is stored for `progress`, and
      each normalized diff is written next to it. Exit 0 iff every requested check passed.
  selftest, baseline      chk-selftest (mutants.selftest(), mutants.baseline())
  progress                tests/progress.tsv: rule, witnesses, passing, failing
  user --o1 X --lowered Y --entry FN [--samples N]
                          usercheck (user.main(o1, lowered, entry, samples))

Environment: CQ_SPEC_DIR (default ../CQ_spec), CQ_BUILD_DIR (default build/), CQ_PLUGIN (default
$CQ_BUILD_DIR/pass/libCQLower.so), CQ_LLVM_BIN (default /usr/local/opt/llvm@19/bin).
"""
from __future__ import annotations

import argparse
import concurrent.futures
import importlib
import os
import subprocess
import sys
from pathlib import Path
from typing import Callable, List, Optional

from cqcheck import progress, report
from cqcheck.contracts import Verdict, to_json


def _unimplemented(what: str) -> int:
    print(f"cq: unimplemented: {what}", file=sys.stderr)
    return 1


def _delegate(module: str, owner: str, name: str) -> Optional[Callable]:
    fn = getattr(importlib.import_module(f"cqcheck.{module}"), name, None)
    return fn if callable(fn) else None


def _spec_lock() -> int:
    """CLAUDE.md: spec.lock is checked before any test run; drift exits 1."""
    r = subprocess.run([sys.executable, str(report.ROOT / "tools" / "spec_lock.py")],
                       capture_output=True, text=True)
    if r.returncode != 0:
        sys.stderr.write(r.stdout + r.stderr)
    return r.returncode


def _one(ex: report.Example, ours_dir: Optional[Path], oracle: str) -> Verdict:
    store = report.out_dir()
    diff_out = store / "diffs" / f"{ex.name}.diff"
    if diff_out.exists():
        diff_out.unlink()
    if ours_dir is not None:
        try:
            ours = report.ours_path(ex, ours_dir)
        except FileNotFoundError as e:
            return report.evaluate(ex, None, oracle, lower_error=str(e))
        return report.evaluate(ex, ours, oracle, diff_out=diff_out)
    lowered, err = report.lower(ex, store / "ours" / ex.name / f"{ex.base}.lowered.ll")
    return report.evaluate(ex, lowered, oracle, lower_error=err, diff_out=diff_out)


def cmd_run(a) -> int:
    if a.all == bool(a.examples):
        print("cqcheck run: give example names or --all (not both)", file=sys.stderr)
        return 2
    if _spec_lock() != 0:
        return 1
    try:
        examples = report.all_examples() if a.all else report.resolve_examples(a.examples)
    except (ValueError, RuntimeError) as e:
        print(e, file=sys.stderr)
        return 2
    ours_dir = Path(a.ours).resolve() if a.ours else None
    if ours_dir is not None and not ours_dir.is_dir():
        print(f"cqcheck run: --ours {ours_dir} is not a directory", file=sys.stderr)
        return 2
    jobs = int(os.environ.get("CQCHECK_JOBS", str(os.cpu_count() or 1)))
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, jobs)) as pool:
        verdicts = list(pool.map(lambda e: _one(e, ours_dir, a.oracle), examples))
    for v in verdicts:
        report.save_verdict(v)
    if a.json:
        Path(a.json).write_text("".join(to_json(v) + "\n" for v in verdicts))
    print(report.format_table(verdicts))
    print(f"verdicts: {report.verdict_store()}  diffs: {report.out_dir() / 'diffs'}")
    if len(verdicts) != len(examples):
        print(f"cq: {len(examples)} examples, {len(verdicts)} verdicts", file=sys.stderr)
        return 1
    return 0 if all(report.requested_green(v) for v in verdicts) else 1


def cmd_progress(a) -> int:
    dest, table, problems = progress.write_progress()
    for p in problems:
        print(f"cq: {p}", file=sys.stderr)
    witnessed = {w.strip() for _, ws, _, _ in table for w in ws.split(",") if w.strip()}
    passing = {w.strip() for _, _, ps, _ in table for w in ps.split(",") if w.strip()}
    print(f"{dest}: {len(table)} rows, {len(witnessed)} witness examples, {len(passing)} passing")
    for rule, ws, ps, _ in table:
        n = len([w for w in ws.split(",") if w.strip()])
        k = len([w for w in ps.split(",") if w.strip()])
        print(f"  {k:>3}/{n:<3} {rule}")
    return 1 if problems else 0


def cmd_selftest(a) -> int:
    fn = _delegate("mutants", "chk-selftest", "selftest")
    return fn() if fn else _unimplemented("chk-selftest: mutants.selftest")


def cmd_baseline(a) -> int:
    fn = _delegate("mutants", "chk-selftest", "baseline")
    return fn() if fn else _unimplemented("chk-selftest: mutants.baseline")


def cmd_user(a) -> int:
    fn = _delegate("user", "usercheck", "main")
    return fn(a.o1, a.lowered, a.entry, a.samples) if fn else _unimplemented("usercheck: user.main")


def main(argv: Optional[List[str]] = None) -> int:
    p = argparse.ArgumentParser(prog="cqcheck")
    sub = p.add_subparsers(dest="cmd", required=True)
    run = sub.add_parser("run")
    run.add_argument("examples", nargs="*")
    run.add_argument("--all", action="store_true")
    run.add_argument("--ours")
    run.add_argument("--oracle", choices=["ref", "c", "both"], default="both")
    run.add_argument("--json")
    sub.add_parser("selftest")
    sub.add_parser("baseline")
    sub.add_parser("progress")
    user = sub.add_parser("user")
    user.add_argument("--o1", required=True)
    user.add_argument("--lowered", required=True)
    user.add_argument("--entry", required=True)
    user.add_argument("--samples", type=int)
    a = p.parse_args(argv)
    return {"run": cmd_run, "selftest": cmd_selftest, "baseline": cmd_baseline,
            "progress": cmd_progress, "user": cmd_user}[a.cmd](a)
