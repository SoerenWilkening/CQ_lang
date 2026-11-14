; ModuleID = 'fnptr_entry_param.c'
source_filename = "fnptr_entry_param.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @sq(i32 noundef %0) #0 {
  %2 = mul nsw i32 %0, %0
  ret i32 %2
}

; Function Attrs: noinline nounwind ssp uwtable
define i32 @ep(ptr nocapture noundef readonly %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2) #5
  %5 = tail call i32 %0(i32 noundef %4) #6
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #6
  ret i32 %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @ep_drv(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #3 {
  %4 = icmp eq i32 %2, 0
  %5 = select i1 %4, ptr @neg, ptr @sq
  %6 = tail call i32 @ep(ptr noundef nonnull %5, i32 noundef %0, double noundef %1)
  ret i32 %6
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal range(i32 -2147483647, -2147483648) i32 @neg(i32 noundef %0) #0 {
  %2 = sub nsw i32 0, %0
  ret i32 %2
}

; Function Attrs: nounwind ssp uwtable
define i32 @ep_host(i32 noundef %0, double noundef %1) local_unnamed_addr #3 {
  %3 = tail call fastcc i32 @ep.specialized.1(i32 noundef %0, double noundef %1)
  ret i32 %3
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @ep.specialized.1(i32 noundef %0, double noundef %1) unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %4 = tail call i32 @llvm.abs.i32(i32 %3, i1 true)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #6
  ret i32 %5
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.abs.i32(i32, i1 immarg) #4

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
