; loop_acc_seeded_accept.ll — ACCEPT (bd test_C_libtooling-01po.19.18, CQ_FINDINGS
; F5): the SEEDED QUANTUM ACCUMULATOR (LoopAccumulator.h). A loop-carried scalar
; with a CLASSICAL seed, updated in place each trip by a QUANTUM source, lowers
; ROLLED: one register `%cq.acc = cqrt_alloc_i32(seed)` minted at the end of the
; loop's entry block, and each trip's step as the in-place quantum-source gate
; `cqrt_{add,sub}_i32(src, %cq.acc)` tagged `!cq.inplace.qq` (Mogensen `x ⊕= y`:
; BennettVM.jl 23d28e6 src/ir/arithmetic_assignment.jl:1-97; Bennett.jl 824458d1
; src/adder.jl:96 `lower_add_cuccaro!`). The register is never freed (R5).
;
; ANALYTIC CHECKS, per function (each register's value on every basis branch):
;  @per_trip_register  `a = 5; for 3: { q = Ry(.5)|0⟩ fresh; a += q; }` — the
;     accumulator holds 5 + q₁ + q₂ + q₃; each q_k is a fresh rotated register
;     (user data, left allocated), read once in slot 0. Was the (Z6) control of
;     loop_carried_handle_reject_accumulator.ll (that file now pins a refused
;     latch instead).
;  @guarded_sub_temp  `acc = 7; for n: acc -= q * 3;` — `cqrt_sub_i32(t, acc)`
;     with the per-trip template `t = 3q` discharged IN ITS TRIP (`_unc` + free,
;     `markIfRailLocal` via `collapseRoundOneAccumulators`); acc = 7 − 3nq. The
;     zero-trip exit φ's seed incoming is renamed to the register, so the one
;     measure reads it on both paths (n = 0 measures 7).
;  @rot_step  `acc = 0; for 2: { acc += q; acc = Ry(.3)(acc); }` — a rotation
;     step on the chain is the register's own in-place gate: add, then
;     `cqrt_ry_i32(%cq.acc)`, per trip.
;  @round2_phase  `c = 0; for 3: { if (c == 1) cq_phi(.5); c += a; }` — the
;     ROUND-2 path (in-body tainted control, `collapseRailPhisIn`): the flag is
;     minted from the register, `cqrt_rz_i1`, stripped, freed, then the add. The
;     register reads 0, a, 2a at the three compares, as `c` does.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOOOP < %t.ll
; NOOOP-NOT: cq_template_add_i32(
; NOOOP-NOT: cq_template_sub_i32(
; NOOOP-NOT: cqrt_addc
; NOOOP-NOT: cqrt_free(i32 %cq.acc
;
; CHECK-LABEL: define i32 @per_trip_register(
; CHECK: entry:
; CHECK-NEXT: %cq.acc = call i32 @cqrt_alloc_i32(i32 5)
; CHECK: head:
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_add_i32(i32 %h, i32 %cq.acc), !cq.inplace.qq
; CHECK: exit:
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %cq.acc)
;
; CHECK-LABEL: define i32 @guarded_sub_temp(
; CHECK: %cq.acc = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: br i1 %guard, label %loop, label %exit
; CHECK: exit:
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %cq.acc)
; CHECK: loop:
; CHECK: %h_op = call i32 @cq_template_mul_i32_hl(i32 %h{{[0-9]*}}, i32 3)
; CHECK-NEXT: call void @cqrt_sub_i32(i32 %h_op, i32 %cq.acc), !cq.inplace.qq
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h{{[0-9]*}}, i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %h_op)
;
; CHECK-LABEL: define i32 @rot_step(
; CHECK: %cq.acc = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: loop:
; CHECK: call void @cqrt_add_i32(i32 %h{{[0-9]*}}, i32 %cq.acc), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %cq.acc, double 3.000000e-01)
;
; CHECK-LABEL: define i32 @round2_phase(
; CHECK: %cq.acc = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %cq.acc, i32 1)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %h_cmp, double 5.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %cq.acc, i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp)
; CHECK-NEXT: call void @cqrt_add_i32(i32 %h{{[0-9]*}}, i32 %cq.acc), !cq.inplace.qq
; CHECK: call i32 @cqrt_measure_i32(i32 %cq.acc)

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @per_trip_register() {
entry:
  br label %head

head:
  %i = phi i32 [ 0, %entry ], [ %inext, %head ]
  %a = phi i32 [ 5, %entry ], [ %anext, %head ]
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %anext = add nsw i32 %a, %q
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head, !llvm.loop !0

exit:
  %m = call i32 @cq_measure_si32(i32 %anext)
  ret i32 %m
}

define i32 @guarded_sub_temp(i32 %seed, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %seed, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

exit:
  %accx = phi i32 [ 7, %entry ], [ %accn, %loop ]
  %m = call i32 @cq_measure_si32(i32 %accx)
  ret i32 %m

loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %acc = phi i32 [ 7, %entry ], [ %accn, %loop ]
  %t = mul i32 %q0, 3
  %accn = sub i32 %acc, %t
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %loop, !llvm.loop !0
}

define i32 @rot_step() {
entry:
  %q0 = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  br label %loop

exit:
  %m = call i32 @cq_measure_si32(i32 %r)
  %m2 = call i32 @cq_measure_si32(i32 %q0)
  %s = add i32 %m, %m2
  ret i32 %s

loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %r, %loop ]
  %t = add i32 %acc, %q0
  %r = call i32 @cq_theta_si32(i32 %t, double 3.000000e-01)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 2
  br i1 %done, label %exit, label %loop, !llvm.loop !0
}

define i32 @round2_phase() {
entry:
  %a = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %c = phi i32 [ 0, %entry ], [ %cn, %latch ]
  %f = icmp eq i32 %c, 1
  br i1 %f, label %arm, label %latch

arm:
  call void @cq_phi(double 5.000000e-01)
  br label %latch

latch:
  %cn = add nsw i32 %c, %a
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %loop, !llvm.loop !0

exit:
  %m = call i32 @cq_measure_si32(i32 %cn)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
