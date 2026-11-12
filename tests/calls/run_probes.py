#!/usr/bin/env python3
"""tests/calls probes (cq-w2a-calls review fixes): small programs through the real cq-lower plugin.

Each case names a probe (probes/<name>.O1.ll, clang -O1 of probes/<name>.c), its entry, extra opt flags and
what it must give:
  - "pass": cq-lower exits 0, plain cq-verify accepts the output, every regex in `match` occurs in the
    lowered module, and the entry is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle);
  - "lower": as "pass" without the §6 run (the case says why the checker cannot run it);
  - "fatal: <text>": cq-lower stops with that error (an unimplemented shape, never a silent output);
  - "reject: <regex>": the lowered module with every line matching the regex deleted is a wrong program, and the §6 run
    must say so (exit 1): the checker's model of what those lines do, kept honest;
  - "wrong: <file>": probes/<file> is a frozen wrong lowering of the probe, and the §6 run must say so (exit 1);
  - "frozen: <file>": probes/<file> is a frozen lowering of a shape cq-lower does not emit for the probe today, and the
    §6 run must accept it (exit 0): the checker's model of that shape, kept honest.
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
# §6 samples per probe where the full set takes minutes (cqcheck user --samples): the musl bodies.
SAMPLES = {"mp1": 64, "mp2": 64, "mst": 64, "mp4": 64, "mp5": 64, "chk1": 64, "chk3": 64, "chk4": 64, "at1": 64, "at2": 64,
           "vaC": 64, "vaD": 64, "vaF": 64, "hc1": 64, "hc3": 64, "fe2": 64, "fe3": 64, "fe6": 64, "trip_ctl": 64, "clone_cell_seq": 64, "fenv_cells": 64, "fenv_ignore_loop": 64, "store_past_object": 64, "fenv_escape": 64, "fenv_indirect": 64, "libm_musl_acosh": 16, "libm_musl_coshf": 16, "libm_musl_lrint": 16, "libm_musl_llrintl": 16, "twin_strict": 64, "libm_musl_floorfn": 32, "libm_musl_atan": 16, "libm_musl_exp": 16, "libm_musl_log": 16}
# (probe, entry, opt flags, expectation, regexes the lowered module must contain)
CASES = [
    # cq-s78ap (rules 8, 9, 16): a classical switch with a dead-end default: the last live arm's complement predicate meets the default's,
    # but the edges of one classical terminator exclude each other. switch_unreachable_default lowers but gets no §6 run: its k >= 3 hit
    # `unreachable`, UB outside the domain, and the checker still compares them (reported).
    ("switch_unreachable_default", "e", [], "lower", []),
    ("switch_unreachable_o1_default", "e", [], "pass", []),
    ("switch_noreturn_default", "e", [], "pass", []),
    ("switch_unreachable_o1_quantum_arms", "e", [], "pass", []),
    ("branch_unreachable_else", "e", [], "pass", []),
    # cq-zo7ja (rules 9, 26): a packed integer's classical phi: its whole is made on the arm, no gate reads the other arm's poison.
    ("packed_phi_call_arms", "e", [], "pass", []),
    ("packed_phi_const_arm", "e", [], "pass", []),
    ("packed_phi_whole_read", "e", [], "pass", []),
    ("packed_phi_field_arm", "e", [], "pass", []),
    # cq-x95qv (rule 19, "a tape or abort event"): a callee with a noreturn arm is a _ctl clone under a quantum predicate: the arm
    # on a rail condition, the arm on a classical condition (rule 16: that path then returns zero-valued results), through a callee
    # by name, through a defined noreturn callee.
    ("abort_arm_ctl", "e", [], "pass", [r"call void @__cq_q_f_1_ctl\("]),
    ("abort_classical_arm_ctl", "e", [], "pass", [r"call void @__cq_q_f_0_ctl\("]),
    ("abort_arm_ctl_nested", "e", [], "pass", [r"call void @__cq_q_f_1_ctl\("]),
    ("abort_arm_ctl_defined", "e", [], "pass", [r"call void @__cq_q_f_1_ctl\("]),
    # cq-mc20u (rule 18): an abort is no reason to have no twin; the twin recomputes through _pure and repeats no abort event. exit,
    # abort, __builtin_trap, under a predicate, and a loading callee.
    ("abort_arm_twin_exit", "e", [], "pass", [r"call void @__cq_q_f_1_unc\(", r"define [^\n]*@__cq_q_f_1_pure\("]),
    ("abort_arm_twin_abort", "e", [], "pass", [r"call void @__cq_q_f_1_unc\("]),
    ("abort_arm_twin_trap", "e", [], "pass", [r"call void @__cq_q_f_1_unc\("]),
    ("abort_arm_twin_ctl", "e", [], "pass", [r"call void @__cq_q_f_1_ctl_unc\("]),
    ("abort_arm_twin_load", "e", [], "pass", [r"call void @__cq_q_f_1_unc\("]),
    # cq-5yuk9 (§1.4): `internal fastcc` helpers: every clone and twin is fastcc and so is every call of one, the reverse calls
    # included (a C-convention call of a fastcc definition is undefined behaviour; cq-verify names it cc-mismatch).
    ("fastcc_twins", "e", [], "pass", [r"call fastcc void @__cq_q_h_11_unc\(", r"call fastcc void @__cq_q_g_1_unc\(",
                                       r"call fastcc void @__cq_q_w_01_ctl_unc\(",
                                       r"define internal fastcc void @__cq_q_w_01_ctl_unc\("]),
    # cq-57ju (rulings 2026-11-02): plain clang -O1 callers of musl b1efda5 bodies (no -fno-builtin, no -frounding-math).
    # llvm.<f> binds to the injected body (cq-odjk); fpexcept.ignore ops are plain templates and the clone takes no
    # mode and no flags (rule 23, cq-75n4); __math_oflow / __math_divzero under a quantum predicate stay host calls,
    # unguarded (rule 19, cq-fl4n). llvm.floor stays the floor template; floorfn calls musl's body (-fno-builtin).
    ("libm_musl_floor", "f_floor", [], "pass", [r"call i32 @cq_template_floor_f64\(i32 %\d+\)"]),
    # cq-babj (musl sweep): a twin replays a classical fpexcept.ignore constrained op as the plain op it is (rule 23)
    # and an ordinary call of a host body whose only accesses are volatile ones to its own dead local (rule 19,
    # cq-fl4n; rule 24); llvm.lrint/lround/nearbyint bind to the injected body of the same name (rule 18).
    # cq-il07 (rules 19, 23): a twin replaying fpexcept.strict host ops (unbracketed, and BRACKETed under the quantum
    # predicate) restores the host flags it found.
    ("libm_musl_llrintl", "sweep_llrintl", [], "pass", [r"%cq.hostflags = call i32 @fetestexcept\(i32 63\)"]),
    ("twin_strict", "e_twin", [], "pass", [r"%cq.hostflags = call i32 @fetestexcept\(i32 63\)",
                                           r"call i32 @feraiseexcept\(i32 %cq.hostflags\)\n  ret void"]),
    # Rules 18, 19: an own symbol returning a callee's result as it stands; its twin recomputes through _pure, so the callee's twin exists.
    ("own_ret_chain", "orc", [], "pass", [r"define internal fastcc void @__cq_q_inner_0_unc\(", r"define internal fastcc void @__cq_q_mid_0_unc\("]),
    # cq-xbpw6 (rule 18): a store in the other arm of a quantum branch lies on no path from a loading clone's call, so the twin
    # still runs after the merge and frees the result: no rail of it stays live for §6 item 1's leak rule.
    ("twin_other_arm_store", "other_arm", [], "pass",
     [r"call void @__cq_q_rd_1_ctl_unc\(i32 %(\d+), i32 %(\d+), i32 %\d+\)\n  call void @cqrt_free\(i32 %\2\)"]),
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
    # cq-4e6m (rules 9, 18, 20): a clone writing a caller cell, reading it back and writing it again, in sequence and
    # under quantum predicates (musl __rem_pio2/__rem_pio2f's *y): one slot result, select per predicated store.
    # cq-4e6m (rules 18, 20, 23; 82 with 163 and 191): a clone carrying the environment writes caller cells and
    # stores through a QRAM triple: the mode and flags trail the formals, the flags are the result's last field.
    # cq-4e6m (rules 14, 23): fpexcept.ignore constrained ops in rule-14 loops are plain templates (not a call class).
    # cq-4e6m (rules 18, 20, 21): a clone's stores past the caller's object on paths it never takes write nothing.
    # cq-4e6m (rules 23, 24; 82 with 101): an escaping clone carrying the environment: {result, flags, escaped}.
    # cq-lyzw: the escape clone of the external fe_inner is fe_inner.cq.esc (rule 24's explicit setjmp rewrite).
    ("fenv_escape", "fe_escape", [], "pass", [r"call \{ i32, i32, i32 \} @__cq_q_fe_inner\.cq\.esc_10\("]),
    # cq-4e6m (rules 19, 23): indirect-call candidates carrying the environment or not: the flags merge over the arms.
    # cq-567j (gate 2a unc-h1 p16-p19): a clone that only reads a caller's slot cell through a pointer formal:
    # the cell's rails are used by the forward call (and read by its item when it has a twin), never freed before.
    # cq-oocu (107's union_slot): a slot record's pointer-kind cell (tag, idx) a clone reads as an integer and
    # writes back (ptrtoint at the load, inttoptr at the store keeping the tag); int and long cells, add and sub.
    # cq-pgen (109's put, T5 cellForward): a clone storing a formal's handle unchanged into a caller cell: no
    # copy-out, no twin; once and in a classically bounded loop over a VLA.
    # cq-r8-d (190's escape, CR rule 27 Pointers): a declared clone handed a pointer into a local slot object:
    # (object, tag, idx, cell count), a snapshot, the twin after the last cell read (dp_reg called the original
    # ext_sink with the handle cells before); two pointers and a classical cell are unimplemented.
    # cq-prvy (95): a variadic clone per call-site arity; its save area holds the actuals' handles.
    # Rule 14, §1.4: a recursion under a quantum predicate is one _ctl clone with its activation counter, cut at K (Q12).
    ("depth_le0", "r4", [], "pass", [r"@__cq_act_"]),
    ("depth_lt0", "r1", [], "pass", [r"@__cq_act_"]),
    ("depth_lt_m1", "r15", [], "pass", [r"@__cq_act_"]),
    ("depth_classical_formal", "r13", [], "pass", [r"@__cq_act_"]),
    ("depth_other_formal", "r14", [], "pass", [r"@__cq_act_"]),
    ("mutual", "mutual", [], "pass", [r"@__cq_act_even", r"@__cq_act_odd"]),
    # Rule 19: a call through a function pointer: a classical pointer (measured, unmeasured with the twin at rule 18's
    # position, under a predicate, all arguments classical), an address rail, a table clone that mints a register.
    ("indirect_mixed", "im_struct", [], "pass", [r"@__cq_clone_resolve"]),
    ("fp_classical", "fp_classical", [], "pass", [r"@__cq_clone_resolve"]),
    ("fp_under_pred", "fp_under_pred", [], "pass", [r"@__cq_clone_resolve\(ptr %\w+, i32 1\)", r"@__cq_clone_resolve\(ptr %\w+, i32 3\)"]),
    ("fp_rail_unmeasured", "fp_rail_unmeasured", [], "pass", [r"@__cq_clone_count"]),
    ("tbl_mint", "tbl_mint", [], "pass", [r"@cqrt_push", r"@cqrt_pop"]),
    # Rule 19: inside a _ctl clone a measurement is a controlled copy under the clone's formal, also in an arm (Q13).
    ("ctl_measure_arm", "ctl_measure_arm", [], "pass", [r"@cqrt_copy_i32_controlled\(i32 %0, "]),
    # cq-ggr3p (rules 2, 19, §1.4): a callee whose only non-template is a measurement takes the predicate: its measurement is the
    # controlled copy and the clone has no twin. The frozen unguarded lowering (rule 2's hoist is for an arm of the same function,
    # never for a callee the input does not enter) must fail §6.
    ("meas_only_ctl", "f", [], "pass", [r"call i32 @__cq_q_mm_1_ctl\(", r"@cqrt_copy_i32_controlled\(i32 %0, "]),
    ("meas_only_ctl_k", "f", [], "pass", [r"call i32 @__cq_q_mm_10_ctl\(", r"@cqrt_copy_i32_controlled\(i32 %0, "]),
    ("meas_only_ctl_qbranch", "f", [], "pass", [r"call i32 @__cq_q_mm_1_ctl\("]),
    ("meas_only_ctl_qbranch", "f", [], "wrong: meas_only_ctl_qbranch.unguarded.ll", []),
    # cq-ej44t (rules 2, 5, 18): an actual the clone measures itself is the caller's measured rail, never uncomputed or freed: a
    # computed one, a chain of clones, a seed of an earlier outcome, a measurement that a quantum branch does not make partial,
    # per trip of a classical loop, in a clone with a twin. Measured on some classical paths of the caller or of the callee only
    # it is lowered as unmeasured and the measurement reads a kept basis copy. Under a predicate it is cq-ggr3p's controlled copy.
    ("meas_byvalue", "f", [], "pass", []),
    ("meas_byvalue_chain", "f", [], "pass", []),
    ("meas_byvalue_seed", "f", [], "pass", []),
    ("meas_byvalue_qbranch", "f", [], "pass", []),
    ("meas_byvalue_loop", "f", [], "pass", []),
    ("meas_byvalue_twin", "f", [], "pass", []),
    ("meas_byvalue_path", "f", [], "pass", [r"call void @cqrt_copy_i32\("]),
    ("meas_byvalue_some", "f", [], "pass", []),
    ("meas_byvalue_kloop", "f", [], "pass", [r"call i32 @__cq_q_in_1_ctl\("]),
    ("meas_byvalue_indirect", "f", [], "pass", []),
    # cq-t2jj2 (CQ_spec 96c7bc5, §1.4): _t measures a kept copy of its formal, not pushed, and leaves the formal to the caller: the
    # bead's probe (f), a formal read and measured again after a measurement (g), a by-name callee that measures the formal (h). The
    # twin cannot re-read the copy, so there is no rule-18 twin: _t_unc is empty and the results stay allocated (211's peek). A
    # measurement of a rail that is not a formal (n) keeps the twin, which re-reads the copy it pushed and zeroes the rail result.
    ("meas_table_t", "f", [], "pass", [
        r"define internal i32 @__cq_q_in_1_t\(i32 %0, i32 %1\) \{\n  %3 = call i32 @cqrt_alloc_i32\(i32 0\)\n"
        r"  call void @cqrt_copy_i32\(i32 %0, i32 %3\)\n  %4 = call i32 @cqrt_measure_i32\(i32 %3\)[^\n]*\n"
        r"  %5 = add nsw i32 %4, 1\n  %6 = call i32 @cqrt_alloc_i32\(i32 %5\)\n  ret i32 %6\n}\n",
        r"define internal void @__cq_q_in_1_t_unc\(i32 %0, i32 %1, i32 %2\) \{\n  ret void\n}\n"]),
    ("meas_table_t", "g", [], "pass", []),
    ("meas_table_t", "h", [], "pass", [r"define internal void @__cq_q_outer_1_t_unc\(i32 %0, i32 %1, i32 %2\) \{\n  ret void\n}\n"]),
    ("meas_table_t", "n", [], "pass", [
        r"define internal void @__cq_q_inner_1_t_unc\(i32 %out(?:(?!\n}\n)[\s\S])*call i32 @cqrt_pop\(\)"
        r"(?:(?!\n}\n)[\s\S])*call void @cqrt_free\(i32 %out\)"]),
    # cq-md33a (§1.4, rule 18): _t measures both its formal and a rail that is not a formal. The formal's measurement leaves no
    # rule-18 twin, so no measured copy is pushed (mintSites is empty) and _t_unc pops only what _t pushed: nothing (f), or the
    # register cq_theta minted, listed and pushed with its count at the return, which _t_unc pops as count then handles (g).
    ("meas_table_both", "f", [], "pass", [
        r"define internal i32 @__cq_q_both_1_t\((?:(?!\n}\n)(?!cqrt_push|__cq_mints_push)[\s\S])*\n}\n",
        r"define internal void @__cq_q_both_1_t_unc\(i32 %0, i32 %1, i32 %2\) \{\n  ret void\n}\n"]),
    ("meas_table_both", "g", [], "pass", [
        r"define internal i32 @__cq_q_bothrot_1_t\((?:(?!\n}\n)(?!cqrt_push\()[\s\S])*call void @__cq_mints_push\(ptr %\d+\)\n"
        r"  %\d+ = call i32 @cqrt_alloc_i32\(i32 %\d+\)\n  ret i32 %\d+\n}\n",
        r"define internal void @__cq_q_bothrot_1_t_unc\(i32 %0, i32 %1, i32 %2\) \{\n  %4 = call i32 @cqrt_pop\(\)\n"
        r"(?:(?!\n}\n)[\s\S])*call i32 @cqrt_pop\(\)\n  %\d+ = sub i32 %\d+, 1\n"]),
    # Every formal of _t is a rail, so a branch on one is quantum: the measurement under it is tainted and _t has no twin (rule 18),
    # in a K-loop (f) and in an arm (g).
    ("meas_table_t_paths", "f", [], "pass", [r"define internal void @__cq_q_sumin_11_t_unc\(i32 %0, i32 %1, i32 %2, i32 %3\) \{\n  ret void\n}\n"]),
    ("meas_table_t_paths", "g", [], "pass", [r"define internal void @__cq_q_some_11_t_unc\(i32 %0, i32 %1, i32 %2, i32 %3\) \{\n  ret void\n}\n"]),
    # Rules 2, 18: a result read only by a measurement of a copy (f: in _t; g: also on some classical paths) has its twin emitted.
    ("meas_own_twin", "f", [], "pass", [r"define internal void @__cq_q_rd_0_unc\("]),
    ("meas_own_twin", "g", [], "pass", [r"define internal void @__cq_q_rd_0_unc\("]),
    # cq-p4ob6 (rules 18, 19): the own symbol of a function on a call cycle, whose record is the least fixpoint: not rotating, its
    # result (read from the bus) is zeroed by the twin; rotating, KEPT (rulings3 F). Direct, mutual, and an aggregate return.
    ("rec_bus_own", "f", [], "pass", [r"call void @__cq_q_r_0_unc\("]),
    ("rec_bus_mutual", "f", [], "pass", []),
    ("rec_bus_pair", "f", [], "pass", []),
    ("rec_rot_own", "f", [], "pass", []),
    # cq-y4lav (rule 14): a purely classical loop in an own symbol keeps its CFG, an exit tested first included (the exit
    # block's predicate, the loop's own, must not take the edge into the loop body).
    ("own_loop_theta", "f", [], "pass", [r"br i1 %\d+, label %(\d+), label %(?!\1\b)\d+"]),
    ("own_loop_two_exits", "f", [], "pass", []),
    ("own_loop_after_arm", "f", [], "pass", []),
    ("own_loop_after_qarm", "f", [], "pass", []),
    # cq-stmvu (rules 19, 26): an own symbol's integer result is one handle, every lane of it, a coerced struct's too; the
    # _pure clone its twin recomputes through has the same layout.
    ("own_small_struct", "f", [], "pass", [r"call i32 @cq_template_or_i64_hl", r"call void @__cq_q_q_0_unc"]),
    ("own_small_struct_rec", "f", [], "pass", []),
    ("own_small_struct_caller", "f", [], "pass", []),
    ("own_small_widen", "f", [], "pass", []),
    ("own_small_mixed_ret", "f", [], "pass", []),
    # Rule 16 Signal table: a result of signal and of raise the program reads; a rail signal number.
    # cq-pt57w (rule 16): a stream call by name is the host boundary although the module has its body (the musl bundle's
    # fprintf): rule 16's effect entry, the body never lifted nor lowered. cq-8bq66: the evaluator prints a performed fprintf
    # entry on stdout and the C oracle calls the host's fprintf, not the module's body.
    ("stream_body_by_name", "stream_body", [], "pass",
     [r"call void @cqrt_tape_effect_controlled\(i32 %\d+, i32 %\d+, ptr @\.cq\.effect\.fprintf, i32 3\)",
      r"define noundef i32 @fprintf\(ptr noalias nocapture noundef %0, ptr noalias nocapture noundef readonly %1, \.\.\.\)"]),
    ("stream_body_differs", "stream_body_differs", [], "pass",
     [r"call void @cqrt_tape_effect_controlled\(i32 %\d+, i32 %\d+, ptr @\.cq\.effect\.fprintf, i32 3\)"]),
    # cq-83c9c: vprintf and vfprintf from a variadic wrapper with a quantum argument: the evaluator reads the va_list on the
    # bus and prints a performed entry on stdout; one on stderr is no effect line, as the C oracle's host call is none.
    ("stream_vforms", "stream_vforms", [], "pass",
     [r"call void @cqrt_tape_effect_controlled\(i32 %\d+, i32 %\d+, ptr @\.cq\.effect\.vprintf, i32 2\)",
      r"call void @cqrt_tape_effect_controlled\(i32 %\d+, i32 %\d+, ptr @\.cq\.effect\.vfprintf, i32 3\)"]),
    # cq-ojgho (rule 16, owner 2026-11-10): a <wchar.h> stream call by name (fputwc) is the host boundary as well; the C oracle
    # drops the module's body (oracle._STREAM_NAMES), so the call is the stand-in's effect on both sides, as fputc's (cq-83c9c).
    ("stream_wide_body_by_name", "stream_wide_body", [], "pass",
     [r"call void @cqrt_tape_effect_controlled\(i32 %\d+, i32 %\d+, ptr @\.cq\.effect\.fputwc, i32 2\)",
      r"define noundef i32 @fputwc\(i32 noundef %0, ptr nocapture noundef %1\)"]),
    # cq-83c9c: the wide printing family (fwprintf, wprintf, vfwprintf, vwprintf) on stdout is stdout text, on stderr none.
    ("stream_wide_forms", "stream_wide_forms", [], "pass",
     [r"call void @cqrt_tape_effect_controlled\(i32 %\d+, i32 %\d+, ptr @\.cq\.effect\.vwprintf, i32 2\)",
      r"call void @cqrt_tape_effect_controlled\(i32 %\d+, i32 %\d+, ptr @\.cq\.effect\.wprintf, i32 4\)"]),
    # cq-xkmrm (rule 16): an `internal` printf body (the musl bundle's, internalized) is turned into the host's printf by the
    # checker as a clean external declaration (not dso_local: the probe and the C oracle bind it to the host library); the
    # lowered text is stdout. The mutant prints x where the C program prints x + 2.
    ("stream_internal_host", "stream_internal_host", [], "pass",
     [r"call void @cqrt_tape_fmt\(i32 %\d+, ptr @\.str\.2\)", r"define internal noundef i32 @printf\("]),
    ("stream_internal_host", "stream_internal_host", [], "wrong: stream_internal_host.wrongarg.ll", []),
    # cq-tgl3i (rule 16, BACKEND_ABI §1.11): scanf (variadic, under a quantum predicate) and vscanf (through a variadic
    # wrapper's va_list) are INPUT entries the evaluator performs with the host's vfscanf on the one input stream (ruling Q5),
    # as the C oracle's call does; %n stores, through the bus. Mutants: the pointers swapped; the call dropped (its result
    # taken as EOF).
    ("stream_scanf", "stream_scanf", [], "pass",
     [r"call i32 @cqrt_tape_effect_i32_controlled\(i32 %\d+, i32 %\d+, ptr @\.cq\.effect\.scanf, i32 3\)",
      r"call i32 @cqrt_tape_effect_i32_controlled\(i32 %\d+, i32 %\d+, ptr @\.cq\.effect\.vscanf, i32 2\)"]),
    ("stream_scanf", "stream_scanf", [], "wrong: stream_scanf.wrongptr.ll", []),
    ("stream_scanf", "stream_scanf", [], "wrong: stream_scanf.noscan.ll", []),
    # Ruling Q5 (DECISIONS 2026-11-11): one finite input stream with state, the same bytes on both sides (fx_standin.h); an
    # INPUT call consumes what the C program consumes on that basis input, and its effect line carries the offset and the
    # bytes taken. The question's witness (a getchar loop until end of file ends); two calls in sequence (the second's length
    # a rail); a call under a quantum predicate (nothing consumed where it reads 0; mutant: the call made unconditional);
    # scanf then getchar (the two scans from one position, the stream advanced once); reading past the end.
    ("stdin_witness", "count_then_rotate", [], "pass", []),
    ("stdin_seq", "stdin_seq", [], "pass", []),
    ("stdin_pred", "stdin_pred", [], "pass", []),
    ("stdin_pred", "stdin_pred", [], "wrong: stdin_pred.always.ll", []),
    ("stdin_scan_getc", "stdin_scan_getc", [], "pass", []),
    ("stdin_eof", "stdin_eof", [], "pass", []),
    ("stdin_wide", "stdin_wide", [], "pass", []),
    # cq-wjysl (ruling Q5): ungetc/ungetwc push back into the one stream; getline/getdelim allocate and consume a line,
    # fgetln returns it; feof sees the stream's end, clearerr clears it, getw reads 4 bytes, pread reads at an offset and
    # consumes nothing. cq-cyjua: a direct input call after a quantum-controlled one shares the stream's state and stores
    # quantum (a frozen lowering: cq-lower makes it a tape entry); an input call whose FILE* is a quantum rail is never
    # deferred (owner ruling 2026-11-12).
    ("stdin_unget", "stdin_unget", [], "pass", []),
    ("stdin_getline", "stdin_getline", [], "pass", []),
    ("stdin_feof", "stdin_feof", [], "pass", []),
    ("stdin_direct", "stdin_direct", [], "pass", []),
    ("stdin_direct", "stdin_direct", [], "frozen: stdin_direct.direct.ll", []),
    ("stdin_ident", "stdin_ident", [], "pass", []),
    # cq-xdscs (rule 16, BACKEND_ABI §1.11): perror and puts read a string whose first byte is quantum, results unread (no
    # stated deviation): deferred entries performed on the measured string, read up to its first 0 (on x0 = 0: ""), as the
    # C program's call reads it. The mutant passes perror the string's second byte.
    ("stream_reads_string", "stream_reads_string", [], "pass",
     [r"call void @cqrt_tape_effect_controlled\(i32 %\d+, i32 %\d+, ptr @\.cq\.effect\.perror, i32 1\)",
      r"call void @cqrt_tape_effect_controlled\(i32 %\d+, i32 %\d+, ptr @\.cq\.effect\.puts, i32 1\)"]),
    ("stream_reads_string", "stream_reads_string", [], "wrong: stream_reads_string.wrongptr.ll", []),
    ("raise_read", "raise_read", [], "pass", [r"@__cq_sig"]),
    ("sig_rail", "sig_rail", [], "pass", [r"@__cq_sig", r"@cqrt_qram_store_i64\("]),
    # Rule 19 extra results: the twin takes the register's handle and repeats no rotation.
    ("mint2", "mint2", [], "pass", [r"call void @__cq_q_f_100_unc\(i32 %\d+, i32 %\d+, i32 %\d+, double %\d+, i32 %\d+\)"]),
    # cq-xhv4 (169): a twin computes no rule 14 kept overflow predicate a_K of its own (the forward keeps one).
    ("twin_kept_overflow", "tk", [], "pass", []),
    # cq-c09h (owner 2026-11-02, revisits cq-kkgh): a by-value formal is a copy: the clone's cq_theta on it
    # rotates a copy of the caller's rail (copy, then Ry on the copy); the caller's rail is untouched.
    ("byvalue_rotated", "p5", [], "pass", [r"call void @cqrt_copy_i32\(i32 %0, i32 (%\d+)\)\n  call void @cqrt_ry_i32\(i32 \1, "]),
    ("byvalue_copied", "p3", [], "pass", [r"call void @cqrt_copy_i32\(i32 %0, i32 (%\d+)\)\n  call void @cqrt_ry_i32\(i32 \1, "]),
    # cq-budv (117): an in-place rotation at a variable offset (T3 kAnyCell) of a runtime-length slot array.
    # cq-i9wk (CR rules 18, 19, 20): a function's in-place activation has its own frame: the entry g (called
    # classically by h) is not rewritten although g's clone keeps handles in the same alloca (musl sin's y[2]).
    # cq-i9wk (CR rule 19, owner 2026-11-02: the compiler never inlines): a callee reached with no quantum argument
    # is called as it is. A frozen result (the callee's register or its rule-6 image) is kept by the caller like
    # its own register; any other result comes from the kept clone, which returns the registers still allocated
    # after it; the twin takes them first.
    # cq-09xh: a byval formal stays byval; the caller passes a snapshot, which the twin gets too.
    # cq-h8vd: a declared clone of an LLVM math intrinsic takes the libm name's K (CQ_K, the per-function flag).
    # libm_k is "lower" (no §6 run): cqcheck user does not read llvm.used, which CQ_K emits (cq-tntm).
    ("libm_k", "k1", [], "lower", [r"call i32 @__cq_q_sin_1\(i32 %\w+, i32 53\)",
                                   r"call i32 @__cq_q_atan2_10\(i32 %\w+, double %\w+, i32 77\)"]),
    ("libm_flag", "k4", ["-cq-k=expf=9"], "pass", [r"call i32 @cqrt_tape_effect_f32_controlled\("]),
    # cq-dxii: a classical loop writing into a QRAM or slot object is not pure classical (it reaches loops-classical;
    # the QRAM probes stop there until loops-classical builds rule 14 over QRAM stores, then they become "pass").
    # cq-99z6: the twin's memory footprint (everything the clone may read or write, by its body): a replayed
    # store after a read of memory it may overwrite, a write into the footprint between the call and the twin
    # (a call reaching an escaped local or a global, a store into an object reached through a loaded pointer).
    # cq-aqk1, cq-366o (rule 18 twin point): one pointer handed to two pointer formals the clone writes through is a
    # call of the callee's alias variant (one route per caller cell); distinct cells lower and are §6-equal.
    # cq-88vg: a measured classical switch phi over a clone's slot outs (52's shape): edge copies; the twin of a
    # clone with a classical result and cell copy-outs.
    # cq-s2zz (CR §1.4 variadic clones, rule 20 save area): the x86-64 SysV layout of the variadic actuals
    # (gp registers, xmm slots at 48 + 16k, the overflow area after 176, a named pointer parameter, a classical
    # pointer actual, an x86_fp80). "lower": the checker's probe counts every read of the save area's xmm and
    # overflow slots, and of an object reached through a pointer read from it, as an access past an object
    # (no sample in the domain; bead in the report).
    # cq-s2zz (CR rule 27 Results, rules 25, 26): a declared clone with an aggregate result (a struct of handles,
    # one twin) and an aggregate argument (one digit per field). "lower": the callees have no body anywhere,
    # so neither oracle can run them.
    ("declared_aggr", "da_res", [], "lower", [r"call \{ i32, i32 \} @__cq_q_ext_rot_10\(i32 %\d+, double %\d+, i32 4\)"]),
    # cq-s2zz (CR rule 19): taint's candidate set (calleeCandidates); a QROM of callee tags whose candidate has a
    # phase (its _ctl clone under tag == k, the twin through its _pure), a candidate with a classical result
    # seeded into the select merge; a classical dispatch merging a struct result field by field.
    ("declared_aggr", "da_arg", [], "lower", [r"call i32 @__cq_q_ext_sum_10\(i32 %\d+, i64 %\d+, i32 4\)"]),
    # cq-sd95 (CR rule 21, §1.4; musl erfl's __polevll): a readonly formal over host tables of different lengths
    # (T3 names no cell for a formal that writes none) crosses as a triple with a classical tag and idx; the
    # clone reads through the caller's pointer (a constant GEP into @B roots at @B in the object table).
    # cq-sd95 (CR rules 19, 27, §1.3): a call through a pointer with no in-module candidate is the registered
    # all-handles clone's (clone_resolve kind 0; kind 1 under a quantum predicate; the twin kind 2). "lower": the
    # callee is outside the program.
    # cq-ro82 (CR rules 14, 19, 27): a call in a rule-14 trip is under the trip rail (lowerInstruction's tripFlag), which
    # currentPredicate() does not see: a declared clone there is its _ctl form (main emitted __cq_q_erf_1 unguarded in
    # tk_decl's K trips), a lifted callee with a gate its _ctl clone, a host effect a controlled tape entry.
    ("trip_ctl", "tk_decl", [], "pass", [r"define i64 @tk_decl\((?:(?!\n}\n)[\s\S])*call i32 @cqrt_tape_effect_f64_controlled\(",
                                         r"define i64 @tk_decl\((?:(?!\n}\n|@__cq_q_erf_1\()[\s\S])*\n}\n"]),
    ("trip_ctl", "tk_decl_arm", [], "pass", [r"\A(?![\s\S]*@__cq_q_cbrt_1\()"]),
    ("trip_ctl", "tk_lift", [], "pass", [r"call void @__cq_q_tc_phase_1_ctl\(i32 %\d+, i32 %\d+\)"]),
    ("trip_ctl", "tk_print", [], "pass", [r"call i32 @cqrt_tape_write_i32_controlled\("]),
    # cq-ro82: loops-classical's stops on lifted and declared calls in a case-3 trip and its exit arm are gone (the call
    # under the trip rail / the arm flag); a declared clone in a case-1 trip is a call group undone by the reverse loop.
    ("trip_ctl", "t3_decl", [], "pass", [r"call i32 @cqrt_tape_effect_f64_controlled\("]),
    ("trip_ctl", "t3_lift", [], "pass", [r"call void @__cq_q_tc_phase_1_ctl\(i32 %\d+, i32 %\d+\)"]),
    ("trip_ctl", "t3_arm", [], "pass", [r"call void @__cq_q_tc_phase_1_b\d+_ctl\(i32 %\d+, i32 %\d+\)",
                                        r"call i32 @cqrt_tape_effect_f64_controlled\("]),
    ("trip_ctl", "t1_decl", [], "pass", [r"call i32 @cqrt_tape_effect_f64_controlled\("]),
    # Rule 18, §1.4 (CQ_spec 96c7bc5): _t measures a kept copy of its formal v, not pushed, so it has no rule-18 twin and its result
    # is kept; in _t_ctl the measurement is the controlled copy, tainted, so its twin only counts and the result is kept.
    ("table_twin_measure", "e_cl", [], "pass", [
        r"define internal void @__cq_q_g_11_t_unc\(i32 %0, i32 %1, i32 %2, i32 %3\) \{\n  ret void\n}\n",
        r"define internal void @__cq_q_g_11_t_ctl_unc\(i32 %0(?:(?!\n}\n|@cqrt_)[\s\S])*\n}\n"]),
    # e_rail: its _t_ctl result is KEPT by the ruling (§1.4; run.kept_results_module).
    ("table_twin_measure", "e_rail", [], "pass", []),
    # Rule 19, cq-ylng: a twin's recompute through a by-name callee that rotates goes through the callee's twin on the registers
    # handed up (no Ry in any twin), a call of an own symbol's rail is one register, a void one is not repeated.
    ("twin_rotating_callee", "y2a", [], "pass", [r"define internal fastcc void @__cq_q_f_11_unc\((?:(?!\n}\n)[\s\S])*call void @__cq_q_rot_1_unc\(i32 (%\d+)(?:(?!\n}\n)[\s\S])*call void @__cq_q_rot_1_unc\(i32 \1"]),
    ("twin_rotating_callee", "y2b", [], "pass", []),
    ("twin_rotating_callee", "y2c", [], "pass", []),
    ("twin_rotating_callee_phase", "y3a", [], "pass", []),
    ("twin_rotating_callee_phase", "y3b", [], "pass", []),
    # Rule 19: a template rail rotated in place is a register; a rule-6 image rotated too; one minted on one classical path only.
    ("twin_register_kinds", "l2", [], "pass", []),
    ("twin_register_kinds", "l3", [], "pass", []),
    ("twin_register_kinds", "l4", [], "pass", []),
    ("twin_register_kinds", "l5", [], "pass", []),
    # Rule 18 (rulings3 F): a rotation in a loop of a by-name callee: no twin of it, of its caller that reads its result either, the
    # results KEPT. Through a rail: _t lists a register per trip, pushes them at its return after its reverse loop, the twin only
    # pops. r3: its result is KEPT by the ruling, as for e_rail above.
    ("twin_rot_in_loop", "r1", [], "pass", [r"\A(?![\s\S]*@__cq_q_f_1_unc)"]),
    ("twin_rot_in_loop", "r2", [], "pass", [r"\A(?![\s\S]*@__cq_q_g_1_unc)(?![\s\S]*@__cq_q_f_1_unc)"]),
    ("twin_rot_in_loop", "r3", [], "pass", [
        r"define internal i32 @__cq_q_h_1_t\((?:(?!\n}\n)[\s\S])*alloca \{ i32, ptr \}(?:(?!\n}\n)[\s\S])*call void @__cq_mints_push",
        r"define internal void @__cq_q_h_1_t_unc\((?:(?!\n}\n|cqrt_ry|_unc\()[\s\S])*call i32 @cqrt_pop\(\)(?:(?!\n}\n|cqrt_free)[\s\S])*\n}\n"]),
    # Rule 16 (rulings3 H): a by-name callee of a table clone is called after an event, its own symbol's path included.
    ("table_called_after", "m1", [], "pass", [r"define internal fastcc i32 @g\((?:(?!\n}\n)[\s\S])*@\.cq\.effect\.srand",
                                              r"define i32 @m1\((?:(?!\n}\n)[\s\S])*@\.cq\.effect\.srand"]),
    ("table_called_after", "m2", [], "pass", [r"define internal fastcc i32 @__cq_q_g2_1\((?:(?!\n}\n)[\s\S])*@\.cq\.effect\.rand"]),
    # cq-c7ej5 (rule 22): memset_pattern4/8/16 is a copy on the bus whose source repeats; a host-resident destination keeps the
    # host call. The C oracle does the writes: a lowering without the stores is rejected.
    ("mp1", "mp1", [], "pass", [r"@cqrt_qram_store_i8_hl\(", r"urem i64 %\d+, 16"]),
    ("mp2", "mp2", [], "pass", [r"@cqrt_qram_store_i8_hl\("]),
    ("mp2", "mp2", [], r"reject: call void @cqrt_qram_store_i8_hl\(", []),
    ("mst", "mst", [], "pass", [r"@cqrt_qram_store_i8_hl_controlled\("]),
    ("mst", "mst", [], r"reject: call void @cqrt_qram_store_i8_hl_controlled\(", []),
    ("mp4", "mp4", [], "pass", [r"call void @memset_pattern16\(ptr %\d+, ptr @\.memset_pattern, i64 32\)"]),
    ("mp5", "mp5", [], "pass", [r"icmp_ugt_i64_hl\(", r"@cqrt_qram_store_i8_hl_controlled\("]),
    # cq-00mrg (rules 16, 22): the fortified forms are the plain ones, and bind to a body the module has. chk2 waits for a
    # bundle with sprintf: rule 16 injects it, the version 1 bundle has none, so it is plain sprintf's effect entry (cq-cdf9z).
    ("chk1", "chk1", [], "pass", [r"@cqrt_qram_store_i8_hl\("]),
    ("chk4", "chk4", [], "pass", [r"@cqrt_qram_store_i8_hl_controlled\("]),
    ("chk3", "chk3", [], "pass", [r"call i32 @__cq_q_sprintf_000\(", r"call ptr @strcpy\("]),
    ("chk2", "chk2", [], "lower", [r"@\.cq\.effect\.sprintf = "]),
    # cq-haf1p (rule 24): oversize atomic libcalls are the ordinary accesses.
    ("at1", "at1", [], "pass", [r"@cqrt_qram_store_i8_hl\("]),
    ("at2", "at2", [], "pass", [r"@cq_template_icmp_eq_i8"]),
    # cq-xc6us (rules 16, 19): a table clone of a variadic function takes the block ptr, at both kinds of pointer.
    ("vaD", "vaD", [], "pass", [r"call i32 %\d+\(i32 %\d+, ptr %\d+, i32 4\)", r"call void %\d+\(i32 %\d+, i32 %\d+, ptr %\d+, i32 4\)"]),
    ("vaC", "vaC", [], "pass", [r"call i32 %\d+\(i32 %\d+, ptr %\d+, i32 4\)"]),
    # cq-f0rb6 (rules 16, 19, 22): va_copy in an own symbol (vget, no quantum argument) of the caller's bus-resident va_list is
    # memcpy(d, s, 24), a bus copy, never the host intrinsic (the evaluator's bus is host memory, so only the form shows it).
    # cq-aa27m (rules 5, 6, 18; CR 556-559): a clone returns the KEPT result of a callee with no twin directly, no copy-out.
    ("kept_result_return", "kept_result_return", [], "pass",
     [r"= call fastcc i32 @vget\(ptr noundef %\d+\)\n  ret i32 %\d+\n}"]),
    ("va_copy_own", "va_copy_own", [], "pass",
     [r"define internal fastcc i32 @vget\(ptr noundef %0\)[^}]*?call i32 @cqrt_qram_load_i8_hl\([^}]*?\n}"]),
    ("vaF", "vaF", [], "pass", [r"call i32 %\d+\(i32 %\d+, i32 %\d+, ptr %\d+, i32 4\)"]),
    # cq-qmqch (rules 5, 18, §6 item 1): a plain store to a host-resident object is a memory version change, so `cal` writes
    # memory: no twin, its results are KEPT by the caller, which §6 names.
    ("hc1", "hc1", [], "pass", [r"call fastcc i32 @__cq_q_cal_10\("]),
    ("hc3", "hc3", [], "pass", []),
    # cq-nupr1 (rule 20, per clone): the entry's load of a host-resident object is classical though the table clone's is a rail;
    # fe6 runs both in one sample.
    ("fe3", "fe3", [], "pass", []),
    ("fe2", "fe2", [], "pass", []),
    ("fe6", "fe6", [], "pass", []),
    # cq-ntvv (CR §1.4: only an internal function with no remaining use is dropped): an exported original whose only in-module
    # call was retargeted to its clone stays, its own body.
    ("extern_original_kept", "e", [], "pass", [r"define i32 @inner\(i32 noundef %0, i32 noundef %1\)"]),
    # cq-rrc52 (CR rule 16): a body the bundle has for fesetround is never lifted for the call: the quantum call is rule 23's
    # rail operation (it reads the host mode with fegetround), no __cq_q_fesetround clone. "lower": the C oracle runs the
    # program's fesetround body where the lowered program has rule 23's call by name (return 1 against the body's -1, the
    # mode rail unrecognised as kept): the checker gap is cq-du1gw.
    ("fenv_body_host", "e", [], "lower", [r"call i32 @fegetround\(\)", r"define [^\n]*@fesetround\("]),
    # cq-ndwfr (rule 23): a strictfp body's 82-ABI clone reached from a caller with no fenv state reads FLAGS (the empty
    # rail it is passed: fetestexcept is the host part alone, as taint has it); a fact one arm of a quantum branch makes a
    # rail (fesetround under the predicate) is a rail in the sibling arm the spine runs after it (rules 9, 23).
    ("fenv_clone_empty_flags", "e", [], "pass", [r"call i32 @fetestexcept\(i32 32\)"]),
    ("fenv_sibling_arm_mode", "e", [], "pass", [r"cq_template_fdiv_f64_\w*rmq\w*\("]),
    # cq-c07bk (rules 8, 9, 23): the arm the spine linearizes first calls a dynamic-mode body with classical arguments; the
    # later arm's fesetround under the predicate does not reach it: the call is the own symbol, as it stands.
    ("fenv_later_arm_mode", "e", [], "pass", [r"call double @nx\(double"]),
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
        elif expect.startswith("frozen: "):
            c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(src), "--lowered",
                                str(PROBES / expect[len("frozen: "):]), "--entry", entry,
                                *(["--samples", str(SAMPLES[probe])] if probe in SAMPLES else [])],
                               capture_output=True, text=True, cwd=ROOT / "checker")
            if c.returncode != 0:
                why.append(f"§6 exited {c.returncode}, expected the frozen lowering accepted: " + c.stdout.strip()[-400:])
        elif expect.startswith("wrong: "):
            c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(src), "--lowered",
                                str(PROBES / expect[len("wrong: "):]), "--entry", entry,
                                *(["--samples", str(SAMPLES[probe])] if probe in SAMPLES else [])],
                               capture_output=True, text=True, cwd=ROOT / "checker")
            if c.returncode != 1:
                why.append(f"§6 exited {c.returncode}, expected the wrong program rejected")
        elif expect.startswith("reject: "):
            cut = re.compile(expect[len("reject: "):])
            kept = [l for l in lowered.read_text().splitlines(keepends=True) if not cut.search(l)]
            if len(kept) == len(lowered.read_text().splitlines()):
                why.append("no line matches " + expect)
            mutant = lowered.with_suffix(".reject.ll")
            mutant.write_text("".join(kept))
            c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(src), "--lowered", str(mutant),
                                "--entry", entry, *(["--samples", str(SAMPLES[probe])] if probe in SAMPLES else [])],
                               capture_output=True, text=True, cwd=ROOT / "checker")
            if c.returncode != 1:
                why.append(f"§6 exited {c.returncode}, expected the wrong program rejected")
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
