; control_swap_reject_stalecond_chained_theta.ll
;
; The compare precedes an Ry on its source; minting the flag at the later branch reads the wrong basis.
;
; Safety net for a stale condition (NORTHSTAR goal 1).
; Preserving the earlier predicate with coherent basis fanout is valid; it is not
; unknown-state cloning. The lowering must retain its correlations across Ry,
; and may free the flag only after proving it clean. The current late-mint path
; cannot do that, so keep the loud diagnostic until the lowering is implemented.
; Retire this negative after analytic and trace evidence establishes the source
; condition and subsequent interference, without inserting a measure.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %t2, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; chained Ry AFTER the compare
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
