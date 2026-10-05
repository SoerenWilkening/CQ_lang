; control_inplace_ry_cond_register_flag_kept_derived_cond.ll — ACCEPT: a DERIVED
; condition over the register the arm rotates (bd test_C_libtooling-dm7f.4).
; What happens to the condition's compare CHAIN once the flag is kept (R5).
;
; @discharged — `if ((q & 3) == 1) cq_theta(&q, .9);`
;   The `and` rail is read only by the flag mint. With no strip in the stream,
;   the uncompute spine's interior discharge of that rail lands right after the
;   mint and BEFORE the controlled Ry: `and_unc(op, q, 3)` recomputes q & 3 from
;   the still-unrotated q, so op returns to |0> and its free is honest. Only the
;   flag stays allocated.
;
; @kept — `int d = q & 6; if (d == 2) cq_theta(&q, .9); ... cq_measure(d * 5)`
;   The `and` rail is ALSO read after the gate (by the `mul`). Its discharge
;   point would follow the Ry on its borrowed parent q, which
;   `preservesBorrowedParent` refuses (a controlled Ry relabels the parent), so
;   the spine leaks it: no `_unc`, no free. The `mul` reads q_pre & 6, which is
;   what C says d holds (d was computed before the region), and that read is of
;   the `and` result, never of q's pre-Ry name, so no stale-record fence has a
;   subject.
;
; In both, the compare flag is never stripped or freed, and M-A warns once per
; gate. Each function's `CHECK-NOT`s are windowed by the `CHECK-LABEL`s.
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

define i32 @kept(i32 %u0) {
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

; WARN-COUNT-2: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record
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
; CHECK-LABEL: define i32 @kept(
; CHECK:      %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 5.000000e-01)
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[H2]], i32 6)
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[D]], i32 2)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F2]], i32 %[[H2]], double 9.000000e-01)
; CHECK-NOT:  _unc
; CHECK-NOT:  cqrt_free
; CHECK:      call i32 @cq_template_mul_i32_hl(i32 %[[D]], i32 5)
; CHECK-NOT:  _unc
; CHECK-NOT:  cqrt_free
; CHECK:      ret i32
