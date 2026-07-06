; spec_reject_fp_select_const_arm.ll — DECLINE (kmdc slice-1 two-derived-arm
; boundary): an fp select with a CONSTANT arm. Materializing a classical arm is a
; proven top-level path but a later widening; slice 1 requires BOTH arms
; non-constant (the fabs shape). isLiftableFpSelect returns false → InBodyControl.
; (Hand-written — clang -O1 often folds a const-arm fp select to llvm.smin/fabs and
; never emits the select at all; this pins the decline for the shape that survives.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
; CHECK-NOT: cqrt_copy_f64_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @ilogb(double)
define i32 @mhelper(i32 %n) {
  %x  = sitofp i32 %n to double
  %c  = icmp slt i32 %n, 0
  %a  = select i1 %c, double %x, double 0.000000e+00   ; false arm CONSTANT
  %r  = call i32 @ilogb(double %a)
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}
