#!/usr/bin/env python3
"""tests/eff-conc (cq-w1-eff-conc): rule 24 probes through the real cq-lower plugin.

For probes/conc.O1.ll and probes/setjmp.O1.ll it checks, and fails on:
  - cq-lower (with its built-in structural verifier) exits 0, and plain cq-verify accepts the output;
  - p_vol_internal drops `volatile` (an unobservable access is the plain one), while
    p_vol_observable keeps both volatile accesses to @obs_counter and p_atomic_classical keeps its
    atomic store and load (the host performs them);
  - every entry is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle).
ERRORS (probes that must make cq-lower exit non-zero with a named message) is empty since cq-lyzw.
p_sj_* (setjmp.O1.ll) are 101's construction (rule 24's one pairing by operand): a longjmp is an escaped
flag the clone returns beside its result, the setjmp join a select on it; no host setjmp/longjmp call is
left. p_sjh_* (setjmp_host.O1.ll): outside the pairing the host calls stay. setjmp_class.O1.ll and the former error probes (setjmp_effect, _nested, _wrapper, _wrapper_p20/p21)
are the class (cq-lyzw: explicit control flow before the final taint, Setjmp.cpp). vol_observable.O1.ll:
an observable volatile store with quantum data is the tape entry volatile_store (rule 24 at f684858). Variants: scalar quantum result, void clone with a pure continuation, classical result, quantum
value on the escaped arm (the != 0 test).
p_vol_local is 32's shape (cq-r4cz): the unobservable volatile slot pair forwards as the plain access;
p_atomic_rmw is 94's (M4): atomicrmw on a slot cell is load + add + store.
The owned example's acceptance is `python3 -m cqcheck run 48_volatile_global --oracle both` (the bead).
Outputs go to build/tests/eff-conc/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBES = Path(__file__).parent / "probes"
ENTRIES = ["p_vol_internal", "p_vol_observable", "p_atomic_classical", "p_vol_local", "p_atomic_rmw"]
ERRORS = {}
MODULES = {"conc.O1.ll": ENTRIES, "setjmp.O1.ll": ["p_sj_scalar", "p_sj_void", "p_sj_classical", "p_sj_qarm"],
           "conc_widen.O1.ll": ["p_join_result", "p_vol_atomic", "p_runtime_routine"],
           "conc_rmw.O1.ll": ["p_rmw_qram"],
           # Rule 5's in-place form over its class, against the C program.
           "inplace_forms.O1.ll": ["f_add_cells", "f_old", "f_new", "f_chain", "f_ends", "f_under", "f_select", "f_bool",
                                   "f_fneg", "f_fwd"],
           # cq-py5f: rule 24 over its class (a join asking for the result, a volatile atomic access).
           
           
           # Rule 24: outside the one pairing, the host calls as they stand; a longjmp under a quantum predicate abort_i1.
           "setjmp_host.O1.ll": ["p_sjh_local", "p_sjh_two", "p_sjh_pred"],
           # cq-lyzw (rule 24 over its class): setjmp/longjmp as explicit control flow; formerly error probes.
           "setjmp_class.O1.ll": ["p_sjc_samefn", "p_sjc_depth3", "p_sjc_value", "p_sjc_retry", "p_sjc_two",
                                  "p_sjc_ptr", "p_sjc_loop"],
           "setjmp_effect.O1.ll": ["setjmp_effect_error"], "setjmp_nested.O1.ll": ["setjmp_nested_error"],
           "setjmp_wrapper.O1.ll": ["setjmp_wrapper_error"], "setjmp_wrapper_p20.O1.ll": ["p20"],
           "setjmp_wrapper_p21.O1.ll": ["p21"],
           # cq-lyzw (rule 24 at f684858): an observable volatile access with quantum data is a host effect.
           "vol_observable.O1.ll": ["vol_quantum_observable", "p_vol_obs_pred"],
           # cq-lyzw (rule 24 with rule 21): an atomic read-modify-write through a pointer rail.
           "conc_rmw_fat.O1.ll": ["p_rmw_fat", "p_cas_fat"],
           # cq-lyzw (rule 24, 106): thread calls collapsed in the IR.
           "conc_threads.O1.ll": ["p_join_qresult"],
           # cq-il07 (rule 24): a volatile read of an internal constant under a quantum predicate (musl exp10l).
           "vol_const_pred.O1.ll": ["e_vol_const_pred"]}
_SJ = (r"cq_template_select_i32", r"call [^\n]*@(setjmp|longjmp)\(")
_NOSJ = (None, r"call [^\n]*@(setjmp|longjmp)\(")
# entry -> (regex that must match its body, regex that must not)
SHAPES = {"p_vol_internal": (None, r"volatile"),
          "p_vol_observable": (r"load volatile i32, ptr @obs_counter[\s\S]*store volatile i32 %\d+, ptr @obs_counter",
                               None),
          "p_atomic_classical": (r"store atomic i32 %\d+, ptr @acell seq_cst[\s\S]*load atomic i32, ptr @acell seq_cst",
                                 None),
          "p_vol_local": (None, r"volatile"),
          "p_atomic_rmw": (r"cqrt_qram_swap_i32", r"atomicrmw"),
          "f_add_cells": (None, None), "f_old": (r"cqrt_qram_swap_i32_hl", None), "f_new": (r"cqrt_qram_swap_i32_hl", None),
          "f_chain": (r"cqrt_qram_swap_i32_hl", None), "f_ends": (r"cqrt_qram_swap_i32_hl", None),
          "f_under": (r"cqrt_qram_swap_i32_hl_controlled", None), "f_select": (r"cq_template_select_i32", None),
          "f_bool": (r"cqrt_qram_swap_i1_hl", None), "f_fneg": (r"cqrt_qram_swap_f64_hl", None), "f_fwd": (None, None),
          "p_join_result": (r"call ptr @job\(", r"@pthread_(create|join)\("),
          "p_rmw_qram": (r"cqrt_qram_swap_i32\(i32 %\d+, i32 %\d+, i32 %\d+\)[\s\S]*cqrt_qram_store_i32\(", r"atomicrmw|cmpxchg"),
          "p_runtime_routine": (r"call ptr %\d+\(ptr", r"@pthread_(create|join)\("),
          "p_vol_atomic": (r"store atomic volatile i32 %\d+, ptr @vcell seq_cst", None),
          "p_sj_scalar": _SJ, "p_sj_void": _SJ, "p_sj_classical": _SJ, "p_sj_qarm": _SJ,
          "vol_quantum_observable": (r"cqrt_tape_effect_controlled\([^\n]*@\.cq\.effect\.volatile_store\)[\s\S]*"
                                     r"cqrt_tape_write_i64_lit\(i32 %\d+, i64 ptrtoint \(ptr @sink to i64\)\)"
                                     r"[\s\S]*cqrt_tape_write_i32\(", r"store volatile"),
          "p_vol_obs_pred": (r"@\.cq\.effect\.volatile_store", r"store volatile"),
          "p_rmw_fat": (None, r"atomicrmw|cmpxchg"), "p_cas_fat": (None, r"atomicrmw|cmpxchg"),
          "p_sjh_local": (r"call i32 @setjmp\(", None), "p_sjh_two": (r"call i32 @setjmp\(ptr[^\n]*@twice", None),
          "p_sjh_pred": (r"call i32 @setjmp\([\s\S]*cqrt_abort_i1\(", r"call [^\n]*@longjmp\("),
          "e_vol_const_pred": (r"call i32 @__cq_q_p_vol_const_pred_\d+\(", None),
          "p_join_qresult": (r"call ptr @__cq_q_qjob_1\(", r"@\\01_pthread_join\(|@pthread_create\(")}
for _e in MODULES["setjmp_class.O1.ll"] + ["setjmp_effect_error", "setjmp_nested_error", "setjmp_wrapper_error",
                                            "p20", "p21"]:
    SHAPES[_e] = _NOSJ


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def lower(a, src: Path, dest: Path):
    return subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(src), "-o",
                           str(dest)], capture_output=True, text=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--entry", action="append", help="check only these entries")
    a = ap.parse_args()
    out = ROOT / "build" / "tests" / "eff-conc" / "out"
    out.mkdir(parents=True, exist_ok=True)
    failures = 0

    for name, text in ERRORS.items():
        r = lower(a, PROBES / name, out / ("err_" + name))
        ok = r.returncode != 0 and text in r.stderr
        failures += not ok
        print(f"{'ok' if ok else 'FAIL':4} {name}" + ("" if ok else "\n     expected: " + text + "\n     got: " +
                                                        (r.stderr.strip() or "exit 0")))

    for mod, entries in MODULES.items():
        probe = PROBES / mod
        lowered = out / mod.replace(".O1.ll", ".lowered.ll")
        r = lower(a, probe, lowered)
        if r.returncode != 0:
            print("FAIL cq-lower " + mod + ": " + r.stderr.strip())
            failures += 1
            continue
        v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                            str(lowered)], capture_output=True, text=True)
        if v.returncode != 0:
            print("FAIL cq-verify " + mod + ": " + v.stderr.strip())
            failures += 1
            continue
        text = lowered.read_text()
        for e in entries:
            if a.entry and e not in a.entry:
                continue
            b = body(text, e)
            why = []
            if not b:
                why.append("no lowered body")
            must, mustnot = SHAPES[e]
            if must and not re.search(must, b):
                why.append("missing: " + must)
            if mustnot and re.search(mustnot, b):
                why.append("present: " + mustnot)
            c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(probe), "--lowered", str(lowered),
                                "--entry", e], capture_output=True, text=True, cwd=ROOT / "checker")
            if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
                why.append("cqcheck user: " + (c.stdout + c.stderr).strip()[-2000:])
            failures += bool(why)
            print(f"{'ok' if not why else 'FAIL':4} {e}" + "".join("\n     " + x for x in why))
    print("FAIL" if failures else "ok", f"({failures} failing)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
