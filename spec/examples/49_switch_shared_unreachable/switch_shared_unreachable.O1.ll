; ModuleID = 'switch_shared_unreachable.c'
source_filename = "switch_shared_unreachable.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @switch_shared_unreachable(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %6 = and i32 %5, 3    ; C: x & 3
  switch i32 %6, label %13 [    ; C: switch (x & 3)  (default -> %13)
    i32 0, label %7    ; C: case 0:
    i32 1, label %7    ; C: case 1:  (shares the arm of case 0)
    i32 2, label %9    ; C: case 2:
    i32 3, label %11    ; C: case 3:
  ]

7:                                                ; preds = %4, %4
  %8 = add nsw i32 %5, %2    ; C: r = x + a;
  br label %14    ; C: break;

9:                                                ; preds = %4
  %10 = mul nsw i32 %5, %3    ; C: r = x * b;
  br label %14    ; C: break;

11:                                               ; preds = %4
  %12 = sub nsw i32 %5, %2    ; C: r = x - a;
  br label %14    ; C: break;

13:                                               ; preds = %4
  unreachable    ; C: default: __builtin_unreachable();

14:                                               ; preds = %11, %9, %7
  %15 = phi i32 [ %12, %11 ], [ %10, %9 ], [ %8, %7 ]    ; C: r  (merge of the three arms)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #3    ; C: cq_measure(r)
  ret i32 %16    ; C: return
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
