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
# §6 samples per probe where the full set takes minutes (cqcheck user --samples): the musl bodies.
SAMPLES = {"trip_ctl": 64, "clone_cell_seq": 64, "fenv_cells": 64, "fenv_ignore_loop": 64, "store_past_object": 64, "fenv_escape": 64, "fenv_indirect": 64, "libm_musl_acosh": 16, "libm_musl_coshf": 16, "libm_musl_lrint": 16, "libm_musl_llrintl": 16, "twin_strict": 64, "libm_musl_floorfn": 32, "libm_musl_atan": 16, "libm_musl_exp": 16, "libm_musl_log": 16}
# (probe, entry, opt flags, expectation, regexes the lowered module must contain)
CASES = [
    # cq-57ju (rulings 2026-11-02): plain clang -O1 callers of musl b1efda5 bodies (no -fno-builtin, no -frounding-math).
    # llvm.<f> binds to the injected body (cq-odjk); fpexcept.ignore ops are plain templates and the clone takes no
    # mode and no flags (rule 23, cq-75n4); __math_oflow / __math_divzero under a quantum predicate stay host calls,
    # unguarded (rule 19, cq-fl4n). llvm.floor stays the floor template; floorfn calls musl's body (-fno-builtin).
    ("libm_musl_floor", "f_floor", [], "pass", [r"call i32 @cq_template_floor_f64\(i32 %\d+\)"]),
    ("libm_musl_floorfn", "f_floorfn", [], "pass", [r"call i32 @__cq_q_floor_1\(i32 %\d+\)\n",
                                                    r"define internal i32 @__cq_q_floor_1\(i32 %0\) \{"]),
    ("libm_musl_atan", "f_atan", [], "pass", [r"call i32 @__cq_q_atan_1\(i32 %\d+\)\n"]),
    ("libm_musl_exp", "f_exp", [], "pass", [r"call i32 @__cq_q_exp_1\(i32 %\d+\)\n",
                                            r"call double @__math_oflow\(i32 noundef 0\)"]),
    ("libm_musl_log", "f_log", [], "pass", [r"call i32 @__cq_q_log_1\(i32 %\d+\)\n",
                                            r"call double @__math_divzero\(i32 noundef 1\)"]),
    # cq-babj (musl sweep): a twin replays a classical fpexcept.ignore constrained op as the plain op it is (rule 23)
    # and an ordinary call of a host body whose only accesses are volatile ones to its own dead local (rule 19,
    # cq-fl4n; rule 24); llvm.lrint/lround/nearbyint bind to the injected body of the same name (rule 18).
    ("libm_musl_acosh", "f_acosh", [], "pass", [r"define internal void @__cq_q_log_1_unc\(",
                                                r"call double @llvm.experimental.constrained.sitofp.f64.i32"]),
    ("libm_musl_coshf", "f_coshf", [], "pass", [r"define internal void @__cq_q___expo2f_\d+_unc\(",
                                                r"call float @__math_oflowf\(i32 noundef 0\)"]),
    ("libm_musl_lrint", "f_lrint", [], "pass", [r"call i32 @__cq_q_lrint_1\(i32 %\d+\)\n"]),
    ("libm_musl_lrint", "f_lround", [], "pass", [r"call i32 @__cq_q_lround_1\(i32 %\d+\)\n"]),
    ("libm_musl_lrint", "f_nearbyint", [], "pass", [r"call i32 @__cq_q_nearbyint_1\(i32 %\d+\)\n"]),
    ("libm_musl_lrint", "f_nearbyintf", [], "pass", [r"call i32 @__cq_q_nearbyintf_1\(i32 %\d+\)\n"]),
    # cq-il07 (rules 19, 23): a twin replaying fpexcept.strict host ops (unbracketed, and BRACKETed under the quantum
    # predicate) restores the host flags it found.
    ("libm_musl_llrintl", "sweep_llrintl", [], "pass", [r"%cq.hostflags = call i32 @fetestexcept\(i32 63\)"]),
    ("twin_strict", "e_twin", [], "pass", [r"%cq.hostflags = call i32 @fetestexcept\(i32 63\)",
                                           r"call i32 @feraiseexcept\(i32 %cq.hostflags\)\n  ret void"]),
    # cq-57ju (rule 18 partial measurement, rule 23 default caller): a FENV_ACCESS callee measured from a plain
    # caller (mode 0, an empty flags rail, the flags dead): the measured result is copied out before the twin.
    ("partial_flags", "sc_measure", [], "pass",
     [r"call fastcc \{ i32, i32 \} @__cq_q_scaled_10\(i32 %\d+, double %\d+, i32 0, i32 %\d+\)",
      r"call void @cqrt_copy_f64\(i32 %(\d+), i32 %(\d+)\)(.|\n)*call void @__cq_q_scaled_10_unc\((.|\n)*"
      r"call double @cqrt_measure_f64\(i32 %\2\)"]),
    ("partial_flags", "sc_twice", [], "pass", [r"call void @cqrt_copy_f64"]),
    ("partial_fields", "pr_first", [], "pass", [r"call void @cqrt_copy_i64(.|\n)*call void @__cq_q_mk_1_unc"]),
    ("partial_fields", "pr_second", [], "pass", [r"call void @cqrt_copy_i64(.|\n)*call void @__cq_q_mk_1_unc"]),
    # cq-57ju (rule 19, cq-fl4n): a host call with classical arguments and no gate under a quantum predicate.
    ("host_unguarded", "hc_arm", [], "pass", [r"tail call fastcc i32 @helper\(i32 noundef 3\)\n  %\d+ = call i32 "
                                              r"@cq_template_select_i32_lh"]),
    ("host_unguarded", "hc_both", [], "pass", [r"call i32 @cq_template_select_i32_ll"]),
    # cq-57ju (rule 23): round.dynamic ops reached from a caller with the fenv state carry its mode.
    ("fenv_reached_mode", "md_up", [], "pass", [r"call \{ i32, i32 \} @__cq_q_third_1\(i32 %\d+, i32 2048, i32 %\d+\)",
                                                r"cq_template_fdiv_f64_hl_rm\("]),
    ("fenv_reached_mode", "md_plain", [], "pass", []),
    # cq-4e6m (rule 23): the reached mode is the LOWERED chain's: `other` holds the fenv state and calls third but
    # is not on ch_split's chain, so split and third are plain clones (no mode, no flags) writing the caller's cells.
    ("fenv_chain_default", "ch_split", [], "pass", [r"call void @__cq_q_split_100\(i32 %\d+, ptr %\d+\)\n",
                                                    r"call i32 @__cq_q_third_1\(i32 %0\)\n"]),
    # cq-4e6m (rules 9, 18, 20): a clone writing a caller cell, reading it back and writing it again, in sequence and
    # under quantum predicates (musl __rem_pio2/__rem_pio2f's *y): one slot result, select per predicated store.
    ("clone_cell_seq", "u_two", [], "pass", []),
    ("clone_cell_seq", "u_cond", [], "pass", [r"call i32 @cq_template_select_f64\("]),
    ("clone_cell_seq", "u_pair", [], "pass", []),
    # cq-4e6m (rules 18, 20, 23; 82 with 163 and 191): a clone carrying the environment writes caller cells and
    # stores through a QRAM triple: the mode and flags trail the formals, the flags are the result's last field.
    ("fenv_cells", "fe_cells", [], "pass", [r"call i32 @__cq_q_sc_100\(i32 %\d+, ptr %\d+, i32 0, i32 %\d+\)"]),
    ("fenv_cells", "fe_reread", [], "pass", [r"call \{ i32, i32 \} @__cq_q_sc2_10\(i32 %\d+, ptr %\d+, i32 0, i32 %\d+\)"]),
    ("fenv_cells", "fe_qram", [], "pass", [r"call \{ i32, i32 \} @__cq_q_addto_00011\("]),
    # cq-4e6m (rules 14, 23): fpexcept.ignore constrained ops in rule-14 loops are plain templates (not a call class).
    ("fenv_ignore_loop", "il_loop", [], "pass", []),
    ("fenv_ignore_loop", "il_array", [], "pass", []),
    # cq-4e6m (rules 18, 20, 21): a clone's stores past the caller's object on paths it never takes write nothing.
    ("store_past_object", "sp_one", [], "pass", []),
    # cq-4e6m (rules 23, 24; 82 with 101): an escaping clone carrying the environment: {result, flags, escaped}.
    # cq-lyzw: the escape clone of the external fe_inner is fe_inner.cq.esc (rule 24's explicit setjmp rewrite).
    ("fenv_escape", "fe_escape", [], "pass", [r"call \{ i32, i32, i32 \} @__cq_q_fe_inner\.cq\.esc_10\("]),
    # cq-4e6m (rules 19, 23): indirect-call candidates carrying the environment or not: the flags merge over the arms.
    ("fenv_indirect", "fi_call", [], "pass", []),
    ("fenv_indirect", "fi_pred", [], "pass", []),
    # cq-567j (gate 2a unc-h1 p16-p19): a clone that only reads a caller's slot cell through a pointer formal:
    # the cell's rails are used by the forward call (and read by its item when it has a twin), never freed before.
    ("read_only_ptr", "ro_bump", [], "pass", []),
    ("read_only_ptr", "ro_phase", [], "pass", []),
    ("read_only_ptr", "ro_result", [], "pass", []),
    ("read_only_ptr", "ro_old", [], "pass", []),
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
    # cq-c09h (owner 2026-11-02, revisits cq-kkgh): a by-value formal is a copy: the clone's cq_theta on it
    # rotates a copy of the caller's rail (copy, then Ry on the copy); the caller's rail is untouched.
    ("byvalue_rotated", "p5", [], "pass", [r"call void @cqrt_copy_i32\(i32 %0, i32 (%\d+)\)\n  call void @cqrt_ry_i32\(i32 \1, "]),
    ("byvalue_copied", "p3", [], "pass", [r"call void @cqrt_copy_i32\(i32 %0, i32 (%\d+)\)\n  call void @cqrt_ry_i32\(i32 \1, "]),
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
    # cq-i9wk (CR rules 18, 19, 20): a function's in-place activation has its own frame: the entry g (called
    # classically by h) is not rewritten although g's clone keeps handles in the same alloca (musl sin's y[2]).
    ("inplace_frame", "f", [], "pass", [r"define i32 @g\(i32 noundef %0\)[^{]*\{(?:(?!cqrt_|cq_template_|__cq_q_)[^}])*\}"]),
    # cq-i9wk (CR rule 19, owner 2026-11-02: the compiler never inlines): a callee reached with no quantum argument
    # is called as it is. A frozen result (the callee's register or its rule-6 image) is kept by the caller like
    # its own register; any other result comes from the kept clone, which returns the registers still allocated
    # after it; the twin takes them first.
    ("rule19_kept", "k_frozen", [], "pass", [r"call i32 @image\(i32 noundef %0, double noundef %1, i32 noundef %2\)"]),
    ("rule19_kept", "k_frozen_rot", [], "pass", [r"%(\d+) = call i32 @image\([^)]*\)\n  call void @cqrt_ry_i32\(i32 %\1, "]),
    ("rule19_kept", "k_twin", [], "pass", [r"call \{ i32, i32 \} @__cq_q_square_00\(i32 %0, double %1\)",
                                           r"call void @__cq_q_square_00_unc\(i32 %\d+, i32 %\d+, i32 %0, double %1\)",
                                           r"define internal void @__cq_q_square_00_unc\(i32 %reg0, i32 %out, i32 %0, "
                                           r"double %1\) \{\n  %\d+ = call i32 @cq_template_mul_i32\(i32 %reg0, i32 %reg0\)"]),
    ("rule19_kept", "k_meas", [], "pass", [r"call \{ i32, i32 \} @__cq_q_square_00\(i32 %0, double %1\)"]),
    ("rule19_kept", "k_twin2", [], "pass", [r"call void @__cq_q_mix_0000_unc\(i32 %\d+, i32 %\d+, i32 %\d+, i32 %0, "
                                            r"double %1, i32 %2, double %3\)"]),
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
    # cq-s2zz (CR §1.4 variadic clones, rule 20 save area): the x86-64 SysV layout of the variadic actuals
    # (gp registers, xmm slots at 48 + 16k, the overflow area after 176, a named pointer parameter, a classical
    # pointer actual, an x86_fp80). "lower": the checker's probe counts every read of the save area's xmm and
    # overflow slots, and of an object reached through a pointer read from it, as an access past an object
    # (no sample in the domain; bead in the report).
    ("varargs_wide", "vw_fp", [], "lower", [r"call i32 @__cq_q_fsum_0100\(ptr %\d+, i32 %\d+, i64 %\d+, double 2\.5"]),
    ("varargs_wide", "vw_ld", [], "lower", [r"call i32 @__cq_q_lsum_001\(i32 poison, x86_fp80 %\d+, i32 %\d+\)"]),
    ("varargs_wide", "vw_ptr", [], "lower", [r"call i32 @__cq_q_pptr_100\(i32 %\d+, ptr @tab, i32 %\d+\)"]),
    ("varargs_over", "vw_over", [], "lower", [r"getelementptr inbounds i8, ptr %va\.save, i64 176"]),
    # cq-s2zz (CR rule 27 Results, rules 25, 26): a declared clone with an aggregate result (a struct of handles,
    # one twin) and an aggregate argument (one digit per field). "lower": the callees have no body anywhere,
    # so neither oracle can run them.
    ("declared_aggr", "da_res", [], "lower", [r"call \{ i32, i32 \} @__cq_q_ext_rot_10\(i32 %\d+, double %\d+, i32 4\)"]),
    # cq-s2zz (CR rule 19): taint's candidate set (calleeCandidates); a QROM of callee tags whose candidate has a
    # phase (its _ctl clone under tag == k, the twin through its _pure), a candidate with a classical result
    # seeded into the select merge; a classical dispatch merging a struct result field by field.
    ("qrom_fn_ctl", "qc_res", [], "pass", [r"call i32 @__cq_q_rot_1_ctl\(i32 %\d+, i32 %\d+\)"]),
    ("qrom_fn_ctl", "qc_cls", [], "pass", []),
    ("indirect_mixed", "im_struct", [], "pass", [r"phi i32 \[", r"phi i64 \["]),
    ("declared_aggr", "da_arg", [], "lower", [r"call i32 @__cq_q_ext_sum_10\(i32 %\d+, i64 %\d+, i32 4\)"]),
    # cq-sd95 (CR rule 21, §1.4; musl erfl's __polevll): a readonly formal over host tables of different lengths
    # (T3 names no cell for a formal that writes none) crosses as a triple with a classical tag and idx; the
    # clone reads through the caller's pointer (a constant GEP into @B roots at @B in the object table).
    # cq-sd95 (CR rules 19, 27, §1.3): a call through a pointer with no in-module candidate is the registered
    # all-handles clone's (clone_resolve kind 0; kind 1 under a quantum predicate; the twin kind 2). "lower": the
    # callee is outside the program.
    ("resolve_fp", "r_plain", [], "lower", [r"%(\d+) = call ptr @cqrt_clone_resolve\(ptr %0, i32 0\)\n  %\d+ = call i32 %\1\(i32 %\d+, i32 4\)"]),
    ("resolve_fp", "r_ctl", [], "lower", [r"call ptr @cqrt_clone_resolve\(ptr %0, i32 1\)",
                                          r"%(\d+) = call ptr @cqrt_clone_resolve\(ptr %0, i32 2\)\n  call void %\1\("]),
    ("host_triple", "f_tables", [], "pass", [r"call i32 @__cq_q_pol_10000\(i32 %\d+, ptr @B, i32 \d+, i32 1, i32 4, i32 2\)"]),
    # cq-ro82 (CR rules 14, 19, 27): a call in a rule-14 trip is under the trip rail (lowerInstruction's tripFlag), which
    # currentPredicate() does not see: a declared clone there is its _ctl form (main emitted __cq_q_erf_1 unguarded in
    # tk_decl's K trips), a lifted callee with a gate its _ctl clone, a host effect a controlled tape entry.
    ("trip_ctl", "tk_decl", [], "pass", [r"define i64 @tk_decl\((?:(?!\n}\n)[\s\S])*call i32 @__cq_q_erf_1_ctl\(i32 %\d+, i32 %\d+, i32 4\)",
                                         r"define i64 @tk_decl\((?:(?!\n}\n|@__cq_q_erf_1\()[\s\S])*\n}\n"]),
    ("trip_ctl", "tk_decl_arm", [], "pass", [r"\A(?![\s\S]*@__cq_q_cbrt_1\()"]),
    ("trip_ctl", "tk_lift", [], "pass", [r"call void @__cq_q_tc_phase_1_ctl\(i32 %\d+, i32 %\d+\)"]),
    ("trip_ctl", "tk_print", [], "pass", [r"call i32 @cqrt_tape_write_i32_controlled\("]),
    # cq-ro82: loops-classical's stops on lifted and declared calls in a case-3 trip and its exit arm are gone (the call
    # under the trip rail / the arm flag); a declared clone in a case-1 trip is a call group undone by the reverse loop.
    ("trip_ctl", "t3_decl", [], "pass", [r"call i32 @__cq_q_erf_1_ctl\(i32 %\d+, i32 %\d+, i32 4\)"]),
    ("trip_ctl", "t3_lift", [], "pass", [r"call void @__cq_q_tc_phase_1_ctl\(i32 %\d+, i32 %\d+\)"]),
    ("trip_ctl", "t3_arm", [], "pass", [r"call void @__cq_q_tc_phase_1_b\d+_ctl\(i32 %\d+, i32 %\d+\)",
                                        r"call i32 @__cq_q_erf_1_ctl\(i32 %\d+, i32 %\d+, i32 4\)"]),
    ("trip_ctl", "t1_decl", [], "pass", [r"call void @__cq_q_erf_1_unc\(i32 %\d+, i32 %\d+, i32 4\)"]),
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
                 "--entry", entry, *(["--samples", str(SAMPLES[probe])] if probe in SAMPLES else [])],
                capture_output=True, text=True, cwd=ROOT / "checker")
            if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
                why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
        print(("FAIL " if why else "ok   ") + probe + ":" + entry + ("" if not why else ": " + "; ".join(why)))
        failures += bool(why)
    print("FAILED" if failures else "ok")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
