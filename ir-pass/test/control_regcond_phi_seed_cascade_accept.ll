; control_regcond_phi_seed_cascade_accept.ll — ACCEPT (bd test_C_libtooling-
; dm7f.77, R11 round 1 B-F1): two in-place QQ xors whose dead targets are
; controlled STATE-PREP merges `phi [Ry(false), false]`.
;
; Source (clang -O1 -include CQ.h; review_s2B/p6_cascade.c):
;   bool a = 0, b = 0, c = 0; cq_theta(&a, 1.1);
;   if (a) cq_theta(&b, .8);  if (b) cq_theta(&c, .6);
;   c ^= a; b ^= c;  cq_theta(&a, .5); cq_theta(&c, .4);
;
; THE SILENT MISCOMPILE THIS PINS (found by R11 round 1 on 348e245f): the merge's
; constant incoming `false` IS the seed the prep's rail is minted at, but the
; single-wire φ test refused every constant, so both xors stayed OUT OF PLACE
; beside the old b/c rails: P(000) 0.6555 emitted vs 0.6709 textbook, every
; outcome wrong, rc 0 (an M-A warning only). Now a constant incoming identical to
; the chain root theta's own seed is the same wire (`singleWirePhiDeadAfter`),
; and any dead user-register φ NOT provably one wire beside a kept result fails
; loudly (step 1's Q1) instead of going out of place. `c ^= a` arrives as -O1's
; `icmp ne (phi i32 [zext Ry, 0]), (zext a)`, narrowed to i1 first (D1).
; ANALYTIC (trace vs textbook CNOT(a,c); CNOT(c,b); Ry(a,.5); Ry(c,.4) after the
; two controlled preps, identical to 12 digits): P(a,b,c) = 000: 0.670947473410,
; 001: 0.013678631310, 010: 0.000082407285, 011: 0.014325511147,
; 100: 0.028656648772, 101: 0.051327278310, 110: 0.001263925165,
; 111: 0.219718124601.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define range(i32 0, 8) i32 @main()
; CHECK:       call void @cqrt_ry_i1_controlled(i32 %[[A:[a-zA-Z0-9_.]+]], i32 %[[B:[a-zA-Z0-9_.]+]], double 8.000000e-01)
; CHECK-NEXT:  %[[C:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[B]], i32 %[[C]], double 6.000000e-01)
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[A]], i32 %[[C]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[C]], i32 %[[B]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[A]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[C]], double 4.000000e-01)
; CHECK-NOT:   cq_template_xor

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 8) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.100000e+00)
  br i1 %1, label %2, label %4

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 8.000000e-01)
  br label %4

4:                                                ; preds = %2, %0
  %5 = phi i1 [ %3, %2 ], [ false, %0 ]
  br i1 %5, label %6, label %9

6:                                                ; preds = %4
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01)
  %8 = zext i1 %7 to i32
  br label %9

9:                                                ; preds = %6, %4
  %10 = phi i32 [ %8, %6 ], [ 0, %4 ]
  %11 = zext i1 %1 to i32
  %12 = icmp ne i32 %10, %11
  %13 = xor i1 %5, %12
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 5.000000e-01)
  %15 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %12, double noundef 4.000000e-01)
  %16 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %14)
  %17 = zext i1 %16 to i32
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %13)
  %19 = select i1 %18, i32 2, i32 0
  %20 = or disjoint i32 %19, %17
  %21 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %15)
  %22 = select i1 %21, i32 4, i32 0
  %23 = or disjoint i32 %20, %22
  ret i32 %23
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
