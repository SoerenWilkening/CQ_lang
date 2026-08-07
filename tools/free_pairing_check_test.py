#!/usr/bin/env python3
"""free_pairing_check_test.py — MUTANT VALIDATION of tools/free_pairing_check.py.

A checker nobody has tried to fool is a checker nobody should trust: this file
is the "validate it before you rely on it" half of bd test_C_libtooling-8txa,
and it is wired into ctest so the checker cannot silently rot into a rubber
stamp that passes everything.

It runs three layers:

  1. POSITIVE — lowered IR from a committed e2e slice (the file and function are
     named in each docstring; regenerate by running stage 2 of
     tests/e2e/run_slice.sh and copying the function out). Each must verify with
     ZERO findings. This is what stops the checker being tightened into
     something that flags shipped, reviewed lowerings.

     TWO HONEST CAVEATS on "verbatim", both re-measured 2026-07-31:
       * The fixtures carrying `cq_template_..._inv` calls are HISTORICAL, not
         current. Since bd 8txa moved the compare flag-strip onto the void
         `_unc` ABI, the ship floor emits ZERO `_inv` across all 237 registered
         slices. They are kept deliberately: they are now the ONLY exercise the
         (T1b) `_inv` matching arm and the (W) orphan rule get anywhere. Do not
         "refresh" them from today's output — that would silently delete two
         rules' entire coverage. Regenerate them only alongside a replacement.
       * `a2-stable-immediate-bracket` is hand-built, not slice output; the
         emitter cannot produce a rail in a classical-immediate slot at all,
         which is exactly why it needs a planted control.
     Everything else is verbatim, and BREAK_INDEX names its one substitution.

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
        * a RAIL parked in a slot the ABI only ASSERTS is classical (bd az1h)
          -> A1-imm-not-classical. FOUR of them, one per accept-arm of
          `provably_not_a_rail` plus the laundered spelling, because a
          predicate with three arms and one probe lets two arms be deleted with
          a green suite (the arms are individually kill-tested: deleting any
          one turns this file red).
        * the (A1) -> (A2) FALL-THROUGH, which is where that hole would move if
          (A2) cancelled an `xorc` bracket without checking the immediate
          stayed put — planted with a `cqrt_ry` between the two halves, and
          paired with a POSITIVE control whose immediate does stay put so the
          fix cannot be faked by refusing every bracket.
        * a `cqrt_cswap` route-pair cancelling while a rail it WRITES moved
          (bd 0gwl) -> A-not-reducible on the work rail, T2-operand-mutated on
          the base, plus the ticket's own reproducer as a third row. Three
          spellings because the two write slots reach two different rules and
          only the reproducer exits 0 pre-change.
          The rule has FOUR admissions to keep, and each has its own POSITIVE
          control, three of them shipped lowerings rather than hand-built:
            - no intervening write, and DIAGONAL-only intervening writes on the
              co-written rail                                  (PHASE_DIAMOND)
            - intervening writes that REDUCE TO IDENTITY        (VALUE_DIAMOND)
            - intervening writes on the COMPLEMENTARY flag branch
                                                              (IFELSE_DERIVED)
            - the `v == target` skip, where the caller's commutation window and
              this path's disagree            (A2_CO_WRITTEN_TARGET_SKIP, the
              one hand-built control, and the one the FIRST arm-kill round
              missed — see its fixture comment)
          All four are individually kill-tested: deleting any one of them turns
          THIS FILE red, each via a different fixture.
        * one CASE B spelling per write-set in the model (bd 6f3o): a cnot
          whose target is its control, a toffoli whose target is a control, a
          cswap whose flag is one of the two rails it swaps, a cswap that
          writes one rail twice, a copy into its own source, a controlled copy
          into its flag, an `_unc` (template, Phase-6 clone, and QRAM load)
          whose `out` slot is one of its inputs, a classical-immediate update
          whose immediate is the rail it writes, and a QRAM store whose array
          token is its index -> B1/B2. `cqrt_tape_write_<W>` is the one
          modelled write-set with NO committed mutant here, for want of a tape
          fixture; it is covered only by the out-of-band corpus sweep described
          in free_pairing_check.py's VALIDATED BEFORE USE section.

  2b. CASE-A NEGATIVES — the other half of the Case-B validation, and the half
     that actually costs something to get wrong. Aliased INPUTS with a fresh
     output are REALIZABLE (`out ^= f(a,a)` is unitary for any f) and 638 calls
     across 27 template symbols in the committed corpus ship exactly that. Each
     entry plants an aliasing a naive "no operand may repeat" rule would flag
     and asserts NO `B*` finding results. (One shape is asserted WITHOUT a
     plant, and is documented at the table rather than listed in it: an
     in-place gate whose single slot is both read and written, `cqrt_measure`,
     where the aliasing is the signature itself and no mutation can introduce
     it. Every POSITIVE fixture covers that one.)

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
     #
     # POSITIVE CONTROL for two of the four bd 0gwl co-written-slot admissions,
     # and the reason no hand-built fixture was added for them: (i) a co-written
     # rail with NO intervening write (`%h` across the route-pair), and (ii) a
     # co-written rail written only DIAGONALLY — the two `cqrt_rz` on `%rail`
     # sit inside the pair and must stay invisible, because Rz relabels nothing
     # and so cannot invalidate the route-back. A rule that demanded literal
     # operand silence rather than basis-label stability would flag this
     # shipped, reviewed arm. See also `MUTANTS` — the same two lines with a
     # non-diagonal `cqrt_ry` in that slot are the two 0gwl mutants.

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
     #
     # POSITIVE CONTROL for the third bd 0gwl admission: a co-written rail whose
     # intervening writes REDUCE TO IDENTITY rather than being absent. Freeing
     # `%rail` cancels the outer route-pair, whose co-written `%h7` is written
     # twice in between — by the inner `%h_op2` route-pair, which cancels in its
     # own right. So the co-written check has to RECURSE into the same reduction
     # rather than demand an empty write history; a rule that demanded the
     # latter fails this shipped method-B arm.

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
     #
     # POSITIVE CONTROL for the fourth and most expensive bd 0gwl admission, and
     # the fixture the ticket named as the one at risk. Freeing `%rail` cancels
     # its route-pair, and the co-written base `%h` IS genuinely written in
     # between — by the `%rail1` route of the OTHER arm. Only complementary-
     # branch commutation explains why that pair still cancels: the two routes
     # are supported on opposite sides of the `¬flag cqrt_x` bracket, so on the
     # branch where the pair acts the intervening route is the identity.
     # Without that admission this correct, reviewed lowering reports
     # A-not-reducible — i.e. the GATE FAILS A GOOD BUILD, which is the
     # expensive direction for a gate and the reason bd 0gwl was scoped out of
     # the az1h/6f3o change rather than folded into it.

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
define void @run(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %cq.brk.idx = call i32 @cqrt_alloc_i32(i32 0)
  %cq.brk.fire = call i32 @cqrt_alloc_i1(i1 false)
  %6 = add nuw nsw i32 %1, 1
  %cq.brk.k = call i32 @cqrt_alloc_i32(i32 %6)
  call void @cqrt_copy_i32_controlled(i32 %cq.brk.fire, i32 %cq.brk.k, i32 %cq.brk.idx)
  %cq.brk.negk = sub i32 0, %6
  call void @cqrt_addc_i32(i32 %cq.brk.k, i32 %cq.brk.negk)
  call void @cqrt_free(i32 %cq.brk.k)
  ret void
}
"""  # tests/e2e/slice_loop_break.c @run (loop body excerpt) — the dtzb
     # index-gated capture rail: allocated at a CLASSICAL k, brought back by a
     # classical `cqrt_addc`, freed. Rule A1, not a palindrome. The ONE
     # substitution the excerpt makes, because the loop itself is excerpted
     # away: the real `%6 = add nuw nsw i32 %5, 1` counts off the loop's
     # induction phi `%5`, which here is the parameter `%1`. Everything else is
     # the emitted stream verbatim.
     #
     # 2026-07-31 (bd 6f3o): the control slot of the `copy_i32_controlled` used
     # to read `%cq.brk.idx` — the DESTINATION — which the Case-B rule correctly
     # flags. It was a fixture defect, not a finding: the emitter passes the
     # fire flag (BreakReversePlay.cpp `{Fire, Ip1, E.Idx}`), and the real
     # stage-2 output of this very slice is
     #   call void @cqrt_copy_i32_controlled(i32 %cq.brk.fire, i32 %cq.brk.k,
     #                                       i32 %cq.brk.idx)
     # — three distinct rails. Verified against the lowered IR (Rule 11), not
     # against the emitter alone, and repaired to it. The moral is the file's
     # own: an excerpt that is not VERBATIM is a fixture that can teach a
     # checker to accept something the compiler never emits — this one had
     # taught it to accept a shape the compiler has never emitted.

