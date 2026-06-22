; control_swap_reject_abort_phase_sibling.ll — Phase 7.2 Inc 3 DECLINE probe: a
; PHASE-class value (`%p = cq_phi(q)`, an Rz / relative-phase carrier) escapes via
; the sibling beside the abort park arm (PRD-7.2 §2.6 deferred interaction /
; §2.11-C-iii; the issue's RED->GREEN negative #2).
;
; Whether the §2.8 `cqrt_cswap` park preserves the relative phase on the surviving
; arm's escaping value is NOT yet proven, so `classifyAbortPark` CONSERVATIVELY
; DECLINES `phase-class value escaping` rather than asserting an outcome (a silent
; XOR/route of a phase dephases it — the verify-clean P0 0.585->0.500 family,
; Rule 7). Never silently route it onto the in-place phase-escape path.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}phase-class value escaping under quantum control
; CHECK-NOT: cqrt_cswap

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort()

define i32 @slice() {
  %q = call i32 @cq_theta_si32(i32 5, double 5.000000e-01)
  %p = call i32 @cq_phi_si32(i32 %q, double 2.500000e-01)   ; phase-class (Rz)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %a, label %cont
a:
  call void @abort()
  unreachable
cont:
  %m = call i32 @cq_measure_si32(i32 %p)    ; the phase-class value escapes here
  ret i32 %m
}
