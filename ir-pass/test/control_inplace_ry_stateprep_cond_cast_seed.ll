; control_inplace_ry_stateprep_cond_cast_seed.ll — ACCEPT: a CROSS-TYPE seed.
; THE SAME-TYPE GATE IN F2 IS A SEMANTIC DISCRIMINATOR, AND THIS FILE IS WHY.
;
; Round-1 Rule-13 review, lenses L1 (F-L1-3), L6 (F-L6-1) and L7 (F-L7-5) all
; landed on the same spelling asymmetry: F1 admits a `ConstantInt` OR
; `ConstantFP` seed, while F2 asks its question only when the seed's LLVM TYPE
; equals the compare operand's. The shipped comment justified that as a
; mechanical `APInt` precondition ("`operator==` is only meaningful at equal bit
; widths"). It is not: it is the whole cross-width discriminator, and tidying it
; into a value-only comparison would silently turn this file into a decline.
;
; This module is the `-O1` image of PLAIN C (measured 2026-09-05):
;
;     long long r = 5;  if (q == 5) r = cq_theta((long long)q, 0.9);
;
; `K` is `i32 5`, the folded seed is `i64 5`. The two are numerically equal — so
; §14.2c item 1's old parenthetical ("if `f` were the identity, `f(k) == k` and
; F2 would have refused") is FALSE here, `sext` being numerically the identity.
; What carries is the OTHER half: a differing type means a CAST was folded away,
; and EVERY cast CQ can lower is OUT OF PLACE — a fresh rail, a different
; physical wire. MEASURED 2026-09-05 on all five spellings `-O1` can fold:
; `sext`/`zext` (`cq_template_sext_i32_to_i64(%h) -> %h_cast`), `trunc`,
; `sitofp`, and — decisively, because it is the only cast with no arithmetic
; content — a same-width `bitcast` reached from C through a `union` or `memcpy`,
; whose unfolded twin lowers to `cq_template_bitcast_i32_to_f32(%h) -> %h_cast`,
; also a fresh handle. So this is the §14.2c derived-temp accept class, not the
; R4-forbidden one, and NO bit-pattern clause across same-width int/fp seeds is
; owed (see `..._stateprep_cond_bitcast_seed.ll`).
;
; ⚠ THE SAME-WIDTH DECLINE CONTROL IS THE SAME-TYPE SPELLING:
; `control_inplace_ry_reject_stateprep_eqfold_coincidence.ll` (seed `i32 5`,
; `k = i32 5`) declines. One token — the seed's type — separates the two files.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i64 @cq_theta_sll(i64, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sll(i64)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i64 @cq_theta_sll(i64 5, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i64 [ %rt, %arm ], [ 5, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i64 @cq_measure_sll(i64 %rm)
  ret i32 %mq
}

; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl({{.*}}, i32 5)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 5)
; CHECK-NEXT: call void @cqrt_ry_i64_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)

; ---------------------------------------------------------------------------
; ⚠ THE NEGATIVE ASSERTIONS, REGENERATED 2026-09-05 (round-1 Rule-13 review,
; lens L7 findings F-L7-1 / F-L7-2 — the Inc-3 F-L6-1 recurrence).
;
; A POSITIVE directive inside a prefix WINDOWS every negative one of that prefix:
; FileCheck scans a "not" directive only between the previous and the next
; positive match. The shipped Inc-4 blocks put a positive COUNT of `cqrt_free`
; INSIDE the NOROUTE prefix, so every negative after it stopped scanning at the
; FLAG's free — which is exactly where the uncompute spine emits. MEASURED at
; hand-back: an injected `_controlled_inv` after the free was caught by 0 of 20
; NOROUTE blocks (7 of 20 caught it in NO prefix at all). NOROUTE is therefore
; PURE-NEGATIVE and WHOLE-FILE from here on, and every count lives in the CNT
; (or XCNT) prefix, where a positive directive is the point.
;
; THE HANDLE NAMES BELOW ARE THE LOWERED MODULE'S, DERIVED FROM THE PASS OUTPUT
; RATHER THAN TYPED (F-L7-2: 9 of 20 files named a `%h1` that does not exist in
; their own output, so the M7 assertion they carried was vacuous).

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: = phi
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi_
; THE FREEZE, whole-file: no `cqrt_free` may EVER name a PREPPED rail. A
; controlled gate's adjoint needs its CONTROL, and the flag is stripped and freed
; inside the region, so emitting one would be a use-after-free of the flag
; followed by a dirty free of a condition-entangled rail (the measured Inc-1
; defect). The rail is LEFT ALLOCATED — Rule 6's sanctioned fallback.
; NOROUTE-NOT: call void @cqrt_free(i32 %h1)
; …and the arm gate must not become UNCONDITIONAL (mutation M7 — that fires the
; rotation on BOTH branches, the wrong unitary this whole clause exists to
; avoid). Named by HANDLE AND ANGLE together, because an unconditional
; `cqrt_ry_<W>` on the prepped rail at a DIFFERENT angle is a legitimate
; post-region user (`..._then_uncond_theta.ll` has exactly one).
; NOROUTE-NOT: call void @cqrt_ry_i64(i32 %h1, double 9.000000e-01)

; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
