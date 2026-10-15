; control_regcond_sink_stops_at_gate.ll — ACCEPT, ADVERSARIAL (bd
; test_C_libtooling-dm7f.77, `sinkCommittedCondition`, RegCondLeaf.cpp): a gate
; on the committed xor's SOURCE between the xor and its branch.
;
; Source (clang -O1 -include CQ.h):
;   bool a = 0, t = 0, b = 0; cq_theta(&a, .4); cq_theta(&t, .3); cq_theta(&b, .2);
;   t ^= a; cq_theta(&a, .6); if (t) cq_theta(&b, .9);
;   return cq_measure(a) | (cq_measure(t) << 1) | (cq_measure(b) << 2);
;
; The commit sinks a committed condition to its branch so independent pure
; readers run before the in-place gate, but it must cross NO call: sinking past
; `cq_theta(&a, .6)` would make the xor read `a` AFTER its rotation. The CNOT
; stays before the Ry. Analytic (trace vs textbook, identical to 12 digits):
; P(a,t,b) = 000: 0.832519297724, 100: 0.098073964842, 110: 0.038764723917,
; 111: 0.014571582290 (and four smaller cells).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define range(i32 0, 8) i32 @main()
; CHECK:       call void @cqrt_cnot(i32 %[[A:[a-zA-Z0-9_.]+]], i32 %[[T:[a-zA-Z0-9_.]+]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[A]], double 6.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[T]], i32 %{{[a-zA-Z0-9_.]+}}, double 9.000000e-01)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 8) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01)
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 2.000000e-01)
  %4 = xor i1 %1, %2
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 6.000000e-01)
  br i1 %4, label %6, label %8

6:                                                ; preds = %0
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef 9.000000e-01)
  br label %8

8:                                                ; preds = %6, %0
  %9 = phi i1 [ %7, %6 ], [ %3, %0 ]
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5)
  %11 = zext i1 %10 to i32
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4)
  %13 = select i1 %12, i32 2, i32 0
  %14 = or disjoint i32 %13, %11
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %9)
  %16 = select i1 %15, i32 4, i32 0
  %17 = or disjoint i32 %14, %16
  ret i32 %17
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
