; spec_accept_clone_read_in_discharge_window_identity.ll — ACCEPT, DISCHARGED (bd
; test_C_libtooling-rhk5; family member `f06`). The IDENTITY callee
; `h(a, k) { return k; }`: its clone's whole body is the Bennett copy-out
; `cqrt_copy_i32(%k, %cqq.out)` — the formal is the copy SOURCE and nothing else.
; That is clause (B3) of `cloneCallPreservesArg` (the existing owner
; `ChainWalk::isCopyOutSink`, which also refuses a `src == dst` alias). Note what the
; clone does NOT do: it never returns `%k` itself — the result is always a fresh
; `cqrt_alloc`, so the call's result is not an alias of `q` (a `ret %k` in a body
; this predicate walked would refuse the call).
;
; ORACLE (main 9a230646): the lyyf-(B) warning, the chain left allocated.
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

define i32 @h(i32 %a, i32 %k) {
  ret i32 %k
}

; SILENT-NOT: warning
; SILENT-NOT: error
;
; LOWER-LABEL: define i32 @slice(
; LOWER: %s = call i32 @__cq_q_h_10(i32 0, i32 %h)
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
; CLONE-LABEL: define internal i32 @__cq_q_h_10(i32 %a, i32 %k)
; CLONE-NEXT: %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
; CLONE-NEXT: call void @cqrt_copy_i32(i32 %k, i32 %cqq.out)
; CLONE-NEXT: ret i32 %cqq.out