CASE_A_ALIASED = """
define void @slice(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  call void @cqrt_rz_i32(i32 %h, double 2.500000e-01)
  %h_cmp = call i32 @cq_template_icmp_slt_i32(i32 %h, i32 %h)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 11)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  %selop1 = call i32 @cqrt_alloc_i32(i32 22)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_slt_i32_unc(i32 %h_cmp, i32 %h, i32 %h)
  call void @cqrt_free(i32 %h_cmp)
  %m = call i32 @cqrt_measure_i32(i32 %out)
  %h14 = call i32 @cqrt_alloc_f64(double %1)
  call void @cqrt_ry_f64(i32 %h14, double 7.500000e-01)
  call void @cqrt_rz_f64(i32 %h14, double 1.250000e-01)
  %h_cmp2 = call i32 @cq_template_fcmp_olt_f64(i32 %h14, i32 %h14)
  %out3 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %selop4 = call i32 @cqrt_alloc_f64(double 1.000000e+00)
  call void @cqrt_copy_f64_controlled(i32 %h_cmp2, i32 %selop4, i32 %out3)
  call void @cqrt_x(i32 %h_cmp2)
  %selop5 = call i32 @cqrt_alloc_f64(double 2.000000e+00)
  call void @cqrt_copy_f64_controlled(i32 %h_cmp2, i32 %selop5, i32 %out3)
  call void @cqrt_x(i32 %h_cmp2)
  call void @cq_template_fcmp_olt_f64_unc(i32 %h_cmp2, i32 %h14, i32 %h14)
  call void @cqrt_free(i32 %h_cmp2)
  %m18 = call double @cqrt_measure_f64(i32 %out3)
  %h15 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %h15, double 1.000000e-01)
  %h_op = call i32 @cq_template_mul_i32(i32 %h15, i32 %h15)
  %m19 = call i32 @cqrt_measure_i32(i32 %h_op)
  ret void
}
"""  # tests/e2e/slice_select_rail_alias_cond.c @slice — the CASE-A NEGATIVE,
     # and the reason it is here rather than a hand-written aliased line: this
     # is the slice bd big5 UN-FENCED, so every aliased form it ships is
     # reviewed, committed output. It carries all three Case-A spellings at
     # once — an aliased-input template MINT (`icmp_slt_i32(%h, %h)`,
     # `fcmp_olt_f64(%h14, %h14)`, `mul_i32(%h15, %h15)` = `x*x`), the aliased
     # -input `_unc` TWIN of the same compare, and (in the wider corpus) 638
     # more calls of that shape across 27 symbols. The Case-B rule must be
     # SILENT on every one: aliasing the INPUTS of a gate whose output is a
     # fresh |0> rail is unconditionally realizable. If a tightening ever flags
     # this fixture, the tightening is wrong — not the fixture.

