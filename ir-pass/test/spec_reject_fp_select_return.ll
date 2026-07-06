; spec_reject_fp_select_return.ll — DECLINE (kmdc, the LOAD-BEARING R1 gate): a
; helper whose fp select result is the fp RETURN. The clone would return double,
; so RetW != "i32" → FpAbi decline. This gate is what confines fp to clone-internal
; scratch (an fp value never crosses the clone boundary toward a caller angle);
; NEVER relax it while fp selects are accepted. Verified live.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: floating-point quantum argument or return has no reversible copy
; CHECK-NOT: cqrt_copy_f64_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define double @mhelper(i32 %n) {
  %x  = sitofp i32 %n to double
  %c  = icmp slt i32 %n, 0
  %nx = fneg double %x
  %a  = select i1 %c, double %nx, double %x
  ret double %a
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call double @mhelper(i32 %q)
  %ri = fptosi double %r to i32
  %m = call i32 @cq_measure_si32(i32 %ri)
  ret void
}
