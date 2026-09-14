; leg 1 boundary: a SINGLE-BLOCK loop carrying the chain. The header phi IS the
; barrier and it lives in the SAME block as the reader, which `reachesWithoutBarrier`
; reaches only by re-entering `From`'s own block from the TOP. Must ACCEPT.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %p = phi i32 [ %q, %entry ], [ %r, %loop ]
  %r = call i32 @cq_theta_si32(i32 %p, double 9.000000e-01)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
