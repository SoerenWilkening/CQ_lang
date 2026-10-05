; lowering_uncompute_measured_parent_open_root.ll — ACCEPT (bd
; test_C_libtooling-01po.8, the general dead-terminal frontier retry). Two
; `clang -O1` functions (debug info stripped), both declining "cq uncompute: dead
; chain would free a measured register" on main 7b4e6359:
;   @f3                 int q=x; cq_theta(&q,.25); int q2=q+1;
;                       int t=q2^9; cq_theta(&t,.5); int u=q^5; cq_theta(&u,.5);
;                       return cq_measure(q2);
;   @moved_live_prefix  int q=x; cq_theta(&q,.25); int a=q*3; cq_theta(&q,.3);
;                       int t=a^9; cq_theta(&t,.5); return cq_measure(q);
;   @moved_live_partial the same with `int s=a+1; cq_theta(&s,.2);` after `t`
;
; WHAT DECLINED. The bd ptue retry borrows only MEASURED rails. In @f3 it borrows
; `q2`, OWNS `q`, and `q`'s consumer `q+1` (q2's producer) is outside the reduced
; DAG: not closed, decline. In @moved_live_prefix it borrows `q`, and `q` is
; rotated inside the window [mul, t's reversal point]: clause (d) fails, decline.
;
; THE FIXPOINT (`planFrontierFixpoint`). After the whole-group retry refuses, the
; components are planned again and the borrowed frontier GROWS, but only by a
; rail every schedule must leave allocated:
;   * @f3: `q` is an open ROOT (`DataDag::OpenRails`). Un-rotating it would act
;     on a register entangled with the live `q2`, so no schedule reverses it; it
;     is borrowed. {t} and {u} then share only borrowed registers, so each is
;     reversed at its own anchor.
;   * @moved_live_prefix / @moved_live_partial: `a = 3q` is USED after the move
;     (`a ^ 9` follows `cq_theta(&q,.3)`), so the program itself keeps `a` across
;     the move as a which-path record of q (`recordLiveAcrossMove`), and `a`'s
;     `_unc` would need q's pre-move label. `a` is borrowed: left allocated,
;     never freed, never adjointed. In @moved_live_prefix `a` is dead after the
;     xor, so M-C makes `t` the in-place chain `xorc(a,9); ry(a,.5)` on a's own
;     rail — the record IS the terminal, which is dropped: nothing is reversed.
;     In @moved_live_partial `a` stays a separate rail, `t` and `s` then share
;     only the borrowed `a`, and each is reversed at its own anchor reading it.
;
; HAND TRACE, @f3. Ry(.25)|x> = Σ_v a_v|v> on q.
;   add_hl(q,1) -> q2 = |v+1>; xor_hl(q2,9) -> t; ry(t,.5)
;   ry(t,-.5); xor_hl_unc(t,q2,9)   q2 unmoved since the xor -> t = 0; free(t)
;   xor_hl(q,5) -> u; ry(u,.5)
;   ry(u,-.5); xor_hl_unc(u,q,5)    q unmoved since that xor -> u = 0; free(u)
;   measure(q2)                     P(v+1) = |a_v|^2, the program's distribution
; q is never un-rotated or freed (born |x>, and entangled with q2 as `q2 = q+1`
; says).
;
; HAND TRACE, @moved_live_prefix. mul_hl(q,3) -> a: Σ a_v |v>|3v>; ry(q,.3)
; acts on q while a records 3v — the program's own circuit, since `a` is read
; after it; xorc(a,9); ry(a,.5) is the user's `t`, left as it is. measure(q) sees
; q dephased by the record exactly as the source does. No `_unc`, no free.
;
; HAND TRACE, @moved_live_partial. As above up to ry(q,.3); then
; xor_hl(a,9) -> t; ry(t,.5); ry(t,-.5); xor_hl_unc(t,a,9): a still holds 3v (its
; users are the mul that wrote it and two forward reads) -> t = 0; free(t).
; add_hl(a,1) -> s; ry(s,.2); ry(s,-.2); add_hl_unc(s,a,1) -> s = 0; free(s).
; `a` stays allocated; measure(q) sees q dephased by it, as the source does.
;
; DECLINE TWINS (char-for-char):
;   lowering_reject_uncompute_measured_parent_open_root_frozen.ll — @f3 with `u`
;     printed: the borrowed root `q` would control a KEPT rail's adjoint (bd eqti);
;   lowering_reject_uncompute_measured_parent_moved_dead_record.ll — the record
;     `a` is dead BEFORE the move, so leaving it would keep more of q than the
;     program does; refused;
;   lowering_reject_uncompute_measured_parent_open_copy.ll — the open rail is a
;     COPY (`a = 3q` read by q2's producer), not a root; refused.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOQ < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f3(i32 %0) {
  %2 = tail call i32 @cq_theta_si32(i32 %0, double 2.500000e-01)
  %3 = add nsw i32 %2, 1
  %4 = xor i32 %3, 9
  %5 = tail call i32 @cq_theta_si32(i32 %4, double 5.000000e-01)
  %6 = xor i32 %2, 5
  %7 = tail call i32 @cq_theta_si32(i32 %6, double 5.000000e-01)
  %8 = tail call i32 @cq_measure_si32(i32 %3)
  ret i32 %8
}

define i32 @moved_live_prefix(i32 %0) {
  %2 = tail call i32 @cq_theta_si32(i32 %0, double 2.500000e-01)
  %3 = mul nsw i32 %2, 3
  %4 = tail call i32 @cq_theta_si32(i32 %2, double 3.000000e-01)
  %5 = xor i32 %3, 9
  %6 = tail call i32 @cq_theta_si32(i32 %5, double 5.000000e-01)
  %7 = tail call i32 @cq_measure_si32(i32 %4)
  ret i32 %7
}

define i32 @moved_live_partial(i32 %0) {
  %2 = tail call i32 @cq_theta_si32(i32 %0, double 2.500000e-01)
  %3 = mul nsw i32 %2, 3
  %4 = tail call i32 @cq_theta_si32(i32 %2, double 3.000000e-01)
  %5 = xor i32 %3, 9
  %6 = tail call i32 @cq_theta_si32(i32 %5, double 5.000000e-01)
  %7 = add nsw i32 %3, 1
  %8 = tail call i32 @cq_theta_si32(i32 %7, double 2.000000e-01)
  %9 = tail call i32 @cq_measure_si32(i32 %4)
  ret i32 %9
}

; CHECK-LABEL: define i32 @f3(i32 %0)
; CHECK-NEXT:  %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT:  %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[Q2]], i32 9)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double -5.000000e-01)
; CHECK-NEXT:  call void @cq_template_xor_i32_hl_unc(i32 %[[T]], i32 %[[Q2]], i32 9)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT:  %[[U:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[U]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[U]], double -5.000000e-01)
; CHECK-NEXT:  call void @cq_template_xor_i32_hl_unc(i32 %[[U]], i32 %[[H]], i32 5)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[U]])
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[Q2]])
; CHECK-NEXT:  ret i32 %[[M]]

