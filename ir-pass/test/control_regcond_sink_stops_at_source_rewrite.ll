; control_regcond_sink_stops_at_source_rewrite.ll — ACCEPT, ADVERSARIAL (bd
; test_C_libtooling-dm7f.77, R11 round 1 A-F1; hand IR review_s2A/p1b.ll): between
; the committed condition `%4 = t ^ a` and its branch sits `%w = a ^ z`, the LAST
; reader of `a` (V's source), which the late round puts IN PLACE on a's rail.
; Sinking %4 past it would make the condition read a's overwritten rail. The sink
; refuses to cross an add/sub/xor whose operand is one of V's and dead after it,
; so the stream is CNOT(a,t) [t ^= a] then CNOT(z,a) [a ^= z] then the prep
; controlled by t's rail — the source order.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define range(i32 0, 16) i32 @main()
; CHECK:       call void @cqrt_cnot(i32 %[[A:[a-zA-Z0-9_.]+]], i32 %[[T:[a-zA-Z0-9_.]+]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[Z:[a-zA-Z0-9_.]+]], i32 %[[A]]), !cq.inplace.qq
; CHECK-NEXT:  %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[T]], i32 %[[B]], double 5.000000e-01)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 16) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FE6666666666666)
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.100000e+00)
  %4 = xor i1 %1, %2
  %w = xor i1 %2, %3
  br i1 %4, label %5, label %7

5:                                                ; preds = %0
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %7

7:                                                ; preds = %5, %0
  %8 = phi i1 [ %6, %5 ], [ false, %0 ]
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4)
  %11 = zext i1 %10 to i32
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %w)
  %13 = select i1 %12, i32 2, i32 0
  %14 = or disjoint i32 %13, %11
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3)
  %16 = select i1 %15, i32 4, i32 0
  %17 = or disjoint i32 %14, %16
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8)
  %19 = select i1 %18, i32 8, i32 0
  %20 = or disjoint i32 %17, %19
  ret i32 %20
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
