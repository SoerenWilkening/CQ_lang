; spec_reject_fp_select_fcmp.ll — DECLINE (kmdc slice-1 boundary): an fp select
; with an FCMP condition. The fabs sign test folds to an INTEGER `icmp slt i32` at
; -O1; an fcmp-condition select (clamp / min-max) is a separate flag path deferred
; past slice 1. isLiftableFpSelect requires an ICmpInst condition → InBodyControl.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
; CHECK-NOT: cqrt_copy_f64_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @ilogb(double)
define i32 @mhelper(i32 %n) {
  %x  = sitofp i32 %n to double
  %c  = fcmp olt double %x, 0.000000e+00     ; FCMP condition
  %nx = fneg double %x
  %a  = select i1 %c, double %nx, double %x
  %r  = call i32 @ilogb(double %a)
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}
