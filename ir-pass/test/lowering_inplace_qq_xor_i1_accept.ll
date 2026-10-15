; lowering_inplace_qq_xor_i1_accept.ll — ACCEPT: a quantum-quantum `t ^= a` whose
; OLD `t` is dead lowers IN PLACE on `t`'s rail (bd test_C_libtooling-r2j3.33,
; dm7f.51 step 1, design V6 at i1; owner ruling owner-ruling-dm7f51-inplace-qq-
; 2026-10-14 Q1/Q3: i1 uses `cqrt_cnot`).
;
; Source (clang -O1 -include CQ.h):
;   bool a = 0, t = 0; cq_theta(&a, .5); cq_theta(&t, .4);
;   t ^= a; cq_theta(&a, .7); cq_measure(a); cq_measure(t);
;
; THE MISCOMPILE THIS PINS. Before this change the xor lowered out of place,
; `%h_op = cq_template_xor_i1(h_a, h_t)`, and the old `t` root rail stood beside
; the result: together they record `a`, so the later Ry on `a` is dephased.
; Analytic (scratch analytic.py, Ry(θ)|0> = cos θ/2|0> + sin θ/2|1>):
;   emitted in place  P(a=0,t=0) = 0.7659, P(a=0,t=1) = 0.0095  (the textbook
;                     CNOT(a->t); Ry(.7) on a)
;   old out of place  P(a=0,t=0) = 0.7960, P(a=0,t=1) = 0.0396
; Now: ONE `cqrt_cnot(h_a, h_t)` tagged `!cq.inplace.qq`, `t` measured from its own
; rail, no template, no third rail, nothing freed (both are rotated user data).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=TAGCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOREC < %t.cqd0.ll
;
; CHECK-LABEL: define noundef i32 @main()
; CHECK-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[A]], double 5.000000e-01)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[A]], i32 %[[T]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[A]], double 0x3FE6666666666666)
; CHECK-NEXT:  call i1 @cqrt_measure_i1(i32 %[[A]])
; CHECK-NEXT:  call i1 @cqrt_measure_i1(i32 %[[T]])
; CHECK-NEXT:  ret i32 0
; CHECK-NOT:   cq_template_xor
; CHECK-NOT:   cqrt_free
;
; TAGCNT-COUNT-1: !cq.inplace.qq
; TAGCNT-NOT:     call void @cqrt_cnot
; The pre-emission dead-operand record never survives into the output.
; NOREC-NOT: cq.qq.dead

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define noundef i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01)
  %3 = xor i1 %1, %2
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 0x3FE6666666666666)
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4)
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3)
  ret i32 0
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
