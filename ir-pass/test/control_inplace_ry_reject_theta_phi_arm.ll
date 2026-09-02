; control_inplace_ry_reject_theta_phi_arm.ll — DECLINE: a `cq_phi` (Rz) BESIDE
; the `cq_theta` (Ry) in one arm (PRD shape S3; bd test_C_libtooling-drbq).
;
;     if (q > 5) { r = cq_phi(r,.2); r = cq_theta(r,.9); }
;
; A mixed in-place SPINE (`rz; ry` on one register) is shape (b), deferred with
; the multi-rotation case (PRD §8). The arm has two non-terminators, so the
; rotation-arm recognizer does not claim it and it keeps the pre-existing generic
; decline. There is no correctness gap in the deferral: the diagonal link is
; harmless, but nothing in Inc 1 hoists TWO gates or orders them under one flag.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %r1 = call i32 @cq_phi_si32(i32 %r, double 2.000000e-01)
  %r2 = call i32 @cq_theta_si32(i32 %r1, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %r2, %arm ], [ %r, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
