; control_inplace_ry_reject_theta_phi_arm.ll — DECLINE: a `cq_phi` (Rz) BESIDE
; the `cq_theta` (Ry) in one arm (PRD shape S3; bd test_C_libtooling-drbq).
;
;     if (q > 5) { cq_phi(.2); cq_theta(&r,.9); }
;
; Pre-3qlq the phase was `r = cq_phi(r,.2)`, making a mixed in-place SPINE
; (`rz; ry` on one register), shape (b), deferred with the multi-rotation case
; (PRD §8). The arm still has two non-terminators, so the rotation-arm recognizer
; does not claim it and it keeps the generic decline: nothing in Inc 1 hoists TWO
; gates or orders them under one flag.
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: control flow under quantum control
; NEW: cq controlled lowering: control flow under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 2.000000e-01)
  %r2 = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %r2, %arm ], [ %r, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
