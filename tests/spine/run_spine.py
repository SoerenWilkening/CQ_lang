#!/usr/bin/env python3
"""tests/spine (cq-w0-construct): the spine's owned examples and probes through the real plugin.

Fatal probes (probes/fatal/) must stop cq-lower with their `; FATAL:` text. Structural checks only; the bead's acceptance is §6 (`python3 -m cqcheck run ... --oracle both`).
Per example it checks, and fails on:

  - cq-lower (with its built-in structural verifier) exits 0 and writes a module;
  - plain cq-verify of the REAL plugin accepts that module;
  - no CQ.h surface call (cq_theta_*, cq_measure_*, cq_phi, __cq_invert_*) is left;
  - every cqrt_measure call carries !cq.measure (V1).

It prints the normalized textual diff count against the reference as a quality signal that never
fails (CLAUDE.md "Reports"). Outputs go to build/tests/spine/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "checker"))
from cqcheck import report  # noqa: E402

OWNED = [
    "01_add_classical_const", "02_add_quantum_quantum", "10_int_ops", "11_int_divrem", "12_int_widths",
    "13_fp_arith", "14_fmuladd", "16_fp_intrinsics", "17_casts", "38_second_rotation", "40_computed_angle",
    "42_measure_one_of_two", "46_mixed_widths", "156_qq_width_matrix", "157_uitofp_quantum_shift64",
    "162_quantum_return_entry", "193_narrow_quantum_return",
]

SURFACE = re.compile(r"call [^@]*@(cq_theta_\w+|cq_measure_\w+|cq_phi|__cq_invert_\w+)\(")
MEASURE = re.compile(r"call [^@]*@cqrt_measure_\w+\(.*")


def function_text(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def check_pattern(text: str) -> "re.Pattern":
    rx = re.escape(text.strip())
    rx = re.sub(r"%\\\{\\\{\w+\\\}\\\}", r"%[\\w.]+", rx)
    return re.compile(rx)


def probes(a) -> int:
    """Synthetic modules in probes/: cq-lower and plain cq-verify accept each; each `; CHECK <fn>: <text>` must occur in <fn>'s lowered body
    (`%{{name}}` matches any local), each `; CHECK-COUNT <fn>: <text> <n>` exactly n times, each `; USERCHECK <fn>`
    §6-equal to its C program."""
    failures = 0
    out = ROOT / "build" / "tests" / "spine" / "out"
    for p in sorted((Path(__file__).parent / "probes").glob("*.ll")):
        dest = out / ("probe_" + p.name)
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
                if m.group(1):
                    text, n = m.group(3).rsplit(" ", 1)
                    got = len(check_pattern(text).findall(body))
                    if got != int(n):
                        reasons.append(f"{m.group(2)}: '{text}' occurs {got} times, expected {n}")
                elif not check_pattern(m.group(3)).search(body):
                    reasons.append(f"{m.group(2)}: missing '{m.group(3)}'")
            # `; USERCHECK <fn>` (cq-5ajv, as tests/mem-slots): <fn> must also be §6-equal to its own C
            # program (the probe's -O1 IR with cq_theta as the identity: `python3 -m cqcheck user`).
            for fn in re.findall(r"^; USERCHECK (\w+)$", p.read_text(), re.M):
                c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(p), "--lowered", str(dest),
                                    "--entry", fn], capture_output=True, text=True, cwd=ROOT / "checker")
                if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
                    reasons.append(f"{fn}: §6 against the C program: " +
                                   ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
        failures += bool(reasons)
        print(f"{'ok' if not reasons else 'FAIL':4} probe {p.name}" + "".join("\n     " + x for x in reasons))
    # probes/fatal/: each must stop cq-lower (non-zero exit, nothing written) with the text of its
    # `; FATAL: <text>` line on stderr (an internal error, never a decline: CLAUDE.md).
    for p in sorted((Path(__file__).parent / "probes" / "fatal").glob("*.ll")):
        want = [m.group(1) for m in re.finditer(r"^; FATAL: (.*)$", p.read_text(), re.M)]
        dest = out / ("fatal_" + p.name)
        dest.unlink(missing_ok=True)
        r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(p),
                            "-o", str(dest)], capture_output=True, text=True)
        reasons = []
        if len(want) != 1:
            reasons.append("expected exactly one '; FATAL:' line")
        elif r.returncode == 0:
            reasons.append("cq-lower exited 0")
        elif want[0] not in r.stderr:
            reasons.append("stderr lacks '" + want[0] + "': " + (r.stderr.strip().splitlines() or ["?"])[0])
        failures += bool(reasons)
        print(f"{'ok' if not reasons else 'FAIL':4} fatal {p.name}" + "".join("\n     " + x for x in reasons))
    return failures


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--spec", required=True)
    ap.add_argument("--show-diff", action="store_true")
    ap.add_argument("examples", nargs="*")
    a = ap.parse_args()
    spec = Path(a.spec)
    out = ROOT / "build" / "tests" / "spine" / "out"
    out.mkdir(parents=True, exist_ok=True)
    failures = 0
    for name in a.examples or OWNED:
        d = spec / "examples" / name
        stem = name.split("_", 1)[1]
        o1, ref = d / f"{stem}.O1.ll", d / f"{stem}.lowered.ll"
        dest = out / f"{stem}.lowered.ll"
        r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(o1),
                            "-o", str(dest)], capture_output=True, text=True)
        reasons = []
        if r.returncode != 0:
            reasons.append("cq-lower: " + (r.stderr.strip().splitlines() or ["?"])[0])
        else:
            v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                                str(dest)], capture_output=True, text=True)
            if v.returncode != 0:
                reasons.append("cq-verify: " + (v.stderr.strip().splitlines() or ["?"])[0])
            text = dest.read_text()
            for line in text.splitlines():
                if SURFACE.search(line):
                    reasons.append("CQ.h call left: " + line.strip())
                if MEASURE.search(line) and "!cq.measure" not in line:
                    reasons.append("cqrt_measure without !cq.measure: " + line.strip())
        diff = "-"
        if not reasons:
            n, text = report.textual_diff(dest, ref)
            diff = str(n)
            if a.show_diff and n:
                print(text)
        status = "ok" if not reasons else "FAIL"
        failures += bool(reasons)
        print(f"{status:4} {name:32} diff-lines={diff}" + ("".join("\n     " + x for x in reasons)))
    if not a.examples:
        failures += probes(a)
    total = len(a.examples or OWNED)
    print(f"{total - failures}/{total} ok")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
