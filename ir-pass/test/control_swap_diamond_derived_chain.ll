; control_swap_diamond_derived_chain.ll — ACCEPT: diamond on a CHAINED derived base.
;
; TWO unconditional pre-region rotations: `%qd2 = rz(rz(q, x), y)`. The
; arm-block-bounded spine walk must stop at the FIRST out-of-block cq_phi it
; reaches from the arm — %qd2, the LIVE register — and gate on THAT, leaving the
; whole pre-region chain (%qd1, %qd2) to ordinary rotation lowering. Both
; pre-region `cqrt_rz` lines fire in program order strictly BEFORE the flag
; mint; neither is collected as an arm gate (a walk that hops the chain would
; replay/erase shared pre-region gates — the WI-3 double-erase family).
;
; Under the §6a control-in-place peephole there is no work rail: the single arm
; gate is emitted as `cqrt_rz_i32_controlled(flag, %qd2, %a)` on the register
; itself. The no-replay property is now pinned by SYMBOL as well as position —
; exactly ONE `cqrt_rz_i32_controlled` (the arm gate) and exactly TWO uncontrolled
; `cqrt_rz_i32` (the pre-region chain). A walk that hopped the chain would show up
; as three controlled rotations.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; Independent EXACT arm-gate / pre-region-gate counts (the no-replay postcondition).
; RUN: %filecheck %s --check-prefix=RZCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PRECNT < %t.cqd0.ll
; The route's ABSENCE, anchored at the function header so the window is the whole
; function (a trailing CHECK-NOT scans only past the LAST positive of its prefix,
; and every route line would land BEFORE that — it could never fire).
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (mixed sites: see the migration report)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; the WHOLE pre-region chain lowers as plain unconditional Rz, in program order,
; before the flag mint — none of it is replayed on the rail
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[Q]], double 1.250000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[Q]], double 3.750000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; exactly ONE arm gate, controlled and in place (the chain must not be re-played here)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; Exactly one CONTROLLED rotation — the single arm gate.
; RZCNT-COUNT-1: call void @cqrt_rz_i32_controlled(
; RZCNT-NOT:     call void @cqrt_rz_i32_controlled(

; Exactly two UNCONTROLLED rotations — the pre-region chain, neither replayed.
; PRECNT-COUNT-2: call void @cqrt_rz_i32(
; PRECNT-NOT:     call void @cqrt_rz_i32(

; No swap route survives: no |0> work rail, no CSWAP, no copy, no data mux —
; window is `define` -> EOF, so a re-introduced route WOULD trip these.
; NOROUTE:     define i32 @example
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: phi i32
