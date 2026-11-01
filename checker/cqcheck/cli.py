"""The cqcheck CLI of cq-arch (module chk-report). Run as `python3 -m cqcheck` from checker/.

  run <NN_name…|--all> [--ours DIR] [--oracle ref|c|both] [--json OUT] [--full] [-j N] [--cost-budget N]
      One Verdict per example (report.evaluate). Without --ours, our lowering is the example's
      .O1.ll through `opt -passes=cq-lower` at K = 4. Every verdict is stored for `progress`, and
      each normalized diff is written next to it. Exit 0 iff every requested check passed.
      Quick by default (sampling.quick_mode: small random sets and search budget, no textual
      diff); --full for the default-mode samples and the diff. -j N examples at a time.
  selftest, baseline      chk-selftest (mutants.selftest(), mutants.baseline())
  progress                tests/progress.tsv: rule, witnesses, passing, failing
  user --o1 X --lowered Y --entry FN [--samples N]
                          usercheck (user.main(o1, lowered, entry, samples))

Launcher (cq-8m6v): <build>/cqcheck-tools/cqcheck <args> is `python3 -m cqcheck <args>` without the pyenv
shim's start and without site-packages (checker/native/cqcheck_launch.c; built by the cqcheck_tools
target). Run it through heavy.sh like any checker run: it is an ordinary process, no daemon.

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
    """CLAUDE.md: spec.lock is checked before any test run; drift exits 1 (speclock: in this process,
    stamped, cq-8m6v)."""
    from cqcheck import speclock
    return speclock.check()


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


def stores_progress(ours_dir: Optional[Path], oracle: str) -> bool:
    """Only our pass, both oracles, the pinned CQ_spec and the pinned toolchain feed progress
    (cq-8dr6; cq-lum1: a non-default CQ_LLVM_BIN lowers and runs with another LLVM), at the default
    cost budget."""
    # cq-g8md: only at the default cost budget (a lower one would turn targets uncovered, CR §6)
    budget = os.environ.get("CQ_COST_BUDGET")
    if budget and int(budget, 0) != 1 << 20:
        return False
    return (ours_dir is None and oracle == "both" and "CQ_PLUGIN" not in os.environ
            and report.spec_dir() == (report.ROOT.parent / "CQ_spec").resolve()
            and all(p.resolve() == report.DEFAULT_LLVM_BIN.resolve()
                    for p in (report.LLVM_BIN, Path(os.environ.get("CQ_LLVM_BIN", str(report.DEFAULT_LLVM_BIN))))))


def _run_examples(a, examples, ours_dir) -> List[Verdict]:
    if not a.full:
        os.environ["CQ_QUICK"] = "1"          # sampling.quick_mode and report: fast development run
    # a.jobs examples at a time, each with one runner per side (run.default_jobs, oracle PARTS = 1,
    # the sampler's pool): never a pool inside a pool. Each verdict prints and is stored as it lands.
    total = max(1, int(os.environ.get("CQCHECK_JOBS", "1") or "1"))
    jobs = max(1, a.jobs or total)
    # cq-8m6v: what $CQCHECK_JOBS leaves to each example in flight goes to its runners (evaluator and
    # C-oracle parts): one example at CQCHECK_JOBS=4 runs its batches in up to 4 parts
    inner = max(1, total // min(jobs, max(1, len(examples))))
    os.environ["CQCHECK_JOBS"] = str(inner)
    from cqcheck import oracle as _oracle, run as _run
    _run.default_jobs = lambda: inner
    _oracle.PARTS = inner
    by_name = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
        futs = {pool.submit(_one, e, ours_dir, a.oracle): e for e in examples}
        for f in concurrent.futures.as_completed(futs):
            v = f.result()
            if stores_progress(ours_dir, a.oracle):
                report.save_verdict(v)
            by_name[v.example] = v
            ok = report.requested_green(v)
            unc = report.uncovered(v) if ok else []
            # cq-g8md: green under the gate (no comparison failed) with its uncovered targets listed
            print(f"{('ok* ' if unc else 'ok  ') if ok else 'FAIL'} {v.example}  s6={v.s6} c={v.c_oracle} "
                  f"verifier={v.verifier}" + (f"  {len(unc)} uncovered target(s)" if unc else "")
                  + ("" if ok or not v.reasons else f"  {v.reasons[0][:200]}"), flush=True)
            for u in unc:
                print(f"     {u}", flush=True)
    return [by_name[e.name] for e in examples if e.name in by_name]


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
    saved = {k: os.environ.get(k) for k in ("CQ_QUICK", "CQCHECK_JOBS", "CQ_COST_BUDGET")}
    if a.cost_budget is not None:
        if a.cost_budget < 1:
            print("cqcheck run: --cost-budget must be positive", file=sys.stderr)
            return 2
        os.environ["CQ_COST_BUDGET"] = str(a.cost_budget)
    from cqcheck import run as _run
    saved_jobs = _run.default_jobs
    from cqcheck import oracle as _oracle
    saved_parts = _oracle.PARTS
    try:
        verdicts = _run_examples(a, examples, ours_dir)
    finally:
        for k, v in saved.items():
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v
        _run.default_jobs = saved_jobs
        _oracle.PARTS = saved_parts
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
    run.add_argument("--full", action="store_true",
                     help="default-mode samples and the textual diff (the gate); without it a quick run")
    run.add_argument("-j", "--jobs", type=int, default=0, help="examples at a time (default $CQCHECK_JOBS or 1)")
    run.add_argument("--cost-budget", type=lambda x: int(x, 0), default=None,
                     help="loop-header executions per sample on the C oracle (default 2^20, owner ruling "
                          "2026-11-01, cq-g8md); a trip target reached only past it is reported uncovered")
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
