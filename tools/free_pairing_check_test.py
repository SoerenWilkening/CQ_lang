#!/usr/bin/env python3
"""free_pairing_check_test.py — MUTANT VALIDATION of tools/free_pairing_check.py.

A checker nobody has tried to fool is a checker nobody should trust: this file
is the "validate it before you rely on it" half of bd test_C_libtooling-8txa,
and it is wired into ctest so the checker cannot silently rot into a rubber
stamp that passes everything.

It runs three layers:

  1. POSITIVE — every fixture below is VERBATIM lowered IR from a committed e2e
     slice (the file and function are named in each docstring; regenerate by
     running stage 2 of tests/e2e/run_slice.sh and copying the function out).
     Each must verify with ZERO findings. This is what stops the checker being
     tightened into something that flags shipped, reviewed lowerings.

  2. NAMED MUTANTS — the three defects bd 8txa says the golden trace CANNOT
     see, plus the lifetime-hygiene family, each planted by hand with the exact
     finding code it must produce:
        * a deleted uncompute toffoli            -> A-not-reducible
        * an `_inv` re-pointed to the wrong rail -> T1-no-reversal
        * a free whose uncompute never ran       -> T1-no-reversal
          (planted by deleting ONE of two TEXTUALLY IDENTICAL `_inv` lines —
          the exact log1pl shape whose golden is byte-stable under this defect
          except for a handle renumber)
        * double free, use after free, free after measure, free of a QRAM
          array token, a stray write after the reversal, a mutated forward
          operand, an orphan `_inv`, an unclassified `cqrt_*` symbol.

  3. PROOF-TARGETED SWEEP — for every free site a fixture VERIFIES, blank each
     source line that site's own proof consumed (`--explain` shows them) and
     assert the module stops verifying clean. This is the layer that catches a
     checker whose rule "passes" for a reason unrelated to the instructions it
     claims to be reading. The one documented exemption is rule
     A1-classical-immediate, where deleting a classical `cqrt_addc` really does
     leave the rail in a (different) known classical basis state and the free
     really does stay Rule-6 sound.

Run: python3 tools/free_pairing_check_test.py [-v]
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import free_pairing_check as fpc  # noqa: E402


# ---------------------------------------------------------------------------
# Fixtures — verbatim stage-2 output. Do not "tidy" these; their value is that
# they are exactly what the pass emits today.
# ---------------------------------------------------------------------------

PHASE_DIAMOND = """
define i32 @slice() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 3)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
  %rail = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_cswap(i32 %h_cmp, i32 %h, i32 %rail)
  call void @cqrt_rz_i32(i32 %rail, double 2.500000e-01)
  call void @cqrt_rz_i32(i32 %rail, double 7.500000e-01)
  call void @cqrt_cswap(i32 %h_cmp, i32 %h, i32 %rail)
  call void @cqrt_free(i32 %rail)
  %h_cmp1 = call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %h, i32 5)
  call void @cqrt_free(i32 %h_cmp)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
}
"""  # tests/e2e/slice_control_phase_diamond.c @slice — the 4.1 routed phase arm.

VALUE_DIAMOND = """
define i32 @slice() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 3)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h7 = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_ry_i32(i32 %h7, double 2.500000e-01)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
  %rail = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_cswap(i32 %h_cmp, i32 %h7, i32 %rail)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %rail, i32 5)
  %h_op1 = call i32 @cq_template_add_i32_hl(i32 %h_op, i32 15)
  %h_op2 = call i32 @cq_template_xor_i32_hl(i32 %h_op1, i32 9)
  call void @cqrt_cswap(i32 %h_cmp, i32 %h7, i32 %h_op2)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h7, i32 %out)
  call void @cqrt_cswap(i32 %h_cmp, i32 %h7, i32 %h_op2)
  call void @cq_template_xor_i32_hl_unc(i32 %h_op2, i32 %h_op1, i32 9)
  call void @cq_template_add_i32_hl_unc(i32 %h_op1, i32 %h_op, i32 15)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %rail, i32 5)
  call void @cqrt_cswap(i32 %h_cmp, i32 %h7, i32 %rail)
  call void @cqrt_free(i32 %rail)
  %h_cmp6 = call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %h, i32 5)
  call void @cqrt_free(i32 %h_cmp)
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
}
"""  # tests/e2e/slice_control_value_diamond.c @slice — 4.2 method-B (chain
     # shortened to 3 links; the `_unc` reverse-play shape is unchanged).

IFELSE_DERIVED = """
define i32 @slice() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 3)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  call void @cqrt_rz_i32(i32 %h, double 9.000000e-01)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
  %rail = call i32 @cqrt_alloc_i32(i32 0)
  %rail1 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_cswap(i32 %h_cmp, i32 %h, i32 %rail)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_cswap(i32 %h_cmp, i32 %h, i32 %rail1)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_rz_i32(i32 %rail, double 2.500000e-01)
  call void @cqrt_rz_i32(i32 %rail, double 1.250000e-01)
  call void @cqrt_rz_i32(i32 %rail1, double 7.500000e-01)
  call void @cqrt_cswap(i32 %h_cmp, i32 %h, i32 %rail)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_cswap(i32 %h_cmp, i32 %h, i32 %rail1)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_free(i32 %rail)
  call void @cqrt_free(i32 %rail1)
  %h_cmp2 = call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %h, i32 5)
  call void @cqrt_free(i32 %h_cmp)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
}
"""  # tests/e2e/slice_control_phase_ifelse_derived.c @slice — the two-arm
     # `¬flag cqrt_x` bracket. `%h` is routed A B A B: only the
     # complementary-branch commutation rule reduces that to identity.

FLAG_NETWORK = """
define double @slice() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_f64(double 5.000000e-01)
  call void @cqrt_ry_f64(i32 %h, double 5.000000e-01)
  %h_cast = call i32 @cq_template_bitcast_f64_to_i64(i32 %h)
  %h_op = call i32 @cq_template_and_i64_hl(i32 %h_cast, i64 9218868437227405312)
  %h_op7 = call i32 @cq_template_and_i64_hl(i32 %h_cast, i64 4503599627370495)
  %h_op8 = call i32 @cq_template_fadd_f64_hl(i32 %h, double -5.000000e-01)
  %h_cmp = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %h, double 5.000000e-01)
  %out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %h_op8, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  %selop = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  %h_cmp1 = call i32 @cq_template_fcmp_ogt_f64_hl_inv(i32 %h, double 5.000000e-01)
  call void @cqrt_free(i32 %h_cmp)
  %h_cmp2 = call i32 @cq_template_icmp_ne_i64_hl(i32 %h_op, i64 9218868437227405312)
  %h_cmp3 = call i32 @cq_template_icmp_eq_i64_hl(i32 %h_op7, i64 0)
  %g = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h_cmp2, i32 %g)
  call void @cqrt_cnot(i32 %h_cmp3, i32 %g)
  call void @cqrt_toffoli(i32 %h_cmp2, i32 %h_cmp3, i32 %g)
  %out4 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64_controlled(i32 %g, i32 %out, i32 %out4)
  call void @cqrt_x(i32 %g)
  call void @cqrt_copy_f64_controlled(i32 %g, i32 %h, i32 %out4)
  call void @cqrt_x(i32 %g)
  call void @cqrt_toffoli(i32 %h_cmp2, i32 %h_cmp3, i32 %g)
  call void @cqrt_cnot(i32 %h_cmp3, i32 %g)
  call void @cqrt_cnot(i32 %h_cmp2, i32 %g)
  call void @cqrt_free(i32 %g)
  %h_cmp5 = call i32 @cq_template_icmp_eq_i64_hl_inv(i32 %h_op7, i64 0)
  call void @cqrt_free(i32 %h_cmp3)
  %h_cmp6 = call i32 @cq_template_icmp_ne_i64_hl_inv(i32 %h_op, i64 9218868437227405312)
  call void @cqrt_free(i32 %h_cmp2)
  %m = call double @cqrt_measure_f64(i32 %out4)
  ret double %m
}
"""  # tests/e2e/slice_libm_real_fdim.c @slice — the PredMux OR ancilla
     # (cnot;cnot;toffoli … toffoli;cnot;cnot on a `cqrt_alloc_i1` rail), which
     # is the conjunction-ancilla palindrome bd 8txa names.

SELECT_MERGE = """
define internal noundef i32 @__cq_q_helper_1(i32 noundef %0) local_unnamed_addr #2 {
  %h_op = call i32 @cq_template_shl_i32_hl(i32 %0, i32 2)
  %h_op1 = call i32 @cq_template_xor_i32_hl(i32 %h_op, i32 9)
  %h_op2 = call i32 @cq_template_mul_i32_hl(i32 %0, i32 3)
  %h_op3 = call i32 @cq_template_add_i32_hl(i32 %h_op2, i32 300)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %0, i32 5)
  %cqq.sel = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op1, i32 %cqq.sel)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op3, i32 %cqq.sel)
  call void @cqrt_x(i32 %h_cmp)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %cqq.sel, i32 %cqq.out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op3, i32 %cqq.sel)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op1, i32 %cqq.sel)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %0, i32 5)
  call void @cq_template_add_i32_hl_unc(i32 %h_op3, i32 %h_op2, i32 300)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op2, i32 %0, i32 3)
  call void @cq_template_xor_i32_hl_unc(i32 %h_op1, i32 %h_op, i32 9)
  call void @cq_template_shl_i32_hl_unc(i32 %h_op, i32 %0, i32 2)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op1)
  call void @cqrt_free(i32 %h_op2)
  call void @cqrt_free(i32 %h_op3)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_free(i32 %cqq.sel)
  ret i32 %cqq.out
}
"""  # tests/e2e/slice_specialize_twoarm_select.c @__cq_q_helper_1 — the 4.4
     # controlled-XOR merge rail, whose four controlled copies pair 1-4 / 2-3
     # only once `cqrt_x` parity is taken MOD 2.

CLONE_UNC = """
define internal i32 @__cq_q_outer_1(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @__cq_q_inner_1(i32 noundef %0) #4
  %h_op = call i32 @cq_template_add_i32_hl(i32 %2, i32 1)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %2, i32 1)
  call void @__cq_q_inner_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}
