; spec_reject_fp_select_f16.ll — DECLINE probe (bd adia whitelist edge): a
; HALF (f16) fp select in a lifted clone body. The adia widening admitted
; exactly f80 into `isLiftableFpSelect` (`isAdmissibleCloneSelect` since bd
; p3kd.7.1, same fp width set) (the coshl/floorl need); f16 stays on
; the explicit whitelist's outside — no tested coverage, so it keeps the loud
; InBodyControl decline (Prime Directive: never accept an unproven-in-test
; shape). The f16 edge pin for the {f32,f64,f80} accept set.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
; CHECK-NOT: cqrt_copy_f16_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @mhelper(i32 %n) {
  %x  = sitofp i32 %n to half
  %c  = icmp slt i32 %n, 0
  %nx = fneg half %x
  %a  = select i1 %c, half %nx, half %x
  %r  = fptosi half %a to i32
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}
