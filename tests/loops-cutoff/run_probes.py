#!/usr/bin/env python3
"""tests/loops-cutoff probes of the widened rule-14 constructions (cq-b58q, owner 2026-11-02: no stops).

Usage: run_probes.py --plugin P --opt O probes/NAME.O1.ll [...]. For each probe file it checks, and fails on:
  - cq-lower (with its built-in structural verifier) exits 0, and plain cq-verify accepts the output;
  - no CQ.h surface call is left in an entry;
  - every entry (each external `define` in NAME.c) is §6-equal to its own C program (`python3 -m cqcheck user`,
    the C oracle) within a time limit.
Outputs go to build/tests/loops-cutoff/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SURFACE = re.compile(r"call [^@]*@(cq_theta_\w+|cq_measure_\w+|cq_phi|__cq_invert_\w+)\(")


# probe -> [(entry, mutant, regex over the entry's lowered body, its replacement)]: the mutant must be REJECTED by the
# §6 check against the C program (exit 1). me_site (cq-47f8h, owner 2026-11-07: measurements are identified by call
# site): an extra measurement at a site the C program has no counterpart of, a copy that measures another rail than
# the site's (on a trip no sample reaches), and a wrong value at the site's first trip, which C reaches.
MUTANTS = {
    "me_site": [
        ("f", "extra_site", r"(  ret i32 %[\w.]+\n)", r"  %cq.a = call i32 @cqrt_alloc_i32(i32 7)\n  %cq.mx = call i32 @cqrt_measure_i32(i32 %cq.a), !cq.measure !6\n\1"),
        # a trip-2 copy with other instructions (a clean add of 0, uncomputed) around it: a call site of another shape,
        # on a trip no sample reaches
        ("f", "other_site", r"  (%40 = call i32 @cqrt_measure_i32\(i32 %39\), !cq.measure !6\n)",
         r"  %d0 = call i32 @cq_template_add_i32_hl(i32 %39, i32 0)\n  call void @cq_template_add_i32_hl_unc(i32 %d0, i32 %39, i32 0)\n"
         r"  call void @cqrt_free(i32 %d0)\n  \1"
         r"  %d1 = call i32 @cq_template_add_i32_hl(i32 %39, i32 0)\n  call void @cq_template_add_i32_hl_unc(i32 %d1, i32 %39, i32 0)\n"
         r"  call void @cqrt_free(i32 %d1)\n"),
        # v's bit 3 (b3) set as 16 instead of 8, forward and uncomputation alike: the first trip, which C reaches, measures another v
        ("f", "wrong_value", r"i32 8, i32 0\)", "i32 16, i32 0)"),
    ],
    # me_cbr (cq-v8cn7, cq-1ye9c; CR rules 2, 8, 14): a measurement behind a classical branch runs only where the
    # classical arguments take it; a trip copy is the site only if it measures the site's register.
    "me_cbr": [
        # the last trip copy (trip 3, which no sample reaches) measures a copy of v (the rail trip 0 shifts), not w
        ("h", "other_register", r"(?s)(lshr_i32_hl\(i32 (%[\w.]+), i32 1\).*)(call void @cqrt_copy_i32\(i32 )%[\w.]+"
         r"(, i32 %[\w.]+\)\n  %[\w.]+ = call i32 @cqrt_measure_i32)", r"\1\3\2\4"),
        # every trip copy's measurement moved above its classical br, so it runs also where (c & 1) is 0
        ("h", "hoist_trips", r"(  br i1 %[\w.]+, label %[\w.]+, label %[\w.]+\n\n[\w.]+:[^\n]*\n)"
         r"(  %[\w.]+ = call i32 @cqrt_alloc_i32\(i32 0\)\n  call void @cqrt_copy_i32[^\n]*\n"
         r"  %[\w.]+ = call i32 @cqrt_measure_i32[^\n]*\n)", r"\2\1"),
        # g's measurement (and the w it measures) moved above the classical br on (c & 1)
        ("g", "hoist_branch", r"(  br i1 %[\w.]+, label %[\w.]+, label %[\w.]+\n\n[\w.]+:[^\n]*\n  %[\w.]+ = phi[^\n]*\n"
         r"  ret i32 %[\w.]+\n\n[\w.]+:[^\n]*\n)((?:  [^\n]*\n)*?  %[\w.]+ = call i32 @cqrt_measure_i32[^\n]*\n)",
         r"\2\1"),
    ],
    # rulings Q3 (2026-11-11): the measurement behind the classical branch on an earlier outcome (m & 1), hoisted above
    # that branch, so it collapses y also where m is even and C keeps y coherent: the C run leaves the site by a classical
    # condition (a statically collapsed outcome), a failure.
    "me_outcome": [
        ("meas_behind_outcome", "hoist_outcome",
         r"(?s)(  br i1 %[\w.]+, label %[\w.]+, label %[\w.]+\n.*?\n[\w.]+:[^\n]*\n)"
         r"(  %[\w.]+ = call i32 @cqrt_alloc_i32\(i32 0\)\n  call void @cqrt_copy_i32[^\n]*\n"
         r"  %[\w.]+ = call i32 @cqrt_measure_i32[^\n]*\n)", r"\2\1"),
    ],
    # rulings Q8: the last trip copy measures a select of its own making, select(!a_3, x0, v_4's register): where trip 4 is
    # reached its condition reads 0 and the value is the site's; where it is not (an extra), it reads 1 and the copy measures
    # x0, another register. The old static rule (any three-rail select followed to its third operand) accepted it.
    "me_carried": [
        ("measure_carried", "own_select", r"(?s)  (%38) = call i32 @cqrt_measure_i32\(i32 (%36)\), !cq.measure !6\n(.*?)"
         r"(  call void @cq_template_select_i32_unc\(i32 %37, )",
         r"  %q.one = call i32 @cqrt_alloc_i1(i1 true)\n  %q.n = call i32 @cqrt_alloc_i1(i1 false)\n"
         r"  call void @cqrt_and_i1(i32 %32, i32 %q.one, i32 %q.n)\n  call void @cqrt_and_i1(i32 %q.one, i32 %q.one, i32 %q.n)\n"
         r"  %q.s = call i32 @cq_template_select_i32(i32 %q.n, i32 %5, i32 \2)\n"
         r"  call void @cqrt_and_i1(i32 %q.one, i32 %q.one, i32 %q.n)\n  call void @cqrt_and_i1(i32 %32, i32 %q.one, i32 %q.n)\n"
         r"  call void @cqrt_free(i32 %q.n)\n  call void @cqrt_free(i32 %q.one)\n"
         r"  \1 = call i32 @cqrt_measure_i32(i32 %q.s), !cq.measure !6\n\3"
         # v_4's register, no longer measured, is uncomputed once its last reader (the after-loop select) is undone
         r"  call void @cq_template_select_i32_unc(i32 %36, i32 %22, i32 %6, i32 %26)\n  call void @cqrt_free(i32 %36)\n\4"),
    ],
    # cq-nmzv3 (review R1 t3): the classical br on c dropped, the measurement on every input
    "q3_conjunct": [
        ("mix", "unguarded", r"  br i1 %[\w.]+, label (%[\w.]+), label %[\w.]+\n", r"  br label \1\n"),
        ("mixc", "unguarded_c", r"  br i1 %[\w.]+, label (%[\w.]+), label %[\w.]+\n", r"  br label \1\n"),
    ],
    # owner ruling Q10 (cq-kbygn exit-test part; CR rule 14): the classical br of test 0 on c dropped, so the chain goes on
    # where c is 0 (a_1 = a_0 & q), and trips C never runs change acc and *f
    "exit_conjunct": [
        ("ec_do", "no_test_branch", r"  br i1 %[\w.]+, label (%[\w.]+), label %[\w.]+\n", r"  br label \1\n"),
    ],
    # cq-nmzv3's sibling (review R1 t2): the second call of g, behind `if (c)`, unguarded
    "q3_phantom": [
        ("phantom", "second_unguarded", r"(?s)(  br i1 (%[\w.]+), label %[\w.]+, label %[\w.]+\n.*?)"
         r"  br i1 \2, label (%[\w.]+), label %[\w.]+\n", r"\1  br label \3\n"),
        ("phantom2", "second_unguarded2", r"(  %[\w.]+ = icmp eq i32 %0, 0\n)  br i1 %[\w.]+, label %[\w.]+, label (%[\w.]+)\n",
         r"\1  br label \2\n"),
    ],
}
_ALL = ("wrong_value", "hoist_trips")      # mutants applied at every match, not the first only
NAMED = ("me_cbr", "me_outcome")                        # probes whose lowered module is mutated after opt -passes=instnamer


def mutants(a, probe: Path, mod: str, out: Path) -> int:
    failures = 0
    stem = probe.name.replace(".O1.ll", "")
    if stem in NAMED and MUTANTS.get(stem):
        # a mutant that moves instructions across blocks needs named values (numbered ones must stay in order)
        mod = subprocess.run([a.opt, "-passes=instnamer", "-S", "-"], input=mod, capture_output=True, text=True,
                             check=True).stdout
    for e, name, old, new in MUTANTS.get(stem, []):
        b = body(mod, e)
        if not re.search(old, b):
            print(f"FAIL {probe.name} mutant {name}: {old!r} is not in @{e}")
            failures += 1
            continue
        low = out / probe.name.replace(".O1.ll", f".{name}.ll")
        low.write_text(mod.replace(b, re.sub(old, new, b, count=(0 if name in _ALL else 1)), 1))
        v = subprocess.run([a.opt, "-passes=verify", "-disable-output", str(low)], capture_output=True, text=True)
        if v.returncode != 0:            # a rejection must come from §6, not from a module that does not parse
            print(f"FAIL {probe.name} mutant {name}: not valid IR: " + (v.stderr.strip().splitlines() or ["?"])[0])
            failures += 1
            continue
        c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(probe), "--lowered", str(low),
                            "--entry", e], capture_output=True, text=True, cwd=ROOT / "checker", timeout=a.timeout)
        rejected = c.returncode == 1 and "FAIL" in c.stdout
        print(("ok   " if rejected else "FAIL ") + f"{probe.name} mutant {name}: "
              + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1][:200])
        failures += not rejected
    return failures


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def entries(o1: str):
    return [m.group(1) for m in re.finditer(r"^define (?!internal|private)[^\n]*@(\w+)\(", o1, re.M)
            if "noinline" not in m.group(0)]


def one(a, probe: Path) -> int:
    out = ROOT / "build" / "tests" / "loops-cutoff" / "out"
    out.mkdir(parents=True, exist_ok=True)
    lowered = out / probe.name.replace(".O1.ll", ".lowered.ll")
    r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(probe), "-o",
                        str(lowered)], capture_output=True, text=True)
    if r.returncode != 0:
        print(f"FAIL {probe.name} cq-lower: " + (r.stderr.strip().splitlines() or ["?"])[0])
        return 1
    v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                        str(lowered)], capture_output=True, text=True)
    if v.returncode != 0:
        print(f"FAIL {probe.name} cq-verify: " + (v.stderr.strip().splitlines() or ["?"])[0])
        return 1
    mod = lowered.read_text()
    failures = 0
    for e in (a.entry or entries(probe.read_text())):
        why = []
        b = body(mod, e)
        if not b:
            why.append("no lowered body")
        if SURFACE.search(b):
            why.append("a CQ.h surface call is left")
        for spec in a.measures_in or []:
            fn, n = spec.split("=")
            got = len(re.findall(r"call [^@]*@cqrt_measure_", body(mod, fn)))
            if got != int(n):
                why.append(f"{got} cqrt_measure calls in @{fn}, not {n}")
        for spec in a.br_in or []:
            fn, n = spec.split("=")
            got = len(re.findall(r"^  br i1 ", body(mod, fn), re.M))
            if got < int(n):
                why.append(f"{got} conditional br in @{fn}, fewer than {n}")
        for spec in a.calls_in or []:
            fn, callee, n = spec.split("=")
            got = len(re.findall(r"call [^@\n]*@" + re.escape(callee) + r"\(", body(mod, fn)))
            if got != int(n):
                why.append(f"{got} calls of @{callee} in @{fn}, not {n}")
        if a.measures is not None and len(re.findall(r"call [^@]*@cqrt_measure_", b)) != a.measures:
            why.append(f"{len(re.findall(r'call [^@]*@cqrt_measure_', b))} cqrt_measure calls, not {a.measures}")
        if a.measures is not None and re.search(r"^define [^\n]*_unc\(.*?^}", mod, re.S | re.M) and any(
                "cqrt_measure" in t for t in re.findall(r"^define [^\n]*_unc\(.*?^}", mod, re.S | re.M)):
            why.append("a twin measures")
        try:
            c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(probe), "--lowered",
                                str(lowered), "--entry", e], capture_output=True, text=True, cwd=ROOT / "checker",
                               timeout=a.timeout)
            if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
                why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
        except subprocess.TimeoutExpired:
            why.append("§6 against the C program: timed out")
        print(("FAIL " if why else "ok   ") + probe.name + " " + e + ("" if not why else ": " + "; ".join(why)))
        failures += bool(why)
    return failures + mutants(a, probe, mod, out)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--entry", action="append")
    ap.add_argument("--measures", type=int, help="the cqrt_measure calls each entry must hold; no twin may hold one")
    ap.add_argument("--measures-in", action="append", help="NAME=N: the cqrt_measure calls function NAME must hold")
    ap.add_argument("--timeout", type=int, default=240, help="seconds for one entry's §6 check")
    ap.add_argument("--br-in", action="append", help="NAME=N: function NAME must hold at least N conditional br (cq-jws5r)")
    ap.add_argument("--calls-in", action="append", help="NAME=CALLEE=N: the calls of CALLEE function NAME must hold")
    ap.add_argument("probes", nargs="+")
    a = ap.parse_args()
    fails = sum(one(a, Path(p).resolve()) for p in a.probes)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
