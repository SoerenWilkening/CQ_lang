; control_inplace_ry_stateprep_warn_live_record.ll — ACCEPT (with the M-A
; WARNING): `warnLiveRecordRotations` is NOT BLINDED by a rail whose root is a
; controlled state prep.
;
; ⚠ ADDED 2026-09-05 (round-1 Rule-13 review, lens L4 finding F-L4-3, probe
; `L4_mA_prep_root.ll`). The implementer's mutation M6 established one direction
; — that the state-prep GATE ITSELF warns nothing, because
; `lowerRotations` files it under `UserSourceRotations` while the guard iterates
; `UserChainedRotations`. It could not establish the COMPLEMENTARY direction:
; does the guard still SEE a live derived record when the record's rail is rooted
; at a controlled gate? IT DOES — this file is the measurement.
;
;   %r  = <the prepped rail>            ; root = cqrt_ry_i32_controlled
;   %c  = add nsw i32 %r, 3             ; a RECORD off the prepped rail
;   %r2 = cq_theta(%r, 0.7)             ; a CHAINED non-diagonal gate on the rail
;   %cz = cq_phi(%c, 1.0)               ; a user Rz on the record, UNOBSERVED
;
; HEAD emits `warning: cq rotation lowering: non-diagonal gate over a live
; derived record` and exits 0. Its exempt control — the same module with the
; record MEASURED after the gate — warns nothing (measured, not committed: a
; warning's ABSENCE is not FileCheck-able against a whole file without a
; positive anchor, and the `_consumer_add` family already pins the no-warning
; shape).
;
; The `-O1` C image of this shape does not exist: the notes' §8 F-1 arithmetic
; sink deletes the post-merge op into the arm. It is HAND IR for that reason,
; like `..._stateprep_consumer_add.ll` and `..._consumer_none.ll`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=WARN    < %t.err
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %cc = icmp eq i32 %q, 9
  br i1 %cc, label %arm, label %merge
arm:
  %t = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %r  = phi i32 [ %t, %arm ], [ 0, %entry ]
  %c  = add nsw i32 %r, 3
  %r2 = call i32 @cq_theta_si32(i32 %r, double 7.000000e-01)
  %m  = call i32 @cq_measure_si32(i32 %r2)
  ret i32 %m
}

; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl({{.*}}, i32 9)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; the record off the prepped rail, then the CHAINED gate on the rail itself
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[R]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 0x3FE6666666666666)

; WARN: warning{{.*}}cq rotation lowering: non-diagonal gate over a live derived record

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
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h1, double 9.000000e-01)

; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
