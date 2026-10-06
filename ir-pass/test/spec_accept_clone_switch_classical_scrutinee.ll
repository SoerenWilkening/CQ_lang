; spec_accept_clone_switch_classical_scrutinee.ll — ACCEPT (bd p3kd.7.2; was
; spec_reject_clone_switch_classical_scrutinee.ll, the p3kd.7.1 gap fixture): a
; switch on a CLASSICAL parameter `%c` whose arms compute from the quantum `%b`.
; Clone-mode PredMux roots a region at the classical switch (owner ruling
; 2026-10-06), flattens it into a select chain on classical case compares, and each
; select becomes a choice between rail handles (CloneRailSelect.h). All three arms
; run; the reverse undoes each on its own rail.
;
; Trace check, |b> and classical c: c=0 → b+1, c=1 → 2b, otherwise b-3.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, i32 %c) {
entry:
  switch i32 %c, label %def [ i32 0, label %z
                              i32 1, label %o ]
z:
  %zb = add i32 %b, 1
  br label %m
o:
  %ob = mul i32 %b, 2
  br label %m
def:
  %db = sub i32 %b, 3
  br label %m
m:
  %r = phi i32 [ %zb, %z ], [ %ob, %o ], [ %db, %def ]
  ret i32 %r
}

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q, i32 %u1)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK-LABEL: define internal i32 @__cq_q_helper_01(i32 %b, i32 %c)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %b, i32 2)
; CHECK-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 1)
; CHECK-NEXT:  %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i32_hl(i32 %b, i32 3)
; CHECK-NEXT:  %[[E1:[a-zA-Z0-9_.]+]] = icmp eq i32 %c, 1
; CHECK-NEXT:  %[[F1:[a-zA-Z0-9_.]+]] = freeze i1 %[[E1]]
; CHECK-NEXT:  %[[S1:[a-zA-Z0-9_.]+]] = select i1 %[[F1]], i32 %[[M]], i32 %[[D]]
; CHECK-NEXT:  %[[E0:[a-zA-Z0-9_.]+]] = icmp eq i32 %c, 0
; CHECK-NEXT:  %[[F0:[a-zA-Z0-9_.]+]] = freeze i1 %[[E0]]
; CHECK-NEXT:  %[[S0:[a-zA-Z0-9_.]+]] = select i1 %[[F0]], i32 %[[A]], i32 %[[S1]]
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[S0]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cq_template_sub_i32_hl_unc(i32 %[[D]], i32 %b, i32 3)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[A]], i32 %b, i32 1)
; CHECK-NEXT:  call void @cq_template_mul_i32_hl_unc(i32 %[[M]], i32 %b, i32 2)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[M]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT:  ret i32 %[[OUT]]
