; spec_accept_consume_live_arg.ll — ACCEPT, NOT consumed (bd
; test_C_libtooling-r2j3.37.1): the dead-argument twin of
; spec_accept_consume_inplace.ll. `t` is measured AFTER `r = fx(t, a)`, so the old
; `t` is the program's own register and the call stays the out-of-place Bennett
; clone (the entangling copy the program wrote; as main lowers the inlined
; `r = t ^ a` with `t` live). A mutant that drops the deadness clause consumes
; `t` here and the CHECK-NOT below fires.
;
; Source: f2.c (lane L scratch), clang-19 -O1 -include CQ.h.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK:      [[A:%[a-z0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[A]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[a-z0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[T]], double 4.000000e-01)
; CHECK-NEXT: [[R:%[0-9]+]] = call i32 @__cq_q_fx_11(i32 [[T]], i32 [[A]])
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[A]], double 0x3FE6666666666666)
; CHECK-NOT:  _c0
; CHECK:      call i1 @cqrt_measure_i1(i32 [[R]])
; CHECK:      call i1 @cqrt_measure_i1(i32 [[T]])
; CHECK-LABEL: define internal i32 @__cq_q_fx_11(
source_filename = "f2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i1 @fx(i1 noundef zeroext %0, i1 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = xor i1 %0, %1
  ret i1 %3
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 8) i32 @main() local_unnamed_addr #1 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #3
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #3
  %3 = tail call zeroext i1 @fx(i1 noundef zeroext %2, i1 noundef zeroext %1)
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 0x3FE6666666666666) #3
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #4
  %6 = zext i1 %5 to i32
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #4
  %8 = select i1 %7, i32 2, i32 0
  %9 = or disjoint i32 %8, %6
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #4
  %11 = select i1 %10, i32 4, i32 0
  %12 = or disjoint i32 %9, %11
  ret i32 %12
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
