#!/usr/bin/env python3
"""cq-025xt (owner ruling 2026-11-13; CR rule 16 Results, §6): the reference of a C library output call by rule 16's class.

  pcp.c         the bead's reproducer: no cq_* call, the pass's identity; printf("%p%n", NULL, &n) is the host's own
                (macOS "0x0", n 3, r 3), never musl's count (1): PASS (it was FAIL on every sample).
  puts_host.c   no cq_* call: puts is the host's (the checker's stand-in on both sides, rulings Q8): PASS.
  puts_entry.c  a lowered module, puts after an effect entry under a quantum predicate: an effect entry, musl's 0: PASS.

The oracle-level values (musl's count for an entry, the host's in an unchanged module) are tests/chk-oracle
OutputValues. Rule 16 allows no module with both classes on the driver's paths: an externally visible function is
"called after an event" whenever the module contains one, and its table clone contains every call it makes.

    CQ_BUILD_DIR=<build> python3 tests/eff-tape/host_results/run_host_results.py
"""
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
CASES = [("pcp.c", "pcp"), ("puts_host.c", "puts_host"), ("puts_entry.c", "puts_entry")]


def main() -> int:
    fails = []
    with tempfile.TemporaryDirectory(prefix="cq-hostres-") as t:
        for src, entry in CASES:
            d = Path(t) / entry
            d.mkdir()
            r = subprocess.run([sys.executable, str(ROOT / "driver" / "cqcc"), "-S", str(HERE / src), "--save-temps",
                                str(d), "-o", str(d / "out.ll")], capture_output=True, text=True)
            if r.returncode:
                fails.append(f"{src}: cqcc exit {r.returncode}: {r.stderr[-1500:]}")
                continue
            r = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(d / "linked.ll"), "--lowered",
                                str(d / "lowered.ll"), "--entry", entry, "--samples", "16", "--light"],
                               cwd=ROOT / "checker", capture_output=True, text=True)
            if r.returncode != 0 or "cqcheck user: PASS:" not in r.stdout + r.stderr:
                fails.append(f"{src}:{entry}: exit {r.returncode}, want PASS:\n{r.stdout[-1500:]}{r.stderr[-500:]}")
            else:
                print(f"ok {src}:{entry}: PASS")
    for f in fails:
        print("FAIL", f)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