; CHECK-LABEL: define i32 @moved_live_prefix(i32 %0)
; CHECK-NEXT:  %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT:  call void @cqrt_xorc_i32(i32 %[[A]], i32 9)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[A]], double 5.000000e-01)
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT:  ret i32 %[[M]]

; CHECK-LABEL: define i32 @moved_live_partial(i32 %0)
; CHECK-NEXT:  %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[A]], i32 9)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double -5.000000e-01)
; CHECK-NEXT:  call void @cq_template_xor_i32_hl_unc(i32 %[[T]], i32 %[[A]], i32 9)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT:  %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[A]], i32 1)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[S]], double 2.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[S]], double -2.000000e-01)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[S]], i32 %[[A]], i32 1)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[S]])
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT:  ret i32 %[[M]]

; Neither borrowed register is ever adjointed or freed (window = def -> ret):
; NOQ-LABEL: define i32 @f3(
; NOQ:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; NOQ-NOT: call void @cqrt_ry_i32(i32 %[[R]], double -2.500000e-01)
; NOQ-NOT: call void @cqrt_free(i32 %[[R]])
; NOQ:     %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(
; NOQ-NOT: call void @cq_template_add_i32_hl_unc(i32 %[[Q2]],
; NOQ-NOT: call void @cqrt_free(i32 %[[Q2]])
; NOQ:     ret i32
; NOQ-LABEL: define i32 @moved_live_partial(
; NOQ:     %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(
; NOQ-NOT: call void @cq_template_mul_i32_hl_unc(i32 %[[A]],
; NOQ-NOT: call void @cqrt_free(i32 %[[A]])
; NOQ:     ret i32
