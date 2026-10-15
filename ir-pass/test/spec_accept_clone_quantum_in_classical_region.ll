; spec_accept_clone_quantum_in_classical_region.ll — ACCEPT (bd p3kd.7.2): a
; QUANTUM branch nested inside a CLASSICAL one in a lifted callee, sharing the
; classical branch's merge (the fdim/scalbn CQ shape):
; `c < 0 ? -c : (b > c ? b - c : 0)`, `b` quantum, `c` classical. The quantum
; region alone left at `E3-mergepred` (its merge has a predecessor on the classical
; arm) and nothing claimed the classical branch. Clone-mode PredMux now roots at the
; classical branch (owner ruling 2026-10-06) and flattens the whole region: the
; quantum merge becomes the controlled-copy mux under `[b > c] ∧ [c >= 0]` (the
; classical half a literal input of `cq_template_and_i1_hl`), and the outer merge a
; classical choice of rail between the materialized |−c> and that mux
; (CloneRailSelect.h).
;
; Trace check, |b> and classical c: c<0 → −c; c>=0 ∧ b>c → b−c; otherwise 0.
;
; bd p3kd.7.8: main's stage list now lowers the clone, so the quantum merge goes
; through main's SelectMergeEmit: the forward's trailing `cqrt_x(g)` strip is elided
; by the Bennett wrap (the flag stays at ¬g until the mirror's `cqrt_x` restores it),
; the reverse is the exact mirror, and the constant-0 arm's |0> rail is now freed
; with the others. Hand trace: out = g ? b−c : 0 (the second copy reads |0>); the
; classical select picks |−c> when c<0 and `out` otherwise; the mirror replays the
; 0-copy, `cqrt_x(g)`, the (b−c)-copy (out back to 0), then the and/icmp/sub `_unc`s,
; so every freed rail is |0>. The |−c> rail stays allocated (non-zero constant).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, i32 %c) {
entry:
  %cc = icmp slt i32 %c, 0
  br i1 %cc, label %neg, label %q
neg:
  %nc = sub i32 0, %c
  br label %m
q:
  %t = icmp sgt i32 %b, %c
  br i1 %t, label %x, label %m
x:
  %d = sub i32 %b, %c
  br label %m
m:
  %r = phi i32 [ %nc, %neg ], [ %d, %x ], [ 0, %q ]
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
; CHECK-NEXT:  %[[CS:[a-zA-Z0-9_.]+]] = freeze i32 %c
; CHECK-NEXT:  %[[CC:[a-zA-Z0-9_.]+]] = icmp slt i32 %[[CS]], 0
; CHECK-NEXT:  %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i32_hl(i32 %b, i32 %[[CS]])
; CHECK-NEXT:  %[[NC:[a-zA-Z0-9_.]+]] = sub i32 0, %[[CS]]
; CHECK-NEXT:  %[[GE:[a-zA-Z0-9_.]+]] = icmp sge i32 %[[CS]], 0
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %b, i32 %[[CS]])
; CHECK-NEXT:  %[[G:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[T]], i1 zeroext %[[GE]])
; CHECK-NEXT:  %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[D]], i32 %[[SEL]])
; (bd dm7f.81: the constant-0 arm emits no write and no bracket, forward or in the reverse; its former %K0 rail and free are gone.)
; CHECK-NEXT:  %[[KNC:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[NC]])
; CHECK-NEXT:  %[[FC:[a-zA-Z0-9_.]+]] = freeze i1 %[[CC]]
; CHECK-NEXT:  %[[RS:[a-zA-Z0-9_.]+]] = select i1 %[[FC]], i32 %[[KNC]], i32 %[[SEL]]
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[RS]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[D]], i32 %[[SEL]])
; CHECK-NEXT:  call void @cq_template_and_i1_hl_unc(i32 %[[G]], i32 %[[T]], i1 zeroext %[[GE]])
; CHECK-NEXT:  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[T]], i32 %b, i32 %[[CS]])
; CHECK-NEXT:  call void @cq_template_sub_i32_hl_unc(i32 %[[D]], i32 %b, i32 %[[CS]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT:  ret i32 %[[OUT]]
; CHECK-NEXT:  }
