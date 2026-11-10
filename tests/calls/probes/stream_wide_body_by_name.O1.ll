; ModuleID = 'stream_wide_body_by_name.c'
source_filename = "stream_wide_body_by_name.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__stdoutp = external local_unnamed_addr global ptr, align 8

; Function Attrs: nofree noinline nounwind ssp uwtable
define noundef i32 @fputwc(i32 noundef %0, ptr nocapture noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @fputc(i32 noundef %0, ptr noundef %1)
  %4 = icmp eq i32 %3, -1
  %5 = select i1 %4, i32 -1, i32 %0
  ret i32 %5
}

; Function Attrs: nofree nounwind
declare noundef i32 @fputc(i32 noundef, ptr nocapture noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @stream_wide_body(i8 noundef signext %0) local_unnamed_addr #2 {
  %2 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef 3.000000e-01) #4
  %3 = tail call fastcc i32 @show(i8 noundef signext %2)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  ret i32 %4
}

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #3

; Function Attrs: nofree noinline nounwind ssp uwtable
define internal fastcc range(i32 -127, 129) i32 @show(i8 noundef signext %0) unnamed_addr #0 {
  %2 = sext i8 %0 to i32
  %3 = and i32 %2, 1
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %10, label %5

5:                                                ; preds = %1
  %6 = and i32 %2, 7
  %7 = add nuw nsw i32 %6, 97
  %8 = load ptr, ptr @__stdoutp, align 8, !tbaa !6
  %9 = tail call i32 @fputwc(i32 noundef %7, ptr noundef %8)
  br label %10

10:                                               ; preds = %5, %1
  %11 = add nsw i32 %2, 1
  ret i32 %11
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

attributes #0 = { nofree noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
