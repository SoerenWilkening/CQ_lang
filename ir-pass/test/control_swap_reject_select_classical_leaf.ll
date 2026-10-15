; control_swap_reject_select_classical_leaf.ll — ACCEPT since bd
; test_C_libtooling-xdu2.13 (the file name is kept, L8 — a `git mv` can be
; resurrected by a merge). A compound select condition mixing a TAINTED leaf with
; a CLASSICAL (untainted) leaf, `or(q>5, k>7)`.
;
; [HISTORY, 3c6m.12 L4] This module was a DECLINE: "a classical leaf has no
; quantum flag to mint … a hybrid classical∧quantum conjunction is out of scope".
; That scope sentence is no longer true. Since xdu2.13 the classical child of an
; `and`/`or` node is the LITERAL of the existing `cq_template_or_i1_hl` (the §5.2
; mixed-operand convention). The §5.2 prohibition still holds and is what this
; file now pins: `%c2` is never given a qubit or a flag of its own, it sits in
; the template's classical slot, and the `_unc` strip reads the SAME SSA literal
; before `gl` is freed at a proven |0> (`gl ^= f ∨ c` twice is 0). See
; ir-pass/include/CondLiteral.h and the condtree_classical_leaf_* family.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
;
; CHECK-LABEL: define i32 @example(
; CHECK: entry:
; CHECK: %[[V0:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V0]], double 5.000000e-01)
; CHECK-NEXT: %c2 = icmp sgt i32 %k, 7
; CHECK-NEXT: %[[V1:[a-z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[V0]], i32 5)
; CHECK-NEXT: %[[V2:[a-z0-9_.]+]] = call i32 @cq_template_or_i1_hl(i32 %[[V1]], i1 zeroext %c2)
; CHECK-NEXT: %[[V3:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[V2]], i32 %[[V0]], i32 %[[V3]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[V2]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[V2]], i32 %[[V3]], i32 %x)
; CHECK-NEXT: call void @cqrt_x(i32 %[[V2]])
; CHECK-NEXT: call void @cq_template_or_i1_hl_unc(i32 %[[V2]], i32 %[[V1]], i1 zeroext %c2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[V1]], i32 %[[V0]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V1]])
; CHECK-NEXT: %[[V5:[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V3]])
; CHECK-NEXT: ret i32 %[[V5]]
;
; NEG is a PURE whole-file negative prefix: the classical leaf is never a
; qubit or a flag of its own, and no select survives.
; NEG-NOT: cqrt_alloc_i1(i1 %c2)
; NEG-NOT: @cq_template_icmp_sgt_i32_hl(i32 %k
; NEG-NOT: select i1
; NEG-NOT: cq.predmux
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %k, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp sgt i32 %q, 5
  %c2  = icmp sgt i32 %k, 7          ; classical leaf — %k is untainted
  %c   = or i1 %c1, %c2
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
