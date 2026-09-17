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
  call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
  %m = call i32 @cqrt_measure_i32(i32 %qret)
  ret i32 %m
}
"""  # tests/e2e/slice_qram_local_uncompute.c @measured_local — the 7.5 Shadow
     # store/load pair and its LIFO reversal.
     #
     # THE INDEX RAILS ARE REVERSE-PLAYED BUT NOT FREED, and this fixture tracks the
     # shipped lowering rather than an invented shape. It used to end
     # `ry(-t); free(%h1); ry(-t); free(%h)`; bd 5pio (owner ruling 2026-08-11) made a
     # `cqrt_copy_<W>` destination a kept carrier for the record freeze, so those two
     # `cq_theta` roots — ancestors of the copy source `%1` — are frozen and left
     # allocated. Keeping the old lines here would have made this POSITIVE fixture
     # assert that a shape the compiler no longer emits must VERIFY, while the rule
     # correctly rejects it. The self-test caught exactly that when the seed landed.
     # `%1` (the load result, a basis permutation of arr/idx) is still freed, which is
     # what keeps this a live free-pairing fixture rather than a leak-only one.

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

# ---------------------------------------------------------------------------
# bd test_C_libtooling-xzdx — VERDICT INVARIANCE UNDER `cqrt_free` ORDER.
#
# The checker memoises `unchanged_over` on `(name, lo, hi)` in a cache that
# lives for the whole STREAM, so it is shared by every free site in it. Until
# 2026-08-08 that function ALSO refused at `depth > 6`, and the depth was not
# part of the key — so a `False` produced by exhausting the budget deep in one
# free's proof was served to a later free whose own proof would have reached the
# same query one level shallower and succeeded. Moving a `cqrt_free` changed the
# answer.
#
# The ladder below is the minimal witness, and every step of it is measured
# rather than asserted (instrumented against the pre-change tool, 2026-08-08):
#
#   frees %R then %c0   PRE: 0 of 2 verified   POST: 2 of 2
#   frees %c0 then %R   PRE: 2 of 2 verified   POST: 2 of 2
#
# In the first order, %R's proof reaches `('%c7', 16, 17)` at depth 7, one past
# the budget, and is cut. That interval is EMPTY — there is no instruction
# between positions 16 and 17 at all, so the honest answer is a trivial "yes,
# unchanged" — yet `False` was cached, propagated up through all seven levels,
# and then handed to %c0's proof as a MEMO HIT. In the second order %c0 asks
# first, from one level up, so the same query lands at depth 6, answers True,
# and %R then reads the True.
#
# Committed as a PAIR because that is the property: not "this file verifies"
# but "these two files agree". A budget re-added anywhere in the recursion turns
# the pair red.
# ---------------------------------------------------------------------------

def order_ladder(D, frees, dirty_at=None):
    """A nested CNOT ladder `D` levels deep, freeing `frees` in that order.

        cnot(%c0, %R)        <- the pair on %R; its READ operand is %c0
          cnot(%c1, %c0)     <- so %c0 must hold still: this pair must cancel,
            ...                 which needs %c1 to hold still, which needs ...
          cnot(%c1, %c0)
        cnot(%c0, %R)

    Proving the outer pair cancels therefore recurses D levels through the
    READS loop of `pair_operands_unchanged` — deliberately that loop and not the
    co-written one, because `unchanged_over` is the MEMOISED edge and the memo
    is where the defect lived.

    `cqrt_cnot` is an involution and the stream is an exact palindrome
    S . reverse(S), so the net unitary is the identity: every rail is back at
    its `cqrt_alloc_i32(0)` value and EVERY free here is Rule-6 sound. That is
    what makes a decline a false positive rather than a taste question.

    `dirty_at=k` plants one `cqrt_ry` (non-diagonal, no adjoint in the stream)
    on %ck at the palindrome centre. Nothing can cancel it, so the level-k
    stability check must fail and the free must NOT verify — the pin that the
    budget was removed rather than the checking disabled.
    """
    L = ["", "define i32 @slice() local_unnamed_addr #0 {",
         "  %R = call i32 @cqrt_alloc_i32(i32 0)"]
    for i in range(D + 1):
        L.append(f"  %c{i} = call i32 @cqrt_alloc_i32(i32 0)")
    fwd = ["  call void @cqrt_cnot(i32 %c0, i32 %R)"]
    for i in range(D):
        fwd.append(f"  call void @cqrt_cnot(i32 %c{i + 1}, i32 %c{i})")
    L += fwd
    if dirty_at is not None:
        L.append(f"  call void @cqrt_ry_i32(i32 %c{dirty_at}, "
                 f"double 5.000000e-01)")
    L += list(reversed(fwd))
    for f in frees:
        L.append(f"  call void @cqrt_free(i32 {f})")
    L += ["  ret i32 0", "}", ""]
    return "\n".join(L)


ORDER_LADDER_RAIL_FIRST = order_ladder(7, ("%R", "%c0"))
ORDER_LADDER_INNER_FIRST = order_ladder(7, ("%c0", "%R"))

# The DEEP positive. 500 levels is far past any budget anyone would re-add by
# hand, so this is the fixture that says the recursion is bounded by INTERVAL
# NARROWING and nothing else. It is also the one that pins
# `ensure_recursion_headroom`: MEASURED 2026-08-08 with this very generator and
# the default limit of 1000, `order_ladder(D)` verifies at D=300 and raises
# `RecursionError` from D=350 once the headroom call is removed — not a finding,
# a traceback, i.e. a correct build failing on a crash. D=500 is chosen to sit
# clear of that wall in any harness, since the frames a caller has already
# pushed count against the same limit.
#   It is deliberately NOT in POSITIVE: layer 3 would blank each of its ~1000
# witness lines in turn and re-check, which buys no new SHAPE (the same ladder
# is swept at D=7) for two orders of magnitude more wall time.
DEEP_LADDER = order_ladder(500, ("%R",))

# The bd xzdx ticket's own reproducer, kept verbatim so its measured claim names
# something re-runnable: 18 gates, an exact palindrome of involutions, differing
# ONLY in where `cqrt_free(i32 %r1)` sits. PRE 2026-08-08: the A file reported 2
# UNPROVEN and exited 1, the B file verified all three sites and exited 0. It is
# a different shape from the ladder — a fuzzer's find, mixing `cqrt_cswap`
# route-pairs (the CO-WRITTEN edge) with `cqrt_cnot` (the READS edge) — so the
# two fixtures do not cover the same path.
XZDX_TICKET_A = """
define i32 @slice() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 3)
  %f0 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 0)
  %f1 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 1)
  %r0 = call i32 @cqrt_alloc_i32(i32 0)
  %r1 = call i32 @cqrt_alloc_i32(i32 0)
  %r2 = call i32 @cqrt_alloc_i32(i32 0)
  %r4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_cswap(i32 %f1, i32 %r1, i32 %r0)
  call void @cqrt_cnot(i32 %r2, i32 %r1)
  call void @cqrt_cswap(i32 %f0, i32 %r2, i32 %r0)
  call void @cqrt_cswap(i32 %f1, i32 %r4, i32 %r1)
  call void @cqrt_cswap(i32 %f0, i32 %r4, i32 %r0)
  call void @cqrt_cswap(i32 %f0, i32 %r2, i32 %r4)
  call void @cqrt_cswap(i32 %f0, i32 %r2, i32 %r0)
  call void @cqrt_cswap(i32 %f1, i32 %r4, i32 %r0)
  call void @cqrt_cswap(i32 %f0, i32 %r4, i32 %r2)
  call void @cqrt_cswap(i32 %f0, i32 %r4, i32 %r2)
  call void @cqrt_cswap(i32 %f1, i32 %r4, i32 %r0)
  call void @cqrt_cswap(i32 %f0, i32 %r2, i32 %r0)
  call void @cqrt_cswap(i32 %f0, i32 %r2, i32 %r4)
  call void @cqrt_cswap(i32 %f0, i32 %r4, i32 %r0)
  call void @cqrt_cswap(i32 %f1, i32 %r4, i32 %r1)
  call void @cqrt_cswap(i32 %f0, i32 %r2, i32 %r0)
  call void @cqrt_cnot(i32 %r2, i32 %r1)
  call void @cqrt_cswap(i32 %f1, i32 %r1, i32 %r0)
  call void @cqrt_free(i32 %r2)
  call void @cqrt_free(i32 %r0)
  call void @cqrt_free(i32 %r1)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
}
"""

XZDX_TICKET_B = XZDX_TICKET_A.replace(
    "  call void @cqrt_free(i32 %r2)\n"
    "  call void @cqrt_free(i32 %r0)\n"
    "  call void @cqrt_free(i32 %r1)\n",
    "  call void @cqrt_free(i32 %r1)\n"
    "  call void @cqrt_free(i32 %r2)\n"
    "  call void @cqrt_free(i32 %r0)\n")
assert XZDX_TICKET_B != XZDX_TICKET_A, "the ticket pair must differ"

def cswap_braid(D):
    """D nested `cqrt_cswap` route pairs over ONE register pair, one flag each.

        cswap(%f0, %A, %B) … cswap(%f19, %A, %B)
        cswap(%f19, %A, %B) … cswap(%f0, %A, %B)      free(%A)

    A palindrome of involutions again, so it verifies — but the interesting
    property is COST, not the verdict. Reducing %A recurses into
    `co_written_stable(%B, …)`, which recurses back into %A over every strictly
    inner window, so the two edges call each other and the same window is
    reachable along 4^(D/2) paths. This is the shape that made the bd xzdx
    Rule-13 round reject the first draft of the budget removal, which left
    `co_written_stable` uncached: at D=20 — SIXTY-THREE calls, a 66-line file —
    it took 44.6 s instead of 0.017 s, and D=30 never finished.
    """
    L = ["", "define i32 @slice() local_unnamed_addr #0 {",
         "  %A = call i32 @cqrt_alloc_i32(i32 0)",
         "  %B = call i32 @cqrt_alloc_i32(i32 0)"]
    for i in range(D):
        L.append(f"  %f{i} = call i32 @cqrt_alloc_i32(i32 0)")
    for i in range(D):
        L.append(f"  call void @cqrt_cswap(i32 %f{i}, i32 %A, i32 %B)")
    for i in reversed(range(D)):
        L.append(f"  call void @cqrt_cswap(i32 %f{i}, i32 %A, i32 %B)")
    L += ["  call void @cqrt_free(i32 %A)", "  ret i32 0", "}", ""]
    return "\n".join(L)


COST_BRAID = cswap_braid(20)

# The memo pin, asserted as a CALL COUNT rather than a wall time so it cannot go
# flaky on a loaded machine. MEASURED 2026-08-08: 381 `co_written_stable` calls
# with the cache, 4^10 - 1 = 1048575 without it. The bound below sits 13x above
# the first and 200x below the second, so it fails only on a real regression.
COST_BRAID_MAX_CO_WRITTEN_CALLS = 5000

# (name, file A, file B) — every free site must get the SAME verdict in both.
ORDER_PAIRS = [
    ("xzdx-ladder-d7-free-order", ORDER_LADDER_RAIL_FIRST,
     ORDER_LADDER_INNER_FIRST),
    ("xzdx-ticket-repro-free-order", XZDX_TICKET_A, XZDX_TICKET_B),
]

# Checked in layer 1 only; see DEEP_LADDER for why it skips the sweep. The braid
# is here for the same reason (a 63-call palindrome has ~40 witness lines per
# proof and the shape is already covered by the ladder sweep) plus one of its
# own: layer 1c re-analyses it under instrumentation, and sweeping it too would
# double that.
# ---------------------------------------------------------------------------
# Inc 2a (bd 6uqc) SHOULD-FIX 2: the two addc immediate spellings beyond plain
# decimals — `i1 true` (self-inverse at width 1) and a symbolic constexpr
# immediate whose adjoint is the explicit `sub (<ty> 0, ...)` negation. Each
# clean module must VERIFY (positives below), and each perturbation must be
# CAUGHT — a pairing rule nobody has tried to fool is a rule nobody may trust.
# ---------------------------------------------------------------------------

ADDC_I1 = """
define void @slice(i1 %x) {
  %h = call i32 @cqrt_alloc_i1(i1 %x)
  call void @cqrt_ry_i1(i32 %h, double 2.500000e-01)
  call void @cqrt_addc_i1(i32 %h, i1 true)
  call void @cqrt_addc_i1(i32 %h, i1 true)
  call void @cqrt_ry_i1(i32 %h, double -2.500000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
"""

ADDC_CONSTEXPR = """
@u = internal global i32 0
define void @slice(i32 %x) {
  %h = call i32 @cqrt_alloc_i32(i32 %x)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  call void @cqrt_addc_i32(i32 %h, i32 ptrtoint (ptr @u to i32))
  call void @cqrt_addc_i32(i32 %h, i32 sub (i32 0, i32 ptrtoint (ptr @u to i32)))
  call void @cqrt_ry_i32(i32 %h, double -2.500000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
"""

# ---------------------------------------------------------------------------
# Inc 2c (bd 6uqc): the SELF-INVERSE in-place gate, `cqrt_xorc_<W>`, on a rail
# that is actually FREED. The checker has always paired `xorc` on `key()`
# equality (`adjoint_of == "self"`), but until 2c that path was exercised only
# by the dtzb LOOP fixtures, whose rails ride `--allow-unproven`. M-C puts the
# gate on straight-line rails inside STRICT slices, so the rule now decides real
# `verified`/`unproven` verdicts and is mutated here for the first time.
#
# XORC_SSA IS THE ONE THAT EARNS ITS PLACE. An SSA-NAMED immediate is the exact
# shape the 2a/2b `addc` analogue CANNOT prove — `is_negation` has no way to
# relate `%v` to `sub iW 0, %v`, so a freed `addc` rail with symbolic immediates
# reports UNPROVEN (recorded in lowering_mc_subc_ssa_imm.ll). Self-inverse needs
# no such predicate: both slots spell `%v`, so this VERIFIES. The mutant proves
# that is a comparison and not a blanket pass — rename the adjoint's immediate
# and the pairing must break.
# ---------------------------------------------------------------------------

XORC_SSA = """
@msk = internal global i32 3
define void @slice(i32 %x) {
  %v = load volatile i32, ptr @msk, align 4
  %w = load volatile i32, ptr @msk, align 4
  %h = call i32 @cqrt_alloc_i32(i32 %x)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  call void @cqrt_xorc_i32(i32 %h, i32 %v)
  call void @cqrt_xorc_i32(i32 %h, i32 %v)
  call void @cqrt_ry_i32(i32 %h, double -2.500000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
"""

XORC_I1 = """
define void @slice(i1 %x) {
  %h = call i32 @cqrt_alloc_i1(i1 %x)
  call void @cqrt_ry_i1(i32 %h, double 2.500000e-01)
  call void @cqrt_xorc_i1(i32 %h, i1 true)
  call void @cqrt_xorc_i1(i32 %h, i1 true)
  call void @cqrt_ry_i1(i32 %h, double -2.500000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
"""

# ---------------------------------------------------------------------------
# bd test_C_libtooling-drbq Inc 0 — the CONTROL-IN-PLACE rotation twins
# `cqrt_{ry,rz}_<W>_controlled(ctrl, handle, angle)`.
#
# These two families left the checker's "unmodelled reserve" list when the epic
# turned §6a control-in-place from an optional peephole into the MECHANISM for a
# tainted-control Ry arm (the swap route cannot carry an Ry at all:
# `Ry(θ)|0⟩ ≠ |0⟩` hands back a dirty rail entangled with the flag). A newly
# modelled symbol is a new claim about what "written" means, so it needs its own
# mutants before any verdict mentioning it is worth anything.
#
# THE PROPERTY UNDER TEST is the Ry/Rz asymmetry, at the new SLOTS: the control
# is arg 0 and the register arg 1, so a model that kept the uncontrolled
# `writes=(0,)` would score the FLAG as the dirtied rail and the register as
# untouched — silently inverting the whole question. CTL_RY_PAIR is the shape
# `EmitInverse` actually emits (same symbol, negated angle, control threaded
# verbatim); the mutants perturb each of its three slots in turn.
CTL_RY_PAIR = """
define void @slice(i32 %x) {
  %f = call i32 @cqrt_alloc_i1(i32 1)
  %h = call i32 @cqrt_alloc_i32(i32 %x)
  call void @cqrt_ry_i32_controlled(i32 %f, i32 %h, double 5.000000e-01)
  call void @cqrt_ry_i32_controlled(i32 %f, i32 %h, double -5.000000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
"""

# The DISCRIMINATION control, and the reason `diagonal=True` on the Rz twin is
# physics and not convenience: an UNPAIRED controlled Rz still leaves the rail
# |0>-clean, because `diag(1, e^{i.theta})` relabels nothing on either branch of
# the flag. The identical file with the `ry` stem is a mutant two lines down.
# Without this control, a model that dropped `diagonal` from the Rz twin — i.e.
# that treated the two stems alike — would still pass every other layer here.
CTL_RZ_UNPAIRED = """
define void @slice(i32 %x) {
  %f = call i32 @cqrt_alloc_i1(i32 1)
  %h = call i32 @cqrt_alloc_i32(i32 %x)
  call void @cqrt_rz_i32_controlled(i32 %f, i32 %h, double 5.000000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
"""

# The REAL emitted stream of `tests/e2e/slice_control_inplace_ry.c` (bd drbq Inc
# 1), verbatim from `cq-opt`, so the slot mutants below run against what the pass
# actually produces rather than against a hand-idealized shape. Its two mutants
# are the round-1 Rule-13 review's own (lens L5, "checker mutation testing"):
# neither the shipped mutant list nor the shipped positives distinguished a
# ctrl/handle SLOT SWAP, which is precisely the mistake `RotationLowering` would
# make by emitting `{Handle, Ctrl, Angle}` and `EmitInverse` by threading
# `CurHandle` into arg 0.
CTL_RY_SLICE = """
define i32 @slice() {
  %h = call i32 @cqrt_alloc_i32(i32 3)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 9.000000e-01)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
  call void @cqrt_free(i32 %h_cmp)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m2 = call i32 @cqrt_measure_i32(i32 %h1)
  %r = add i32 %m2, %m
  ret i32 %r
}
"""

DEEP_POSITIVE = [
    ("xzdx-deep-ladder-d500", DEEP_LADDER),
    ("xzdx-cswap-braid-d20", COST_BRAID),
]

POSITIVE = [
    # Inc 2a addc immediate spellings (bd 6uqc SHOULD-FIX 2) — clean forms VERIFY:
    ("addc-i1-self-inverse", ADDC_I1),
    ("addc-constexpr-negation", ADDC_CONSTEXPR),
    # Inc 2c xorc (bd 6uqc) — the self-inverse gate on a FREED straight-line
    # rail. The SSA-immediate arm is the one `addc` cannot prove (see above).
    ("xorc-ssa-immediate-self-inverse", XORC_SSA),
    ("xorc-i1-self-inverse", XORC_I1),
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
    ("xzdx-ladder-d7-rail-freed-first", ORDER_LADDER_RAIL_FIRST),
    ("xzdx-ladder-d7-inner-freed-first", ORDER_LADDER_INNER_FIRST),
    ("xzdx-ticket-repro-a", XZDX_TICKET_A),
    ("xzdx-ticket-repro-b", XZDX_TICKET_B),
    # bd drbq Inc 0 — the control-in-place rotation twins.
    ("ctl-ry-negated-angle-pair", CTL_RY_PAIR),
    ("ctl-rz-unpaired-is-diagonal", CTL_RZ_UNPAIRED),
    # The shipped e2e slice's own lowered IR — the control for the two slot
    # mutants below (round-1 Rule-13 review, lens L5).
    ("ctl-ry-slice-emitted-stream", CTL_RY_SLICE),
    # ⚠ (T4)'s two shipped-lowering fixtures are APPENDED to this list where
    # they are defined (search `POSITIVE.append`), because they sit below the
    # mutation helpers this file's later sections need. They are in POSITIVE so
    # that layer 3 blanks the lines (T4)'s proof rests on — its mint and its
    # reversal — and requires the proof to break.
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

# ---- bd 261j(b): the RECORDED-RAIL rule (R1) -------------------------------
#
# THE MUTANTS THIS FILE ADMITTED IT LACKED. The docstring above says
# `cqrt_tape_write_<W>` is "the one modelled write-set with NO committed mutant
# here, for want of a tape fixture". These are it — and they are not synthetic
# shapes invented to exercise a rule: TAPE_RECORDED_RY is the lowering the compiler
# ACTUALLY EMITTED before bd 261j(a), which four different proof rules of this very
# file certified as sound (`A2-reduces-to-identity`, `T1-unc-reversal`, and two more
# found on `p_i8`/`p_qram_qidx` shapes). A checker that certifies a shipped hidden
# measurement through four independent paths is the strongest possible argument for
# a rule that does not go through any of them.
#
# The NEGATIVES matter as much as the positive, because a rule that declines the bad
# input is worthless if it also declines the good one. Each isolates one conjunct:
#   * TAPE_RECORDED_RZ    — diagonal rotation, trivial on |0>, must VERIFY.
#   * TAPE_RECORDED_DERIV — the DERIVED rail whose free bd 261j(a) deliberately KEPT
#     (lowering_io_tape_derived_uncompute.ll); recorded, but its own chain is a
#     template permutation, so it must VERIFY. This is the discrimination case: a
#     rule keyed on "recorded" alone drops it.
#   * ROTATED_NO_TAPE     — an Ry rail with no record at all, must VERIFY.
TAPE_RECORDED_RY = """
define void @io(i32 %u0) {
  %h = call i32 @cqrt_alloc_i32(i32 %u0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %t = call i32 @cqrt_tape_alloc()
  %w = call i32 @cqrt_tape_write_i32(i32 %t, i32 %h)
  call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
"""

TAPE_RECORDED_RY_CTRL = """
define void @io(i32 %u0, i32 %s) {
  %h = call i32 @cqrt_alloc_i32(i32 %u0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %t = call i32 @cqrt_tape_alloc()
  %w = call i32 @cqrt_tape_write_i32_controlled(i32 %h, i32 %t, i32 %s)
  call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
"""

TAPE_RECORDED_CHAINED = """
define void @chained(i32 %u0) {
  %h = call i32 @cqrt_alloc_i32(i32 %u0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %o = call i32 @cq_template_add_i32_hl(i32 %h, i32 1)
  call void @cqrt_ry_i32(i32 %o, double 2.500000e-01)
  %t = call i32 @cqrt_tape_alloc()
  %w = call i32 @cqrt_tape_write_i32(i32 %t, i32 %o)
  call void @cqrt_ry_i32(i32 %o, double -2.500000e-01)
  call void @cq_template_add_i32_hl_unc(i32 %o, i32 %h, i32 1)
  call void @cqrt_free(i32 %o)
  ret void
}
"""

TAPE_RECORDED_RZ = TAPE_RECORDED_RY.replace("cqrt_ry_i32", "cqrt_rz_i32")

TAPE_RECORDED_DERIV = """
define void @derived(i32 %u0) {
  %h = call i32 @cqrt_alloc_i32(i32 %u0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %o = call i32 @cq_template_add_i32_hl(i32 %h, i32 1)
  %t = call i32 @cqrt_tape_alloc()
  %w = call i32 @cqrt_tape_write_i32(i32 %t, i32 %o)
  call void @cq_template_add_i32_hl_unc(i32 %o, i32 %h, i32 1)
  call void @cqrt_free(i32 %o)
  ret void
}
"""

ROTATED_NO_TAPE = """
define void @norec(i32 %u0) {
  %h = call i32 @cqrt_alloc_i32(i32 %u0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
"""

# The ANCESTOR case, and the only one that exercises the BACKWARD CLOSURE: the tape
# records the DESCENDANT `%o`, whose own free is sound (a template permutation), while
# the rotated ANCESTOR `%h` is correlated only through the closure. Added because the
# arm-kill matrix measured that without it, deleting the closure entirely left this
# file GREEN — the other three mutants all record the rotated rail directly.
TAPE_RECORDED_ANCESTOR = """
define void @ancestor(i32 %u0) {
  %h = call i32 @cqrt_alloc_i32(i32 %u0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %o = call i32 @cq_template_add_i32_hl(i32 %h, i32 1)
  %t = call i32 @cqrt_tape_alloc()
  %w = call i32 @cqrt_tape_write_i32(i32 %t, i32 %o)
  call void @cq_template_add_i32_hl_unc(i32 %o, i32 %h, i32 1)
  call void @cqrt_free(i32 %o)
  call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
"""

# bd 5pio (owner ruling 2026-08-11): a `cqrt_copy_<W>` DESTINATION is a kept carrier
# too, so the copy surface seeds R1 exactly as the tape does. These four fixtures are
# the gate validation for that seed — without them the seed is an unexercised rule.
#
# COPY_RECORDED_RY is the canonical hazard the ruling exists to stop, and it is the
# shape the PASS now refuses to emit (`ry(%h); copy(%h,%dst); ry(-%h); free(%h)`).
# Before the seed this checker CERTIFIED it — "2 verified, 0 violations", rc=0.
COPY_RECORDED_RY = """
define void @cp(i32 %u0) {
  %h = call i32 @cqrt_alloc_i32(i32 %u0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %dst = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h, i32 %dst)
  call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
"""

# The ANCESTOR arm, which is where the ruling's whole measured effect actually landed
# (9 lit fixtures + 6 e2e goldens): the copied rail is a template permutation and is
# freeable, but its Ry ROOT is correlated through it and must not be freed.
COPY_RECORDED_ANCESTOR = """
define void @cp(i32 %u0) {
  %h = call i32 @cqrt_alloc_i32(i32 %u0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %o = call i32 @cq_template_add_i32_hl(i32 %h, i32 1)
  %dst = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %o, i32 %dst)
  call void @cq_template_add_i32_hl_unc(i32 %o, i32 %h, i32 1)
  call void @cqrt_free(i32 %o)
  call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
"""

# NEGATIVE — the DISCRIMINATION case, and the reason the seed is slot-AWARE. `%h` is
# the copy DESTINATION, not its source; it records nothing, so a rule keyed on "is an
# operand of a copy" would wrongly drop it. Must VERIFY.
COPY_DEST_SLOT_RY = """
define void @cp(i32 %u0) {
  %src = call i32 @cqrt_alloc_i32(i32 %u0)
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  call void @cqrt_copy_i32(i32 %src, i32 %h)
  call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
"""

# NEGATIVE — a copy-recorded rail whose own chain IS a basis permutation. Recorded but
# still freeable, exactly like TAPE_RECORDED_DERIV on the tape surface: a rule keyed on
# "recorded" alone drops it.
COPY_RECORDED_DERIV = """
define void @cp(i32 %u0) {
  %h = call i32 @cqrt_alloc_i32(i32 %u0)
  %o = call i32 @cq_template_add_i32_hl(i32 %h, i32 1)
  %dst = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %o, i32 %dst)
  call void @cq_template_add_i32_hl_unc(i32 %o, i32 %h, i32 1)
  call void @cqrt_free(i32 %o)
  ret void
}
"""

# bd drbq Inc 0 — the R1 recorded-rail rule reaches the CONTROLLED Ry too. R1
# keys on `w.sym.startswith("cqrt_ry_")` over the target rail's WRITE history,
# so it only sees this gate at all because the model puts the write in slot 1;
# a slot-0 model would have recorded the flag as the rotated rail and left the
# register's history empty, and this fixture would have certified clean. The
# negated-angle pair reduces to identity, exactly as in CTL_RY_PAIR — which is
# the point: R1 fires REGARDLESS of the proof rules, because the tape record is
# never restored and the rail is entangled with it (Rules 5/6/8).
CTL_RY_RECORDED = """
define void @rec(i32 %x) {
  %f = call i32 @cqrt_alloc_i1(i32 1)
  %h = call i32 @cqrt_alloc_i32(i32 %x)
  call void @cqrt_ry_i32_controlled(i32 %f, i32 %h, double 5.000000e-01)
  %t = call i32 @cqrt_tape_alloc()
  %w = call i32 @cqrt_tape_write_i32(i32 %t, i32 %h)
  call void @cqrt_ry_i32_controlled(i32 %f, i32 %h, double -5.000000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
"""

# NEGATIVE control for the above: the same record on a rail written only by the
# DIAGONAL controlled Rz. R1 must stay silent (an `rz` never enters a write
# history at all — `if not e.diagonal` — so this also witnesses the Rz twin's
# `diagonal=True` one layer below where CTL_RZ_UNPAIRED witnesses it).
CTL_RZ_RECORDED = """
define void @rec(i32 %x) {
  %f = call i32 @cqrt_alloc_i1(i32 1)
  %h = call i32 @cqrt_alloc_i32(i32 %x)
  call void @cqrt_rz_i32_controlled(i32 %f, i32 %h, double 5.000000e-01)
  %t = call i32 @cqrt_tape_alloc()
  %w = call i32 @cqrt_tape_write_i32(i32 %t, i32 %h)
  call void @cqrt_free(i32 %h)
  ret void
}
"""

RECORD_MUTANTS = [
    # ---- Inc 2c xorc: the self-inverse pairing must be a COMPARISON ---------
    # If `key()` equality were not actually checked, both of these would pass.
    ("xorc-ssa-adjoint-names-a-different-value",
     XORC_SSA.replace("call void @cqrt_xorc_i32(i32 %h, i32 %v)\n"
                      "  call void @cqrt_xorc_i32(i32 %h, i32 %v)",
                      "call void @cqrt_xorc_i32(i32 %h, i32 %v)\n"
                      "  call void @cqrt_xorc_i32(i32 %h, i32 %w)"),
     "A-not-reducible"),
    ("xorc-i1-adjoint-flipped-to-false",
     XORC_I1.replace("call void @cqrt_xorc_i1(i32 %h, i1 true)\n"
                     "  call void @cqrt_xorc_i1(i32 %h, i1 true)",
                     "call void @cqrt_xorc_i1(i32 %h, i1 true)\n"
                     "  call void @cqrt_xorc_i1(i32 %h, i1 false)"),
     "A-not-reducible"),
    # ---- Inc 2a addc immediate spellings: each perturbation must be caught --
    ("addc-i1-adjoint-flipped-to-false",
     ADDC_I1.replace("call void @cqrt_addc_i1(i32 %h, i1 true)\n  call void @cqrt_addc_i1(i32 %h, i1 true)",
                     "call void @cqrt_addc_i1(i32 %h, i1 true)\n  call void @cqrt_addc_i1(i32 %h, i1 false)"),
     "A-not-reducible"),
    ("addc-constexpr-adjoint-wrong-global",
     ADDC_CONSTEXPR.replace("@u = internal global i32 0",
                            "@u = internal global i32 0\n@v = internal global i32 0")
                   .replace("i32 sub (i32 0, i32 ptrtoint (ptr @u to i32))",
                            "i32 sub (i32 0, i32 ptrtoint (ptr @v to i32))"),
     "A-not-reducible"),
    ("addc-constexpr-adjoint-missing-negation",
     ADDC_CONSTEXPR.replace("i32 sub (i32 0, i32 ptrtoint (ptr @u to i32))",
                            "i32 ptrtoint (ptr @u to i32)"),
     "A-not-reducible"),
    ("tape-recorded-ancestor-via-closure", TAPE_RECORDED_ANCESTOR,
     "R1-recorded-rotated-rail"),
    ("tape-recorded-ry-rail", TAPE_RECORDED_RY, "R1-recorded-rotated-rail"),
    ("tape-recorded-ry-ctrl-slot", TAPE_RECORDED_RY_CTRL,
     "R1-recorded-rotated-rail"),
    ("tape-recorded-chained-theta", TAPE_RECORDED_CHAINED,
     "R1-recorded-rotated-rail"),
    ("copy-recorded-ry-rail", COPY_RECORDED_RY, "R1-recorded-rotated-rail"),
    ("copy-recorded-ancestor-via-closure", COPY_RECORDED_ANCESTOR,
     "R1-recorded-rotated-rail"),
    ("ctl-ry-recorded-rail", CTL_RY_RECORDED, "R1-recorded-rotated-rail"),
]

RECORD_POSITIVES = [
    ("ctl-rz-recorded-diagonal", CTL_RZ_RECORDED),
    ("tape-recorded-rz-diagonal", TAPE_RECORDED_RZ),
    ("tape-recorded-derived-permutation", TAPE_RECORDED_DERIV),
    ("rotated-rail-no-record", ROTATED_NO_TAPE),
    ("copy-destination-slot-not-recorded", COPY_DEST_SLOT_RY),
    ("copy-recorded-derived-permutation", COPY_RECORDED_DERIV),
]


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

    # ---- bd drbq Inc 0: the control-in-place rotation twins ---------------
    # One mutant per SLOT of `cqrt_ry_<W>_controlled(ctrl, handle, angle)`,
    # because the whole modelling decision is which slot means what.
    #  * angle slot (2): the adjoint tag is `negate-arg2`, not the uncontrolled
    #    `negate-arg1` — a copy-paste of the uncontrolled Effect would compare
    #    the HANDLE for negation and the ANGLE for equality, and would then
    #    certify a same-sign pair as a reversal. That is this mutant.
    #  * control slot (0): the adjoint must run under the SAME flag. A pair
    #    split across two flags composes to nothing on either branch alone.
    #  * the gate itself: deleting the adjoint outright must decline — the base
    #    check that the register is modelled as WRITTEN at all (a slot-0 model
    #    would score the flag as the dirty rail and pass this).
    ("ctl-ry-adjoint-angle-sign-not-flipped",
     sub(CTL_RY_PAIR, "@cqrt_ry_i32_controlled", "double -5.000000e-01",
         "double 5.000000e-01", 1),
     "A-not-reducible"),
    ("ctl-ry-adjoint-under-a-different-flag",
     insert_after(CTL_RY_PAIR, "%f = call",
                  "  %f2 = call i32 @cqrt_alloc_i1(i32 1)")
     .replace("i32 %f, i32 %h, double -5.000000e-01",
              "i32 %f2, i32 %h, double -5.000000e-01"),
     "A-not-reducible"),
    ("ctl-ry-adjoint-deleted",
     drop(CTL_RY_PAIR, "double -5.000000e-01", 0),
     "A-not-reducible"),
    # The Rz twin's DISCRIMINATION mutant: the same unpaired-rotation-then-free
    # shape that VERIFIES for `rz` (CTL_RZ_UNPAIRED, a POSITIVE) must DECLINE
    # for `ry`. Committed as a pair with that positive — neither half states the
    # property on its own.
    ("ctl-ry-unpaired-is-not-diagonal",
     CTL_RZ_UNPAIRED.replace("@cqrt_rz_i32_controlled",
                             "@cqrt_ry_i32_controlled"),
     "A-not-reducible"),
    # ---- round-1 Rule-13 review (lens L5): the two SLOT-SWAP mutants the
    # shipped list did not have. The whole modelling decision for this family is
    # "arg 1 is the rail, arg 0 is the control", and nothing here tested it on
    # the pass's REAL output.
    #  * FORWARD swap — what `RotationLowering` would emit if it built the call
    #    as `{Handle, Ctrl, Angle}`. The gate then writes the FLAG rail, which
    #    the strip `_unc` cannot zero, so the flag's `cqrt_free` is a hidden
    #    measurement. A slot-0 write model would leave the register's history
    #    EMPTY and score this clean.
    ("ctl-ry-slice-ctrl-and-handle-slots-swapped",
     CTL_RY_SLICE.replace("i32 %h_cmp, i32 %h1, double 9.000000e-01",
                          "i32 %h1, i32 %h_cmp, double 9.000000e-01"),
     "T3-rail-written-before-reversal"),
    #  * ADJOINT-ONLY swap — the exact `EmitInverse` bug its own comment warns
    #    about (a `CurHandle` relabel applied to arg 0 instead of arg 1). The
    #    forward gate is correct, so only the reversal is wrong: the rail is
    #    rotated and never un-rotated, and the free is dirty.
    ("ctl-ry-adjoint-slots-swapped",
     CTL_RY_PAIR.replace("i32 %f, i32 %h, double -5.000000e-01",
                         "i32 %h, i32 %f, double -5.000000e-01"),
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

    # ---- bd xzdx: deep is still CHECKED, not waved through ----------------
    # Removing the depth budget must not become "stop looking past depth 6".
    # Both defects sit at the BOTTOM of a 7-level ladder, where the pre-change
    # tool declined for the wrong reason (it ran out of budget) and where a
    # tool that had simply stopped recursing would now report OK.
    ("deep-nest-dirtied-at-the-bottom",
     order_ladder(7, ("%R",), dirty_at=7),
     "A-not-reducible"),
    ("deep-nest-innermost-adjoint-deleted",
     drop(ORDER_LADDER_RAIL_FIRST, "@cqrt_cnot(i32 %c7", 1),
     "A-not-reducible"),
    # A self-aliased `cqrt_cnot` is a Case-B input and must be reported as one.
    # It is committed here for a SECOND reason, so that it is greppable: it is
    # the arm-kill probe for the `unchanged_over` re-entry assertion, and the
    # only one that works. The obvious way to break the narrowing invariant —
    # weakening `writes_in` to `lo <= p <= hi` — runs away through
    # `co_written_stable` on every `cqrt_cswap`-bearing fixture, so it kills the
    # OTHER guard and leaves this one standing. This module has no `cqrt_cswap`
    # at all, so `co_written_stable` is never entered; the aliased `%a` is both
    # a READ and a written rail of the same call, which is what lets the READS
    # edge re-enter its own query. Under that mutation the shipped tool raises
    # `NarrowingViolation` naming `('%a', 3, 4)`; with the assertion deleted the
    # same input dies on a `RecursionError` that names nothing.
    ("case-b-self-aliased-cnot-aka-the-narrowing-probe", """
define i32 @slice() local_unnamed_addr #0 {
  %a = call i32 @cqrt_alloc_i32(i32 0)
  %r = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_cnot(i32 %a, i32 %r)
  call void @cqrt_cnot(i32 %a, i32 %a)
  call void @cqrt_cnot(i32 %a, i32 %a)
  call void @cqrt_cnot(i32 %a, i32 %r)
  call void @cqrt_free(i32 %r)
  ret i32 0
}
""", "B1-input-aliases-written-rail"),

    # …and the same defect 500 levels down, because the two rows above only
    # reach depth 7. A regression that stops recursing past ANY depth N >= 9 and
    # answers TRUE — the unsound direction, the one a re-added budget would take
    # if someone "optimised" it the wrong way — leaves the D=500 POSITIVE
    # verifying and every shallow mutant caught, so without this row the suite
    # would be entirely green. Found by the bd xzdx Rule-13 round.
    ("deep-nest-dirtied-500-levels-down",
     order_ladder(500, ("%R",), dirty_at=500),
     "A-not-reducible"),

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
# ---------------------------------------------------------------------------
# bd test_C_libtooling-21re — THE RAIL-BANK MEMORY SURFACE.
#
# WHY THESE ARE HAND-BUILT AND MUST STAY SO FOR NOW. bd `xdu2` (L-1a) carves
# `bool b[N]` into an `[N x i32]` bank of rail HANDLES marked `!cq.railbank`.
# Track A ships the CLASSIFIER this session while the taint rule and the type
# rewrite are DELIBERATELY DEFERRED (BRIEF_A §0), so NO compiler in the tree can
# emit a `!cq.railbank` load today. A checker fix with no subject is the vacuity
# trap in its purest form, so the subjects are written by construction and the
# committed `.ll` copies live in
#   docs/prd/.../session-2026-09-14c-xdu2-w1/trackI/probes/p{1..6}*.ll
#
# ⚠ L8 RETIREMENT TRIGGER: when L-1a's taint rule + type rewrite + D5 allow-list
# land (bd `xdu2`, the second half), a real slice produces these shapes; re-derive
# every fixture below against it then, and re-derive (L3)'s measure-only
# exemption against the allow-list the pass actually ships. Do NOT delete them.
#
# WHAT THE PRE-FIX TOOL DID, MEASURED (this is the defect, not a hypothetical):
#   p1  bank load in a classical-immediate slot -> `OK ... via A1-classical-immediate`, exit 0
#   p2  bank load as a gate CONTROL             -> `OK ... via A2-reduces-to-identity`, exit 0
#   p5  rail stored to unmarked memory          -> 1 verified, exit 0
#   p6  bank in scope, unresolvable load base   -> 1 verified, exit 0
# ---------------------------------------------------------------------------

# POSITIVE: the D5-sanctioned shape — a bank cell is stored, loaded, and the
# load's ONLY use is the user's `cq_measure`. This is the L-1a design target
# (SCOPE_L1a's TARGET_rolled_stage2.ll, trimmed to one cell and one trip). A
# checker that refuses the increment's own emitted shape is an over-decline.
BANK_MEASURE_ONLY = """
define i32 @slice() local_unnamed_addr {
entry:
  %bank = alloca [1 x i32], align 4, !cq.railbank !0
  %ha = call i32 @cqrt_alloc_i32(i32 5)
  %f = call i32 @cq_template_icmp_sgt_i32_hl(i32 %ha, i32 2)
  %hb = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1_controlled(i32 %f, i32 %hb, double 5.000000e-01)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %f, i32 %ha, i32 2)
  call void @cqrt_free(i32 %f)
  %cell = getelementptr inbounds [1 x i32], ptr %bank, i64 0, i64 0
  store i32 %hb, ptr %cell, align 4
  %v = load i32, ptr %cell, align 4
  %m = call i1 @cqrt_measure_i1(i32 %v)
  %z = zext i1 %m to i32
  ret i32 %z
}
!0 = !{!"i1"}
"""

# POSITIVE, and the DISCRIMINATION control that earns the rule its precision:
# a bank IS in scope, and a SECOND load — from an unmarked global — still lands
# in a classical-immediate slot and must still discharge (A1). Without this
# fixture, "refuse every load whenever a bank is in the module" would pass every
# other row here, and it would over-decline the 4 real `load volatile i32,
# ptr @off` corpus sites the docstring names.
BANK_PLUS_CLASSICAL_LOAD = """
@off = internal global i32 3
define i32 @slice() local_unnamed_addr {
entry:
  %bank = alloca [1 x i32], align 4, !cq.railbank !0
  %hb = call i32 @cqrt_alloc_i1(i1 false)
  %cell = getelementptr inbounds [1 x i32], ptr %bank, i64 0, i64 0
  store i32 %hb, ptr %cell, align 4
  %k = load volatile i32, ptr @off, align 4
  %r = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_addc_i32(i32 %r, i32 %k)
  call void @cqrt_free(i32 %r)
  %v = load i32, ptr %cell, align 4
  %m = call i1 @cqrt_measure_i1(i32 %v)
  %z = zext i1 %m to i32
  ret i32 %z
}
!0 = !{!"i1"}
"""

# POSITIVE: the bank is a module-scope GLOBAL reached by a CONSTANT-EXPRESSION
# getelementptr — the other spelling of the same object, and the one whose
# pointer operand is nested inside the load's own text. It exercises the
# `bank_globals` arm and `first_ptr_operand`'s constexpr path together.
BANK_GLOBAL_CONSTEXPR = """
@bank = internal global [2 x i32] zeroinitializer, align 4, !cq.railbank !0
define i32 @slice() local_unnamed_addr {
entry:
  %hb = call i32 @cqrt_alloc_i1(i1 false)
  store i32 %hb, ptr getelementptr inbounds ([2 x i32], ptr @bank, i64 0, i64 1), align 4
  %v = load i32, ptr getelementptr inbounds ([2 x i32], ptr @bank, i64 0, i64 1), align 4
  %m = call i1 @cqrt_measure_i1(i32 %v)
  %z = zext i1 %m to i32
  ret i32 %z
}
!0 = !{!"i1"}
"""

# --- the four defects, one per arm -----------------------------------------

# (A1's checked slot) bd `az1h` through a NEW DOOR. Pre-fix: `OK ... via
# A1-classical-immediate`, exit 0, with %r freed while entangled with %hb.
BANK_IMM_SLOT = """
define i32 @slice() local_unnamed_addr {
entry:
  %bank = alloca [1 x i32], align 4, !cq.railbank !0
  %hb = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %hb, double 5.000000e-01)
  %cell = getelementptr inbounds [1 x i32], ptr %bank, i64 0, i64 0
  store i32 %hb, ptr %cell, align 4
  %r = call i32 @cqrt_alloc_i32(i32 7)
  %v = load i32, ptr %cell, align 4
  call void @cqrt_xorc_i32(i32 %r, i32 %v)
  call void @cqrt_free(i32 %r)
  %m = call i1 @cqrt_measure_i1(i32 %hb)
  %z = zext i1 %m to i32
  ret i32 %z
}
!0 = !{!"i1"}
"""

# (L3) the bead's own example: a bank load as a gate CONTROL, with the rail
# flipped through its MINT name between the two halves of the pair. The write
# history is keyed on the SSA operand string, so %v's history is EMPTY and the
# pair "cancels" — pre-fix `OK ... via A2-reduces-to-identity`, exit 0, while %o
# is left holding %r's value. This one never reaches `provably_not_a_rail` at
# all, which is why the fix cannot be a one-line edit to that predicate.
BANK_CONTROL_SLOT = """
define i32 @slice() local_unnamed_addr {
entry:
  %bank = alloca [1 x i32], align 4, !cq.railbank !0
  %hb = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %hb, double 5.000000e-01)
  %cell = getelementptr inbounds [1 x i32], ptr %bank, i64 0, i64 0
  store i32 %hb, ptr %cell, align 4
  %v = load i32, ptr %cell, align 4
  %r = call i32 @cqrt_alloc_i32(i32 3)
  %o = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %v, i32 %r, i32 %o)
  call void @cqrt_x(i32 %hb)
  call void @cqrt_copy_i32_controlled(i32 %v, i32 %r, i32 %o)
  call void @cqrt_free(i32 %o)
  ret i32 0
}
!0 = !{!"i1"}
"""

# (L1) the premise itself: a rail reaches memory that carries no marker. Either
# the promoter forgot it or a second escape mechanism exists; either way every
# load classification below it would be a guess.
UNMARKED_RAIL_STORE = """
define i32 @slice() local_unnamed_addr {
entry:
  %slot = alloca i32, align 4
  %hb = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %hb, double 5.000000e-01)
  store i32 %hb, ptr %slot, align 4
  %r = call i32 @cqrt_alloc_i32(i32 7)
  %v = load i32, ptr %slot, align 4
  call void @cqrt_xorc_i32(i32 %r, i32 %v)
  call void @cqrt_free(i32 %r)
  ret i32 0
}
"""

# (L2) a bank is in scope and a load's object cannot be resolved — here through
# a formal parameter. Under the old premise "unresolvable" was harmless; with a
# bank present it is the difference between a classical immediate and a rail.
UNDECIDABLE_LOAD_BASE = """
define i32 @slice(ptr %p) local_unnamed_addr {
entry:
  %bank = alloca [1 x i32], align 4, !cq.railbank !0
  %hb = call i32 @cqrt_alloc_i1(i1 false)
  %cell = getelementptr inbounds [1 x i32], ptr %bank, i64 0, i64 0
  store i32 %hb, ptr %cell, align 4
  %r = call i32 @cqrt_alloc_i32(i32 7)
  %v = load i32, ptr %p, align 4
  call void @cqrt_xorc_i32(i32 %r, i32 %v)
  call void @cqrt_free(i32 %r)
  ret i32 0
}
!0 = !{!"i1"}
"""

# POSITIVE: the VARIABLE-INDEX bank cell inside a rolled loop — the shape the
# L-1a design target actually emits
# ($SESP/trackL/probes/TARGET_rolled_stage2.ll, which this file must not start
# refusing: measured `4 rail mint(s) of which 3 left allocated, 2 cqrt_free
# site(s): 2 verified` before AND after bd 21re). None of the fixtures above
# exercises `getelementptr ... i64 %i`, and a `first_ptr_operand` that only
# handled constant indices would pass every one of them.
BANK_VARIABLE_INDEX = """
define i32 @slice() local_unnamed_addr {
entry:
  %bank = alloca [2 x i32], align 4, !cq.railbank !0
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %i.next, %loop ]
  %hb = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %hb, double 5.000000e-01)
  %cell = getelementptr inbounds [2 x i32], ptr %bank, i64 0, i64 %i
  store i32 %hb, ptr %cell, align 4
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 2
  br i1 %done, label %measure, label %loop

measure:
  %c0 = getelementptr inbounds [2 x i32], ptr %bank, i64 0, i64 0
  %v0 = load i32, ptr %c0, align 4
  %m0 = call i1 @cqrt_measure_i1(i32 %v0)
  %z0 = zext i1 %m0 to i32
  ret i32 %z0
}
!0 = !{!"i1"}
"""

MEM_POSITIVE = [
    ("bank-load-measured-only", BANK_MEASURE_ONLY),
    ("bank-plus-unmarked-classical-load", BANK_PLUS_CLASSICAL_LOAD),
    ("bank-global-constexpr-gep", BANK_GLOBAL_CONSTEXPR),
    ("bank-variable-index-in-loop", BANK_VARIABLE_INDEX),
]

# Layers 1 (must verify clean) and 3 (proof-targeted sweep) are generic, so the
# bank positives join them rather than being re-implemented. Layer 2's memory
# tables stay separate: the counts have to be VISIBLE in the summary line, and
# a harness that cannot say how many memory constructs it checked is a hole
# (CLAUDE.md L10 — the injection matrix that printed `0 mutations, MISSED 0,
# N/A 0` when invoked with no fixture).
POSITIVE.extend(MEM_POSITIVE)

# (name, module, expected FINDING code) — a defect the model can still render a
# verdict about.
MEM_MUTANTS = [
    ("bank-load-in-classical-immediate-slot", BANK_IMM_SLOT,
     "A1-imm-not-classical"),
]

# (name, module, expected Undecidable CODE) — a construct the model cannot
# decide, so it must refuse to render a verdict at all.
MEM_STOP_MUTANTS = [
    ("bank-load-as-gate-control", BANK_CONTROL_SLOT,
     "L3-bank-rail-in-a-modelled-rail-slot"),
    ("bank-load-freed-through-its-load-name",
     sub(BANK_MEASURE_ONLY, "%m = call i1 @cqrt_measure_i1(i32 %v)",
         "%m = call i1 @cqrt_measure_i1(i32 %v)",
         "%m = call i1 @cqrt_measure_i1(i32 %v)\n  call void @cqrt_free(i32 %v)"),
     "L3-bank-rail-in-a-modelled-rail-slot"),
    ("bank-load-rotated-through-its-load-name",
     insert_after(BANK_MEASURE_ONLY, "%v = load i32",
                  "  call void @cqrt_ry_i1(i32 %v, double 2.500000e-01)"),
     "L3-bank-rail-in-a-modelled-rail-slot"),
    ("rail-stored-to-unmarked-alloca", UNMARKED_RAIL_STORE,
     "L1-rail-stored-to-unmarked-memory"),
    # THE MARKER'S OWN KILL TEST: strip `!cq.railbank` from the POSITIVE and it
    # must stop being a bank. Without this row the positive could be green
    # because the rule never fires, which is Rule-12 hygiene defect (c).
    ("bank-marker-removed-from-the-alloca",
     sub(BANK_MEASURE_ONLY, "alloca [1 x i32]", ", !cq.railbank !0", ""),
     "L1-rail-stored-to-unmarked-memory"),
    ("rail-stored-to-unmarked-global",
     sub(BANK_GLOBAL_CONSTEXPR, "@bank = internal global", ", !cq.railbank !0",
         ""),
     "L1-rail-stored-to-unmarked-memory"),
    ("bank-in-scope-unresolvable-load-base", UNDECIDABLE_LOAD_BASE,
     "L2-undecidable-load-provenance"),
    # `select` and `phi` FORWARD no object: two bank cells merged by a select
    # is exactly the shape a rolled bank would take if the promoter emitted one,
    # and the model must refuse it rather than pick a side.
    ("bank-variable-index-load-in-a-gate-slot",
     insert_after(BANK_VARIABLE_INDEX, "%v0 = load i32",
                  "  call void @cqrt_x(i32 %v0)"),
     "L3-bank-rail-in-a-modelled-rail-slot"),
    ("bank-load-through-a-select-of-pointers",
     sub(BANK_MEASURE_ONLY, "%v = load i32, ptr %cell",
         "%v = load i32, ptr %cell",
         "%sel = select i1 true, ptr %cell, ptr %bank\n"
         "  %v = load i32, ptr %sel"),
     "L2-undecidable-load-provenance"),
]


# ---------------------------------------------------------------------------
# bd 1739 HOLE 2 — `undef`/`poison` OPERAND TEXT IS NOT A VALUE MATCH
#
# Why the existing layers could not catch this (the ticket says it, and it is
# the general lesson): layer 3 mutates what the checker MODELS — it blanks a
# line a proof consumed. Hole 2 is not a missing line; it is an OPERAND AXIS
# outside the model, so every witness line is present, the structure is
# perfect, and only the run-time VALUES differ. A checker nobody has tried to
# fool on an axis it does not model is a checker nobody should trust on it.
#
# Each mutant is paired with a POSITIVE CONTROL carrying the same shape and a
# REAL literal, so the fix cannot be faked by refusing every pair.
# ---------------------------------------------------------------------------

UNDEF_T1_PAIR = """\
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
define void @f() {
  %h = call i32 @cqrt_alloc_i32(i32 3)
  %c = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 LIT)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %c, i32 %h, i32 LIT)
  call void @cqrt_free(i32 %c)
  ret void
}
"""

UNDEF_T1B_PAIR = """\
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl_inv(i32, i32)
declare void @cqrt_free(i32)
define void @f() {
  %h = call i32 @cqrt_alloc_i32(i32 3)
  %c = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 LIT)
  %u = call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %h, i32 LIT)
  call void @cqrt_free(i32 %c)
  ret void
}
"""

# (A2) rather than (A1): the `cqrt_cnot` pair is not a classical-immediate
# write, so `all(w.eff.classical_imm ...)` is false and the write-history
# reduction owns the verdict. The two `cqrt_xorc_i32` are SELF-adjoint and
# cancel by `key()` equality — i.e. by operand text.
UNDEF_A2_BRACKET = """\
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_xorc_i32(i32, i32)
declare void @cqrt_cnot(i32, i32)
declare void @cqrt_free(i32)
define void @f() {
  %c = call i32 @cqrt_alloc_i1(i1 false)
  %r = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_xorc_i32(i32 %r, i32 LIT)
  call void @cqrt_cnot(i32 %c, i32 %r)
  call void @cqrt_cnot(i32 %c, i32 %r)
  call void @cqrt_xorc_i32(i32 %r, i32 LIT)
  call void @cqrt_free(i32 %r)
  ret void
}
"""

# A constant EXPRESSION that merely CONTAINS an undef is still not a value: the
# `norm_arg` constexpr arm keeps the whole text, so the textual match succeeds
# for exactly the same wrong reason.
UNDEF_CONSTEXPR_PAIR = UNDEF_T1_PAIR.replace(
    "i32 LIT", "i32 add (i32 undef, i32 1)")

UNDEF_MUTANTS = [
    ("undef-t1a-unc-pair", UNDEF_T1_PAIR.replace("LIT", "undef"),
     "T1-undef-literal-pairing"),
    ("poison-t1a-unc-pair", UNDEF_T1_PAIR.replace("LIT", "poison"),
     "T1-undef-literal-pairing"),
    ("undef-t1b-inv-pair", UNDEF_T1B_PAIR.replace("LIT", "undef"),
     "T1-undef-literal-pairing"),
    ("undef-constexpr-operand", UNDEF_CONSTEXPR_PAIR,
     "T1-undef-literal-pairing"),
    ("undef-a2-xorc-bracket", UNDEF_A2_BRACKET.replace("LIT", "undef"),
     "A-undef-literal-pairing"),
]

# The controls. Same shapes, real literals: these must verify CLEAN, so a
# "fix" that refuses every pair is caught here rather than in the field.
UNDEF_CONTROLS = [
    ("undef-control-t1a-real-literal", UNDEF_T1_PAIR.replace("LIT", "7")),
    ("undef-control-a2-real-literal", UNDEF_A2_BRACKET.replace("LIT", "12")),
]

# ⚠ ONE SLOT IS DELIBERATELY NOT REFUSED, and it is the only `undef` the whole
# shipped corpus actually contains (MEASURED at the fix: 1 of 368 lowered e2e
# slices carries `undef` in ANY modelled-call operand — `%selop = call i32
# @cqrt_alloc_f64(double undef)` in slice_libm_ld80_nexttoward, bd u7z9's
# blessed precedent). Rules (A1)/(A2) rest on the rail holding *a* classical
# basis state, not on knowing WHICH: an unentangled rail in an unknown-but-
# definite basis state is still a sound reset. Pinned as a control so that
# "refuse every undef everywhere" cannot be shipped by accident — it would
# turn a committed golden's slice red for a property this file does not claim.
UNDEF_SEED_CONTROL = """\
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_xorc_i32(i32, i32)
declare void @cqrt_free(i32)
define void @f() {
  %r = call i32 @cqrt_alloc_i32(i32 undef)
  call void @cqrt_xorc_i32(i32 %r, i32 5)
  call void @cqrt_free(i32 %r)
  ret void
}
"""
UNDEF_CONTROLS.append(("undef-control-alloc-seed-slot", UNDEF_SEED_CONTROL))


# ---------------------------------------------------------------------------
# THE CENSUS (bd rixk, bd 19vy, bd 1739 hole 1)
#
# The census is not a finding, so NO layer above can see it: a mutant layer
# keyed on finding codes scores a census that reports twice the truth as a
# pass. That is this project's own recurring shape — an instrument whose
# failure mode is to report a pass — so the census gets a table of its own,
# with the expected numbers written out rather than derived.
#
# Each case is (name, module text, expected (minted, leaked, tmpl, dirty,
# unresolved)).
# ---------------------------------------------------------------------------

# bd rixk, the reproducer: `-O1` inlines `slice` into `main` AND KEEPS the
# out-of-line body (external linkage, no call site left). Six static
# `cqrt_alloc` sites, three that can execute.
CENSUS_INLINED_DEAD_BODY = """\
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_measure_i1(i32)
define i32 @slice() {
  %a = call i32 @cqrt_alloc_i1(i1 false)
  %b = call i32 @cqrt_alloc_i1(i1 false)
  %c = call i32 @cqrt_alloc_i1(i1 false)
  %m = call i32 @cqrt_measure_i1(i32 %a)
  ret i32 %m
}
define i32 @main() {
  %a = call i32 @cqrt_alloc_i1(i1 false)
  %b = call i32 @cqrt_alloc_i1(i1 false)
  %c = call i32 @cqrt_alloc_i1(i1 false)
  %m = call i32 @cqrt_measure_i1(i32 %a)
  ret i32 0
}
"""

# The control the ticket demands be preserved: `main` CALLS `slice`, so the
# callee's sites are live and the number is the old one. This is the shape of
# slice_control_cascade_three_bools, whose "9 rail mint(s) of which 7 left
# allocated" CLAUDE.md quotes.
CENSUS_CALLED_CALLEE = CENSUS_INLINED_DEAD_BODY.replace(
    """define i32 @main() {
  %a = call i32 @cqrt_alloc_i1(i1 false)
  %b = call i32 @cqrt_alloc_i1(i1 false)
  %c = call i32 @cqrt_alloc_i1(i1 false)
  %m = call i32 @cqrt_measure_i1(i32 %a)
  ret i32 0
}""",
    """define i32 @main() {
  %r = call i32 @slice()
  ret i32 0
}""")

# BOTH: inlined into `main` AND still called. Six sites, six activations —
# the count must NOT drop here, which is what distinguishes reachability from
# "just ignore the callee".
CENSUS_INLINED_AND_CALLED = CENSUS_INLINED_DEAD_BODY.replace(
    "  %m = call i32 @cqrt_measure_i1(i32 %a)\n  ret i32 0",
    "  %m = call i32 @cqrt_measure_i1(i32 %a)\n"
    "  %r = call i32 @slice()\n  ret i32 0")

# An address-taken function can be entered from outside the static call graph.
CENSUS_ADDRESS_TAKEN = CENSUS_INLINED_DEAD_BODY.replace(
    "define i32 @main() {",
    "@fp = global ptr @slice\ndeclare void @sink(ptr)\ndefine i32 @main() {")

# An indirect call means the static call graph is not the call graph. The
# census falls back to counting everything AND SAYS SO.
CENSUS_INDIRECT = CENSUS_INLINED_DEAD_BODY.replace(
    "  %m = call i32 @cqrt_measure_i1(i32 %a)\n  ret i32 0",
    "  %m = call i32 @cqrt_measure_i1(i32 %a)\n"
    "  %fp = load ptr, ptr null\n  %r = call i32 %fp()\n  ret i32 0")

# No `main`: every function nothing in the module calls is an entry.
CENSUS_NO_MAIN = """\
declare i32 @cqrt_alloc_i1(i1)
define i32 @a() {
  %x = call i32 @cqrt_alloc_i1(i1 false)
  ret i32 %x
}
define i32 @b() {
  %y = call i32 @cqrt_alloc_i1(i1 false)
  ret i32 %y
}
"""

# A call cycle with no entry at all must terminate and count everything rather
# than silently reporting zero — a census that can be talked down to 0 is the
# failure bd 261j(b) added it to prevent.
CENSUS_CYCLE_NO_ENTRY = """\
declare i32 @cqrt_alloc_i1(i1)
define i32 @a() {
  %x = call i32 @cqrt_alloc_i1(i1 false)
  %r = call i32 @b()
  ret i32 %x
}
define i32 @b() {
  %y = call i32 @cqrt_alloc_i1(i1 false)
  %r = call i32 @a()
  ret i32 %y
}
"""

# bd 19vy / bd 1739 hole 1 — the template-minted rail. `%t` is minted by a
# template, never reversed, never freed, never measured: the C-1 leak shape,
# and the `h6` of slice_control_cascade_three_bools.
CENSUS_TEMPLATE_DIRTY = """\
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cqrt_measure_i32(i32)
define i32 @main() {
  %h = call i32 @cqrt_alloc_i32(i32 0)
  %t = call i32 @cq_template_add_i32_hl(i32 %h, i32 -3)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
}
"""
# ...measured instead: discharged, and the census must say so.
CENSUS_TEMPLATE_MEASURED = CENSUS_TEMPLATE_DIRTY.replace(
    "call i32 @cqrt_measure_i32(i32 %h)", "call i32 @cqrt_measure_i32(i32 %t)")
# ...reversed instead.
CENSUS_TEMPLATE_UNCD = CENSUS_TEMPLATE_DIRTY.replace(
    "  %m = call i32 @cqrt_measure_i32(i32 %h)",
    "  call void @cq_template_add_i32_hl_unc(i32 %t, i32 %h, i32 -3)\n"
    "  %m = call i32 @cqrt_measure_i32(i32 %h)").replace(
    "declare i32 @cqrt_measure_i32(i32)",
    "declare i32 @cqrt_measure_i32(i32)\n"
    "declare void @cq_template_add_i32_hl_unc(i32, i32, i32)")
# ...freed instead.
CENSUS_TEMPLATE_FREED = CENSUS_TEMPLATE_UNCD.replace(
    "  %m = call i32 @cqrt_measure_i32(i32 %h)",
    "  call void @cqrt_free(i32 %t)\n"
    "  %m = call i32 @cqrt_measure_i32(i32 %h)").replace(
    "declare i32 @cqrt_alloc_i32(i32)",
    "declare i32 @cqrt_alloc_i32(i32)\ndeclare void @cqrt_free(i32)")
# ...returned (it escapes; the caller owns it).
CENSUS_TEMPLATE_RETURNED = CENSUS_TEMPLATE_DIRTY.replace(
    "  %m = call i32 @cqrt_measure_i32(i32 %h)\n  ret i32 %m",
    "  ret i32 %t")
# The output tape is KEPT BY DESIGN (7.6) and must never be counted dirty.
CENSUS_TAPE_KEPT = """\
declare i32 @cqrt_tape_alloc()
declare i32 @cqrt_tape_write_i32(i32, i32)
declare i32 @cqrt_alloc_i32(i32)
define i32 @main() {
  %tp = call i32 @cqrt_tape_alloc()
  %h = call i32 @cqrt_alloc_i32(i32 0)
  %w = call i32 @cqrt_tape_write_i32(i32 %tp, i32 %h)
  ret i32 0
}
"""

# FREED but never reversed: `freed` must be its own discharge clause, not one
# that another clause happens to cover. (Added because the kill test of the
# `res in freed` clause came back GREEN — the first draft's "freed" case was
# ALSO `_unc`'d, so deleting `freed` changed nothing. A clause nobody has
# deleted is a clause nobody has validated.)
CENSUS_TEMPLATE_FREED_ONLY = CENSUS_TEMPLATE_DIRTY.replace(
    "  %m = call i32 @cqrt_measure_i32(i32 %h)",
    "  call void @cqrt_free(i32 %t)\n"
    "  %m = call i32 @cqrt_measure_i32(i32 %h)").replace(
    "declare i32 @cqrt_alloc_i32(i32)",
    "declare i32 @cqrt_alloc_i32(i32)\ndeclare void @cqrt_free(i32)")

# Passed to a callee this file does not model: the rail ESCAPES and the callee
# owns its discharge, exactly as `U1`/`U3` refuse to vouch for a cross-stream
# handle rather than calling it leaked.
CENSUS_TEMPLATE_ESCAPED = CENSUS_TEMPLATE_DIRTY.replace(
    "  %m = call i32 @cqrt_measure_i32(i32 %h)",
    "  call void @user_sink(i32 %t)\n"
    "  %m = call i32 @cqrt_measure_i32(i32 %h)").replace(
    "declare i32 @cqrt_alloc_i32(i32)",
    "declare i32 @cqrt_alloc_i32(i32)\ndeclare void @user_sink(i32)")

# No `main`, and a mutual-recursion cycle nothing in the module enters. A
# `defined - called` root rule would drop @a and @b here; the shipped rule
# counts them, because a module with no `main` is a translation unit whose
# external functions may be entered from OUTSIDE it. This is the case that
# pins that clause — without it, "roots = main only" passes unnoticed.
CENSUS_NO_MAIN_CYCLE = """\
declare i32 @cqrt_alloc_i1(i1)
define i32 @a() {
  %x = call i32 @cqrt_alloc_i1(i1 false)
  %r = call i32 @b()
  ret i32 %x
}
define i32 @b() {
  %y = call i32 @cqrt_alloc_i1(i1 false)
  %r = call i32 @a()
  ret i32 %y
}
define i32 @c() {
  %z = call i32 @cqrt_alloc_i1(i1 false)
  ret i32 %z
}
"""

CENSUS_CASES = [
    # name,                         module,                      (mint, leak, tmpl, dirty, unresolved)
    ("rixk-inlined-dead-body",      CENSUS_INLINED_DEAD_BODY,    (3, 3, 0, 0, False)),
    ("rixk-control-callee-called",  CENSUS_CALLED_CALLEE,        (3, 3, 0, 0, False)),
    ("rixk-inlined-AND-called",     CENSUS_INLINED_AND_CALLED,   (6, 6, 0, 0, False)),
    ("rixk-address-taken-is-live",  CENSUS_ADDRESS_TAKEN,        (6, 6, 0, 0, False)),
    ("rixk-indirect-counts-all",    CENSUS_INDIRECT,             (6, 6, 0, 0, True)),
    ("rixk-no-main-both-entries",   CENSUS_NO_MAIN,              (2, 2, 0, 0, False)),
    ("rixk-cycle-with-no-entry",    CENSUS_CYCLE_NO_ENTRY,       (2, 2, 0, 0, False)),
    ("rixk-no-main-cycle-counted",  CENSUS_NO_MAIN_CYCLE,        (3, 3, 0, 0, False)),
    ("1739h1-template-left-dirty",  CENSUS_TEMPLATE_DIRTY,       (1, 1, 1, 1, False)),
    ("1739h1-template-measured",    CENSUS_TEMPLATE_MEASURED,    (1, 1, 1, 0, False)),
    ("1739h1-template-reversed",    CENSUS_TEMPLATE_UNCD,        (1, 1, 1, 0, False)),
    ("1739h1-template-freed",       CENSUS_TEMPLATE_FREED,       (1, 1, 1, 0, False)),
    ("1739h1-template-freed-only",  CENSUS_TEMPLATE_FREED_ONLY,  (1, 1, 1, 0, False)),
    ("1739h1-template-escaped",     CENSUS_TEMPLATE_ESCAPED,     (1, 1, 1, 0, False)),
    ("1739h1-template-returned",    CENSUS_TEMPLATE_RETURNED,    (1, 1, 1, 0, False)),
    ("1739h1-tape-kept-by-design",  CENSUS_TAPE_KEPT,            (1, 1, 0, 0, False)),
]


# ⚠ THE CENSUS OBJECT IS NOT THE CENSUS LINE, and the first draft of this file
# pinned only the object. A regression that computed every number correctly and
# then dropped the template clause from `main()`'s printed line scored GREEN
# across all of layer 2e — the instrument's own failure mode, one level down.
# These cases run `main()` and read what a human (or a record) actually sees.
# (name, module, list of substrings the printed line MUST contain)
CENSUS_LINE_CASES = [
    ("line-rixk-inlined-dead-body", CENSUS_INLINED_DEAD_BODY,
     ["3 rail mint(s) of which 3 left allocated",
      "0 template rail mint(s) of which 0 left dirty"]),
    ("line-template-left-dirty", CENSUS_TEMPLATE_DIRTY,
     ["1 rail mint(s) of which 1 left allocated",
      "1 template rail mint(s) of which 1 left dirty"]),
    ("line-indirect-says-so", CENSUS_INDIRECT,
     ["6 rail mint(s) of which 6 left allocated",
      "[call graph unresolved: every function counted]"]),
]


# ---------------------------------------------------------------------------
# (T4) THE LOOP-EXIT / CROSS-STREAM DISCHARGE  (Track C, 2026-09-18)
#
# WHY THESE EXIST. Group 1's P2 anchor discharges a rail minted OUTSIDE a loop
# at that loop's unique EXIT, so the mint and the reversal land in two different
# STREAMS and `check_free` reported `U3-extern-rail` on a rail that is provably
# |0>. That is not one slice's inconvenience: `e2e-loop-twin-matrix` runs this
# checker STRICT per side, so 24 twin cells plus the pinned boundary control
# `q_armoncond` became `HARNESS-ERROR` and stopped having a verdict at all — and
# that matrix is the only instrument in the tree that can see a leaked
# TEMPLATE-minted rail. (T4) is the rule that verifies the shape instead.
#
# ⚠ (T4) IS THE FIRST RULE HERE THAT READS OUTSIDE ITS OWN STREAM, so it is the
# one most able to over-accept, and the mutant table below is sized for that:
# every conjunct (T4a)/(T4b)/(T4c)/(T4d)/(T4f-mint)/(T4f-free)/(T4g) plus the
# undef arm has its OWN row, and each row is ASSERTED to be refused by the arm
# it was built for (the harness matches the refusal text, not just the finding
# code) — because a mutant caught one arm earlier proves nothing about the arm
# it was written for. That is not hypothetical here: the FIRST two-exit-block
# mutant (`t4-two-exit-blocks-two-reversals`) is caught by (T4c), not by (T4d),
# because a second exit block carries a second `_unc`; isolating (T4d) needed
# `t4-one-reversal-two-frees`, where ONE reversal dominates two free sites.
#
# The two POSITIVE fixtures are verbatim stage-2 output on the 2026-09-18
# combined binary (cq-opt 96d74fe6008133b8):
#   * T4_RANGE_SLICE — twin-matrix cell `m_none_range_none`, ROLLED side, the
#     1-rail shape (`cq_template_add_i32_hl`). One of the 24.
#   * T4_HOISTED_CHAIN — `tests/e2e/slice_loop_hoisted_chain_exit_discharge.c`,
#     the 3-rail LICM chain `sitofp -> fadd -> sqrt`. This is the e2e slice
#     Group 1 had to register with `--allow-unproven`; with (T4) it reports
#     `4 verified, 0 violation(s), 0 unproven` STRICT.
# Both are in POSITIVE as well, so the proof-targeted SWEEP blanks (T4)'s
# witness lines — the mint and the reversal — and requires the proof to break.
# ---------------------------------------------------------------------------

T4_RANGE_SLICE = """
define i32 @slice() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 -6)
  br label %2

1:                                                ; preds = %2
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %h, i32 -6)
  call void @cqrt_free(i32 %h_op)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %4, %2 ]
  %h_cmp = call i32 @cq_template_icmp_ult_i32_hl(i32 %h_op, i32 14)
  call void @cqrt_rz_i1(i32 %h_cmp, double 0x400921FB54442D18), !cq.branchphase !6
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 14)
  call void @cqrt_free(i32 %h_cmp)
  %4 = add nuw nsw i32 %3, 1
  %5 = icmp eq i32 %3, 0
  br i1 %5, label %2, label %1, !llvm.loop !7
}
"""

T4_HOISTED_CHAIN = """
define i32 @slice() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h1, double 3.000000e-01)
  %h_cast = call i32 @cq_template_sitofp_i32_to_f64(i32 %h)
  %h_op = call i32 @cq_template_fadd_f64_hl(i32 %h_cast, double 3.000000e+00)
  %h_intr = call i32 @cq_template_sqrt_f64(i32 %h_op)
  br label %3

1:                                                ; preds = %3
  call void @cq_template_sqrt_f64_unc(i32 %h_intr, i32 %h_op)
  call void @cqrt_free(i32 %h_intr)
  call void @cq_template_fadd_f64_hl_unc(i32 %h_op, i32 %h_cast, double 3.000000e+00)
  call void @cqrt_free(i32 %h_op)
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %h_cast, i32 %h)
  call void @cqrt_free(i32 %h_cast)
  call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m2 = call i32 @cqrt_measure_i32(i32 %h1)
  %2 = add nsw i32 %m2, %m
  ret i32 %2

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 0, %0 ], [ %7, %3 ]
  %5 = load volatile i32, ptr @off, align 4, !tbaa !6
  %6 = sitofp i32 %5 to double
  %h_cmp = call i32 @cq_template_fcmp_ugt_f64_hl(i32 %h_intr, double %6)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 9.000000e-01)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_fcmp_ugt_f64_hl_unc(i32 %h_cmp, i32 %h_intr, double %6)
  call void @cqrt_free(i32 %h_cmp)
  %7 = add nuw nsw i32 %4, 1
  %8 = icmp eq i32 %4, 0
  br i1 %8, label %3, label %1, !llvm.loop !10
}
"""

# -- the (T4d) isolating pair: ONE reversal, TWO free sites -------------------
# The two-exit-block spelling (`t4-two-exit-blocks-two-reversals`, below) is
# caught by (T4c) because each exit block carries its own `_unc`. To reach
# (T4d) the reversal has to DOMINATE both frees, so there is only ever one
# write to the rail and only the free COUNT is wrong.
T4_ONE_UNC_TWO_FREES = """
define i32 @slice(i32 %esc) local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 -6)
  br label %2

1:                                                ; preds = %2
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %h, i32 -6)
  call void @cqrt_free(i32 %h_op)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %6 = icmp eq i32 %esc, 3
  br i1 %6, label %8, label %9

8:                                                ; preds = %1
  call void @cqrt_free(i32 %h_op)
  ret i32 0

9:                                                ; preds = %1
  ret i32 %m

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %4, %2 ]
  %h_cmp = call i32 @cq_template_icmp_ult_i32_hl(i32 %h_op, i32 14)
  call void @cqrt_rz_i1(i32 %h_cmp, double 0x400921FB54442D18), !cq.branchphase !6
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 14)
  call void @cqrt_free(i32 %h_cmp)
  %4 = add nuw nsw i32 %3, 1
  %5 = icmp eq i32 %3, 0
  br i1 %5, label %2, label %1, !llvm.loop !7
}
"""
# Its CONTROL: the same module with the stray second free removed. It must
# VERIFY, so (T4d) cannot be faked by refusing every multi-successor exit.
T4_ONE_UNC_ONE_FREE = T4_ONE_UNC_TWO_FREES.replace(
    """8:                                                ; preds = %1
  call void @cqrt_free(i32 %h_op)
  ret i32 0""",
    """8:                                                ; preds = %1
  ret i32 0""")

# -- two exit blocks, each with its own reversal + free (caught by (T4c)) -----
T4_TWO_EXIT_BLOCKS = """
define i32 @slice(i32 %esc) local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 -6)
  br label %2

