; spec_reject_fp_select_mixed.ll — DECLINE (kmdc, the load-bearing taint re-proof):
; a shape-accepted fp select whose CONDITION tests a CLASSICAL param while the arms
; derive from a TAINTED param — a classical flag over quantum fp data, no proven
; lowering. The SpecializeReject shape gate is taint-blind; lowerCloneSelect
; re-proves the condition AND BOTH arms tainted and loudly declines a mix.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: mixed classical/quantum fp select under quantum lift
; CHECK-NOT: cqrt_copy_f64_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @ilogb(double)
define i32 @mhelper(i32 %n, i32 %m) {
  %x  = sitofp i32 %n to double        ; arms derive from TAINTED %n
  %c  = icmp slt i32 %m, 0             ; condition tests CLASSICAL %m
  %nx = fneg double %x
  %a  = select i1 %c, double %nx, double %x
  %r  = call i32 @ilogb(double %a)
  ret i32 %r
}
define void @example(i32 %u0, i32 %u1) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q, i32 %u1)   ; arg0 tainted, arg1 classical
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}
