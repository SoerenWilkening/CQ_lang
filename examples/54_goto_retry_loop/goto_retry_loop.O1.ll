; ModuleID = '54_goto_retry_loop/goto_retry_loop.c'
source_filename = "54_goto_retry_loop/goto_retry_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @goto_retry_loop(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  br label %7    ; C: recompute:  (the shared back edge)

7:                                                ; preds = %12, %5
  %8 = phi i32 [ %6, %5 ], [ %13, %12 ]    ; C: x at recompute
  %9 = icmp sgt i32 %8, %2    ; C: if (x > k)
  br i1 %9, label %10, label %14    ; C: if (x > k)

10:                                               ; preds = %7
  %11 = sub nsw i32 %8, %2    ; C: x -= k;
  br label %12    ; C: goto recompute;  (first goto)

12:                                               ; preds = %10, %17
  %13 = phi i32 [ %11, %10 ], [ %18, %17 ]    ; C: x after either goto
  br label %7    ; C: recompute:  (the shared back edge)

14:                                               ; preds = %7
  %15 = mul nsw i32 %8, %3    ; C: y = x * c;
  %16 = icmp sgt i32 %15, %4    ; C: if (y > m)
  br i1 %16, label %17, label %19    ; C: if (y > m)

17:                                               ; preds = %14
  %18 = ashr i32 %8, 1    ; C: x = x >> 1;
  br label %12    ; C: goto recompute;  (second goto)

19:                                               ; preds = %14
  %20 = tail call i32 @cq_measure_si32(i32 noundef %15) #3    ; C: cq_measure(y)
  ret i32 %20    ; C: return
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