1:                                                ; preds = %7
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %h, i32 -6)
  call void @cqrt_free(i32 %h_op)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m

6:                                                ; preds = %7
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %h, i32 -6)
  call void @cqrt_free(i32 %h_op)
  ret i32 0

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %4, %2 ]
  %h_cmp = call i32 @cq_template_icmp_ult_i32_hl(i32 %h_op, i32 14)
  call void @cqrt_rz_i1(i32 %h_cmp, double 0x400921FB54442D18), !cq.branchphase !6
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 14)
  call void @cqrt_free(i32 %h_cmp)
  %4 = add nuw nsw i32 %3, 1
  %5 = icmp eq i32 %3, 0
  br i1 %5, label %2, label %7, !llvm.loop !7

7:                                                ; preds = %2
  %8 = icmp eq i32 %esc, 3
  br i1 %8, label %1, label %6
}
"""

# -- the MINT inside the loop, reversal + free outside: (T4f), mint side ------
T4_MINT_IN_LOOP = """
define i32 @slice() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  br label %2

1:                                                ; preds = %2
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %h, i32 -6)
  call void @cqrt_free(i32 %h_op)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %4, %2 ]
  %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 -6)
  %4 = add nuw nsw i32 %3, 1
  %5 = icmp eq i32 %3, 0
  br i1 %5, label %2, label %1, !llvm.loop !7
}
"""

# -- an ALLOC rail in the same cross-stream bracket shape: (T4a) --------------
# `xorc(%r,5) … xorc(%r,5)` genuinely reduces to identity, so this is a
# DELIBERATE over-decline and it is the point: an alloc rail's soundness is a
# REDUCTION of its whole write history, and reducing one across a back edge is
# exactly what the stream model refuses to do.
T4_ALLOC_RAIL = """
define i32 @slice() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_op = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_xorc_i32(i32 %h_op, i32 5)
  br label %2

