; control_inplace_ry_stateprep_then_rolled_loop.ll — ACCEPT: a FLAT state prep
; followed by a classically-bounded loop that ROTATES THE PREPPED REGISTER, and
; the loop ROLLS.
;
; ⚠ A NEW ACCEPT CLASS WITH NO FIXTURE, NO SLICE, NO GOLDEN AND NO MATRIX CELL
; AT HAND-BACK, and the record predicted it could not happen (round-1 Rule-13
; review, lens L6 finding F-3, probe `L2`). PRD §14.6 and notes §3 both said a
; hoisted state-prep `T` is a mint "which set WOULD CLAIM it if R7 were lifted",
; and §14.5 gave the reason: "the obstruction is positional — the hoisted `T`
; sits INSIDE the loop body, so `DT.dominates(Mint, L->getHeader())` fails".
; THAT IS TRUE ONLY WHEN THE REGION IS IN THE LOOP. For a FLAT prep followed by a
; loop, `T` DOMINATES the header and `LoopLowering::railPhiRootMint` succeeds
; with a `Mint` that is a CONTROLLED rotation — a shape that did not exist before
; Inc 4. `collapseFlattenedLoopRails` then claims the rail φ, and the body rolls.
;
; The C original (measured HEAD rc=0, pre-Inc-4 oracle rc=1):
;
;     int q = cq_theta(u0, .5);  int r = 0;
;     if (q == 7) r = cq_theta(0, .9);                        /* flat prep */
;     for (int i=0;i<3;i++){ if (q>5) q=cq_phi(q,.2); r=cq_theta(r,.1); }
;
; NO DEFECT ON THIS WITNESS: the hand-unrolled K=3 twin links and runs to a
; BYTE-IDENTICAL trace (24 lines each), strict stage 2b 0 violations / 0
; unproven.
;
; ⚠ IT IS CONTEXT-DEPENDENT, AND THAT IS A PRE-EXISTING `LoopLowering` FACT, NOT
; AN Inc-4 ONE: `collapseFlattenedLoopRails` only runs when
; `taint.InLoopFlattenedPreds` is non-empty, so REMOVING the unrelated in-loop
; `if (q > 5)` region makes the identical prepped-rail loop DECLINE
; (`cq taint escape: tainted value muxed by a classical-condition phi`, on BOTH
; binaries). The disposition of the state-prep rail's loop therefore depends on
; whether some OTHER register has a region inside that loop. Recorded here so the
; next reader does not conclude from this file that "a prepped rail always rolls".
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 7
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ 0, %entry ], [ %rt, %arm ]
  br label %header
header:
  %i  = phi i32 [ 0, %merge ], [ %inext, %latch ]
  %rp = phi i32 [ %rm, %merge ], [ %rn, %latch ]
  %qp = phi i32 [ %q, %merge ], [ %qp, %latch ]
  %bc = icmp sgt i32 %qp, 5
  br i1 %bc, label %barm, label %latch
barm:
  call void @cq_phi(double 2.000000e-01)
  br label %latch
latch:
  %rn = call i32 @cq_theta_si32(i32 %rp, double 1.000000e-01)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %header
exit:
  %mq = call i32 @cq_measure_si32(i32 %qp)
  %mr = call i32 @cq_measure_si32(i32 %rn)
  %s  = add i32 %mq, %mr
  ret i32 %s
}

; the flat prep, before the loop
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 7)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; the body, ROLLED: one trip's gates, and the prepped rail is named DIRECTLY —
; the rail phi was COLLAPSED, which is the whole finding.
; CHECK:      %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[Q]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)

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
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi_
; THE FREEZE, whole-file: no `cqrt_free` may EVER name a PREPPED rail. A
; controlled gate's adjoint needs its CONTROL, and the flag is stripped and freed
; inside the region, so emitting one would be a use-after-free of the flag
; followed by a dirty free of a condition-entangled rail (the measured Inc-1
; defect). The rail is LEFT ALLOCATED — Rule 6's sanctioned fallback.
; NOROUTE-NOT: call void @cqrt_free(i32 %h2)
; …and the arm gate must not become UNCONDITIONAL (mutation M7 — that fires the
; rotation on BOTH branches, the wrong unitary this whole clause exists to
; avoid). Named by HANDLE AND ANGLE together, because an unconditional
; `cqrt_ry_<W>` on the prepped rail at a DIFFERENT angle is a legitimate
; post-region user (`..._then_uncond_theta.ll` has exactly one).
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h2, double 9.000000e-01)

; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
