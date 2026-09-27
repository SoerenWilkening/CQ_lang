; spec_accept_dropped_arg_musttail_kept.ll — ACCEPT, no argument dropped (bd
; test_C_libtooling-vsfp ROUND 2 — the drop's `musttail` refusal; hand-written IR).
;
; `@g` forwards `a` to `@h` by a `musttail` call and `@h` ignores it. The drop refuses a
; `musttail` SITE, so `@h(%a, %k)` is kept, `a` stays live in `@g`, and `main`'s `g(%m, …)`
; is kept too (NODROP). ⚠ This pins a CONSERVATISM, not a soundness property: a constant
; argument changes no signature, and LLVM's DAE refuses `musttail` only where it would
; change one. It is the mirror the reviewers asked for (bd vsfp r1A F-VA-1), pinned so
; that relaxing it is a decision (mutant R7 flips it).
;
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
;
; The ordered call sequence of @main (derived from the lowered module; SSA names
; wildcarded, constants — every dropped `0` and every angle — kept):
; Between consecutive matches NO other runtime/clone call may appear, so the
; runtime stream is pinned EXACTLY, not as a subsequence.
; CHECK-LABEL: define {{.*}}@main(
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @g(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: ret i32
; NODROP-NOT: CQ_DEADARG_DBG

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @h(i32 %a, i32 %k) {
  %r = add i32 %k, 1
  ret i32 %r
}

define i32 @g(i32 %a, i32 %k) {
  %r = musttail call i32 @h(i32 %a, i32 %k)
  ret i32 %r
}

define i32 @main(i32 %m) {
  %q = call i32 @cq_theta_si32(i32 %m, double 5.000000e-01)
  %z = call i32 @cq_measure_si32(i32 %q)
  %t = call i32 @g(i32 %m, i32 %z)
  %s = add i32 %t, %z
  ret i32 %s
}
