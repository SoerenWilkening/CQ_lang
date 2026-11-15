; ModuleID = 'k_chain.c'
source_filename = "k_chain.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_k_kc_chain = internal constant i32 2, align 4
@__cq_k_kc_one = internal constant i32 1, align 4
@pt = global ptr @kt, align 8
@pu = global ptr @ku, align 8
@llvm.used = appending global [2 x ptr] [ptr @__cq_k_kc_chain, ptr @__cq_k_kc_one], section "llvm.metadata"

; Function Attrs: noinline nounwind ssp uwtable
define internal i32 @kt(i32 noundef %0) #0 {
  %2 = icmp ugt i32 %0, 3
  br i1 %2, label %3, label %9

3:                                                ; preds = %1
  %4 = load volatile ptr, ptr @pt, align 8, !tbaa !6
  %5 = add i32 %0, -3
  %6 = tail call i32 %4(i32 noundef %5) #4
  %7 = shl i32 %6, 1
  %8 = or disjoint i32 %7, 1
  br label %9

9:                                                ; preds = %1, %3
  %10 = phi i32 [ %8, %3 ], [ %0, %1 ]
  ret i32 %10
}

; Function Attrs: nounwind ssp uwtable
define i32 @kc_chain(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %4 = load volatile ptr, ptr @pt, align 8, !tbaa !6
  %5 = tail call i32 %4(i32 noundef %3) #4
  %6 = tail call i32 @cq_measure_ui32(i32 noundef %5) #4
  ret i32 %6
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal noundef i32 @ku(i32 noundef %0) #3 {
  %2 = mul i32 %0, 3
  %3 = add i32 %2, 1
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @kc_one(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %4 = load volatile ptr, ptr @pu, align 8, !tbaa !6
  %5 = tail call i32 %4(i32 noundef %3) #4
  %6 = load volatile ptr, ptr @pu, align 8, !tbaa !6
  %7 = add i32 %3, 1
  %8 = tail call i32 %6(i32 noundef %7) #4
  %9 = add i32 %8, %5
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #4
  ret i32 %10
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