# The (A1) -> (A2) FALL-THROUGH must not become the new hiding place. When (A1)
# declines a non-classical immediate it hands the rail to (A2), and (A2) cancels
# adjoint pairs. `cqrt_xorc_<W>` is self-adjoint and declares reads=(), so
# without treating the immediate as an operand whose stability matters, (A2)
# cancels this pair on `key()` equality alone and VERIFIES the very
# entangle-then-free (A1) just refused — the az1h hole moving one rule down
# rather than closing. Found by the bd az1h/6f3o Rule-13 round, 2026-07-31, in
# the fall-through that change introduced. Hand-built (not slice output): the
# emitter cannot produce it, which is exactly why only a planted probe can hold
# the line here.
A2_MOVED_IMMEDIATE = """
define void @f(i32 %u) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  %r = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_xorc_i32(i32 %r, i32 %h)
  call void @cqrt_ry_i32(i32 %h, double 7.500000e-01)
  call void @cqrt_xorc_i32(i32 %r, i32 %h)
  call void @cqrt_free(i32 %r)
  ret void
}
"""

# Its CONTROL: the same bracket with the immediate left alone is genuinely
# self-cancelling and MUST still verify, via (A2). Without this pair the fix
# above could be "passed" by simply refusing every xorc bracket.
A2_STABLE_IMMEDIATE = """
define void @f(i32 %u) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  %r = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_xorc_i32(i32 %r, i32 %h)
  call void @cqrt_xorc_i32(i32 %r, i32 %h)
  call void @cqrt_free(i32 %r)
  ret void
}
"""

