; control_inplace_ry_reject_rail_inloop_multilatch.ll — DECLINE: the bare-`_Bool`
; in-place controlled-Ry arm inside a MULTI-LATCH loop. bd
; `test_C_libtooling-wx8g` retires the l4x4.b rail-in-loop carve-out; it does NOT
; touch `ControlDetect::flatRegionRollableInLoop`'s CFG gates, and gate (C) (a
; single latch) refuses before `Region.InLoop` is ever set.
;
; The rail spelling must reach the SAME CFG fences the compare spelling reaches —
; that is the point of this file and of its three siblings (`_nested`,
; `_irreducible` for the compare form, and `_tainted_exit`). A widening that
; retires an ARM-class carve-out and quietly relaxes a CFG gate would be
; invisible without them.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i1 %k) {
entry:
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rm, %lat1 ], [ %rm2, %lat2 ]
  br i1 %b, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %loop ]
  br i1 %k, label %lat1, label %lat2
lat1:
  br label %loop
lat2:
  %rm2 = call i32 @cq_theta_si32(i32 %rm, double 1.000000e-01)
  br i1 %k, label %loop, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %rm2)
  ret i32 %m
}
