; SCOPE §15.4 — P3 admits an `Argument` incoming. `%u` is a classical function
; argument used as one arm of the peeled mux.
define i32 @example(i32 %u) {
entry:
  %b0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %b0, 1
  br i1 %c, label %merge, label %arm
arm:
  %t = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %merge
merge:
  %amux = phi i32 [ %u, %arm ], [ 2, %entry ]
  %b1 = phi i32 [ %t, %arm ], [ 0, %entry ]
  %m1 = call i32 @cq_measure_si32(i32 %b1)
  %ma = call i32 @cq_measure_si32(i32 %amux)
  %s = add nsw i32 %m1, %ma
  ret i32 %s
}
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
