; OVER-DECLINE PROBE: the chain's pre-loop incoming is a CONSTANT, so `phiTracksWire`
; refuses the phi for a reason that has nothing to do with staleness. The wire IS
; re-established every trip by the reader itself.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example() {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %p = phi i32 [ 7, %entry ], [ %r, %loop ]
  %r = call i32 @cq_theta_si32(i32 %p, double 9.000000e-01)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