# The bd 0gwl `v == target` clause is an ACCEPT-ARM, and this is the fixture that
# proves it. Hand-built, not slice output — like `a2-stable-immediate-bracket`,
# and for the same reason: the emitter does not put a non-`cqrt_x` write on a
# live routing flag, so only a planted control can hold this line.
#
# SHAPE. `%rail` is routed A B A B, the `IFELSE_DERIVED` two-arm pattern, PLUS a
# self-cancelling `cqrt_cnot(%g, %f)` pair on the flag inside the first route.
# That pair is what separates the two commutation windows: the caller licenses
# the intervening write over (w, p2) and sees only a `cqrt_x`, while re-deriving
# the target's own stability here would look over (p1, w) and see two `cqrt_cnot`s.
#
# IT MUST VERIFY, and that is a claim about physics, not about the checker: every
# operator is block-diagonal in `%f`, so on the f=1 block the stream is
# SWAP·I·SWAP·I = I and on the f=0 block I·SWAP·I·SWAP = I, and the `cnot` pair is
# literally the identity. `%rail` is EXACTLY |0> at the free for ANY superposition
# of `%f`. Deleting the clause reports `A-not-reducible` — a gate failing a
# correct build. Found by the bd 0gwl Rule-13 round, which refuted this file's
# own earlier claim that the clause was redundant and could not be distinguished.
A2_CO_WRITTEN_TARGET_SKIP = """
define i32 @slice() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 3)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h2 = call i32 @cqrt_alloc_i32(i32 4)
  call void @cqrt_ry_i32(i32 %h2, double 2.500000e-01)
  %g = call i32 @cqrt_alloc_i1(i1 false)
  %f = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
  %rail = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_cswap(i32 %f, i32 %h, i32 %rail)
  call void @cqrt_cnot(i32 %g, i32 %f)
  call void @cqrt_cnot(i32 %g, i32 %f)
  call void @cqrt_x(i32 %f)
  call void @cqrt_cswap(i32 %f, i32 %h2, i32 %rail)
  call void @cqrt_x(i32 %f)
  call void @cqrt_cswap(i32 %f, i32 %h, i32 %rail)
  call void @cqrt_x(i32 %f)
  call void @cqrt_cswap(i32 %f, i32 %h2, i32 %rail)
  call void @cqrt_x(i32 %f)
  call void @cqrt_free(i32 %rail)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
}
"""

