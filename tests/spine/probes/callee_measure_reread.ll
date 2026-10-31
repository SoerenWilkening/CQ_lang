; cq-ihlt (decision A on CR rule 2): y = x + c, readout(x) measures x in the clone, cq_measure(y):
; the caller re-reads x's measured rail right after the clone call and y is m_x + c classically.
; CHECK f: call fastcc i32 @__cq_q_readout_10(i32 %{{x}}, i32 %{{k}})
; CHECK f: = call i32 @cqrt_measure_i32(i32 %{{x}}), !cq.measure
; CHECK-COUNT f: @cqrt_measure_i32( 1
; CHECK-COUNT f: call void @cqrt_free( 1
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
  %m = tail call i32 @cq_measure_si32(i32 %v)
  %r = tail call i32 @llvm.smax.i32(i32 %m, i32 %k)
  ret i32 %r
}
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.smax.i32(i32, i32)
