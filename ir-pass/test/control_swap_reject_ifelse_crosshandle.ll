; control_swap_reject_ifelse_crosshandle.ll — DECLINE: if/else over TWO handles.
;
; `if (q > 5) { rz(q, a); } else { rz(p, b); }` — both arms are pure phase chains,
; but the then-arm rotates the routed handle %q while the else-arm rotates a
; DIFFERENT tainted source %p. A swap-route if/else routes ONE shared handle and
; strips the flag with icmp_inv(q); muxing a phase of %p against a phase of %q has
; no single routed handle, so the strip would be invalid. classifyArms anchors the
; routed handle on the first arm's base (%q) and rejects the second arm because its
; base (%p) != the routed handle → loud decline ("control flow"), lower nothing.
;
; The existing control_swap_reject_crosshandle.ll exercises the DIAMOND path; this
; pins the same guard on the TWO-ARM if/else path (the second-arm Base==Routed
; check, which the diamond fixture never reaches).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  %qt = call i32 @cq_phi_si32(i32 %q, double %a)   ; rotates the routed %q
  br label %merge
else:
  %pe = call i32 @cq_phi_si32(i32 %p, double %b)   ; rotates a DIFFERENT handle %p
  br label %merge
merge:
  %qm = phi i32 [ %qt, %then ], [ %pe, %else ]     ; muxes phase-of-%q vs phase-of-%p
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK: error{{.*}}control flow under quantum control
