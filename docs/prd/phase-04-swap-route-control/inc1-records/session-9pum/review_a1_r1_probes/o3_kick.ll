; O-3 attack: the kickback round-2 window PLUS a post-region theta on the
; condition wire that is visible TAINT-BLIND (so reverifyCmpCondReads' second
; call suppresses the whole rung-(iii) re-ask) and PROVEN post-region at round 1
; (so condWireDisposition returns ProvenPostRegion and the classifier accepts).
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge

arm:
  %r = call i32 @f(i32 4)
  br label %merge

merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %keep = add i32 %y, 0
  br label %second

second:
  %b = call i32 @cq_theta_si32(i32 %y, double 5.000000e-01)
  %b3 = call i32 @cq_theta_si32(i32 %y, double 9.000000e-01)
  %cc = icmp sgt i32 %b, 0
  br i1 %cc, label %ph, label %join

ph:
  call void @cq_phi(double 7.000000e-01)
  br label %join

join:
  %b2 = call i32 @cq_theta_si32(i32 %b, double -5.000000e-01)
  %mm = call i32 @cq_measure_si32(i32 %b3)
  %m2 = call i32 @cq_measure_si32(i32 %b2)
  %t0 = add i32 %mm, %keep
  %t = add i32 %t0, %m2
  ret i32 %t
}

attributes #0 = { nounwind willreturn memory(none) }
