; spec_reject_fp_select_f80.ll — DECLINE (kmdc slice-1 width whitelist): an
; x86_fp80 (long double) fp select. cqrt_copy_f80_controlled / cqrt_alloc_f80 exist,
; but slice 1 gates on an EXPLICIT {f32,f64} whitelist (NOT abiWidthHasControlledFpCopy)
; so f16/f80 have NO coverage and decline (Prime Directive: never accept an
; unproven-in-test shape). isLiftableFpSelect returns false → InBodyControl.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
; CHECK-NOT: cqrt_copy_f80_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @ilogbl(x86_fp80)
define i32 @mhelper(i32 %n) {
  %x  = sitofp i32 %n to x86_fp80
  %c  = icmp slt i32 %n, 0
  %nx = fneg x86_fp80 %x
  %a  = select i1 %c, x86_fp80 %nx, x86_fp80 %x
  %r  = call i32 @ilogbl(x86_fp80 %a)
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}
