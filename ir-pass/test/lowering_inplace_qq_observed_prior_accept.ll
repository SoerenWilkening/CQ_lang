; lowering_inplace_qq_observed_prior_accept.ll — ACCEPT (bd test_C_libtooling-
; dm7f.77, design D2(b): "a prior reader that is OBSERVED counts settled").
;
; Source (clang -O1 -include CQ.h):
;   bool q1 = 0, q2 = 0, q4 = 1; cq_theta(&q2, .5); cq_theta(&q1, .6);
;   q4 ^= q2; q2 ^= q1; cq_theta(&q1, .3);
;   return cq_measure(q1) | (cq_measure(q2) << 1) | (cq_measure(q4) << 2);
;
; `q4 = 1 ^ q2` is an out-of-place `_hl` record of q2's OLD value; it is MEASURED,
; so the spine never reverses it and overwriting q2 after it stales nothing
; (`priorUseIsSettled` arm (d3), quantum source only). Main 27aaf1e1 failed
; loudly (G7). dicke.c's `q4 = !q2 ... q2 ^= q1` is this shape. Analytic (trace vs
; textbook, identical to 12 digits): P(q1,q2,q4) = 000: 0.000119374212,
; 001: 0.837670629699, 010: 0.054615703484, 011: 0.001830906954,
; 100: 0.005226117426, 101: 0.019133950339, 110: 0.001247523933,
; 111: 0.080155793953.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define range(i32 0, 8) i32 @main()
; CHECK:       %[[Q4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i1_hl(i32 %[[Q2:[a-zA-Z0-9_.]+]], i1 true)
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[Q1:[a-zA-Z0-9_.]+]], i32 %[[Q2]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[Q1]], double 3.000000e-01)
; CHECK:       call i1 @cqrt_measure_i1(i32 %[[Q4]])

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 8) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01)
  %3 = xor i1 %1, true
  %4 = xor i1 %1, %2
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef 3.000000e-01)
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5)
  %7 = zext i1 %6 to i32
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4)
  %9 = select i1 %8, i32 2, i32 0
  %10 = or disjoint i32 %9, %7
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3)
  %12 = select i1 %11, i32 4, i32 0
  %13 = or disjoint i32 %10, %12
  ret i32 %13
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
