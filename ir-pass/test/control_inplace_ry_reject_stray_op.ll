; control_inplace_ry_reject_stray_op.ll — DECLINE: a STRAY op beside the arm's
; rotation (control-in-place-PRD §4 R1; bd test_C_libtooling-drbq).
;
;     if (q > 5) { cq_measure(r); r = cq_theta(r, .9); }
;
; `RegionFlatten` ERASES the arm block. Anything the emitter does not hoist is
; therefore silently DROPPED from the emitted program — here a USER MEASUREMENT
; would simply vanish (Rule 5) — and its `taint.MeasureCalls` pointer dangles into
; `lowerMeasures` (a use-after-free). `armBlockIsPureSpine`'s two reasons, applied
; to this class: the arm's non-terminator content must be the ONE hoisted gate.
;
; It also stands in for the FAN-OUT half of R1, which cannot have a fixture of its
; own: a second user of the arm theta must live either in the arm block (then it
; is a stray op — this fixture) or after it, where `arm` does not dominate `merge`
; and the module is not well-formed at all.
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
  %d  = call i32 @cq_measure_si32(i32 %r)
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
