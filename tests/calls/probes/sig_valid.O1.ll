; ModuleID = 'sig_valid.c'
source_filename = "sig_valid.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@err = internal global i32 0, align 4
@hits = internal unnamed_addr global i32 0, align 4

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef nonnull ptr @__errno_location() local_unnamed_addr #0 {
  ret ptr @err
}

; Function Attrs: nounwind ssp uwtable
define i32 @sv_const(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = tail call ptr @signal(i32 noundef 9, ptr noundef nonnull @h) #5
  %5 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  %6 = icmp eq ptr %4, inttoptr (i64 -1 to ptr)
  %7 = icmp ne ptr %4, null
  %8 = zext i1 %7 to i32
  %9 = select i1 %6, i32 2, i32 %8
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %11 = add nsw i32 %10, %5
  %12 = load i32, ptr @err, align 4, !tbaa !6
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #5
  %14 = add nsw i32 %11, %13
  ret i32 %14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare ptr @signal(i32 noundef, ptr noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define internal void @h(i32 noundef %0) #3 {
  %2 = load i32, ptr @hits, align 4, !tbaa !6
  %3 = add nsw i32 %2, %0
  store i32 %3, ptr @hits, align 4, !tbaa !6
  ret void
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @sv_runtime(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2) #4
  %5 = tail call ptr @signal(i32 noundef %0, ptr noundef nonnull @h) #5
  %6 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  %7 = icmp eq ptr %5, inttoptr (i64 -1 to ptr)
  %8 = icmp ne ptr %5, null
  %9 = zext i1 %8 to i32
  %10 = select i1 %7, i32 2, i32 %9
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  %12 = add nsw i32 %11, %6
  %13 = load i32, ptr @err, align 4, !tbaa !6
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #5
  %15 = add nsw i32 %12, %14
  ret i32 %15
}

; Function Attrs: nounwind ssp uwtable
define i32 @sv_rail(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = tail call ptr @signal(i32 noundef %3, ptr noundef nonnull @h) #5
  %5 = icmp eq ptr %4, inttoptr (i64 -1 to ptr)
  %6 = icmp ne ptr %4, null
  %7 = zext i1 %6 to i32
  %8 = select i1 %5, i32 2, i32 %7
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #5
  %10 = load i32, ptr @err, align 4, !tbaa !6
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  %12 = add nsw i32 %11, %9
  ret i32 %12
}

; Function Attrs: nounwind ssp uwtable
define i32 @sv_rail_pred(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %5 = icmp sgt i32 %4, %2
  br i1 %5, label %6, label %13

6:                                                ; preds = %3
  %7 = and i32 %4, 63
  %8 = tail call ptr @signal(i32 noundef %7, ptr noundef nonnull @h) #5
  %9 = icmp eq ptr %8, inttoptr (i64 -1 to ptr)
  %10 = icmp ne ptr %8, null
  %11 = zext i1 %10 to i32
  %12 = select i1 %9, i32 2, i32 %11
  br label %13

13:                                               ; preds = %6, %3
  %14 = phi i32 [ %12, %6 ], [ 0, %3 ]
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #5
  %16 = load i32, ptr @err, align 4, !tbaa !6
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #5
  %18 = add nsw i32 %17, %15
  ret i32 %18
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
