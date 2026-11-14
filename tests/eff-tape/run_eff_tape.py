#!/usr/bin/env python3
"""tests/eff-tape (cq-w1-eff-tape): rule 16, host effects and noreturn arms, through the real cq-lower plugin.

Structural checks only; the bead's acceptance is §6 (`python3 -m cqcheck run 45_unreachable_arm
47_printf_tape 138_tape_variants --oracle both`). Two parts, each failing the test:

  - probes/*.ll: synthetic modules. Each `; CHECK <fn>: <text>` must occur in <fn>'s lowered body
    (`%{{name}}` matches any local), each `; CHECK-COUNT <fn>: <text> <n>` exactly n times; the output
    must pass plain cq-verify. A probe with `; EXPECT-ERROR: <text>` must instead make cq-lower exit
    non-zero with <text> on stderr (an internal error, never a lowering).
  - probes/deferred_*.c (owner ruling 2026-11-12, rule 16): C programs reading the result of a deferred C library
    output call, through driver/cqcc -S (so the bundle's result entries are linked by driver/cq_entries.py's
    contract), with `// CHECK` / `// CHECK-COUNT` lines as above; the output must pass plain cq-verify.
  - the owned examples: cq-lower (with its built-in verifier) exits 0, cq-verify accepts the output, no
    CQ.h surface call is left. The normalized textual diff against the reference is printed as a quality
    signal that never fails.

Outputs go to build/tests/eff-tape/out/.
"""
import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "checker"))
from cqcheck import report  # noqa: E402

OWNED = ["45_unreachable_arm", "47_printf_tape", "138_tape_variants"]
SURFACE = re.compile(r"call [^@]*@(cq_theta_\w+|cq_measure_\w+|cq_phi|__cq_invert_\w+)\(")
OUT = ROOT / "build" / "tests" / "eff-tape" / "out"


def function_text(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"(\.cq\.entry)?\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def check_pattern(text: str) -> "re.Pattern":
    rx = re.escape(text.strip())
    rx = re.sub(r"%\\\{\\\{\w+\\\}\\\}", r"%[\\w.]+", rx)
    return re.compile(rx)


def lower(a, src: Path, dest: Path):
    return subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(src),
                           "-o", str(dest)], capture_output=True, text=True)


def verify(a, dest: Path) -> list:
    v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                        str(dest)], capture_output=True, text=True)
    return [] if v.returncode == 0 else ["cq-verify: " + (v.stderr.strip().splitlines() or ["?"])[0]]


def cqcc_lower(a, src: Path, dest: Path):
    env = dict(os.environ, CQ_PLUGIN=str(Path(a.plugin).resolve()), CQ_SPEC_DIR=str(Path(a.spec).resolve()))
    return subprocess.run([sys.executable, str(ROOT / "driver" / "cqcc"), "-S", str(src), "-o", str(dest)],
                          capture_output=True, text=True, env=env)


def probes(a) -> int:
    failures = 0
    here = Path(__file__).parent / "probes"
    for p in sorted(here.glob("*.ll")) + sorted(here.glob("deferred_*.c")):
        if p.name.endswith(".control.ll") or (a.probe and not any(p.name.startswith(x) for x in a.probe)):
            continue   # a control module, lowered by the probe that names it (`; SAME`)
        dest = OUT / ("probe_" + p.stem + ".ll")
        src = p.read_text()
        r = cqcc_lower(a, p, dest) if p.suffix == ".c" else lower(a, p, dest)
        reasons = []
        expect = re.search(r"^; EXPECT-ERROR: (.*)$", src, re.M)
        if expect:
            if r.returncode == 0:
                reasons.append("cq-lower succeeded; expected: " + expect.group(1))
            elif expect.group(1) not in r.stderr:
                reasons.append("cq-lower: " + (r.stderr.strip().splitlines() or ["?"])[0])
        elif r.returncode != 0:
            reasons.append("cq-lower: " + (r.stderr.strip().splitlines() or ["?"])[0])
        else:
            module = dest.read_text()
            reasons += verify(a, dest)
            for line in src.splitlines():
                m = re.match(r"(?:;|//) CHECK(-COUNT)? (\w+): (.*)$", line)
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
            # `; IDENTITY <fn>`: <fn>'s lowered definition is byte-identical to the pass's identity (opt with no passes).
            ident = re.findall(r"^; IDENTITY (\w+)$", src, re.M)
            if ident:
                plain = subprocess.run([a.opt, "-S", str(p)], capture_output=True, text=True).stdout
                for fn in ident:
                    want = function_text(plain, fn)
                    if not want or function_text(module, fn) != want:
                        reasons.append(f"{fn}: not the pass's identity")
            # `; SAME <fn> <other.ll>`: <fn>'s lowered definition is byte-identical to its lowering in the probe
            # <other.ll> (a control module).
            for fn, other in re.findall(r"^; SAME (\w+) (\S+)$", src, re.M):
                odest = OUT / ("probe_" + Path(other).stem + ".same.ll")
                r2 = lower(a, p.parent / other, odest)
                want = function_text(odest.read_text(), fn) if r2.returncode == 0 else ""
                if not want or function_text(module, fn) != want:
                    reasons.append(f"{fn}: lowered otherwise than in {other}")
        failures += bool(reasons)
        print(f"{'ok' if not reasons else 'FAIL':4} probe {p.name}" + "".join("\n     " + x for x in reasons))
    return failures


def examples(a, names) -> int:
    failures = 0
    for name in names:
        d = Path(a.spec) / "examples" / name
        stem = name.split("_", 1)[1]
        o1, ref = d / f"{stem}.O1.ll", d / f"{stem}.lowered.ll"
        dest = OUT / f"{stem}.lowered.ll"
        r = lower(a, o1, dest)
        reasons = []
        if r.returncode != 0:
            reasons.append("cq-lower: " + (r.stderr.strip().splitlines() or ["?"])[0])
        else:
            reasons += verify(a, dest)
            for line in dest.read_text().splitlines():
                if SURFACE.search(line):
                    reasons.append("CQ.h call left: " + line.strip())
        diff = "-"
        if not reasons:
            n, text = report.textual_diff(dest, ref)
            diff = str(n)
            if a.show_diff and n:
                print(text)
        failures += bool(reasons)
        print(f"{'ok' if not reasons else 'FAIL':4} {name:32} diff-lines={diff}" + "".join("\n     " + x for x in reasons))
    return failures


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--spec", required=True)
    ap.add_argument("--show-diff", action="store_true")
    ap.add_argument("--probes-only", action="store_true")
    ap.add_argument("--probe", action="append", help="only the probes whose file name starts with this (repeatable)")
    ap.add_argument("examples", nargs="*")
    a = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    failures = probes(a)
    if not a.probes_only:
        failures += examples(a, a.examples or OWNED)
    print("FAIL" if failures else "ok", f"({failures} failing)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
