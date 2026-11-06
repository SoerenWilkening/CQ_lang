#!/usr/bin/env python3
"""tests/pred probes (cq-1b92): small C programs through the real cq-lower plugin, each §6-equal to its C program.

Each probes/<name>.c has its committed probes/<name>.O1.ll (clang -O1 with CQ.h, the corpus triple). The
lowered module must pass cq-verify, and each `// USERCHECK <fn>` line names an entry that must pass
`python3 -m cqcheck user` (the reference is the C program: the -O1 IR with cq_theta as the identity).
Outputs go to build/tests/pred/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "tests" / "pred" / "out"


def first(s: str) -> str:
    return (s.strip().splitlines() or ["?"])[-1]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("names", nargs="*")
    a = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    failures = 0
    probes = Path(__file__).parent / "probes"
    # A probe is probes/<name>.c with its clang -O1 output probes/<name>.O1.ll, or a hand-written IR probe
    # probes/<name>.ir.ll (a shape -O1 does not spell from C) with `; USERCHECK <fn>` lines.
    for c in sorted(list(probes.glob("*.c")) + list(probes.glob("*.ir.ll"))):
        name = c.name[:-len(".ir.ll")] if c.name.endswith(".ir.ll") else c.stem
        if a.names and name not in a.names:
            continue
        o1 = c if c.name.endswith(".ir.ll") else c.with_suffix(".O1.ll")
        dest = OUT / (name + ".lowered.ll")
        reasons = []
        r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-cq-k-default=4", "-S",
                            str(o1), "-o", str(dest)], capture_output=True, text=True)
        if r.returncode != 0:
            reasons.append("cq-lower: " + first(r.stderr))
        else:
            v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                                str(dest)], capture_output=True, text=True)
            if v.returncode != 0:
                reasons.append("cq-verify: " + first(v.stderr))
            for fn in re.findall(r"^(?://|;) USERCHECK (\w+)$", c.read_text(), re.M):
                u = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(o1), "--lowered", str(dest),
                                    "--entry", fn], capture_output=True, text=True, cwd=ROOT / "checker")
                if u.returncode != 0 or "PASS" not in u.stdout + u.stderr:
                    reasons.append(f"{fn}: §6 against the C program: " + first(u.stdout + u.stderr))
        failures += bool(reasons)
        print(f"{'ok' if not reasons else 'FAIL':4} probe {c.name}" + "".join("\n     " + x for x in reasons))
    print("FAIL" if failures else "ok", f"({failures} failing)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
