; control_regcond_not_tree_discharge_accept.ll — ACCEPT (bd test_C_libtooling-
; dm7f.77): the reporter's t7.c CCRy followed by a rotation of a control.
;
; Source (clang -O1 -include CQ.h):
;   bool a = 0, b = 0, t = 1; cq_theta(&a, 1.0); cq_theta(&b, 1.0);
;   b ^= a; if (a & b) cq_theta(&t, .5); b ^= a; cq_theta(&a, .3);
;   return cq_measure(a) | (cq_measure(b) << 1) | (cq_measure(t) << 2);
;
; -O1 folds `a & (a ^ b)` to `a & !b` (no CNOT left). The NOT no network takes,
; so the condition's own out-of-place rail is a fresh REGISTER condition. It must
; be DISCHARGED before the later Ry on `a`: a record of `a` left standing there
; dephases it (dead-record ruling). The spine's new row (c′) (ChainWalk.cpp:
; a control read finishes with the rail) is what discharges it; without it the
; stream ended with `and_i1` dirty and M-A warned "non-diagonal gate over a live
; derived record". Main 27aaf1e1 declined `control flow`. Analytic (trace vs
; textbook, identical to 12 digits): P(a,b,t) = 000: 0.000241966060,
; 001: 0.490817741410, 011: 0.145666572208, 100: 0.010593100672,
; 101: 0.268498344791, 111: 0.084182274858.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define range(i32 0, 8) i32 @main()
; CHECK:       %[[NB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i1_hl(i32 %[[B:[a-zA-Z0-9_.]+]], i1 true)
; CHECK-NEXT:  %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i1(i32 %[[A:[a-zA-Z0-9_.]+]], i32 %[[NB]])
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 true)
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[C]], i32 %[[T]], double 5.000000e-01)
; CHECK-NEXT:  call void @cq_template_and_i1_unc(i32 %[[C]], i32 %[[A]], i32 %[[NB]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT:  call void @cq_template_xor_i1_hl_unc(i32 %[[NB]], i32 %[[B]], i1 true)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[NB]])
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[A]], double 3.000000e-01)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 8) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.000000e+00)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.000000e+00)
  %3 = xor i1 %2, true
  %4 = and i1 %1, %3
  br i1 %4, label %5, label %7

5:                                                ; preds = %0
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 5.000000e-01)
  br label %7

7:                                                ; preds = %5, %0
  %8 = phi i1 [ %6, %5 ], [ true, %0 ]
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 3.000000e-01)
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %9)
  %11 = zext i1 %10 to i32
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2)
  %13 = select i1 %12, i32 2, i32 0
  %14 = or disjoint i32 %13, %11
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8)
  %16 = select i1 %15, i32 4, i32 0
  %17 = or disjoint i32 %14, %16
  ret i32 %17
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
