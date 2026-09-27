; spec_accept_dropped_arg_dead_read_ir.ll — ACCEPT with the twin's stream (bd
; test_C_libtooling-vsfp ROUND 2 — LIVENESS, not `use_empty()`; hand-written IR).
;
; `@h` computes `a * 3 + k` and discards it: its parameter HAS USES, all DEAD. Round 1 asked
; `use_empty()` and did not drop, so the 4.4 select `p` stayed alive for a callee that
; never reads it (round 1's own re-spelled fixtures used exactly this dead `mul` to keep a
; parameter "used"). The liveness predicate calls `a` dead, the call becomes `h(0, m)`, the
; select is deleted, and the stream is the program with `h` inlined as `-O1` would
; (`t = m + 1`, no `p`): alloc; Ry(.5); Ry(.7); measure. IR-only: `clang -O1` deletes the
; dead `mul` in the library TU; the fenv residue (`volatile char z = a;`) is the
; C-reachable member of the same class (spec_accept_dropped_arg_volatile_char.ll).
;
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
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

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @h(i32 %a, i32 %k) {
  %d = mul i32 %a, 3
  %d2 = add i32 %d, %k
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
