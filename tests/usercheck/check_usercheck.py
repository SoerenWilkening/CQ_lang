#!/usr/bin/env python3
"""tests/usercheck (cq-w1-usercheck): `cqcheck user`, the C-oracle check of any program.

Fails on any of:
  program   a small C program (src/*.c) compiled by cqcc -S is not green under `cqcheck user` with its
            entry (exit 0)
  corpus    a CQ_spec example's reference lowered.ll is not green against its .O1.ll, with the entry
            from drivers.txt and no quantum flags (default 01, 02, 42; --examples NN_name... for more)
  mutant    a wrong lowered module is not rejected (exit 1): built from 01's reference with the Ry's
            angle negated, the add computed before the Ry (only cq_theta substitution sees it), the
            measured rail replaced by its classical input, and an empty body (ret 0)
  error     a missing entry or main(argc, argv) is not an error (exit 2)

Every run goes through the CLI (`python3 -m cqcheck user` from checker/), as cqcc --cq-check runs it.
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
CQCC = ROOT / "driver" / "cqcc"
SRC = HERE / "src"
PROGRAMS = [("classical", "poly"), ("qmain", "main"), ("phase", "phase_if"), ("fromptr", "from_ptr"),
            ("fpq", "fpq")]
DEFAULT_EXAMPLES = ["01_add_classical_const", "02_add_quantum_quantum", "42_measure_one_of_two"]

failures = []


def fail(test, msg):
    failures.append(test)
    print(f"FAIL {test}: {msg}")


def ok(test, msg=""):
    print(f"ok   {test}" + (f": {msg}" if msg else ""))


def user(o1, low, entry):
    r = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(o1), "--lowered", str(low),
                        "--entry", entry], cwd=ROOT / "checker", capture_output=True, text=True)
    return r.returncode, (r.stdout + r.stderr).strip()


def expect(test, status, got):
    code, out = got
    last = out.splitlines()[-1] if out else ""
    if code != status:
        fail(test, f"exit {code}, want {status}:\n{out}")
    else:
        ok(test, last)


def drivers_entry(spec, ex):
    for line in (spec / "_tools" / "drivers.txt").read_text().splitlines():
        if line.startswith(ex + "|"):
            calls = line.split("|")[2].split(";")
            return calls[0].split("(")[0].strip()
    raise SystemExit(f"{ex}: no drivers.txt line")


def mutants(ref_text):
    """name -> a wrong lowered module of 01_add_classical_const (add_classical)."""
    ry = "  call void @cqrt_ry_i32(i32 %4, double %1)"
    add = "  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %2)"
    meas = "  %7 = call i32 @cqrt_measure_i32(i32 %5)"
    for s in (ry, add, meas):
        if s not in ref_text:
            raise SystemExit(f"01's reference changed: {s!r} not found")
    lines = ref_text.splitlines()
    out = {}
    out["negated_angle"] = ref_text.replace(ry, "  %neg = fneg double %1\n  call void @cqrt_ry_i32(i32 %4, double %neg)")
    i_ry = next(i for i, l in enumerate(lines) if l.startswith(ry))
    i_add = next(i for i, l in enumerate(lines) if l.startswith(add))
    swapped = list(lines)
    swapped[i_ry], swapped[i_add] = lines[i_add], lines[i_ry]
    out["add_before_ry"] = "\n".join(swapped) + "\n"
    out["measure_classical_input"] = ref_text.replace(meas, meas + "\n  %bad = add i32 %0, %2").replace(
        "  ret i32 %7", "  ret i32 %bad")
    body = re.search(r"(define i32 @add_classical\([^)]*\)[^{]*\{)(.*?)(\n\})", ref_text, re.S)
    out["empty"] = ref_text[:body.end(1)] + "\n  ret i32 0" + ref_text[body.start(3):]
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--spec", type=Path, default=ROOT.parent / "CQ_spec")
    ap.add_argument("--examples", nargs="*", default=DEFAULT_EXAMPLES)
    a = ap.parse_args()
    spec = a.spec.resolve()
    with tempfile.TemporaryDirectory(prefix="cqu-test-") as t:
        tmp = Path(t)
        for name, entry in PROGRAMS:
            d = tmp / name
            r = subprocess.run([sys.executable, str(CQCC), "-S", str(SRC / f"{name}.c"), "--save-temps", str(d),
                                "-o", str(tmp / f"{name}.ll")], capture_output=True, text=True)
            if r.returncode != 0:
                fail(f"program {name}", f"cqcc exited {r.returncode}: {r.stderr.strip()}")
                continue
            expect(f"program {name} ({entry})", 0, user(d / "linked.ll", d / "lowered.ll", entry))

        for ex in a.examples:
            d = spec / "examples" / ex
            base = ex.split("_", 1)[1]
            expect(f"corpus {ex}", 0, user(d / f"{base}.O1.ll", d / f"{base}.lowered.ll", drivers_entry(spec, ex)))

        d = spec / "examples" / "01_add_classical_const"
        o1 = d / "add_classical_const.O1.ll"
        for name, text in mutants((d / "add_classical_const.lowered.ll").read_text()).items():
            p = tmp / f"mutant_{name}.ll"
            p.write_text(text)
            expect(f"mutant {name}", 1, user(o1, p, "add_classical"))

        expect("error: no such entry", 2, user(o1, d / "add_classical_const.lowered.ll", "nosuch"))
        argv = tmp / "argv"
        (argv / "x").mkdir(parents=True)
        src = argv / "argv.c"
        src.write_text("int main(int argc, char **argv) { int x = argc; cq_theta(&x, 0.5); "
                       "return cq_measure(x + 1); }\n")
        r = subprocess.run([sys.executable, str(CQCC), "-S", str(src), "--save-temps", str(argv / "x"),
                            "-o", str(argv / "argv.ll")], capture_output=True, text=True)
        if r.returncode != 0:
            fail("error: main(argc, argv)", f"cqcc exited {r.returncode}: {r.stderr.strip()}")
        else:
            expect("error: main(argc, argv)", 2, user(argv / "x" / "linked.ll", argv / "x" / "lowered.ll", "main"))

    print(f"{len(failures)} failures" if failures else "all usercheck tests passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
