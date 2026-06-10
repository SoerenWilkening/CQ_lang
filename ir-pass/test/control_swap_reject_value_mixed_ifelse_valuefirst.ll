; control_swap_reject_value_mixed_ifelse_valuefirst.ll — heterogeneous if/else
; with the VALUE arm FIRST (then) and the phase arm second (else) — the
; converse arm order of control_swap_reject_value_mixed_ifelse.ll (4.2 WI-3;
; Rule-12 pin for the SawValueArm-then-phase guard; classification is by
; merge-phi incoming identity, never edge order).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}mixed phase/value arm under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  %pt = mul i32 %p, 7                              ; VALUE arm over %p (first)
  br label %merge
else:
  %pe = call i32 @cq_phi_si32(i32 %p, double %a)   ; PHASE arm over %p (second)
  br label %merge
merge:
  %pm = phi i32 [ %pt, %then ], [ %pe, %else ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
