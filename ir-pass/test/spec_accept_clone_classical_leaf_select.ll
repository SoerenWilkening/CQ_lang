; spec_accept_clone_classical_leaf_select.ll — ACCEPT (bd test_C_libtooling-p3kd.3),
; the plain-C spelling of spec_accept_clone_classical_leaf.ll:
;
;   __attribute__((noinline)) int helper(int b, int k) {
;     return (b > 5 & k > 3) ? b * 3 : b ^ 6;   // b quantum, k classical
;   }
;   int f(int u, int k) { int q = u; cq_theta(&q, .5); return cq_measure(helper(q, k)); }
;
; `clang -O1` (19.1.7) emits the body below for `&`, for `&&` and for the
; `if (b > 5 && k > 3) r = b * 3; else r = b ^ 6;` spelling alike (measured):
; a STRAIGHT-LINE `select` on `and i1 (icmp b), (icmp k)`; no diamond reaches the
; clone's PredMux flatten.
;
; WAS: `cq specialization: callee contains tainted control flow under quantum
; lift`, at the select, BEFORE the per-leaf fence. `scanBody`'s shape gate
; `isLiftableSelect` admitted a straight-line select only on a bare `icmp`
; condition, while `lowerCloneSelect` lowers any `collectCondTree` condition (the
; same select reached through a flattened diamond compiled, 5po2 I2). The gate now
; asks that grammar for the two-arm shape. Then the classical leaf `k > 3` is the
; network's classical literal (spec_accept_clone_classical_leaf.ll has the
; trace argument): `gl = and_i1_hl(icmp_sgt_i32_hl(b, 5), k > 3)`, out = gl ? 3b :
; b^6, the source's value on every basis state; the Bennett reverse returns every
; scratch rail to |0> before its free.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ERR --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=PHANTOM < %t.cqd0.ll
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @helper(i32 noundef %b, i32 noundef %k) {
  %c1 = icmp sgt i32 %b, 5
  %c2 = icmp sgt i32 %k, 3
  %c = and i1 %c1, %c2
  %t = mul nsw i32 %b, 3
  %e = xor i32 %b, 6
  %s = select i1 %c, i32 %t, i32 %e
  ret i32 %s
}

define i32 @f(i32 noundef %u, i32 noundef %k) {
  %q = tail call i32 @cq_theta_si32(i32 noundef %u, double noundef 5.000000e-01)
  %r = tail call i32 @helper(i32 noundef %q, i32 noundef %k)
  %m = tail call i32 @cq_measure_si32(i32 noundef %r)
  ret i32 %m
}

; ERR-NOT: error
; ERR-NOT: warning
;
; CHECK-LABEL: define i32 @f(
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = {{(tail )?}}call i32 @__cq_q_helper_01(i32 noundef %[[H]], i32 noundef %k)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R]])
;
; CHECK-LABEL: define internal i32 @__cq_q_helper_01(
; CHECK-DAG: %[[C2:[a-zA-Z0-9_.]+]] = icmp sgt i32 %k, 3
; CHECK-DAG: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %b, i32 3)
; CHECK-DAG: %[[E:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %b, i32 6)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %b, i32 5)
; CHECK-NEXT: %[[GL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[F1]], i1 zeroext %[[C2]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[GL]], i32 %[[T]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[GL]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[GL]], i32 %[[E]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[GL]])
; CHECK-NEXT: %[[RES:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[OUT]], i32 %[[RES]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[GL]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[GL]], i32 %[[E]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[GL]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[GL]], i32 %[[T]], i32 %[[OUT]])
; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[GL]], i32 %[[F1]], i1 %[[C2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %b, i32 5)
; CHECK-NEXT: call void @cq_template_xor_i32_hl_unc(i32 %[[E]], i32 %b, i32 6)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T]], i32 %b, i32 3)
; CHECK-DAG: call void @cqrt_free(i32 %[[GL]])
; CHECK-DAG: call void @cqrt_free(i32 %[[F1]])
; CHECK-DAG: call void @cqrt_free(i32 %[[OUT]])
; CHECK-DAG: call void @cqrt_free(i32 %[[T]])
; CHECK-DAG: call void @cqrt_free(i32 %[[E]])
; CHECK:     ret i32 %[[RES]]
; CHECK:     declare void @cq_template_and_i1_hl_unc(i32, i32, i1 zeroext)
;
; PHANTOM-NOT: cq_template_icmp_sgt_i32_hl(i32 %k
