; control_inplace_ry_reject_stale_chained_theta.ll — DECLINE: the stale read is a
; CHAINED Ry record on the rotated register's own wire (control-in-place-PRD §4
; R6; bd test_C_libtooling-drbq Inc 1, finding J).
;
;     int r  = cq_theta(0, .3);
;     int r2 = cq_theta(r, .5);            // chained Ry — IN PLACE on r's handle
;     if (q > 5) r = cq_theta(r, .9);      // R == `r`, the PRE-r2 record
;     use(cq_measure(r2));
;
; The third hop of the same hole, and the one that shows the closure must cross
; `cq_theta` as well as `cq_phi`: `RotationLowering`'s chained branch mints NO
; alloc, so `r2` and `r` are one rail exactly as a diagonal alias is. Measured
; before the fix: `ry(h1,.3); ry(h1,.5); … ry_controlled(f,h1,.9); measure(h1);
; measure(h1)` — the first measurement is the source's `r2`, taken before the
; controlled Ry and read after it.
;
; The FORWARD closure crosses this theta because it is NOT one of the region's arm
; gates; the arm gates are excluded by block, which is what keeps the accept
; possible at all (crossing the arm theta would make the merge φ a member and turn
; every legitimate post-region consumer into a stale read).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r  = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %r2 = call i32 @cq_theta_si32(i32 %r, double 5.000000e-01)
  %c  = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %a  = call i32 @cq_measure_si32(i32 %r2)
  %b  = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %a, %b
  ret i32 %s
}
