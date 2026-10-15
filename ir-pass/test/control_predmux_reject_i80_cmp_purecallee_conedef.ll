; control_predmux_reject_i80_cmp_purecallee_conedef.ll — ACCEPT (dm7f.16.1).
; The former purity-only shield proof was unsound (bd 3c6m.14.2). The new
; total-call owner proves this exact branchless body defined, including its ret.
; Let c=(q>3)&&(leaf(q)>0). Results are q+7 and 3q on c, q otherwise.
; Bind the callee result in the shield compare and retain clone-on-taint.
; Retpoison, unsafe casts/shifts and poison-immarg siblings remain negatives.
; Historical filename retained.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leaf(i32 %a) {
e:
  %z = zext i32 %a to i80
  %m = and i80 %z, 4294967295
  %eq = icmp eq i80 %m, 555
  %w = zext i1 %eq to i32
  ret i32 %w
}

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %r = call i32 @leaf(i32 %q)
  %b = icmp sgt i32 %r, 0
  %sc = select i1 %a, i1 %b, i1 false     ; clang -O1's poison-shielded `a && b`
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:                                    ; 2 merge phis = the W3 claim witness
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m2
}


; CHECK-LABEL: define i32 @probe(
; CHECK: %[[U:[a-zA-Z0-9_.]+]] = freeze i32 %u
; CHECK: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[U]])
; CHECK: %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_leaf_1(i32 %[[Q]])
; CHECK: %[[ADD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[Q]], i32 7)
; CHECK: %[[MUL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[Q]], i32 3)
; CHECK: %[[A0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK: %[[B0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[R]], i32 0)
; CHECK: %[[G0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A0]], i32 %[[B0]], i32 %[[G0]])
; CHECK-NEXT: %[[O0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G0]], i32 %[[ADD]], i32 %[[O0]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G0]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G0]], i32 %[[Q]], i32 %[[O0]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G0]])
; CHECK: %[[A1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK: %[[B1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[R]], i32 0)
; CHECK: %[[G1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A1]], i32 %[[B1]], i32 %[[G1]])
; CHECK-NEXT: %[[O1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G1]], i32 %[[MUL]], i32 %[[O1]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G1]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G1]], i32 %[[Q]], i32 %[[O1]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G1]])
; CHECK: %[[SUM:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[O0]], i32 %[[O1]])
; bd r2j3.32: the add is both merge rails' last reader; each is then reversed
; (core re-emitted in reverse under its still-live AND rail), its network strip
; DEFERRED to after that, and freed.
; CHECK-NEXT: call void @cqrt_x(i32 %[[G0]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G0]], i32 %[[Q]], i32 %[[O0]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G0]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G0]], i32 %[[ADD]], i32 %[[O0]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A0]], i32 %[[B0]], i32 %[[G0]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G0]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[B0]], i32 %[[R]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[B0]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[A0]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A0]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[O0]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G1]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G1]], i32 %[[Q]], i32 %[[O1]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G1]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G1]], i32 %[[MUL]], i32 %[[O1]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A1]], i32 %[[B1]], i32 %[[G1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G1]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[B1]], i32 %[[R]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[B1]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[A1]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[O1]])
; CHECK: call i32 @cqrt_measure_i32(i32 %[[SUM]])
; CHECK-LABEL: define internal i32 @__cq_q_leaf_1(i32 %a)
; CHECK: %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i32_to_i80(i32 %a)
; CHECK-NEXT: %[[MASK:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i80_hl(i32 %[[Z]], i80 4294967295)
; CHECK-NEXT: %[[EQ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i80_hl(i32 %[[MASK]], i80 555)
; CHECK-NEXT: %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[EQ]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[W]], i32 %[[OUT]])
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 %[[W]], i32 %[[EQ]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i80_hl_unc(i32 %[[EQ]], i32 %[[MASK]], i80 555)
; CHECK-NEXT: call void @cq_template_and_i80_hl_unc(i32 %[[MASK]], i32 %[[Z]], i80 4294967295)
; CHECK-NEXT: call void @cq_template_zext_i32_to_i80_unc(i32 %[[Z]], i32 %a)
; CHECK-NEXT: call void @cqrt_free(i32 %[[Z]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[MASK]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[EQ]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[W]])
; CHECK-NEXT: ret i32 %[[OUT]]
