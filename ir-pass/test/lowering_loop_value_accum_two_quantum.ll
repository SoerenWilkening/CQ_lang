; lowering_loop_value_accum_two_quantum.ll — ACCEPT (bd test_C_libtooling-01po.19.18;
; was lowering_reject_loop_value_accum_two_quantum.ll, issue dtzb, the X1 decline
; of the two-quantum accumulate — bd c9gw AXIS 2 for loops):
;     int q = seed; cq_theta(&q, 0.25);
;     int acc = 0;
;     for (int i = 0; i < n; i++) acc = acc + q;    // both operands quantum
;     return cq_measure(acc);
; The SEEDED ACCUMULATOR (LoopAccumulator.h): the register is minted once from
; the classical seed, `%cq.acc = cqrt_alloc_i32(0)`, at the end of the entry
; block — which is the zero-trip GUARD here (no preheader) — and each trip is the
; in-place quantum-source add `cqrt_add_i32(%h_q, %cq.acc)` tagged
; `!cq.inplace.qq` (Mogensen `x += y`, BennettVM.jl 23d28e6
; src/ir/arithmetic_assignment.jl; Bennett.jl 824458d1 src/adder.jl:96).
;
; ANALYTIC CHECK. `q` is |s⟩ with Ry(0.25) on every qubit (backend.md §11.3), a
; superposition of 32-bit integers. After n trips the register holds n·q (mod 2^32) on each
; branch, which is `acc`; on the zero-trip edge it holds 0 = the seed, and the
; exit φ's guard incoming (the seed `0`) is renamed to the register, so the one
; measure reads `%cq.acc` on both paths. The register is measured, never freed
; (R5). `q` is only read (slot 0), never written.
;
; What the dtzb decline protected still holds and is still pinned: a quantum `q`
; never lands in the CLASSICAL-immediate slot of `cqrt_{addc,xorc}` (NOINPLACE).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOINPLACE < %t.ll
; CHECK-LABEL: define i32 @twoq(
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 %seed)
; CHECK: %cq.acc = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: br i1 %guard, label %loop, label %exit
; CHECK: exit:
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %cq.acc)
; CHECK: loop:
; CHECK: call void @cqrt_add_i32(i32 %h, i32 %cq.acc), !cq.inplace.qq
; NOINPLACE-NOT: cqrt_free
; NOINPLACE-NOT: cqrt_addc
; NOINPLACE-NOT: cqrt_xorc
; NOINPLACE-NOT: cq_template_add

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @twoq(i32 %seed, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %seed, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

exit:                                             ; preds = %entry, %loop
  %accx = phi i32 [ 0, %entry ], [ %accn, %loop ]
  %m = call i32 @cq_measure_si32(i32 %accx)
  ret i32 %m

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %accn, %loop ]
  %accn = add i32 %acc, %q0                        ; BOTH operands tainted (two-quantum)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %loop
}
