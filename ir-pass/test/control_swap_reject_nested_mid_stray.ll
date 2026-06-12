; control_swap_reject_nested_mid_stray.ll — DECLINE: the outer arm (Mid) holds a
; stray op beside its phase gate + the inner condition/branch (COMPLETENESS#5).
;
; Mid legitimately carries the intervening cq_phi gate, the inner cond, and the
; inner br; the Mid purity carve-out narrows the rejection to EXACTLY that
; content. Here Mid ALSO holds `%s7 = q*7` (a value op feeding a non-merge sink,
; neither a merge edge nor a value arm). The whole-block Mid scan still catches
; it → `impure phase arm` (a spine-only walk would silently ACCEPT the stray and
; the emitter would drop %s7 on flatten — a verify-clean over-accept / dangling-
; taint UAF; this fixture pins that door shut).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %g  = call i32 @cq_phi_si32(i32 %q, double %b)
  %s7 = mul nsw i32 %g, 7
  %sm = call i32 @cq_measure_si32(i32 %s7)
  %c2 = icmp slt i32 %g, 9
  br i1 %c2, label %arm, label %merge
arm:
  %h  = call i32 @cq_phi_si32(i32 %g, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %h, %arm ], [ %g, %mid ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; CHECK: error{{.*}}impure phase arm under quantum control