# The bd 0gwl ticket's VERBATIM reproducer, committed so the claim "the old tool
# reported OK via A2-reduces-to-identity, exit 0" names something that can be
# re-run. The two PHASE_DIAMOND-derived mutants below are planted into real
# lowered IR and are the better regression tests, but neither of them is this —
# each carries a second free site that the OLD tool already flagged, so neither
# reproduces the ticket's exit-0 observation on its own.
A2_CO_WRITTEN_TICKET_REPRO = """
define i32 @slice() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 3)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %f = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
  %rail = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_cswap(i32 %f, i32 %h, i32 %rail)
  call void @cqrt_ry_i32(i32 %h, double 7.500000e-01)
  call void @cqrt_cswap(i32 %f, i32 %h, i32 %rail)
  call void @cqrt_free(i32 %rail)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
}
"""

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
    ("case-a-aliased-inputs", CASE_A_ALIASED),
    ("a2-stable-immediate-bracket", A2_STABLE_IMMEDIATE),
    ("a2-co-written-target-skip", A2_CO_WRITTEN_TARGET_SKIP),
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

    # ---- bd az1h: a RAIL in a slot the ABI only ASSERTS is classical -------
    # Rule (A1) used to convert `classify()`'s `classical_imm` declaration
    # straight into a Rule-6 clearance without ever looking at the operand.
    # Neither other gate can see this: at W=i32 both `cqrt_xorc_i32` parameters
    # are `int32_t` (verify-clean) and the runtime prints the immediate slot as
    # a bare decimal, so rail h13 renders as `13` in the golden trace.
    # `provably_not_a_rail` has THREE independent accept-arms, and a probe that
    # only exercises one lets the other two be deleted with a green suite. One
    # mutant per arm (Rule-13 round, 2026-07-31 — the earlier draft had a single
    # witness, and it happened to satisfy two arms at once):
    #   arm 1, `self.rails`     — a value this stream has OBSERVED being used as
    #   a rail (a gate wrote it), reached through a `select` so that it is NOT a
    #   call result and therefore invisible to arms 2 and 3. This is the arm
    #   that still catches a handle laundered through stock integer/select/phi
    #   code, PROVIDED the stream also uses it as a rail somewhere.
    ("a1-immediate-slot-holds-a-laundered-rail",
     sub(insert_after(BREAK_INDEX, "%cq.brk.fire = call",
                      "  %cq.brk.laundered = select i1 true, i32 %cq.brk.idx, "
                      "i32 %cq.brk.idx\n"
                      "  call void @cqrt_x(i32 %cq.brk.laundered)"),
         "@cqrt_addc_i32", "i32 %cq.brk.negk", "i32 %cq.brk.laundered", 0),
     "A1-imm-not-classical"),
    #   arm 1 again, the direct spelling: a rail minted in THIS stream
    ("a1-immediate-slot-holds-a-rail",
     sub(BREAK_INDEX, "@cqrt_addc_i32", "i32 %cq.brk.negk",
         "i32 %cq.brk.idx", 0),
     "A1-imm-not-classical"),
    #   arm 2, `self.params`    — a bare formal parameter, whose rail-ness
    #   arrives from outside and which nothing in this file can vouch for (a
    #   Phase-6 clone's quantum argument and a loop trip count both spell `%0`)
    ("a1-immediate-slot-holds-a-formal-parameter",
     sub(BREAK_INDEX, "@cqrt_addc_i32", "i32 %cq.brk.negk", "i32 %0", 0),
     "A1-imm-not-classical"),
    #   arm 3, `self.rail_defs` — a rail minted elsewhere in the SAME function
    #   but outside this straight-line stream, which `self.rails` cannot see
    ("a1-immediate-slot-holds-a-rail-from-another-stream",
     sub(sub(BREAK_INDEX, "%cq.brk.idx = call", "%cq.brk.idx = call",
             "%cq.brk.idx = call", 0),
         "@cqrt_addc_i32", "i32 %cq.brk.negk", "i32 %cq.brk.other", 0)
     .replace("define void @run(i32 noundef %0, i32 noundef %1) "
              "local_unnamed_addr #0 {",
              "define void @run(i32 noundef %0, i32 noundef %1) "
              "local_unnamed_addr #0 {\n"
              "  %cq.brk.other = call i32 @cqrt_alloc_i32(i32 0)\n"
              "  br label %body\n\nbody:"),
     "A1-imm-not-classical"),

    # ---- bd 6f3o: CASE B — an input aliasing a rail the gate WRITES --------
    # One spelling per write-set in the model. Each is planted into REAL
    # lowered IR, because the shape a checker must reject is the shape an
    # emitter bug produces, not a hand-written approximation of it.
    ("case-b-cnot-target-aliases-control",
     sub(FLAG_NETWORK, "@cqrt_cnot", "i32 %h_cmp2, i32 %g",
         "i32 %g, i32 %g", 0),
     "B1-input-aliases-written-rail"),
    ("case-b-toffoli-target-aliases-control",
     sub(FLAG_NETWORK, "@cqrt_toffoli", "i32 %h_cmp2, i32 %h_cmp3, i32 %g",
         "i32 %g, i32 %h_cmp3, i32 %g", 0),
     "B1-input-aliases-written-rail"),
    # cqrt_cswap writes BOTH x and y, so the flag aliasing EITHER is Case B —
    # this is the SwapRouteEmit.cpp:603 near-miss the bd big5 audit chased
    # (`cswap(c,c,b)` maps both |1,0> and |0,1> to |0,1>: not injective).
    ("case-b-cswap-flag-aliases-a-routed-rail",
     sub(PHASE_DIAMOND, "@cqrt_cswap", "i32 %h_cmp, i32 %h, i32 %rail",
         "i32 %rail, i32 %h, i32 %rail", 0),
     "B1-input-aliases-written-rail"),
    ("case-b-cswap-writes-the-same-rail-twice",
     sub(PHASE_DIAMOND, "@cqrt_cswap", "i32 %h_cmp, i32 %h, i32 %rail",
         "i32 %h_cmp, i32 %rail, i32 %rail", 0),
     "B2-two-written-rails-alias"),
    ("case-b-copy-source-aliases-destination",
     sub(VALUE_DIAMOND, "@cqrt_copy_i32(", "i32 %h7, i32 %out",
         "i32 %out, i32 %out", 0),
     "B1-input-aliases-written-rail"),
    ("case-b-controlled-copy-destination-aliases-the-flag",
     sub(SELECT_MERGE, "@cqrt_copy_i32_controlled",
         "i32 %h_cmp, i32 %h_op1, i32 %cqq.sel",
         "i32 %h_cmp, i32 %h_op1, i32 %h_cmp", 0),
     "B1-input-aliases-written-rail"),
    ("case-b-unc-out-slot-aliases-an-input",
     sub(SELECT_MERGE, "@cq_template_add_i32_hl_unc",
         "i32 %h_op3, i32 %h_op2, i32 300", "i32 %h_op2, i32 %h_op2, i32 300",
         0),
     "B1-input-aliases-written-rail"),
    ("case-b-clone-unc-out-slot-aliases-its-argument",
     sub(CLONE_UNC, "@__cq_q_inner_1_unc", "i32 %2, i32 %0", "i32 %0, i32 %0",
         0),
     "B1-input-aliases-written-rail"),
    # The classical-immediate slot is an INPUT like any other, so the az1h axis
    # and the 6f3o axis meet here: `xorc(%r, %r)` writes %r and reads %r.
    ("case-b-classical-immediate-aliases-the-written-rail",
     sub(BREAK_INDEX, "@cqrt_addc_i32", "i32 %cq.brk.negk", "i32 %cq.brk.k", 0),
     "B1-input-aliases-written-rail"),
    ("case-b-qram-array-token-aliases-the-index",
     sub(QRAM_LOCAL, "@cqrt_qram_store_i32(", "i32 %arr, i32 %h, i32 %qval",
         "i32 %arr, i32 %arr, i32 %qval", 0),
     "B1-input-aliases-written-rail"),
    ("case-b-qram-load-unc-out-slot-aliases-its-array",
     sub(QRAM_LOCAL, "@cqrt_qram_load_i32_unc", "i32 %1, i32 %arr, i32 %h1",
         "i32 %arr, i32 %arr, i32 %h1", 0),
     "B1-input-aliases-written-rail"),

    # ---- the (A1) -> (A2) fall-through must not become the hiding place ----
    ("a2-cancels-an-xorc-bracket-whose-rail-immediate-moved",
     A2_MOVED_IMMEDIATE, "A1-imm-not-classical"),

    # ---- bd 0gwl: the CO-WRITTEN slot of a two-write gate ------------------
    # `pair_operands_unchanged` used to iterate `read_idx()` only, and
    # `cqrt_cswap` is modelled `reads=(0,) writes=(1,2)` (a Fredkin physically
    # reads all three) — so a route-pair cancelled with only the FLAG's
    # stability ever checked. Both spellings below are the same defect on the
    # two different write slots, and they land in two different rules, which is
    # why both are here rather than one standing in for the other. Each was
    # ATTRIBUTED against the pre-change tool rather than assumed: the code
    # asserted is one the checker did NOT emit before this rule existed.
    #
    #   The ticket's VERBATIM reproducer, on its own: routing psi onto %rail
    #   leaves |0> on %h; dirtying %h and routing back parks Ry(0.75)|0> on
    #   %rail, and the free is the hidden measurement Rules 6/8 forbid. THIS is
    #   the module the old tool discharged with `OK ... via
    #   A2-reduces-to-identity` and exit 0 — the row below is not, and an
    #   earlier draft of this comment wrongly attributed that observation to it.
    ("a2-co-written-ticket-reproducer",
     A2_CO_WRITTEN_TICKET_REPRO, "A-not-reducible"),
    #   slot 1, planted into REAL lowered IR — the better regression test, since
    #   hand-written .ll is not the ship floor. Note it is NOT the ticket's
    #   repro: PHASE_DIAMOND carries a second free site (%h_cmp) that the old
    #   tool ALREADY flagged `T2-operand-mutated`, so pre-change this module
    #   exited 1. What is attributable to bd 0gwl is the asserted code —
    #   `A-not-reducible` on %rail is one the old tool did not emit here.
    ("a2-cswap-route-pair-whose-co-written-rail-was-dirtied",
     insert_after(PHASE_DIAMOND, "@cqrt_cswap",
                  "  call void @cqrt_ry_i32(i32 %h, double 7.500000e-01)", 0),
     "A-not-reducible"),
    #   slot 2 — the mirror, reached through (T2) instead of (A2). Dirtying the
    #   WORK rail between the routes means the base %h comes back changed, so
    #   `icmp_sgt_i32_hl_inv(%h, 5)` recomputes a different flag and does not
    #   zero %h_cmp. This is also the row that pins the `v == target` skip to
    #   the right operand: get that backwards and this direction is invisible.
    ("t2-cswap-route-pair-whose-work-rail-was-dirtied",
     insert_after(PHASE_DIAMOND, "@cqrt_cswap",
                  "  call void @cqrt_ry_i32(i32 %rail, double 7.500000e-01)",
                  0),
     "T2-operand-mutated"),
]

