; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 7
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01) #5
  %8 = mul nsw i32 %7, 3
  %9 = xor i32 %8, %7
  %10 = tail call i32 @h(i32 noundef %5, i32 noundef %7) #5
  %11 = icmp eq i32 %9, 10
  br i1 %11, label %12, label %13

12:                                               ; preds = %2
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %13

13:                                               ; preds = %12, %2
  %14 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  %15 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 0x3FE6666666666666) #5
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #5
  %17 = add nsw i32 %16, %14
  ret i32 %17
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare void @cq_phi(double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @a6(i32 noundef %0) local_unnamed_addr #3 {
  %2 = add nsw i32 %0, 1
  ret i32 %2
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483645, -2147483648) i32 @b6(i32 noundef %0) local_unnamed_addr #3 {
  %2 = add nsw i32 %0, 3
  ret i32 %2
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a5(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call i32 @a6(i32 noundef %0)
  %3 = tail call i32 @b6(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b5(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call i32 @a6(i32 noundef %0)
  %3 = tail call i32 @b6(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a4(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call i32 @a5(i32 noundef %0)
  %3 = tail call i32 @b5(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b4(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call i32 @a5(i32 noundef %0)
  %3 = tail call i32 @b5(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a3(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call i32 @a4(i32 noundef %0)
  %3 = tail call i32 @b4(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b3(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call i32 @a4(i32 noundef %0)
  %3 = tail call i32 @b4(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a2(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call i32 @a3(i32 noundef %0)
  %3 = tail call i32 @b3(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b2(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call i32 @a3(i32 noundef %0)
  %3 = tail call i32 @b3(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a1(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call i32 @a2(i32 noundef %0)
  %3 = tail call i32 @b2(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b1(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call i32 @a2(i32 noundef %0)
  %3 = tail call i32 @b2(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a0(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call i32 @a1(i32 noundef %0)
  %3 = tail call i32 @b1(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b0(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call i32 @a1(i32 noundef %0)
  %3 = tail call i32 @b1(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = tail call i32 @a0(i32 noundef %1)
  ret i32 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
