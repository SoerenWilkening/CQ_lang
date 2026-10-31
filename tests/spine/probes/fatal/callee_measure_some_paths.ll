; cq-ihlt: the callee measures its formal on one classical path only, then the caller measures a
; value computed from it: no single re-read point; an internal error, never an output.
; FATAL: the callee measures it on some paths only
target triple = "x86_64-apple-macosx16.0.0"
define i32 @f(i32 %x0, double %th, i32 %k, i32 %c) {
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  %y = add nsw i32 %x, %c
  %m = tail call fastcc i32 @readout(i32 %x, i32 %k)
  %my = tail call i32 @cq_measure_si32(i32 %y)
  %r = add nsw i32 %my, %m
  ret i32 %r
}
define internal fastcc i32 @readout(i32 %v, i32 %k) noinline {
entry:
  %t = icmp sgt i32 %k, 0
  br i1 %t, label %meas, label %done
meas:
  %m = tail call i32 @cq_measure_si32(i32 %v)
  br label %done
done:
  %r = phi i32 [ %m, %meas ], [ %k, %entry ]
  ret i32 %r
}
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
