; leg 1 boundary: an IRREDUCIBLE two-entry cycle whose reader reads a loop-INVARIANT
; name. `reachesWithoutBarrier` is a plain successor walk with no loop-info, so it
; must still see the cycle. Must DECLINE.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u1, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br i1 %c, label %A, label %B
A:
  %b = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %mm = call i32 @cq_measure_si32(i32 %b)
  br label %B
B:
  %t = phi i32 [ 0, %entry ], [ %mm, %A ]
  %d = icmp sgt i32 %t, 3
  br i1 %d, label %exit, label %A
exit:
  ret i32 %t
}
