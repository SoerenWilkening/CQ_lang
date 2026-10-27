; Rule 2: dominated uses of a measured value read the outcome; a re-measurement is a classical re-read;
; cq_theta on the measured value mints a new register from the outcome. Classical control flow and a
; classical loop in a tainted function stay classical.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @collapse(i32 %x0, double %t, i32 %n) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %m = call i32 @cq_measure_si32(i32 %x)
  %y = add i32 %x, 7
  %m2 = call i32 @cq_measure_si32(i32 %x)
  %z = call i32 @cq_theta_si32(i32 %x, double %t)
  %c = icmp sgt i32 %n, 0
  br i1 %c, label %loop, label %done
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %i1 = add i32 %i, 1
  %e = icmp eq i32 %i1, %n
  br i1 %e, label %done, label %loop
done:
  %k = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %mz = call i32 @cq_measure_si32(i32 %z)
  %s1 = add i32 %y, %m2
  %s2 = add i32 %s1, %k
  %s3 = add i32 %s2, %mz
  ret i32 %s3
}
; CHECK collapse: %{{y}} = add i32 %{{m}}, 7
; CHECK collapse: call i32 @cqrt_alloc_i32(i32 %{{m}})
; CHECK collapse: phi i32
; CHECK collapse: br i1
; CHECK-COUNT collapse: cqrt_measure_i32 2
