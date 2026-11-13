#!/usr/bin/env python3
"""cq-p9pty: a restricted self-test prints its final line and exits promptly after its last check.

    python3 tests/mutants/test_selftest_exit.py [--replay]

Runs mutants.selftest(only=[03-drop-free], empty=[01_add_classical_const]) in a child process (2 jobs, its own
temporary CQ_BUILD_DIR; the plugin from $CQ_PLUGIN or the default build) and requires: exit 0 within BOUND seconds;
every outcome line ends with `t=<s>s took=<s>s`; the last line is `selftest: PASS (restricted), wall time <s>s, <s>s
after the last check` with at most TAIL seconds after the last check; the process exits within TAIL seconds of that
line. --replay adds the clone replay checks (about a minute more), which run as the pool's first job.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BOUND = 240.0
TAIL = 5.0
OUTCOME = re.compile(r"^(ok  |FAIL) (\w+)\s.*  t=(\d+\.\d)s took=(\d+\.\d|\?)s?$")
FINAL = re.compile(r"^selftest: (PASS|FAIL) \(restricted\), wall time (\d+\.\d)s, (\d+\.\d)s after the last check$")


def main() -> int:
    replay = "--replay" in sys.argv
    work = Path(tempfile.mkdtemp(prefix="cq-selftest-exit."))
    env = dict(os.environ, CQ_BUILD_DIR=str(work), CQCHECK_JOBS="2")
    if "CQ_PLUGIN" not in env:
        env["CQ_PLUGIN"] = str(ROOT / "build" / "pass" / "libCQLower.so")
    code = ("import sys; from cqcheck import mutants; sys.exit(mutants.selftest(only=['03-drop-free'], "
            f"empty=['01_add_classical_const'], replay={replay}))")
    bad = []
    try:
        t0 = time.monotonic()
        p = subprocess.Popen([sys.executable, "-u", "-c", code], cwd=ROOT / "checker", env=env,
                             stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        lines, t_final = [], None
        for line in p.stdout:
            line = line.rstrip("\n")
            lines.append(line)
            print(line, flush=True)
            if FINAL.match(line):
                t_final = time.monotonic()
        try:
            rc = p.wait(timeout=max(1.0, BOUND - (time.monotonic() - t0)))
        except subprocess.TimeoutExpired:
            p.kill()
            p.wait()
            print(f"FAIL: no exit within {BOUND:.0f} s")
            return 1
        t_exit = time.monotonic()
        if rc != 0:
            bad.append(f"exit status {rc}")
        if t_exit - t0 > BOUND:
            bad.append(f"took {t_exit - t0:.1f} s > {BOUND:.0f} s")
        outs = [m for m in map(OUTCOME.match, lines) if m]
        kinds = sorted(m.group(2) for m in outs)
        want = sorted(["control", "mutant", "empty"] + (["replay"] * 3 if replay else []))
        if kinds != want:
            bad.append(f"outcome lines {kinds}, want {want}")
        f = FINAL.match(lines[-1]) if lines else None
        if not f:
            bad.append(f"last line is not the final line: {lines[-1:]!r}")
        else:
            if f.group(1) != "PASS":
                bad.append("final line says FAIL")
            if float(f.group(3)) > TAIL:
                bad.append(f"{f.group(3)} s after the last check > {TAIL} s")
            if outs and float(f.group(2)) + 0.05 < max(float(m.group(3)) for m in outs):
                bad.append("wall time before the last check's t")
        if t_final is not None and t_exit - t_final > TAIL:
            bad.append(f"exit {t_exit - t_final:.1f} s after the final line > {TAIL} s")
    finally:
        shutil.rmtree(work, ignore_errors=True)
    print("tests/mutants selftest exit:", "PASS" if not bad else f"FAIL {bad}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
