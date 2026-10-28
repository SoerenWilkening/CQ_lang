#!/usr/bin/env python3
"""tests/mem-qram (cq-alez): rule 22 memory intrinsics through the real cq-lower plugin.

Structural checks only (the §6 verdicts are cqcheck's). probes/*.ll are synthetic modules. Each
`; CHECK <fn>: <text>` must occur in <fn>'s lowered body (`%{{name}}` matches any local), each
`; CHECK-COUNT <fn>: <text> <n>` exactly n times; the output must pass plain cq-verify. A probe with
`; EXPECT-ERROR: <text>` must instead make cq-lower exit non-zero with <text> on stderr.

Outputs go to build/tests/mem-qram/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "tests" / "mem-qram" / "out"


def function_text(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"(\.cq\.entry)?\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def check_pattern(text: str) -> "re.Pattern":
    rx = re.escape(text.strip())
    rx = re.sub(r"%\\\{\\\{\w+\\\}\\\}", r"%[\\w.]+", rx)
    return re.compile(rx)


def run(a, passes: str, src: Path, dest: Path = None):
    out = ["-S", "-o", str(dest)] if dest else ["-disable-output"]
    return subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", f"-passes={passes}", str(src)] + out,
                          capture_output=True, text=True)


def first_line(r) -> str:
    return (r.stderr.strip().splitlines() or ["?"])[0]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    a = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    failures = 0
    for p in sorted((Path(__file__).parent / "probes").glob("*.ll")):
        dest = OUT / p.name
        src = p.read_text()
        r = run(a, "cq-lower", p, dest)
        reasons = []
        expect = re.search(r"^; EXPECT-ERROR: (.*)$", src, re.M)
        if expect:
            if r.returncode == 0:
                reasons.append("cq-lower succeeded; expected: " + expect.group(1))
            elif expect.group(1) not in r.stderr:
                reasons.append("cq-lower: " + first_line(r))
        elif r.returncode != 0:
            reasons.append("cq-lower: " + first_line(r))
        else:
            module = dest.read_text()
            v = run(a, "cq-verify", dest)
            if v.returncode != 0:
                reasons.append("cq-verify: " + first_line(v))
            for line in src.splitlines():
                m = re.match(r"; CHECK(-COUNT)? (\w+): (.*)$", line)
                if not m:
                    continue
                body = function_text(module, m.group(2))
                if not body:
                    reasons.append(f"{m.group(2)}: no lowered function")
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
    print("FAIL" if failures else "ok", f"({failures} failing)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
