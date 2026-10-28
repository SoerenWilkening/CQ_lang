; A prep of a classical value under a quantum predicate with a quantum angle needs rule 10's register
; (the merge names one rail seeded with the straight-through value) with rule 15's primitive: not built
; yet, an internal error, never a lowering.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @prep_controlled(i32 %x0, i32 %r0, double %t, double %c, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %xd = sitofp i32 %x to double
  %a = fmul double %xd, %c
  %f = icmp sgt i32 %x, %k
  br i1 %f, label %then, label %done
then:
  %r = call i32 @cq_theta_si32(i32 %r0, double %a)
  br label %done
done:
  %rr = phi i32 [ %r, %then ], [ %r0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rr)
  ret i32 %m
}
; EXPECT-ERROR: cq: unimplemented: rot-qangle: a prep of a classical value under a quantum predicate with a quantum angle
