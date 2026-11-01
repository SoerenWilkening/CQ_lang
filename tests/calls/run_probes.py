#!/usr/bin/env python3
"""tests/calls probes (cq-w2a-calls review fixes): small programs through the real cq-lower plugin.

Each case names a probe (probes/<name>.O1.ll, clang -O1 of probes/<name>.c), its entry, extra opt flags and
what it must give:
  - "pass": cq-lower exits 0, plain cq-verify accepts the output, every regex in `match` occurs in the
    lowered module, and the entry is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle);
  - "lower": as "pass" without the §6 run (the case says why the checker cannot run it);
  - "fatal: <text>": cq-lower stops with that error (an unimplemented shape, never a silent output).
Outputs go to build/tests/calls/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBES = Path(__file__).parent / "probes"

QRAM_LOOP = "fatal: cq: unimplemented: loops-classical: a store into QRAM memory in a classically bounded loop"
TWIN_STORE = "_unc would replay a store to memory outside the clone's frame"
TWIN_BARRIER = ("cq: unimplemented: uncompute: a write that may change an object a clone call's pointer argument "
                "points to")
TWIN_ALIAS = ("cq: unimplemented: uncompute: a clone call whose twin may read a caller cell the clone writes by "
              "another route than the writing pointer")
# (probe, entry, opt flags, expectation, regexes the lowered module must contain)
CASES = [
    # cq-oocu (107's union_slot): a slot record's pointer-kind cell (tag, idx) a clone reads as an integer and
    # writes back (ptrtoint at the load, inttoptr at the store keeping the tag); int and long cells, add and sub.
    ("ptr_cell", "pc_two", [], "pass", [r"call fastcc void @__cq_q_step_0011\(ptr %\d+, i32 \d+, i32 0, i32 1\)",
                                        r"call void @__cq_q_step_0011_unc\("]),
    ("ptr_cell", "pc_long", [], "pass", [r"cq_template_lshr_i64_hl\(i32 %\d+, i64 3\)"]),
    ("ptr_cell_interior", "pc_interior", [], "fatal: cq: unimplemented: mem-slots: a pointer stored into a "
     "pointer-kind slot cell that is not a select over objects' starts", []),
    ("ptr_cell_observed", "pc_observed", [], "fatal: cq: unimplemented: mem-slots: a clone's integer read from a "
     "caller's pointer-kind cell observed as a number", []),
    # cq-pgen (109's put, T5 cellForward): a clone storing a formal's handle unchanged into a caller cell: no
    # copy-out, no twin; once and in a classically bounded loop over a VLA.
    ("forward_cell", "fwd_once", [], "pass", [r"define internal fastcc void @__cq_q_put_01\(ptr %0, i32 %1\) \{\n  store i32 %1, ptr %0"]),
    ("forward_cell", "fwd_loop", [], "pass", [r"define internal fastcc void @__cq_q_put2_01\(ptr %0, i32 %1\) \{\n  store i32 %1, ptr %0"]),
    # cq-r8-d (190's escape, CR rule 27 Pointers): a declared clone handed a pointer into a local slot object:
    # (object, tag, idx, cell count), a snapshot, the twin after the last cell read (dp_reg called the original
    # ext_sink with the handle cells before); two pointers and a classical cell are unimplemented.
    ("declared_ptr", "dp_esc", [], "pass", [r"call void @__cq_q_ext_sink_0010\(ptr %\d+, i32 1, i32 0, i32 2, i32 2, i32 4\)",
                                            r"call i32 @cqrt_measure_i32\(i32 %\d+\).*\n  call void @__cq_q_ext_sink_0010_unc\(ptr %\d+, i32 1, i32 0, i32 2, i32 2, i32 4, ptr %\d+\)"]),
    ("declared_ptr", "dp_reg", [], "pass", [r"call void @__cq_q_ext_sink_0010\(ptr %\d+, i32 1, i32 0, i32 1, i32 1, i32 4\)"]),
    ("declared_ptr", "dp_after", [], "pass", [r"call i32 @cq_template_add_i32\(i32 %\d+, i32 %\d+\)\n  call void @__cq_q_ext_sink_0010_unc"]),
    ("declared_ptr2", "dp_two", [], "fatal: cq: unimplemented: calls: a declared clone with two pointer arguments", []),
    ("declared_ptr3", "dp_classical_cell", [], "fatal: cq: unimplemented: calls: a declared clone's pointer into a slot "
     "object a cell of which holds no handle at the call", []),
    # cq-prvy (95): a variadic clone per call-site arity; its save area holds the actuals' handles.
    ("varargs", "vprobe", [], "pass", [r"call i32 @__cq_q_pick_001\(i32 poison, i32 %\d+, i32 %\d+\)"]),
    # cq-5xde: a quantum-depth recursion is cut only under a proved depth bound B <= the cut level.
    ("depth_le0", "r4", [], "pass", []),
    # cq-xhv4 (169): a twin computes no rule 14 kept overflow predicate a_K of its own (the forward keeps one).
    ("twin_kept_overflow", "tk", [], "pass", []),
    # cq-kkgh: a clone's in-place rotation of a by-value formal is a non-diagonal gate on the caller's rail.
    ("byvalue_rotated", "p5", [], "pass", []),
    # cq-budv (117): an in-place rotation at a variable offset (T3 kAnyCell) of a runtime-length slot array.
    ("rotated_any", "ra", [], "pass", [r"call fastcc void @__cq_q_rot_all_100\("]),
    ("depth_lt0", "r1", [], "fatal: cq: unimplemented: loops-cutoff: a quantum-depth recursion cut at K with B > K "
     "or no bound", []),
    ("depth_lt_m1", "r15", [], "fatal: cq: unimplemented: loops-cutoff: a quantum-depth recursion cut at K with "
     "B > K or no bound", []),
    ("depth_other_formal", "r14", [], "fatal: cq: unimplemented: calls: a quantum-depth recursion cut at level 1 "
     "below its proved depth bound 3", []),
    ("depth_classical_formal", "r13", [], "fatal: cq: unimplemented: calls: a quantum-depth recursion cut at "
     "level 1 below its proved depth bound 3", []),
    # cq-09xh: a byval formal stays byval; the caller passes a snapshot, which the twin gets too.
    ("byval", "b3", [], "pass", [r"call i32 @__cq_q_f_\w+\(ptr byval\(%struct\.B\)"]),
    ("byval", "b_twin", [], "pass", [r"call void @__cq_q_f_\w+_unc\(i32 %\w+, ptr %byval\.snap"]),
    # cq-h8vd: a declared clone of an LLVM math intrinsic takes the libm name's K (CQ_K, the per-function flag).
    # libm_k is "lower" (no §6 run): cqcheck user does not read llvm.used, which CQ_K emits (cq-tntm).
    ("libm_k", "k1", [], "lower", [r"call i32 @__cq_q_sin_1\(i32 %\w+, i32 53\)",
                                   r"call i32 @__cq_q_atan2_10\(i32 %\w+, double %\w+, i32 77\)"]),
    ("libm_flag", "k4", ["-cq-k=expf=9"], "pass", [r"call i32 @__cq_q_expf_1\(i32 %\w+, i32 9\)"]),
    # cq-dxii: a classical loop writing into a QRAM or slot object is not pure classical (it reaches loops-classical;
    # the QRAM probes stop there until loops-classical builds rule 14 over QRAM stores, then they become "pass").
    ("qram_loop_stack", "t8", [], QRAM_LOOP, []),
    ("qram_loop_columns", "t2", [], QRAM_LOOP, []),
    ("qram_loop_stack8", "p9", [], QRAM_LOOP, []),
    ("qram_loop_heap", "p10", [], QRAM_LOOP, []),
    ("qram_loop_heap_branch", "p6", [], QRAM_LOOP, []),
    ("slot_loop", "s1", [], "pass", [r"call void @cqrt_push"]),
    # cq-99z6: the twin's memory footprint (everything the clone may read or write, by its body): a replayed
    # store after a read of memory it may overwrite, a write into the footprint between the call and the twin
    # (a call reaching an escaped local or a global, a store into an object reached through a loaded pointer).
    ("twin_store_after_load", "ent_a1", [], "fatal: " + TWIN_STORE, []),
    ("twin_store_after_alias_load", "ent_a2", [], "fatal: " + TWIN_STORE, []),
    ("twin_escaped_write", "ent_b1", [], "fatal: " + TWIN_BARRIER, []),
    ("twin_global_write", "ent_b2", [], "fatal: " + TWIN_BARRIER, []),
    ("twin_loaded_pointer", "ent_b4", [], "fatal: " + TWIN_BARRIER, []),
    # cq-aqk1: a caller cell the clone writes, read by the twin through another route (aliasing pointer
    # arguments); distinct cells lower and are §6-equal.
    ("twin_alias_cell", "ent_c1", [], "fatal: " + TWIN_ALIAS, []),
    ("twin_alias_cell_rmw", "te3", [], "fatal: " + TWIN_ALIAS, []),
    ("twin_distinct_cells", "ent_c2", [], "pass", []),
    # cq-88vg: a measured classical switch phi over a clone's slot outs (52's shape): edge copies; the twin of a
    # clone with a classical result and cell copy-outs.
    ("switch_slot_arms", "sw", [], "pass", [r"call void @__cq_q_put2_\w+_unc\("]),
]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--case", action="append", help="run only these probes")
    a = ap.parse_args()
    out = ROOT / "build" / "tests" / "calls" / "out"
    out.mkdir(parents=True, exist_ok=True)
    failures = 0
    for probe, entry, flags, expect, match in CASES:
        if a.case and probe not in a.case:
            continue
        src = PROBES / (probe + ".O1.ll")
        lowered = out / (probe + "." + entry + ".lowered.ll")
        r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", *flags, "-S", str(src),
                            "-o", str(lowered)], capture_output=True, text=True)
        why = []
        if expect.startswith("fatal: "):
            if r.returncode == 0:
                why.append("cq-lower succeeded, expected " + expect)
            elif expect[len("fatal: "):] not in r.stderr:
                why.append("cq-lower: " + r.stderr.strip()[:400])
        elif r.returncode != 0:
            why.append("cq-lower: " + r.stderr.strip()[:400])
        else:
            v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                                str(lowered)], capture_output=True, text=True)
            if v.returncode != 0:
                why.append("cq-verify: " + v.stderr.strip()[:400])
            text = lowered.read_text()
            for m in match:
                if not re.search(m, text):
                    why.append("no match for " + m)
            c = subprocess.CompletedProcess([], 0, "PASS", "") if expect == "lower" else subprocess.run(
                [sys.executable, "-m", "cqcheck", "user", "--o1", str(src), "--lowered", str(lowered),
                 "--entry", entry], capture_output=True, text=True, cwd=ROOT / "checker")
            if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
                why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
        print(("FAIL " if why else "ok   ") + probe + ":" + entry + ("" if not why else ": " + "; ".join(why)))
        failures += bool(why)
    print("FAILED" if failures else "ok")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
