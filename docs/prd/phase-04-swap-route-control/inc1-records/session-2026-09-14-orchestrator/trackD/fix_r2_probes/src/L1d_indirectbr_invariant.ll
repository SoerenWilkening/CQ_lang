; leg 1 boundary: the back edge is an `indirectbr`. `reachesWithoutBarrier` walks
; succ_begin/succ_end, which enumerates the listed destinations. Must DECLINE.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u1, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %b = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %mm = call i32 @cq_measure_si32(i32 %b)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  %tgt = select i1 %done, ptr blockaddress(@example, %exit), ptr blockaddress(@example, %loop)
  indirectbr ptr %tgt, [ label %exit, label %loop ]
exit:
  ret i32 %mm
}
