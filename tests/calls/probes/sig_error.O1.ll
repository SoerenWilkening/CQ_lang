; ModuleID = 'sig_error.c'
source_filename = "sig_error.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@hits = internal unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @se_const(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %4 = tail call ptr @__error() #4
  store i32 0, ptr %4, align 4, !tbaa !6
  %5 = tail call ptr @signal(i32 noundef 9, ptr noundef nonnull @h) #4
  %6 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  %7 = icmp eq ptr %5, inttoptr (i64 -1 to ptr)
  %8 = icmp ne ptr %5, null
  %9 = zext i1 %8 to i32
  %10 = select i1 %7, i32 2, i32 %9
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #4
  %12 = add nsw i32 %11, %6
  %13 = tail call ptr @__error() #4
  %14 = load i32, ptr %13, align 4, !tbaa !6
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #4
  %16 = add nsw i32 %12, %15
  ret i32 %16
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare ptr @__error() local_unnamed_addr #1

declare ptr @signal(i32 noundef, ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define internal void @h(i32 noundef %0) #2 {
  %2 = load i32, ptr @hits, align 4, !tbaa !6
  %3 = add nsw i32 %2, %0
  store i32 %3, ptr @hits, align 4, !tbaa !6
  ret void
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @se_rail(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %4 = tail call ptr @__error() #4
  store i32 0, ptr %4, align 4, !tbaa !6
  %5 = tail call ptr @signal(i32 noundef %3, ptr noundef nonnull @h) #4
  %6 = icmp eq ptr %5, inttoptr (i64 -1 to ptr)
  %7 = icmp ne ptr %5, null
  %8 = zext i1 %7 to i32
  %9 = select i1 %6, i32 2, i32 %8
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  %11 = tail call ptr @__error() #4
  %12 = load i32, ptr %11, align 4, !tbaa !6
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  %14 = add nsw i32 %13, %10
  ret i32 %14
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
