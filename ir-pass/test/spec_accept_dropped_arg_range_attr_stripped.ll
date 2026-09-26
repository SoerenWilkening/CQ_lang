; spec_accept_dropped_arg_range_attr_stripped.ll — ACCEPT with the hand-inlined twin's stream
; (bd test_C_libtooling-vsfp ROUND 2; hand-written IR, round 1's range_attr module).
;
; The dead parameter carries `range(i32 1, 100)`. A null constant violates it (a poison
; argument), so LLVM DAE strips the attribute when it rewrites the argument, and so does
; the drop: `range` is removed from the callee's parameter AND the call site, then the
; argument becomes `i32 0` and the dead 4.4 select is deleted. The CHECKs pin both the
; stream and that no `range` survives on `@h`'s first parameter.
;
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ATTR < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=DROP < %t.err
;
; The ordered call sequence of @main (derived from the lowered module; SSA names
; wildcarded, constants — every dropped `0` and every angle — kept):
; Between consecutive matches NO other runtime/clone call may appear, so the
; runtime stream is pinned EXACTLY, not as a subsequence.
; CHECK-LABEL: define {{.*}}@main(
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i1(i1 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i1(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @h(i32 0, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i1(i32 %{{[a-zA-Z0-9_.]+}}, double 0x3FE6666666666666)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: ret i32
;
; Callees the ORACLE emitted in @main and this lowering must not:
; NEG-LABEL: define {{.*}}@main(
; NEG-NOT: @__cq_q_h_01(
; NEG-NOT: @cqrt_alloc_i32(
; NEG-NOT: @cqrt_cnot(
; NEG-NOT: @cqrt_copy_i32_controlled(
; NEG-NOT: @cqrt_free(
; NEG-NOT: @cqrt_x(
; NEG: ret i32
; DROP: CQ_DEADARG_DBG: drop arg 0 of @h in @main (inst)
; No `range` survives on `@h`'s parameter (it precedes @main) nor at the call:
; ATTR-NOT: range(i32 1, 100)
; ATTR: call i32 @h(i32 0, i32 %m)

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @h(i32 range(i32 1, 100) %a, i32 %k) {
  %r = add i32 %k, 1
  ret i32 %r
}

define i32 @main(i32 %m) {
  %lo = trunc i32 %m to i1
  %b = call i1 @cq_theta_i1(i1 %lo, double 5.000000e-01)
  %p = select i1 %b, i32 9, i32 4
  %t = call i32 @h(i32 %p, i32 %m)
  %b2 = call i1 @cq_theta_i1(i1 %b, double 7.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %b2)
  %mz = zext i1 %mm to i32
  %s = add i32 %t, %mz
  ret i32 %s
}
