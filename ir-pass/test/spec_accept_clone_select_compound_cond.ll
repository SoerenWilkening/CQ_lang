; spec_accept_clone_select_compound_cond.ll — ACCEPT (bd test_C_libtooling-p3kd.3,
; L9 disclosure). `scanBody`'s select gate `isLiftableSelect` admitted a
; STRAIGHT-LINE select only on a bare `icmp` condition; bd p3kd.3 made it ask the
; `collectCondTree` grammar `lowerCloneSelect` lowers, for the two-arm shape (both
; arms non-constant, every compare leaf an `icmp`, no register leaf). Since bd
; p3kd.7.1 the gate (`isAdmissibleCloneSelect`) asks no grammar and admits every
; select a mask could lower; the condition is `lowerCloneSelect`'s. That newly
; admits a compound condition whose leaves are ALL quantum, the
; `(a > 5 & b < 9) ? a * 3 : b ^ 6` spelling below (clang -O1's straight-line
; form of `&`/`&&` over cheap compares). The SAME condition reached through a
; branch diamond already lowered (5po2 I2): this is that network, unchanged.
;
; SEMANTIC EVIDENCE (basis-state trace). For basis values (va, vb):
; `f1 = icmp_sgt_i32_hl(a, 5)` holds [va>5], `f2 = icmp_slt_i32_hl(b, 9)` holds
; [vb<9], `g` (fresh |0> i1) gets `toffoli(f1, f2, g)` = [va>5]∧[vb<9]; `out`
; (fresh |0>) receives 3·va under g and vb⊕6 under ¬g (inside the `cqrt_x(g)`
; bracket), the source's select. The Bennett wrap copies `out` to the result, then the
; reverse replays the copies (out → |0>), the toffoli (g → |0>), both compare
; `_unc`s and both arm `_unc`s; every freed rail is |0>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ERR --allow-empty < %t.err
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @helper(i32 noundef %a, i32 noundef %b) {
  %c1 = icmp sgt i32 %a, 5
  %c2 = icmp slt i32 %b, 9
  %c = and i1 %c1, %c2
  %t = mul nsw i32 %a, 3
  %e = xor i32 %b, 6
  %s = select i1 %c, i32 %t, i32 %e
  ret i32 %s
}

define i32 @f(i32 noundef %u, i32 noundef %v) {
  %qa = tail call i32 @cq_theta_si32(i32 noundef %u, double noundef 5.000000e-01)
  %qb = tail call i32 @cq_theta_si32(i32 noundef %v, double noundef 2.500000e-01)
  %r = tail call i32 @helper(i32 noundef %qa, i32 noundef %qb)
  %m = tail call i32 @cq_measure_si32(i32 noundef %r)
  ret i32 %m
}

; ERR-NOT: error
; ERR-NOT: warning
;
; CHECK-LABEL: define i32 @f(
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = {{(tail )?}}call i32 @__cq_q_helper_11(
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R]])
;
; CHECK-LABEL: define internal i32 @__cq_q_helper_11(
; CHECK-DAG: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %a, i32 3)
; CHECK-DAG: %[[E:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %b, i32 6)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %a, i32 5)
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %b, i32 9)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 {{false|0}})
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[T]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[E]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: %[[RES:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[OUT]], i32 %[[RES]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[E]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[T]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %b, i32 9)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %a, i32 5)
; CHECK-DAG: call void @cqrt_free(i32 %[[G]])
; CHECK-DAG: call void @cqrt_free(i32 %[[F1]])
; CHECK-DAG: call void @cqrt_free(i32 %[[F2]])
; CHECK-DAG: call void @cqrt_free(i32 %[[OUT]])
; CHECK:     ret i32 %[[RES]]
