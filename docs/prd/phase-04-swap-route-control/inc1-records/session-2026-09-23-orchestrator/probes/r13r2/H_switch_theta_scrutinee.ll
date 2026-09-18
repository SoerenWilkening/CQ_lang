; The SWITCH scrutinee is the user's own `cq_theta_si32` CALL.  E6 applies NO
; cond-tree grammar to a switch scrutinee (only taint + isMuxableType), and
; run()'s `track(SI->getCondition())` puts it in MaybeDead with no filter.
; All merge phis are constant-false so every edge-predicate term drops, the
; minted `icmp eq`s die, and the scrutinee drops to zero uses.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %s = call i32 @cq_theta_si32(i32 %u, double 7.000000e-01)
  switch i32 %s, label %merge [ i32 1, label %arm ]
arm:
  br label %merge
merge:
  %p1 = phi i1 [ false, %arm ], [ false, %entry ]
  %p2 = phi i1 [ false, %arm ], [ false, %entry ]
  %z1 = zext i1 %p1 to i32
  %z2 = zext i1 %p2 to i32
  %m  = call i32 @cq_measure_si32(i32 %q)
  %a  = add i32 %z1, %z2
  %b  = add i32 %a, %m
  ret i32 %b
}
