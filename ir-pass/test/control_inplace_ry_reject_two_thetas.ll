; control_inplace_ry_reject_two_thetas.ll — DECLINE: TWO rotations in one arm
; (control-in-place-PRD §4 R1, owner Q4 chose shape (a) — exactly ONE theta per
; arm; bd test_C_libtooling-drbq).
;
;     if (q > 5) { r = cq_theta(r,.9); r = cq_theta(r,.4); }
;
; The multi-gate in-place SPINE is deferred to shape (b), after Inc 3 (PRD §8),
; so the arm-block purity test admits exactly one non-terminator. The general
; reason purity is tested at all is `armBlockIsPureSpine`'s, verbatim:
; `RegionFlatten` ERASES the arm block, so anything the emitter does not hoist is
; silently DROPPED from the IR and its taint work-list pointer dangles.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %r1 = call i32 @cq_theta_si32(i32 %r,  double 9.000000e-01)
  %r2 = call i32 @cq_theta_si32(i32 %r1, double 4.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %r2, %arm ], [ %r, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
