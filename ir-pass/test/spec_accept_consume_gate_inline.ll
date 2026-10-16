; spec_accept_consume_gate_inline.ll — ACCEPT, in place (bd
; test_C_libtooling-r2j3.37.1): a lift site the gate-subroutine inliner (bd
; p3kd.21) EXPOSES after the lift's own detection, in both inliner phases:
;   c_phase1  `g(t,a){ cq_phi(.3); return f(t,a); }` (first phase)
;   c_phase2  `h(t,a){ y = f(t,a); cq_theta(&y,.2); return y; }` (the
;             CrossCallResults phase)
; Both become one consuming call `__cq_q_f_11_c0(t, a)` (cnot(a, t)); in
; c_phase2 the inlined Ry then rotates t's rail. Analytic replay equals the
; textbook circuit (t ^= a; Ry(.2) t; Ry(.7) a).
;
; THE MECHANISM (SpecializeConsume.h; design of record bd r2j3.37.1): the lifted
; call becomes ONE call to a CONSUMING CLONE `__cq_q_<f>_<mask>_c<k>` that maps
; |t>|a> -> |f(t,a)>|a> on the dead argument t's own rail (slot k), tagged
; `!cq.inplace.qq`; its body is the in-place gates the in-place rounds mint, one per
; op of f's return chain, each fed by a parameter, a constant or a lifted SOURCE
; clone (computed, used, uncomputed and freed inside the body). The decision is
; the inlined twin's (InPlaceQQConsume.cpp).
;
; Source: f7.c (lane L scratch), clang-19 -O1 -include CQ.h.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=ERR --allow-empty < %t.err
; ERR-NOT: error
;
; CHECK-LABEL: define {{.*}}i32 @c_phase1(
; CHECK:      [[A:%[a-z0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[A]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[a-z0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[T]], double 4.000000e-01)
; CHECK-NEXT: call void @__cq_q_f_11_c0(i32 [[T]], i32 [[A]]), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[A]], double 0x3FE6666666666666)
; CHECK-LABEL: define {{.*}}i32 @c_phase2(
; CHECK:      [[A:%[a-z0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[A]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[a-z0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[T]], double 4.000000e-01)
; CHECK-NEXT: call void @__cq_q_f_11_c0(i32 [[T]], i32 [[A]]), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[T]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[A]], double 0x3FE6666666666666)
; CHECK-LABEL: define internal void @__cq_q_f_11_c0(i32 %0, i32 %1)
; CHECK-NEXT: call void @cqrt_cnot(i32 %1, i32 %0), !cq.inplace.qq
source_filename = "f7.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i1 @f(i1 noundef zeroext %0, i1 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = xor i1 %0, %1
  ret i1 %3
}

; Function Attrs: noinline nounwind ssp uwtable
define noundef zeroext i1 @g(i1 noundef zeroext %0, i1 noundef zeroext %1) local_unnamed_addr #1 {
  tail call void @cq_phi(double noundef 3.000000e-01) #4
  %3 = tail call zeroext i1 @f(i1 noundef zeroext %0, i1 noundef zeroext %1)
  ret i1 %3
}

declare void @cq_phi(double noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define zeroext i1 @h(i1 noundef zeroext %0, i1 noundef zeroext %1) local_unnamed_addr #1 {
  %3 = tail call zeroext i1 @f(i1 noundef zeroext %0, i1 noundef zeroext %1)
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef 2.000000e-01) #5
  ret i1 %4
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define range(i32 0, 4) i32 @c_phase1() local_unnamed_addr #1 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #5
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #5
  %3 = tail call zeroext i1 @g(i1 noundef zeroext %2, i1 noundef zeroext %1)
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 0x3FE6666666666666) #5
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #4
  %6 = zext i1 %5 to i32
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #4
  %8 = select i1 %7, i32 2, i32 0
  %9 = or disjoint i32 %8, %6
  ret i32 %9
}

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define range(i32 0, 4) i32 @c_phase2() local_unnamed_addr #1 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #5
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #5
  %3 = tail call zeroext i1 @h(i1 noundef zeroext %2, i1 noundef zeroext %1)
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 0x3FE6666666666666) #5
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #4
  %6 = zext i1 %5 to i32
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #4
  %8 = select i1 %7, i32 2, i32 0
  %9 = or disjoint i32 %8, %6
  ret i32 %9
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 7) i32 @main() local_unnamed_addr #3 {
  %1 = tail call i32 @c_phase1()
  %2 = tail call i32 @c_phase2()
  %3 = add nuw nsw i32 %2, %1
  ret i32 %3
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