"""  # tests/e2e/specialize_transitive_*.c @__cq_q_outer_1 — the Phase-6.3
     # transitive `_unc` twin. Note `i32 noundef %0` on the forward and plain
     # `i32 %0` on the twin: parameter attributes must be normalised away or
     # this pairing is missed.

UNCOMPUTE_CHAIN = """
define void @slice(i32 noundef %0, i32 noundef %1, float noundef %2) local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  %h_op = call i32 @cq_template_sub_i32_lh(i32 100, i32 %h)
  %h_op3 = call i32 @cq_template_shl_i32_lh(i32 5, i32 %h_op)
  call void @cqrt_rz_i32(i32 %h_op3, double 5.000000e-01)
  %h2 = call i32 @cqrt_alloc_f32(float %2)
  call void @cqrt_ry_f32(i32 %h2, double 4.000000e-01)
  %h_fneg = call i32 @cq_template_fneg_f32(i32 %h2)
  call void @cqrt_rz_f32(i32 %h_fneg, double 0x3FE6666666666666)
  call void @cqrt_rz_f32(i32 %h_fneg, double 0xBFE6666666666666)
  call void @cq_template_fneg_f32_unc(i32 %h_fneg, i32 %h2)
  call void @cqrt_free(i32 %h_fneg)
  call void @cqrt_ry_f32(i32 %h2, double -4.000000e-01)
  call void @cqrt_free(i32 %h2)
  call void @cqrt_rz_i32(i32 %h_op3, double -5.000000e-01)
  call void @cq_template_shl_i32_lh_unc(i32 %h_op3, i32 5, i32 %h_op)
  call void @cqrt_free(i32 %h_op3)
  call void @cq_template_sub_i32_lh_unc(i32 %h_op, i32 100, i32 %h)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_ry_i32(i32 %h, double -2.500000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
"""  # tests/e2e/slice_uncompute_dead_shapes.c @slice — the Phase-5 whole-DAG
     # LIFO `_unc` spine plus `cq_theta` source rails undone by `ry(-0)`.

QRAM_LOCAL = """
define internal fastcc i32 @measured_local() unnamed_addr #1 {
  %arr = call i32 @cqrt_qram_alloc_i32(i32 8)
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_i32(i32 1)
  call void @cqrt_ry_i32(i32 %h1, double 5.000000e-01)
  %qval = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_qram_store_i32(i32 %arr, i32 %h, i32 %qval)
  %1 = call i32 @cqrt_qram_load_i32(i32 %arr, i32 %h1)
  %qret = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %qret)
  call void @cqrt_qram_load_i32_unc(i32 %1, i32 %arr, i32 %h1)
  call void @cqrt_free(i32 %1)
  call void @cqrt_qram_store_i32_unc(i32 %arr, i32 %h, i32 %qval)
  call void @cqrt_ry_i32(i32 %h1, double -5.000000e-01)
  call void @cqrt_free(i32 %h1)
  call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
  call void @cqrt_free(i32 %h)
  %m = call i32 @cqrt_measure_i32(i32 %qret)
  ret i32 %m
}
"""  # tests/e2e/slice_qram_local_uncompute.c @measured_local — the 7.5 Shadow
     # store/load pair and its LIFO reversal.

IDENTICAL_INV = """
define void @slice() local_unnamed_addr #0 {
  %out46 = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
  %h_op174 = call i32 @cqrt_alloc_i32(i32 0)
  %out59 = call i32 @cqrt_alloc_i32(i32 0)
  %out66 = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
  %out63 = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
  %h_cmp68 = call i32 @cq_template_fcmp_olt_f80_hl(i32 %out46, x86_fp80 0xK3FFEB504F333F9DE6484)
  %out69 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp68, i32 %h_op174, i32 %out69)
  call void @cqrt_x(i32 %h_cmp68)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp68, i32 %out59, i32 %out69)
  call void @cqrt_x(i32 %h_cmp68)
  %h_cmp70 = call i32 @cq_template_fcmp_olt_f80_hl_inv(i32 %out46, x86_fp80 0xK3FFEB504F333F9DE6484)
  call void @cqrt_free(i32 %h_cmp68)
  %h_cmp71 = call i32 @cq_template_fcmp_olt_f80_hl(i32 %out46, x86_fp80 0xK3FFEB504F333F9DE6484)
  %out72 = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
  call void @cqrt_copy_f80_controlled(i32 %h_cmp71, i32 %out66, i32 %out72)
  call void @cqrt_x(i32 %h_cmp71)
  call void @cqrt_copy_f80_controlled(i32 %h_cmp71, i32 %out63, i32 %out72)
  call void @cqrt_x(i32 %h_cmp71)
  %h_cmp73 = call i32 @cq_template_fcmp_olt_f80_hl_inv(i32 %out46, x86_fp80 0xK3FFEB504F333F9DE6484)
  call void @cqrt_free(i32 %h_cmp71)
  ret void
}
"""  # tests/e2e/slice_libm_real_log1pl.c @slice, lines 188-204 — THE
     # motivating shape: two rails, two TEXTUALLY IDENTICAL `_inv` lines. The
     # golden trace distinguishes them only by the fresh return handle, so it
     # is byte-stable (modulo a renumber) under a dropped or swapped reversal.

BREAK_INDEX = """
define void @run(i32 noundef %0) local_unnamed_addr #0 {
  %cq.brk.idx = call i32 @cqrt_alloc_i32(i32 0)
  %cq.brk.k = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_copy_i32_controlled(i32 %cq.brk.idx, i32 %cq.brk.k, i32 %cq.brk.idx)
  %cq.brk.negk = sub i32 0, %0
  call void @cqrt_addc_i32(i32 %cq.brk.k, i32 %cq.brk.negk)
  call void @cqrt_free(i32 %cq.brk.k)
  ret void
}
"""  # tests/e2e/slice_loop_break.c @run (loop body excerpt) — the dtzb
     # index-gated capture rail: allocated at a CLASSICAL k, brought back by a
     # classical `cqrt_addc`, freed. Rule A1, not a palindrome.

POSITIVE = [
    ("phase-diamond", PHASE_DIAMOND),
    ("value-diamond", VALUE_DIAMOND),
    ("ifelse-derived-two-rail", IFELSE_DERIVED),
    ("predmux-flag-network", FLAG_NETWORK),
    ("select-merge-rail", SELECT_MERGE),
    ("clone-unc-twin", CLONE_UNC),
    ("uncompute-lifo-chain", UNCOMPUTE_CHAIN),
    ("qram-store-load-lifo", QRAM_LOCAL),
    ("identical-inv-group", IDENTICAL_INV),
    ("break-index-rail", BREAK_INDEX),
]


# ---------------------------------------------------------------------------
# Mutation helpers.
# ---------------------------------------------------------------------------

def drop(text, needle, nth=0):
    """Blank the nth line containing `needle` (line-preserving deletion)."""
    lines = text.split("\n")
    hits = [i for i, l in enumerate(lines) if needle in l]
    assert len(hits) > nth, f"fixture has no line #{nth} containing {needle!r}"
    lines[hits[nth]] = ""
    return "\n".join(lines)


def sub(text, needle, old, new, nth=0):
    """Replace `old` with `new` inside the nth line containing `needle`."""
    lines = text.split("\n")
    hits = [i for i, l in enumerate(lines) if needle in l]
    assert len(hits) > nth, f"fixture has no line #{nth} containing {needle!r}"
    assert old in lines[hits[nth]], f"{old!r} not in {lines[hits[nth]]!r}"
    lines[hits[nth]] = lines[hits[nth]].replace(old, new, 1)
    return "\n".join(lines)


def insert_after(text, needle, new_line, nth=0):
    lines = text.split("\n")
    hits = [i for i, l in enumerate(lines) if needle in l]
    assert len(hits) > nth, f"fixture has no line #{nth} containing {needle!r}"
    lines.insert(hits[nth] + 1, new_line)
    return "\n".join(lines)


# (name, mutated module, expected finding code)
MUTANTS = [
    # ---- the three defects bd 8txa says the golden trace cannot see --------
    ("deleted-uncompute-toffoli",
     drop(FLAG_NETWORK, "@cqrt_toffoli", 1),
     "A-not-reducible"),
    ("deleted-uncompute-cnot",
     drop(FLAG_NETWORK, "@cqrt_cnot", 2),
     "A-not-reducible"),
    ("inv-repointed-to-wrong-rail",
     sub(IDENTICAL_INV, "fcmp_olt_f80_hl_inv", "i32 %out46", "i32 %out63", 1),
     "T1-no-reversal"),
    ("free-with-no-uncompute-identical-inv-group",
     drop(IDENTICAL_INV, "fcmp_olt_f80_hl_inv", 1),
     "T1-no-reversal"),
    ("free-with-no-uncompute-unc-deleted",
     drop(SELECT_MERGE, "@cq_template_add_i32_hl_unc", 0),
     "T1-no-reversal"),
    ("unc-out-slot-repointed",
     sub(CLONE_UNC, "@__cq_q_inner_1_unc", "i32 %2,", "i32 %h_op,", 0),
     "T1-no-reversal"),
    ("inv-classical-literal-perturbed",
     sub(PHASE_DIAMOND, "icmp_sgt_i32_hl_inv", "i32 5)", "i32 6)", 0),
     "T1-no-reversal"),

    # ---- the reversal ran, but not on the value it was compiled for -------
    ("forward-operand-mutated-before-inv",
     insert_after(PHASE_DIAMOND, "%h_cmp = call", "  call void @cqrt_x(i32 %h)"),
     "T2-operand-mutated"),
    ("rail-written-after-its-reversal",
     insert_after(PHASE_DIAMOND, "icmp_sgt_i32_hl_inv",
                  "  call void @cqrt_x(i32 %h_cmp)"),
     "T3-rail-written-after-reversal"),
    ("half-of-a-not-flag-bracket-deleted",
     drop(SELECT_MERGE, "@cqrt_x(i32 %h_cmp)", 1),
     "A-not-reducible"),
    ("route-back-cswap-deleted",
     drop(PHASE_DIAMOND, "@cqrt_cswap", 1),
     "A-not-reducible"),
    ("adjoint-rotation-sign-flipped",
     sub(UNCOMPUTE_CHAIN, "@cqrt_ry_f32", "double -4.000000e-01",
         "double 4.000000e-01", 1),
     "A-not-reducible"),
    ("adjoint-rotation-deleted",
     drop(UNCOMPUTE_CHAIN, "@cqrt_ry_i32", 1),
     "A-not-reducible"),
    ("orphan-reversal-no-free-claims-it",
     drop(PHASE_DIAMOND, "@cqrt_free(i32 %h_cmp)", 0),
     "W-orphan-reversal"),
    ("qram-load-unc-deleted",
     drop(QRAM_LOCAL, "@cqrt_qram_load_i32_unc", 0),
     "T1-no-reversal"),
    # A Shadow store moved INSIDE the load's live range: the cell the `_unc`
    # un-copies from is no longer the cell the load copied. (Deleting the
    # store's `_unc` twin outright is deliberately NOT in this list — it dirties
    # an array token that is never freed, so it is a real miscompile that the
    # golden trace catches and this file, by its own stated scope, does not.)
    ("qram-cell-stored-inside-the-load-live-range",
     insert_after(drop(QRAM_LOCAL, "@cqrt_qram_store_i32(", 0),
                  "@cqrt_copy_i32(i32 %1",
                  "  call void @cqrt_qram_store_i32(i32 %arr, i32 %h, i32 %qval)"),
     "T2-operand-mutated"),

    # A handle that arrives from outside the stream but is written inside it:
    # its state on entry is unknown, so no in-stream history can discharge it.
    ("free-of-a-rail-minted-outside-the-stream",
     insert_after(
         insert_after(CLONE_UNC, "tail call i32 @__cq_q_inner_1",
                      "  call void @cqrt_x(i32 %0)"),
         "@__cq_q_inner_1_unc", "  call void @cqrt_free(i32 %0)"),
     "U3-extern-rail"),

    # ---- lifetime hygiene, which has no other gate in the project ---------
    ("double-free",
     insert_after(PHASE_DIAMOND, "@cqrt_free(i32 %rail)",
                  "  call void @cqrt_free(i32 %rail)"),
     "F1-double-free"),
    ("use-after-free",
     insert_after(PHASE_DIAMOND, "@cqrt_free(i32 %h_cmp)",
                  "  call void @cqrt_x(i32 %h_cmp)"),
     "F2-use-after-free"),
    ("free-after-measure",
     insert_after(PHASE_DIAMOND, "@cqrt_measure_i32",
                  "  call void @cqrt_free(i32 %h)"),
     "F8-free-after-measure"),
    ("free-of-qram-array-token",
     insert_after(QRAM_LOCAL, "@cqrt_qram_alloc_i32",
                  "  call void @cqrt_free(i32 %arr)"),
     "F9-free-of-nonrail"),
]

# A `cqrt_*` symbol the effect model does not know must abort the run, not be
# quietly skipped: its read/write behaviour is exactly what every verdict rests
# on (the Prime Directive, applied to the checker itself).
UNCLASSIFIED_MUTANT = sub(PHASE_DIAMOND, "@cqrt_cswap", "@cqrt_cswap",
                          "@cqrt_teleport_i32", 0)

# Rules whose proof legitimately survives deletion of a witness line, with the
# reason. A1 says "every write is a classical immediate, so the rail is still a
# known classical basis state" — deleting one classical `cqrt_addc` changes
# WHICH classical state, never whether it is one, so the free stays Rule-6
# sound and the checker is right not to flag it.
SWEEP_EXEMPT_RULES = {"A1-classical-immediate"}


def findings(text):
    f, _v, _s, _p = fpc.check_module(text)
    return f


def main():
    verbose = "-v" in sys.argv
    fails = []
    n_pos = n_mut = n_sweep = 0

    # ---- layer 1: the shipped lowerings must verify clean -----------------
    for name, text in POSITIVE:
        n_pos += 1
        f = findings(text)
        if f:
            fails.append(f"POSITIVE {name}: expected 0 findings, got "
                         + "; ".join(str(x) for x in f))
        elif verbose:
            _f, v, s, _p = fpc.check_module(text)
            print(f"  ok  positive  {name:32s} {v}/{s} free sites verified")

    # ---- layer 2: each named defect must produce its named code -----------
    for name, text, want in MUTANTS:
        n_mut += 1
        codes = [x.code for x in findings(text)]
        if want not in codes:
            fails.append(f"MUTANT {name}: expected {want}, got "
                         + (", ".join(codes) if codes else "NOTHING (survived)"))
        elif verbose:
            print(f"  ok  mutant    {name:32s} -> {want}")
    n_mut += 1
    try:
        findings(UNCLASSIFIED_MUTANT)
        fails.append("MUTANT unclassified-runtime-symbol: expected the run to "
                     "abort, got a verdict")
    except fpc.Unclassified as e:
        if verbose:
            print(f"  ok  mutant    {'unclassified-runtime-symbol':32s} -> {e}")

    # ---- layer 3: blank every line a verified proof rests on --------------
    exempt = 0
    for name, text in POSITIVE:
        lines = text.split("\n")
        base = len(findings(text))
        _f, _v, _s, proofs = fpc.check_module(text)
        for (fn, free_line, handle, rule, wlines) in proofs:
            for wl in wlines:
                if rule in SWEEP_EXEMPT_RULES:
                    exempt += 1
                    continue
                n_sweep += 1
                m = list(lines)
                m[wl - 1] = ""
                if len(findings("\n".join(m))) <= base:
                    fails.append(
                        f"SWEEP {name}: blanking line {wl} "
                        f"({lines[wl-1].strip()!r}), which the proof of "
                        f"{handle} @{fn}:{free_line} ({rule}) consumes, left "
                        f"the module verifying clean")
        if verbose:
            print(f"  ok  sweep     {name:32s} {len(proofs)} proof(s)")

    print(f"free_pairing_check_test: {n_pos} positive fixture(s), {n_mut} "
          f"named mutant(s), {n_sweep} proof-targeted mutant(s) "
          f"({exempt} exempt by rule), {len(fails)} failure(s)")
    for x in fails:
        print("  FAIL " + x, file=sys.stderr)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
