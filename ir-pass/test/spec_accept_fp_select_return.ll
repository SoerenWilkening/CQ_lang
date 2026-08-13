; spec_accept_fp_select_return.ll — bd 3c6m.54 (supersedes the deleted kmdc
; `spec_reject_fp_select_return.ll`): an fp-select clone (the fabs `(x<0)?-x:x`
; shape) whose fp select result is the fp RETURN now ACCEPTS. The kmdc R1
; precondition (`RetW == "i32"`, which used to DECLINE this) is LIFTED: the fp
; return copies out to an i32 handle (`cqrt_copy_f64`), and the escaping i32 handle
; is backstopped by the top-level `declineTaintedAngle` fence if a caller ever
; steers it toward a rotation angle (see `spec_reject_fp_return_used_as_angle.ll`).
; The caller's `fptosi double %r` recovers the fp source width from the recorded
; result HandleWidth (`cq_template_fptosi_f64_to_i32`, not a decline).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
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

; The clone: fp select via the 4.4 controlled-XOR copy (kmdc), fp return copied out.
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_mhelper_1(i32 %{{[a-zA-Z0-9_.]+}})
; The caller's fptosi recovers the fp width from the result HandleWidth (NOT a decline).
; CHECK:     call i32 @cq_template_fptosi_f64_to_i32(i32 %[[R]])
; CHECK:     define internal i32 @__cq_q_mhelper_1(i32 %n)
; The fp select's |0> rail, then its controlled-XOR copy (kmdc).
; CHECK:     %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[SEL]])
; The fp RETURN copy-out: a SECOND |0> rail + the UNcontrolled cqrt_copy_f64.
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64(i32 %[[SEL]], i32 %[[OUT]])
; CHECK:     ret i32 %[[OUT]]
; CHECK-NOT: floating-point quantum argument or return has no reversible copy
