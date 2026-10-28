#!/usr/bin/env python3
"""tests/rot-cry (cq-w1-rot-cry): rule 10 probes through the real cq-lower plugin.

Structural checks only; the bead's acceptance is §6 (`python3 -m cqcheck run <owned> --oracle both`).
Per probe module in probes/: cq-lower (with its built-in structural verifier) exits 0, plain cq-verify
accepts the output, and each `; CHECK <fn>: <text>` occurs in <fn>'s lowered body (`%{{name}}`
matches any local), each `; CHECK-COUNT <fn>: <text> <n>` exactly n times. Outputs go to
build/tests/rot-cry/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def function_text(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def check_pattern(text: str) -> "re.Pattern":
    rx = re.escape(text.strip())
    rx = re.sub(r"%\\\{\\\{\w+\\\}\\\}", r"%[\\w.]+", rx)
    return re.compile(rx)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    a = ap.parse_args()
    out = ROOT / "build" / "tests" / "rot-cry" / "out"
    out.mkdir(parents=True, exist_ok=True)
    probes = sorted((Path(__file__).parent / "probes").glob("*.ll"))
    failures = 0
    for p in probes:
        dest = out / p.name
        r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(p),
                            "-o", str(dest)], capture_output=True, text=True)
        reasons = []
        if r.returncode != 0:
            reasons.append("cq-lower: " + (r.stderr.strip().splitlines() or ["?"])[0])
        else:
            v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                                str(dest)], capture_output=True, text=True)
            if v.returncode != 0:
                reasons.append("cq-verify: " + (v.stderr.strip().splitlines() or ["?"])[0])
            module = dest.read_text()
            for line in p.read_text().splitlines():
                m = re.match(r"; CHECK(-COUNT)? (\w+): (.*)$", line)
                if not m:
                    continue
                body = function_text(module, m.group(2))
                if not body:
                    reasons.append(f"{m.group(2)}: no such function in the output")
                    continue
                if m.group(1):
                    text, n = m.group(3).rsplit(" ", 1)
                    got = len(check_pattern(text).findall(body))
                    if got != int(n):
                        reasons.append(f"{m.group(2)}: '{text}' occurs {got} times, expected {n}")
                elif not check_pattern(m.group(3)).search(body):
                    reasons.append(f"{m.group(2)}: missing '{m.group(3)}'")
        failures += bool(reasons)
        print(f"{'ok' if not reasons else 'FAIL':4} probe {p.name}" + "".join("\n     " + x for x in reasons))
    print(f"{len(probes) - failures}/{len(probes)} ok")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