1:                                                ; preds = %2
  call void @cqrt_xorc_i32(i32 %h_op, i32 5)
  call void @cqrt_free(i32 %h_op)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %4, %2 ]
  %h_cmp = call i32 @cq_template_icmp_ult_i32_hl(i32 %h_op, i32 14)
  call void @cqrt_rz_i1(i32 %h_cmp, double 0x400921FB54442D18), !cq.branchphase !6
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 14)
  call void @cqrt_free(i32 %h_cmp)
  %4 = add nuw nsw i32 %3, 1
  %5 = icmp eq i32 %3, 0
  br i1 %5, label %2, label %1, !llvm.loop !7
}
"""

# The K:1 shape P2's own anchor walk exists to avoid: minted ONCE outside,
# reversed AND freed PER TRIP inside. (T4f), free side.
_T4_K1 = insert_after(
    drop(drop(T4_RANGE_SLICE, "add_i32_hl_unc"), "cqrt_free(i32 %h_op)"),
    "cqrt_rz_i1",
    "  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %h, i32 -6)\n"
    "  call void @cqrt_free(i32 %h_op)")

# The adjoint inside the loop with the free outside — the other half of K:1.
_T4_UNC_IN_LOOP = insert_after(
    drop(T4_RANGE_SLICE, "add_i32_hl_unc"), "cqrt_rz_i1",
    "  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %h, i32 -6)")

# The free ABOVE the adjoint in the exit block.
def _swap_lines(text, a, b):
    lines = text.split("\n")
    i = next(k for k, l in enumerate(lines) if a in l)
    j = next(k for k, l in enumerate(lines) if b in l)
    lines[i], lines[j] = lines[j], lines[i]
    return "\n".join(lines)


_T4_FREE_BEFORE_UNC = _swap_lines(T4_RANGE_SLICE, "add_i32_hl_unc",
                                  "cqrt_free(i32 %h_op)")

# (name, module, expected finding code, a fragment of the refusal text that
#  identifies WHICH arm refused it — or None when the shape is refused BEFORE
#  (T4) is ever consulted, which is itself a fact worth pinning.)
T4_MUTANTS = [
    # (T4c) — a write to the rail inside the loop body.
    ("t4-write-to-rail-inside-the-loop",
     insert_after(T4_RANGE_SLICE, "cqrt_rz_i1",
                  "  call void @cqrt_x(i32 %h_op)"),
     "U3-extern-rail", "also writes %h_op"),
    # (T4c) — the same arm reached by a MEASUREMENT, which is the conjunct that
    # keeps (T4) from bypassing `F8-free-after-measure`: the `extern` branch
    # returns before F8 runs, so if (T4c) ever stopped counting a measure as a
    # write, a measured rail would be VERIFIED here.
    ("t4-rail-measured-then-freed",
     insert_after(T4_RANGE_SLICE, "add_i32_hl_unc",
                  "  %mm = call i32 @cqrt_measure_i32(i32 %h_op)"),
     "U3-extern-rail", "also writes %h_op"),
    # (T4c) — and by a non-diagonal ROTATION, the conjunct that keeps (T4) from
    # bypassing `R1-recorded-rotated-rail` for the same structural reason.
    ("t4-rail-rotated-inside-the-loop",
     insert_after(T4_RANGE_SLICE, "cqrt_rz_i1",
                  "  call void @cqrt_ry_i32(i32 %h_op, double 5.000000e-01)"),
     "U3-extern-rail", "also writes %h_op"),
    # (T4b) — the adjoint recomputes a DIFFERENT value.
    ("t4-adjoint-with-a-different-literal",
     sub(T4_RANGE_SLICE, "add_i32_hl_unc", "i32 -6", "i32 -7"),
     "U3-extern-rail", "no `@cq_template_add_i32_hl_unc"),
    # (T4b) — `undef` text is not a value (bd 1739 hole 2), so a pairing that
    # matches only through it is not a cancellation.
    ("t4-undef-forward-operand",
     sub(sub(T4_RANGE_SLICE, "add_i32_hl(", "i32 -6", "i32 undef"),
         "add_i32_hl_unc", "i32 -6", "i32 undef"),
     "U3-extern-rail", "`undef`/`poison`"),
    # (T4f), FREE side — the K:1 shape: minted once outside, reversed and freed
    # per trip inside. Every other conjunct passes; only this one refuses.
    ("t4-k1-reversal-and-free-inside-the-loop", _T4_K1,
     "U3-extern-rail", "can execute more than once"),
    # (T4f), MINT side.
    ("t4-mint-inside-the-loop", T4_MINT_IN_LOOP,
     "U3-extern-rail", "can execute more than once, so the mint is not a single"),
    # (T4d) — ONE reversal dominating TWO free sites.
    ("t4-one-reversal-two-frees", T4_ONE_UNC_TWO_FREES,
     "U3-extern-rail", "`cqrt_free(%h_op)` site(s) in this function"),
    # (T4c), reached by the two-exit-block spelling. Recorded with the arm it
    # ACTUALLY hits, not the one it was written for — see the section header.
    ("t4-two-exit-blocks-two-reversals", T4_TWO_EXIT_BLOCKS,
     "U3-extern-rail", "also writes %h_op"),
    # (T4g) — a forward operand of the mint moves inside the loop, so the
    # reversal recomputes a different value.
    ("t4-forward-operand-moved-inside-the-loop",
     insert_after(T4_RANGE_SLICE, "cqrt_rz_i1",
                  "  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)"),
     "U3-extern-rail", "is written by `call void @cqrt_ry_i32(i32 %h"),
    # (T4a) — an ALLOC rail in the same shape. A deliberate over-decline.
    ("t4-alloc-rail-cross-stream-bracket", T4_ALLOC_RAIL,
     "U3-extern-rail", "not a reversible out-of-place template mint"),
    # Refused BEFORE (T4): the adjoint is in the loop, so the exit stream has no
    # write to the rail at all and it never becomes an `extern` record.
    ("t4-adjoint-in-loop-free-outside", _T4_UNC_IN_LOOP,
     "U1-cross-stream", None),
    # Refused BEFORE (T4) as well, and loudly: with the free above the reversal
    # the rail is not yet in the stream's table at the free, and the reversal is
    # then a use-after-free.
    ("t4-free-above-the-adjoint", _T4_FREE_BEFORE_UNC,
     "F2-use-after-free", None),
]

# Shapes (T4) must stay SILENT on, each one operand away from a mutant above.
T4_POSITIVES = [
    # The 1-rail twin-matrix cell and the 3-rail e2e chain. The counts are the
    # T4 proofs only — each module ALSO verifies its per-trip flag through the
    # ordinary (T1) in-stream rule, which is not this rule's business.
    ("t4-range-cell-rolled", T4_RANGE_SLICE, 1),
    ("t4-hoisted-chain-rolled", T4_HOISTED_CHAIN, 3),
    # (T4d)'s control: the same multi-successor exit, one free.
    ("t4-one-reversal-one-free", T4_ONE_UNC_ONE_FREE, 1),
    # The DIAGONAL exclusion, which is (T4)'s write model agreeing with
    # `StreamAnalysis.run`'s: an `rz` on the rail inside the loop is not a write
    # in either, so this must still verify where the `ry` twin above refuses.
    # ⚠ It inherits this file's standing Rz blindness (see the checker's WHAT IT
    # DOES **NOT** WITNESS): the phase really is applied K times and no rule
    # here can see that. The pair pins the two models AGREEING, not the physics.
    ("t4-diagonal-rz-on-the-rail-inside-the-loop",
     insert_after(T4_RANGE_SLICE, "cqrt_rz_i1",
                  "  call void @cqrt_rz_i32(i32 %h_op, double 5.000000e-01)"), 1),
]

# The two SHIPPED lowerings also go into POSITIVE, which is what puts them
# through layer 3 (blank every line a verified proof consumed and require the
# module to stop verifying clean). For a (T4) proof those lines are the MINT and
# the REVERSAL, the only two instructions the rule reads for content.
POSITIVE.append(("t4-range-cell-rolled", T4_RANGE_SLICE))
POSITIVE.append(("t4-hoisted-chain-rolled", T4_HOISTED_CHAIN))


UNCLASSIFIED_MUTANT = sub(PHASE_DIAMOND, "@cqrt_cswap", "@cqrt_cswap",
                          "@cqrt_teleport_i32", 0)

# Rules whose proof legitimately survives deletion of a witness line, with the
# reason. A1 says "every write is a classical immediate, so the rail is still a
# known classical basis state" — deleting one classical `cqrt_addc` changes
# WHICH classical state, never whether it is one, so the free stays Rule-6
# sound and the checker is right not to flag it.
SWEEP_EXEMPT_RULES = {"A1-classical-immediate"}


class _Stop:
    """An `Undecidable` refusal, rendered finding-shaped (bd 21re).

    A refusal is not a finding — the checker is declining to render a verdict
    about the module, not reporting a defect in it — but every layer here asks
    the same two questions of both ("did the checker stop being silent?" and
    "with which code?"), so they are compared through one shape. The SWEEP in
    particular must count a refusal as "no longer verifying clean", which is
    exactly what it is.
    """

    kind = "REFUSED"

    def __init__(self, e):
        self.code, self.fn, self.line = e.code, e.fn, e.line
        self.handle, self.msg = "-", e.msg

    def __str__(self):
        return f"REFUSED {self.code} @{self.fn} line {self.line}"


def findings(text):
    try:
        f, _v, _s, _p, _c = fpc.check_module(text)
    except fpc.Undecidable as e:
        return [_Stop(e)]
    return f


def proofs_of(text):
    """The VERIFIED-proof records, or [] if the checker refused the module.

    ⚠ Guarded on purpose (bd 21re arm-kill round). Layer 3 used to call
    `fpc.check_module` directly, so a mutation that made a POSITIVE fixture
    REFUSE crashed the harness with a traceback AFTER layer 1 had already
    recorded the real failure — a harness that dies mid-run reports neither its
    counts nor its other layers, which is the `n/a is a HOLE` failure mode one
    step removed.
    """
    try:
        _f, _v, _s, proofs, _c = fpc.check_module(text)
    except fpc.Undecidable:
        return []
    return proofs


def verdict_map(text):
    """{handle: verdict} for every free site — what an ORDER_PAIR compares."""
    try:
        f, _v, _s, proofs, _c = fpc.check_module(text)
    except fpc.Undecidable as e:
        return {"-": "REFUSED:" + e.code}
    d = {handle: "OK:" + rule for _fn, _l, handle, rule, _w in proofs}
    for x in f:
        d[x.handle] = x.kind + ":" + x.code
    return d


def main():
    verbose = "-v" in sys.argv
    fails = []
    n_pos = n_mut = n_sweep = n_neg = n_pair = n_mem = 0
    n_census = n_t4 = 0

    # ---- layer 1: the shipped lowerings must verify clean -----------------
    for name, text in POSITIVE + DEEP_POSITIVE:
        n_pos += 1
        f = findings(text)
        if f:
            fails.append(f"POSITIVE {name}: expected 0 findings, got "
                         + "; ".join(str(x) for x in f))
        elif verbose:
            print(f"  ok  positive  {name:32s} "
                  f"{len(proofs_of(text))} free site(s) verified")

    # ---- layer 1b: the verdict may not depend on `cqrt_free` ORDER --------
    # Layer 1 already demands both members verify clean; this layer states the
    # PROPERTY, so a future regression that declines both members consistently
    # is reported as the false positive it is rather than as an order bug.
    for name, ta, tb in ORDER_PAIRS:
        n_pair += 1
        va, vb = verdict_map(ta), verdict_map(tb)
        if va != vb:
            fails.append(f"ORDER PAIR {name}: moving a cqrt_free changed the "
                         f"verdict — {va} vs {vb}")
        elif verbose:
            print(f"  ok  order     {name:32s} {va}")

    # ---- layer 1c: the recursion stays CHEAP on the braid -----------------
    # Removing the depth budget removed the only bound on WORK as well as on
    # depth, and the co-written edge calls itself through the reads edge. This
    # counts the calls rather than the seconds so it cannot go flaky.
    n_cost = 1
    calls = [0]
    orig_co = fpc.StreamAnalysis.co_written_stable

    def counted(self, *a, **k):
        calls[0] += 1
        return orig_co(self, *a, **k)

    fpc.StreamAnalysis.co_written_stable = counted
    try:
        f = findings(COST_BRAID)
    finally:
        fpc.StreamAnalysis.co_written_stable = orig_co
    if f:
        fails.append(f"COST xzdx-cswap-braid-d20: expected 0 findings, got "
                     + "; ".join(str(x) for x in f))
    if calls[0] > COST_BRAID_MAX_CO_WRITTEN_CALLS:
        fails.append(
            f"COST xzdx-cswap-braid-d20: co_written_stable was entered "
            f"{calls[0]} times, over the bound of "
            f"{COST_BRAID_MAX_CO_WRITTEN_CALLS} — the recursion is no longer "
            f"being memoised on that edge, which is exponential (4^(D/2)) and "
            f"turns a 66-line input into a hung build gate")
    elif verbose:
        print(f"  ok  cost      {'xzdx-cswap-braid-d20':32s} "
              f"{calls[0]} co_written_stable call(s)")

    # ---- layer 2: each named defect must produce its named code -----------
    for name, text, want in MUTANTS:
        n_mut += 1
        codes = [x.code for x in findings(text)]
        if want not in codes:
            fails.append(f"MUTANT {name}: expected {want}, got "
                         + (", ".join(codes) if codes else "NOTHING (survived)"))
        elif verbose:
            print(f"  ok  mutant    {name:32s} -> {want}")
    # ---- layer 2b: bd 261j(b) recorded-rail rule, both directions ---------
    for name, text, want in RECORD_MUTANTS:
        n_mut += 1
        codes = [x.code for x in findings(text)]
        if want not in codes:
            fails.append(f"RECORD MUTANT {name}: expected {want}, got "
                         + (", ".join(codes) if codes else "NOTHING (survived)"))
        elif verbose:
            print(f"  ok  mutant    {name:32s} -> {want}")
    for name, text in RECORD_POSITIVES:
        n_mut += 1
        bad = [x.code for x in findings(text) if x.code.startswith("R1-")]
        if bad:
            fails.append(f"RECORD POSITIVE CONTROL {name}: the rule must NOT "
                         f"fire here, got " + ", ".join(bad))
        elif verbose:
            print(f"  ok  control   {name:32s} -> no R1")

    # ---- layer 2c: bd 21re, the rail-BANK memory surface ------------------
    # Two tables on purpose. A defect the model can still render a verdict
    # about is a FINDING; a construct it cannot decide is a REFUSAL, and the
    # two are not interchangeable — an UNPROVEN finding can be waived with
    # `--allow-unproven`, and a waivable model-unsoundness is the hole itself.
    for name, text, want in MEM_MUTANTS:
        n_mem += 1
        codes = [x.code for x in findings(text)]
        if want not in codes:
            fails.append(f"MEMORY MUTANT {name}: expected {want}, got "
                         + (", ".join(codes) if codes else "NOTHING (survived)"))
        elif verbose:
            print(f"  ok  memory    {name:38s} -> {want}")
    for name, text, want in MEM_STOP_MUTANTS:
        n_mem += 1
        got = findings(text)
        codes = [x.code for x in got]
        if want not in codes or not all(x.kind == "REFUSED" for x in got
                                        if x.code == want):
            fails.append(f"MEMORY REFUSAL {name}: expected a REFUSED {want}, "
                         "got " + (", ".join(f"{x.kind}:{x.code}" for x in got)
                                   if got else "NOTHING (survived)"))
        elif verbose:
            print(f"  ok  refusal   {name:38s} -> {want}")

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

    # ---- layer 2d: bd 1739 hole 2, the undef/poison operand axis ---------
    for name, text, want in UNDEF_MUTANTS:
        n_mut += 1
        codes = [x.code for x in findings(text)]
        if want not in codes:
            fails.append(f"UNDEF MUTANT {name}: expected {want}, got "
                         + (", ".join(codes) if codes else "NOTHING (survived)"))
        elif verbose:
            print(f"  ok  undef     {name:32s} -> {want}")
    for name, text in UNDEF_CONTROLS:
        n_mut += 1
        got = findings(text)
        if got:
            fails.append(f"UNDEF CONTROL {name}: the rule must NOT fire here "
                         f"(same shape, real literal), got "
                         + "; ".join(str(x) for x in got))
        elif verbose:
            print(f"  ok  control   {name:32s} -> clean")

    # ---- layer 2g: (T4), the loop-EXIT / cross-stream discharge ----------
    # ⚠ THE ARM IS ASSERTED, NOT JUST THE CODE. Every mutant here would report
    # `U3-extern-rail` if (T4) simply stopped working, so matching the finding
    # code alone would let ELEVEN of these twelve rows pass against a rule with
    # one conjunct left. Each row therefore also names a fragment of the
    # refusal text that identifies WHICH conjunct spoke — and the two rows whose
    # shape is refused BEFORE (T4) is consulted carry `None` and assert the
    # ABSENCE of a (T4) clause, so they cannot drift into fake arm coverage.
    for name, text, want, arm in T4_MUTANTS:
        n_t4 += 1
        got = findings(text)
        codes = [x.code for x in got]
        if want not in codes:
            fails.append(f"T4 MUTANT {name}: expected {want}, got "
                         + (", ".join(codes) if codes else "NOTHING (survived)"))
            continue
        msgs = [x.msg for x in got if x.code == want]
        clause = "(T4) loop-exit discharge refused:"
        if arm is None:
            if any(clause in m for m in msgs):
                fails.append(f"T4 MUTANT {name}: this shape is meant to be "
                             f"refused BEFORE (T4) is consulted, but a (T4) "
                             f"refusal clause was printed")
            elif verbose:
                print(f"  ok  t4        {name:44s} -> {want} (pre-T4)")
            continue
        if not any(clause in m and arm in m for m in msgs):
            fails.append(
                f"T4 MUTANT {name}: got {want}, but no (T4) refusal naming "
                f"{arm!r} — some OTHER conjunct caught it, so the arm this "
                f"mutant exists for is untested. Got: "
                + " | ".join(m[-220:] for m in msgs))
        elif verbose:
            print(f"  ok  t4        {name:44s} -> {want} / {arm[:34]!r}")

    for name, text, want_t4 in T4_POSITIVES:
        n_t4 += 1
        got = findings(text)
        if got:
            fails.append(f"T4 POSITIVE {name}: expected 0 findings, got "
                         + "; ".join(str(x) for x in got))
            continue
        n = sum(1 for _fn, _l, _h, rule, _w in proofs_of(text)
                if rule == "T4-loop-exit-discharge")
        if n != want_t4:
            # A fixture that verifies clean through some OTHER rule proves
            # nothing about (T4); count the proofs, do not assume them.
            fails.append(f"T4 POSITIVE {name}: expected {want_t4} site(s) "
                         f"discharged by T4-loop-exit-discharge, got {n}")
        elif verbose:
            print(f"  ok  t4        {name:44s} -> {n} T4 proof(s)")

    # ---- layer 2e: the CENSUS (bd rixk, bd 19vy, bd 1739 hole 1) ---------
    # No other layer can see this: the census is not a finding, so a census
    # reporting twice the truth scores as a pass everywhere above.
    for name, text, want in CENSUS_CASES:
        n_census += 1
        try:
            _f, _v, _s, _p, cen = fpc.check_module(text)
        except fpc.Undecidable as e:
            fails.append(f"CENSUS {name}: the checker refused the module "
                         f"({e.code})")
            continue
        got = (cen.minted, cen.leaked, cen.tmpl_minted, cen.tmpl_dirty,
               cen.unresolved_callgraph)
        if got != want:
            fails.append(f"CENSUS {name}: expected "
                         f"(mint,leak,tmpl,dirty,unresolved)={want}, got {got}")
        elif verbose:
            print(f"  ok  census    {name:32s} -> {got}")

    # ---- layer 2f: the census LINE, not just the census object -----------
    import io as _io
    import tempfile as _tf
    for name, text, wants in CENSUS_LINE_CASES:
        n_census += 1
        with _tf.NamedTemporaryFile("w", suffix=".ll", delete=False) as fh:
            fh.write(text)
            path = fh.name
        buf = _io.StringIO()
        keep = sys.stdout
        try:
            sys.stdout = buf
            fpc.main([path])
        finally:
            sys.stdout = keep
            os.unlink(path)
        line = next((l for l in buf.getvalue().splitlines()
                     if l.startswith("free_pairing_check:")), "")
        missing = [w for w in wants if w not in line]
        if missing:
            fails.append(f"CENSUS LINE {name}: printed line is missing "
                         + "; ".join(repr(m) for m in missing)
                         + f" — got {line!r}")
        elif verbose:
            print(f"  ok  censline  {name:32s} -> ok")

    # ---- layer 3: blank every line a verified proof rests on --------------
    exempt = 0
    for name, text in POSITIVE:
        lines = text.split("\n")
        base = len(findings(text))
        proofs = proofs_of(text)
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

    print(f"free_pairing_check_test: {n_pos} positive fixture(s), {n_pair} "
          f"free-order pair(s), {n_cost} cost bound(s), {n_mut} named "
          f"mutant(s), {n_mem} memory mutant(s)/refusal(s), {n_neg} Case-A "
          f"negative(s), {n_census} census case(s), {n_t4} T4 loop-exit "
          f"case(s), {n_sweep} proof-targeted "
          f"mutant(s) ({exempt} exempt by rule), {len(fails)} failure(s)")
    for x in fails:
        print("  FAIL " + x, file=sys.stderr)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
