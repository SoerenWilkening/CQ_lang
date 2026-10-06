; libm_bind_accept_second_round.ll — bd 3c6m.72, review round 2: the `cbrt`
; operand is tainted only after promoteVolatileScalarLocals (a non-escaping
; volatile local, R16), so the FIRST bindLibmCalls sees a classical call. The
; KeepBindable early sweep keeps `__cq_libm_cbrt` (a program call could bind
; to it), and the re-ask before detectSpecializations binds and lifts it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=GONE < %t.ll
; CHECK:     define double @g(double noundef %0)
; CHECK:     call i32 @__cq_q___cq_libm_cbrt_1(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     define internal i32 @__cq_q___cq_libm_cbrt_1(i32 %x)
; GONE-NOT:  @__cq_libm_cbrt(
declare double @cq_theta_f64(double noundef, double noundef)
declare double @cq_measure_f64(double noundef)
declare double @cbrt(double noundef)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

define double @__cq_libm_cbrt(double %x) {
  %y = fadd double %x, 2.000000e+00
  ret double %y
}

define double @g(double noundef %0) {
  %2 = alloca double, align 8
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  store volatile double %3, ptr %2, align 8
  %4 = load volatile double, ptr %2, align 8
  %5 = tail call double @cbrt(double noundef %4)
  %6 = tail call double @cq_measure_f64(double noundef %5)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  ret double %6
}
