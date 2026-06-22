; control_swap_reject_phase_value_escaping.ll — Phase 7.2 Inc 4 DECLINE: a
; tainted-condition `br` whose one exit `ret`s a PHASE-CLASS value (an `Rz` /
; `cq_phi` lineage). Returning a relative phase down a non-reconverging value exit
; is the §2.6 deferred park-coherence interaction: a data-copy of a phase is the
; Rule-7 dephasing leak (P0 0.585 → 0.500, a CNOT copies a basis label, not the
; phase). Conservatively DECLINED with the dedicated `phase-class value escaping`
; diagnostic (§2.11-C-iii), the SAME string `classifyAbortPark` fires for a phase
; sibling beside a recognized abort sink — here the sink is a plain value exit, so
; the OffPattern partition owns it.
;
; The phase check is gated on the ret operand being TAINTED, so a MEASURED return
; (`ret %m`, `%m = cq_measure …`, phase already collapsed) does NOT trip it — that
; is why control_swap_reject_nested_switch.ll's `ret`-of-measure arm stays generic.
; %p below is a raw `cq_phi` result (tainted, never measured), so it does.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}phase-class value escaping under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_phi_si32(i32 %q, double %a)   ; Rz — a relative-phase carrier
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %ph, label %cont
ph:
  ret i32 %p                                       ; phase-class value escaping
cont:
  ret i32 %q
}
