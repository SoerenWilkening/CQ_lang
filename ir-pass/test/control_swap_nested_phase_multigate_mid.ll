; control_swap_nested_phase_multigate_mid.ll — ACCEPT: depth-2 phase nest whose
; outer arm (`Mid`) holds TWO intervening Rz gates and the inner condition reads
; the LAST one (an intermediate diagonal alias). Positive coverage for the WI-3
; criterion-5 strengthening (§8 review 2026-06-12): the inner compare's tainted
; operand must be a DIRECT rail-closure member — and a multi-gate Mid's `%g2`
; (= cq_phi(cq_phi(%q,b1),b2)) IS one (Rz preserves the basis value, so every
; closure member compares equal to rail1). The criterion-5 fix declines a NON-
; diagonal derived operand (`add %g,1`) but must NOT decline a diagonal alias —
; this pins that it doesn't over-decline. Both intervening gates replay verbatim on
; rail1 before the inner mint; ZERO controlled gates, EXACTLY FOUR cqrt_free.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b1, double %b2) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %g1 = call i32 @cq_phi_si32(i32 %q, double %b1)
  %g2 = call i32 @cq_phi_si32(i32 %g1, double %b2)
  %c2 = icmp slt i32 %g2, 9
  br i1 %c2, label %arm, label %merge
arm:
  %h  = call i32 @cq_phi_si32(i32 %g2, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %h, %arm ], [ %g2, %mid ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; 1 outer mint + route-in
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     %[[R1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[Q]], i32 %[[R1]])
; 2 BOTH intervening gates replay on rail1, in forward program order
; CHECK:     call void @cqrt_rz_i32(i32 %[[R1]], double %b1)
; CHECK:     call void @cqrt_rz_i32(i32 %[[R1]], double %b2)
; 3 inner mint FROM RAIL1 + route + gate + route-back
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[R1]], i32 9)
; CHECK:     %[[R2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F2]], i32 %[[R1]], i32 %[[R2]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R2]], double %a)
; CHECK:     call void @cqrt_cswap(i32 %[[F2]], i32 %[[R1]], i32 %[[R2]])
; 4 inner clean-up (LIFO) + 5 outer route-back + clean-up
; CHECK:     call void @cqrt_free(i32 %[[R2]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[R1]], i32 9)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[Q]], i32 %[[R1]])
; CHECK:     call void @cqrt_free(i32 %[[R1]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])

; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: phi i32

; Exactly four frees.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
; CNT-COUNT-4: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