# CASE-A NEGATIVES — aliasing that IS realizable and must stay UNFLAGGED.
#
# This table is the load-bearing half of the Case-B validation, not a courtesy.
# The expensive failure mode for an alias rule is a FALSE POSITIVE: 638 calls
# across 27 template symbols in the committed corpus ship aliased inputs
# (`cq_template_fmul_f64(%h, %h)` for `x*x`), plus 15 `_unc` twins of the same
# shape. Each entry below PLANTS an aliasing that a naive "no operand may repeat"
# rule would flag, and asserts NO `B*` finding comes out. Other findings are
# expected and ignored — perturbing a real fixture usually breaks its palindrome
# — so the assertion is precisely "the Case-B rule stayed silent".
CASE_A_NEGATIVES = [
    # out-of-place mint: `out(fresh |0>) ^= f(a, a)` is unitary for ANY f.
    ("case-a-template-mint-with-aliased-inputs",
     sub(PHASE_DIAMOND, "icmp_sgt_i32_hl(", "i32 %h, i32 5", "i32 %h, i32 %h",
         0)),
    # the `_unc` twin of that same forward: out distinct, inputs aliased.
    ("case-a-unc-twin-with-aliased-inputs",
     sub(VALUE_DIAMOND, "@cq_template_mul_i32_hl_unc",
         "i32 %h_op, i32 %rail, i32 5", "i32 %h_op, i32 %rail, i32 %rail", 0)),
    # toffoli(c, c, G) degenerates to cnot(c, G) — a permutation, still unitary.
    ("case-a-toffoli-with-both-controls-the-same",
     sub(FLAG_NETWORK, "@cqrt_toffoli", "i32 %h_cmp2, i32 %h_cmp3, i32 %g",
         "i32 %h_cmp2, i32 %h_cmp2, i32 %g", 0)),
    # A QRAM store's INDEX and VALUE are both reads; aliasing them writes the
    # cell arr[q] with q itself, which is a permutation, not a Case B. Only the
    # ARRAY token is written, and it stays distinct.
    ("case-a-qram-store-index-aliases-value",
     sub(QRAM_LOCAL, "@cqrt_qram_store_i32(", "i32 %arr, i32 %h, i32 %qval",
         "i32 %arr, i32 %h, i32 %h", 0)),
    # An `_unc` twin whose two INPUT slots alias while `out` stays distinct —
    # the shape 15 calls in the committed corpus actually ship.
    ("case-a-qram-load-unc-inputs-aliased",
     sub(QRAM_LOCAL, "@cqrt_qram_load_i32_unc", "i32 %1, i32 %arr, i32 %h1",
         "i32 %1, i32 %arr, i32 %arr", 0)),
]
# NOTE on a row that is deliberately NOT here: "an in-place gate whose one slot
# is both read and written" (`cqrt_measure_<W>(%h)`, reads=(0,) writes=(0,)) has
# nothing to plant — the aliasing is the symbol's own signature, not something a
# mutation can introduce. It is covered instead by every POSITIVE fixture, all of
# which contain a measure and all of which must produce zero findings. An earlier
# draft listed it here as an unmutated copy of PHASE_DIAMOND; that row asserted a
# strict subset of POSITIVE[0] and was removed rather than left looking like
# coverage (bd az1h/6f3o Rule-13 round, 2026-07-31).

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
    n_pos = n_mut = n_sweep = n_neg = 0

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

    # ---- layer 2b: Case-A aliasing must NOT be flagged --------------------
    for name, text in CASE_A_NEGATIVES:
        n_neg += 1
        b = [x for x in findings(text) if x.code.startswith("B")]
        if b:
            fails.append(f"CASE-A NEGATIVE {name}: the Case-B rule fired on "
                         f"realizable aliasing — "
                         + "; ".join(str(x) for x in b))
        elif verbose:
            print(f"  ok  case-A    {name:32s} -> no B* finding")

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
          f"named mutant(s), {n_neg} Case-A negative(s), {n_sweep} "
          f"proof-targeted mutant(s) ({exempt} exempt by rule), "
          f"{len(fails)} failure(s)")
    for x in fails:
        print("  FAIL " + x, file=sys.stderr)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
