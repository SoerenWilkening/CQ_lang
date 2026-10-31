; cq-dtvp: a loop exiting on select(i + 1 < n, q, true), i.e. !(i + 1 < n) | q, has a classical
; disjunct of its exit test (rule 14 case 3, ClassicalBoundQuantumExit), exactly as the `or` form
; `i + 1 >= n || q` does: the loop runs classically over i and n, the carried v advances by the trip
; flag. spine's loops::classify (cq-dtvp), taint's forcingLeaves (cq-wxch) and loops-classical's
; exit split (cq-bea6) all split this select form, so the counter i stays classical and the loop is
; lowered as case 3 (a reverse loop over i), never a K cutoff.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @exit_select_negated(i32 %x0, double %t, i32 %n) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %v = phi i32 [ %x, %entry ], [ %v1, %loop ]
  %v1 = add i32 %v, 1
  %i1 = add nuw nsw i32 %i, 1
  %c = icmp slt i32 %i1, %n
  %q = icmp eq i32 %v1, 7
  %e = select i1 %c, i1 %q, i1 true
  br i1 %e, label %exit, label %loop

exit:
  %m = call i32 @cq_measure_si32(i32 %v1)
  ret i32 %m
}
; CHECK exit_select_negated: add nuw nsw i32 %i, 1
; CHECK exit_select_negated: icmp slt i32 %{{a}}, %n
; CHECK exit_select_negated: call i32 @cqrt_pop()
