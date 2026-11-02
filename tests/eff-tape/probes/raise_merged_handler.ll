; cq-a63l (CR rule 16 signal table): see raise_merged_handler.c (clang 19.1.7 -O1). signal() under a quantum predicate
; is a tape entry; the later raise reads the handler as a merged value (the installation predicate selects).
; CHECK merged_handler: call i32 @cq_template_select_i1_lh(
; CHECK merged_handler: call void @__cq_q_h1_0_ctl(
; CHECK merged_handler: call void @cqrt_abort_i1(
source_filename = "/tmp/sigq.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [7 x i8] c"h1 %d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define i32 @merged_handler(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #4
  %4 = icmp sgt i32 %3, %1
  br i1 %4, label %5, label %7

5:                                                ; preds = %2
  %6 = tail call ptr @signal(i32 noundef 30, ptr noundef nonnull @h1) #5
  br label %7

7:                                                ; preds = %5, %2
  %8 = icmp sgt i32 %3, 2
  br i1 %8, label %9, label %11

9:                                                ; preds = %7
  %10 = tail call i32 @raise(i32 noundef 30) #5
  br label %11

11:                                               ; preds = %9, %7
  %12 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare ptr @signal(i32 noundef, ptr noundef) local_unnamed_addr #1

; Function Attrs: nofree nounwind ssp uwtable
define internal void @h1(i32 noundef %0) #2 {
  %2 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %0)
  ret void
}

declare i32 @raise(i32 noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
