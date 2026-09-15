; x1 — the prep is INSIDE a bounded loop; the phase kickback reads the merge phi
; AFTER the loop, i.e. its EXIT value (the LAST trip's). The gap is the latch +
; the exit edge. `Cyclic = isPotentiallyReachable(Pred=%exit, DefBB=%m)` is FALSE
; here, so the walk starts at Def->next. This is the shape the CFG-bounded scan
; has to get right for a loop-carried rail whose reader is outside the loop.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br label %hdr
hdr:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  br i1 %b0, label %arm, label %m
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %m
m:
  %M = phi i1 [ %t, %arm ], [ false, %hdr ]
  br label %latch
latch:
  %inext = add i32 %i, 1
  %cc = icmp slt i32 %inext, 4
  br i1 %cc, label %hdr, label %exit
exit:
  br i1 %M, label %ph, label %post
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %post
post:
  %mm = call i1 @cq_measure_i1(i1 %M)
  ret i1 %mm
}
