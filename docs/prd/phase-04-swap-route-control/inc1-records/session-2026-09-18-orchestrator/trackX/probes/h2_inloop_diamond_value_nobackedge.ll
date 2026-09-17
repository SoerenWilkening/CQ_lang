; h2_inloop_diamond_value_nobackedge.ll — Track X (bd x5fp), session 2026-09-18.
; THE ISOLATING CONTROL for h1: the same rolled diamond value arm with NO back
; edge into the condition (the comparand is the constant 0, and the measure
; result feeds nothing carried). If this ACCEPTS and h1 declines §3c, S-1 is the
; ONLY wall for h1 and the per-activation narrowing has a real accept witness.
define i32 @main() {
entry:
  br label %hdr

hdr:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %q = call i32 @cq_theta_si32(i32 9, double 3.000000e-01)
  %r = call i32 @cq_theta_si32(i32 7, double 2.000000e-01)
  %c = icmp sgt i32 %q, 0
  br i1 %c, label %arm, label %merge

arm:
  %r1 = add nsw i32 %r, 3
  br label %merge

merge:
  %rm = phi i32 [ %r1, %arm ], [ %r, %hdr ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  br label %latch

latch:
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %hdr

exit:
  ret i32 %m
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
