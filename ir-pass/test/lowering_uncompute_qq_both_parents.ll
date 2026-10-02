; lowering_uncompute_qq_both_parents.ll — Phase 5 WI-4 QQ headline (PRD §2.11 /
; IMPLEMENTATION §4 WI-4). A DEAD two-quantum-operand product `prod = q1 * q2`:
; the whole-DAG recovery hops BOTH tainted parents (`dataInputHandle` returns all
; tainted operands now), so the recovered DAG is {ry(q1), ry(q2), mul(q1,q2)} with
; TWO roots. The single reverse-topological pass adjoints the product via the VOID
; in-place `cq_template_mul_i32_unc(out, q1, q2)` reading BOTH live parents (DD-3
; slots: out, then the forward operands in order), frees the |0> product rail, then
; un-rotates q2 (the later root, reversed first) and q1 — and KEEPS both roots:
; Ry-dagger restores their runtime seeds |x>, |y>, not |0> (bd 5c5b, libcqops vmz9).
; The zero-seed / runtime-seed split of this same shape is pinned per rail by
; lowering_uncompute_root_birth_seed_free.ll's `@mixed_qq`.
;
; A swapped / omitted QQ source slot, or a one-parent measured-upstream scan, is a
; verify-clean WRONG UNITARY (PRD §6); this pins both sources, both slots, both
; root adjoints, and the one free (the product rail).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
;
; Forward: two theta roots (alloc + ry each), then the QQ product:
; CHECK:     %[[Q1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q1]], double 2.500000e-01)
; CHECK:     %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %y)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q2]], double 3.500000e-01)
; CHECK:     %[[PROD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %[[Q1]], i32 %[[Q2]])
;
; Reversed whole-DAG adjoint: the QQ `_unc` reads BOTH live parents, frees the
; product rail, then un-rotates q2 (later root, reversed first) then q1, keeping both:
; CHECK:     call void @cq_template_mul_i32_unc(i32 %[[PROD]], i32 %[[Q1]], i32 %[[Q2]])
; CHECK:     call void @cqrt_free(i32 %[[PROD]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q2]], double -3.500000e-01)
; CHECK-NOT: call void @cqrt_free(i32 %[[Q2]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q1]], double -2.500000e-01)
; CHECK-NOT: call void @cqrt_free(i32 %[[Q2]])
; CHECK-NOT: call void @cqrt_free(i32 %[[Q1]])
;
; CHECK-NOT: cq_template_mul_i32_inv
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: mul i32
;
; Exactly ONE `_unc` (the single product gate, adjointed once) and ONE free
; (the product rail; both roots are kept):
; CNT-COUNT-1: _unc(i32 %
; CNT-NOT:     _unc(i32 %
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x, i32 %y) {
entry:
  %q1 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %y, double 3.500000e-01)
  %prod = mul i32 %q1, %q2                        ; dead QQ terminal
  ret void
}
