; control_inplace_ry_reject_rail_inloop_nested.ll — DECLINE: the bare-`_Bool`
; in-place controlled-Ry arm inside a NESTED loop (the region sits in the inner
; loop, the rotated rail is carried by the outer one).
;
; `ControlDetect::flatRegionRollableInLoop` gate (B) — "every region block sits
; at EXACTLY `L`'s depth" — refuses it, before `Region.InLoop` is set and
; therefore before any clause of R7 is asked. bd `test_C_libtooling-wx8g` does
; not touch that gate; the file exists so a future widening cannot relax it
; silently under cover of the rail carve-out's retirement.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  br label %outer
outer:
  %r = phi i32 [ %r0, %entry ], [ %rm, %olat ]
  %i = phi i32 [ 0, %entry ], [ %inext, %olat ]
  br label %inner
inner:
  %j = phi i32 [ 0, %outer ], [ %jnext, %imerge ]
  %rin = phi i32 [ %r, %outer ], [ %rmi, %imerge ]
  br i1 %b, label %arm, label %imerge
arm:
  %rt = call i32 @cq_theta_si32(i32 %rin, double 9.000000e-01)
  br label %imerge
imerge:
  %rmi = phi i32 [ %rt, %arm ], [ %rin, %inner ]
  %jnext = add i32 %j, 1
  %jdone = icmp sgt i32 %jnext, 1
  br i1 %jdone, label %olat, label %inner
olat:
  %rm = phi i32 [ %rmi, %imerge ]
  %inext = add i32 %i, 1
  %idone = icmp sgt i32 %inext, 1
  br i1 %idone, label %exit, label %outer
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
