; control_inplace_ry_cond_register_flag_kept_derived_cond.ll — ACCEPT: a DERIVED
; condition over the register the arm rotates (bd test_C_libtooling-dm7f.4).
; What happens to the condition's compare CHAIN, and to the flag, in each of the
; accept's two cases (review round 2, F-A): KEPT when the strip is impossible,
; STRIPPED after the gate when every tainted compare operand is a record the
; program keeps.
;
; @discharged — CASE: KEPT. `if ((q & 3) == 1) cq_theta(&q, .9);`
;   The `and` rail is read only by the flag mint, so nothing could recompute the
;   predicate after the gate and the flag is kept (the owner-ruled record). With
;   no strip in the stream, the spine's interior discharge of the `and` rail lands
;   right after the mint and BEFORE the controlled Ry: `and_unc(op, q, 3)`
;   recomputes q & 3 from the still-unrotated q, so op returns to |0> and its
;   free is honest. Only the flag stays allocated.
;
; @chain_observed — CASE: STRIPPED.
;   `int d = q & 6; if (d == 2) cq_theta(&q, .9); ... cq_measure(d * 5)`
;   (named @kept until review round 2, when its flag was still kept.)
;   The `and` rail is ALSO read after the gate (by the `mul`). Its discharge
;   point would follow the Ry on its borrowed parent q, which
;   `preservesBorrowedParent` refuses (a controlled Ry relabels the parent), so
;   the spine leaks it: no `_unc`, no free. The `mul` reads q_pre & 6, which is
;   what C says d holds (d was computed before the region), and that read is of
;   the `and` result, never of q's pre-Ry name, so no stale-record fence has a
;   subject. Because that rail is live and unchanged after the gate, the strip
;   `icmp_eq_hl_unc(f, d, 2)` is exact there, and the flag is stripped and freed.
;
; @lifted_observed — CASE: STRIPPED.
;   `int t = h(q); if (t > 13) cq_theta(&q, .9); … cq_measure(t)` (added by
;   review round 1, F1). A lifted call's `__cq_q_*` result is never discharged
;   by the spine (bd ln16), so it stands at the gate. Here the PROGRAM keeps it:
;   `t` is measured after the gate, the record is the source's own data, and the
;   chain postcondition (`declineUndischargedKeptFlagChains`, M-A's
;   `recordIsExemptAt` clause 3) admits it. The flag is stripped against `t`
;   after the gate. Its twin with `t` unread is
;   control_inplace_ry_reject_cond_register_lifted_chain.ll, which DECLINES.
;
; M-A warns once per gate. For @discharged that is the kept flag. For the two
; STRIPPED functions it is an over-warn on the transient flag, whose strip runs
; after the gate (see control_inplace_ry_cond_register_strip_observed.ll). Each
; function's `CHECK-NOT`s are windowed by the `CHECK-LABEL`s.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; RUN: %filecheck %s < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @discharged(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = and i32 %q, 3
  %c = icmp eq i32 %a, 1
  br i1 %c, label %arm, label %merge
arm:
  %qt = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

define i32 @chain_observed(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = and i32 %q, 6
  %c = icmp eq i32 %d, 2
  br i1 %c, label %arm, label %merge
arm:
  %qt = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %arm ], [ %q, %entry ]
  %m1 = call i32 @cq_measure_si32(i32 %qm)
  %d5 = mul nuw nsw i32 %d, 5
  %m2 = call i32 @cq_measure_si32(i32 %d5)
  %s  = add nsw i32 %m2, %m1
  ret i32 %s
}

define i32 @h(i32 %x) #0 {
  %a = mul nsw i32 %x, 3
  %b = add nsw i32 %a, 1
  ret i32 %b
}

define i32 @lifted_observed(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t = call i32 @h(i32 %q)
  %c = icmp sgt i32 %t, 13
  br i1 %c, label %arm, label %merge
arm:
  %qt = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %arm ], [ %q, %entry ]
  %m1 = call i32 @cq_measure_si32(i32 %qm)
  %m2 = call i32 @cq_measure_si32(i32 %t)
  %s  = add nsw i32 %m2, %m1
  ret i32 %s
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }

; WARN-COUNT-3: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: error

; CHECK-LABEL: define i32 @discharged(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[OP]], i32 1)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[OP]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[OP]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[H]], double 9.000000e-01)
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32
;
; CHECK-LABEL: define i32 @chain_observed(
; CHECK:      %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 5.000000e-01)
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[H2]], i32 6)
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[D]], i32 2)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F2]], i32 %[[H2]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[D]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 %[[H2]])
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = call i32 @cq_template_mul_i32_hl(i32 %[[D]], i32 5)
; CHECK-NOT:  _unc
; CHECK-NOT:  cqrt_free
; CHECK:      ret i32
;
; CHECK-LABEL: define i32 @lifted_observed(
; CHECK:      %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H3]], double 5.000000e-01)
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_h_1(i32 %[[H3]])
; CHECK-NEXT: %[[F3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[T]], i32 13)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F3]], i32 %[[H3]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F3]], i32 %[[T]], i32 13)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F3]])
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 %[[H3]])
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 %[[T]])
; CHECK-NOT:  keptflag
