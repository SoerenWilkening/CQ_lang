; spec_accept_clone_read_in_discharge_window_nested.ll — ACCEPT, DISCHARGED (bd
; test_C_libtooling-rhk5; family member `f05`). The companion of
; spec_accept_clone_read_in_discharge_window.ll with a NESTED clone: the callee
; `h(a,k) = g(k) + 1` calls a `noinline` `g(k) = k * 5`, so `h`'s clone body holds an
; INNER clone call `__cq_q_g_1(%k)` and, in its Bennett reverse, the inner `_unc`
; TWIN call `__cq_q_g_1_unc(%t, %k)`. `cloneCallPreservesArg` must prove the formal
; `%k` read-only THROUGH both (clause (B4), recursively): in `__cq_q_g_1` it is read
; by `mul_i32_hl` and the adjoint's slot 1; in the twin by the same two. Both are
; bodies the SPECIALIZER built and recorded (`taint.SpecHandleArgMask`).
;
; ORACLE (main 9a230646): the lyyf-(B) warning, no chain adjoint, `3q`/`3q ^ q` left
; allocated and entangled across the second Ry. The companion
; spec_leak_clone_read_twin_writes_arg.ll pre-supplies a twin that WRITES `%k`: the
; same call is then refused, which is what shows the twin body is actually walked.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=LOWER < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CLONE < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @slice(i32 %m) {
entry:
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %u = xor i32 %p, %q
  %s = call i32 @h(i32 %m, i32 %q)
  %c = icmp eq i32 %u, 10
  br i1 %c, label %arm, label %merge

arm:
  call void @cq_phi(double 3.141590e+00)
  br label %merge

merge:
  %ms = call i32 @cq_measure_si32(i32 %s)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 0x3FE6666666666666)
  %mq = call i32 @cq_measure_si32(i32 %q2)
  %r = add nsw i32 %mq, %ms
  ret i32 %r
}

define i32 @g(i32 %k) noinline {
  %r = mul nsw i32 %k, 5
  ret i32 %r
}

define i32 @h(i32 %a, i32 %k) {
  %t = call i32 @g(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

; SILENT-NOT: warning
; SILENT-NOT: error
;
; LOWER-LABEL: define i32 @slice(
; LOWER: %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
; LOWER-NEXT: %h_op1 = call i32 @cq_template_xor_i32(i32 %h, i32 %h_op)
; LOWER-NEXT: %s = call i32 @__cq_q_h_10(i32 0, i32 %h)
; LOWER-NEXT: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 10)
; LOWER-NEXT: call void @cqrt_rz_i1(i32 %h_cmp, double 3.141590e+00), !cq.branchphase
; LOWER-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
; LOWER-NEXT: call void @cq_template_xor_i32_unc(i32 %h_op1, i32 %h, i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op1)
; LOWER-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_cmp)
; LOWER-NEXT: %m2 = call i32 @cqrt_measure_i32(i32 %s)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
;
; The outer clone: the inner clone call, and its twin in the Bennett reverse,
; both READING `%k`.
; CLONE-LABEL: define internal i32 @__cq_q_h_10(i32 %a, i32 %k)
; CLONE-NEXT: %t = call i32 @__cq_q_g_1(i32 %k)
; CLONE-NEXT: %h_op = call i32 @cq_template_add_i32_hl(i32 %t, i32 1)
; CLONE-NEXT: %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
; CLONE-NEXT: call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
; CLONE-NEXT: call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %t, i32 1)
; CLONE-NEXT: call void @__cq_q_g_1_unc(i32 %t, i32 %k)
; CLONE-NEXT: call void @cqrt_free(i32 %t)
; CLONE-NEXT: call void @cqrt_free(i32 %h_op)
; CLONE-NEXT: ret i32 %cqq.out
; CLONE-LABEL: define internal i32 @__cq_q_g_1(i32 %k)
; CLONE-NEXT: %h_op = call i32 @cq_template_mul_i32_hl(i32 %k, i32 5)
; CLONE-LABEL: define internal void @__cq_q_g_1_unc(i32 %out, i32 %k)
; CLONE-NEXT: %h_op = call i32 @cq_template_mul_i32_hl(i32 %k, i32 5)
; CLONE-NEXT: call void @cqrt_copy_i32(i32 %h_op, i32 %out)
; CLONE-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %k, i32 5)
; CLONE-NEXT: call void @cqrt_free(i32 %h_op)
; CLONE-NEXT: ret void
