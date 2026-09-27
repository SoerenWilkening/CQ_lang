; spec_accept_dropped_arg_loop_callee_kept.ll — ACCEPT, the call KEPT (bd
; test_C_libtooling-vsfp ROUND 2 — the liveness predicate's `bodyIsSideEffectFree`
; refuses a CYCLIC body; hand-written IR).
;
; `@spin` ignores `a` (dropped: `spin(0, m)`) and loops on `k` with no memory effect and no
; `mustprogress` — it may legitimately never terminate, so an unused call to it is NOT
; dead. The predicate's body rule admits only an ACYCLIC body (every execution terminates);
; with that conjunct removed (mutant L5) the call is deleted and a possibly non-terminating
; program is made to terminate. `-O1` would keep it too without `mustprogress`.
;
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
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
; CHECK: call i32 @spin(i32 0, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i1(i32 %{{[a-zA-Z0-9_.]+}}, double 0x3FE6666666666666)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: ret i32
; DROP: CQ_DEADARG_DBG: drop arg 0 of @spin in @main (inst)

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

; No `mustprogress`: this loop may legitimately never terminate (x = x*3+1 mod 2^32
; need not reach 7), so a call to @spin is NOT removable even though its body writes
; no memory and its result is unused.
define i32 @spin(i32 %a, i32 %k) {
entry:
  br label %loop
loop:
  %x = phi i32 [ %k, %entry ], [ %x2, %loop ]
  %x2 = mul i32 %x, 3
  %x3 = add i32 %x2, 1
  %done = icmp eq i32 %x3, 7
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %x3
}

define i32 @main(i32 %m) {
  %lo = trunc i32 %m to i1
  %b = call i1 @cq_theta_i1(i1 %lo, double 5.000000e-01)
  %p = select i1 %b, i32 9, i32 4
  %t = call i32 @spin(i32 %p, i32 %m)
  %b2 = call i1 @cq_theta_i1(i1 %b, double 7.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %b2)
  %mz = zext i1 %mm to i32
  ret i32 %mz
}
