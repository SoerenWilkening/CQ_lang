; ModuleID = 'nonreconverging_returns.c'
source_filename = "nonreconverging_returns.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @nonreconverging_returns(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %8 = icmp sgt i32 %7, %2    ; C: x > k
  br i1 %8, label %9, label %12    ; C: if (x > k)

9:                                                ; preds = %6
  %10 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %4) #2    ; C: cq_theta(&r, t1);  (r = r0)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %7) #3    ; C: return cq_measure(x);  (first arm)
  br label %16

12:                                               ; preds = %6
  %13 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %5) #2    ; C: cq_theta(&r, t2);  (r = r0)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %7) #3    ; C: cq_measure(x)  (second arm)
  %15 = add nsw i32 %14, 1    ; C: cq_measure(x) + 1
  br label %16

16:                                               ; preds = %12, %9
  %17 = phi i32 [ %11, %9 ], [ %15, %12 ]    ; C: the two returns, merged by clang
  ret i32 %17    ; C: return ...;
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
