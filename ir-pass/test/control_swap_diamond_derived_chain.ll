; control_swap_diamond_derived_chain.ll — ACCEPT: diamond on a CHAINED derived base.
;
; TWO unconditional pre-region rotations: `%qd2 = rz(rz(q, x), y)`. The
; arm-block-bounded spine walk must stop at the FIRST out-of-block cq_phi it
; reaches from the arm — %qd2, the LIVE register — and route THAT, leaving the
; whole pre-region chain (%qd1, %qd2) to ordinary rotation lowering. Both
; pre-region `cqrt_rz` lines fire in program order strictly BEFORE the flag
; mint; neither is collected as an arm gate (a walk that hops the chain would
; replay/erase shared pre-region gates — the WI-3 double-erase family).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd1 = call i32 @cq_phi_si32(i32 %q,   double 1.250000e-01)  ; pre-rotation 1
  %qd2 = call i32 @cq_phi_si32(i32 %qd1, double 3.750000e-01)  ; pre-rotation 2 — the LIVE base
  %c = icmp sgt i32 %qd2, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %qd2, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %qd2, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; the WHOLE pre-region chain lowers as plain unconditional Rz, in program order,
; before the flag mint — none of it is replayed on the rail
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[Q]], double 1.250000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[Q]], double 3.750000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; exactly ONE arm gate on the rail (the chain must not be re-played here)
; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %a)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_free(i32 %[[T]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
