; spec_accept_transitive.ll — Phase 6.3 WI-3.2/3.3/3.6: the transitive worklist.
; A clone whose body calls another pure-classical fn with a tainted (post-seed)
; argument specializes the INNER call too. `outer(t)` calls `inner(t)`; both
; @__cq_q_outer_1 and @__cq_q_inner_1 synthesize, the inner retarget lives INSIDE
; the outer clone, and the outer Bennett wrap's reverse COVERS the inner call via
; the inner's void uncompute twin @__cq_q_inner_1_unc (zeroing the entangled inner
; result rail before it is freed, so the borrowed quantum input `t` is restored —
; Rule 6/8). The two clone bodies lower under their OWN disjoint cloneTaint, so no
; gate is double-adjointed (3.6).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=COUNT %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @inner(i32 %a) {
entry:
  %y = mul i32 %a, 7
  ret i32 %y
}

define i32 @outer(i32 %t) {
entry:
  %u = call i32 @inner(i32 %t)
  %r = add i32 %u, 1
  ret i32 %r
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = call i32 @outer(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %s)
  ret void
}

; Caller: theta lowered; the call retargets to the OUTER clone; result measured.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:      %[[S:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_outer_1(i32 %[[H]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[S]])

; Outer clone: the inner clone call is an ordinary forward handle op; the add
; lowers to a template; the reverse is LIFO (add_unc THEN the inner twin), then
; both scratch rails free, then the basis copy returns.
; CHECK:      define internal i32 @__cq_q_outer_1(i32 %t)
; CHECK:      %[[U:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_inner_1(i32 %t)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[U]], i32 1)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[R]], i32 %[[OUT]])
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[R]], i32 %[[U]], i32 1)
; CHECK-NEXT: call void @__cq_q_inner_1_unc(i32 %[[U]], i32 %t)
; CHECK-NEXT: call void @cqrt_free(i32 %[[U]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT: ret i32 %[[OUT]]

; Inner forward clone: the canonical single-op Bennett wrap.
; CHECK:      define internal i32 @__cq_q_inner_1(i32 %a)
; CHECK:      %[[IMUL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %a, i32 7)
; CHECK-NEXT: %[[IOUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[IMUL]], i32 %[[IOUT]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[IMUL]], i32 %a, i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[IMUL]])
; CHECK-NEXT: ret i32 %[[IOUT]]

; Inner uncompute twin: `out` is a PARAMETER (no internal alloc), the copy XORs
; the recomputed result into it (zeroing it), the scratch is reversed + freed, and
; it returns void. This is the adjoint the outer wrap calls.
; CHECK:      define internal void @__cq_q_inner_1_unc(i32 %out, i32 %a)
; CHECK:      %[[TMUL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %a, i32 7)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[TMUL]], i32 %out)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[TMUL]], i32 %a, i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[TMUL]])
; CHECK-NEXT: ret void

; No escape decline; the original intrinsic is gone; exactly ONE inner clone and
; ONE twin synthesize (the inner is not double-emitted).
; CHECK-NOT:  cq taint escape
; CHECK-NOT:  cq_theta_si32
; COUNT-COUNT-1: define internal i32 @__cq_q_inner_1(
; COUNT-NOT:     define internal i32 @__cq_q_inner_1(
; COUNT-COUNT-1: define internal void @__cq_q_inner_1_unc(
; COUNT-NOT:     define internal void @__cq_q_inner_1_unc(
