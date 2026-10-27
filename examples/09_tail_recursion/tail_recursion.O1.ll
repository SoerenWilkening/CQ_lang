; ModuleID = 'tail_recursion.c'
source_filename = "tail_recursion.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @tail_recursion(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3    ; C: unsigned x = x0; cq_theta(&x, th);
  %7 = tail call fastcc i32 @count(i32 noundef %6, i32 noundef 0, i32 noundef %2, i32 noundef %3, i32 noundef %4)    ; C: count(x, 0, k, a, b)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #4    ; C: cq_measure(...)
  ret i32 %8    ; C: return cq_measure(count(...));
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nofree noinline nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @count(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) unnamed_addr #2 {
  br label %6    ; C: entry of count (tail recursion turned into a loop by -O1)

6:                                                ; preds = %10, %5
  %7 = phi i32 [ %0, %5 ], [ %12, %10 ]    ; C: x  (parameter / recursive argument x * a + b)
  %8 = phi i32 [ %1, %5 ], [ %13, %10 ]    ; C: n  (parameter / recursive argument n + 1)
  %9 = icmp ugt i32 %7, %2    ; C: x > k
  br i1 %9, label %10, label %14    ; C: if (x > k)

10:                                               ; preds = %6
  %11 = mul i32 %3, %7    ; C: x * a
  %12 = add i32 %11, %4    ; C: x * a + b  (argument of the recursive call)
  %13 = add nsw i32 %8, 1    ; C: n + 1  (argument of the recursive call)
  br label %6    ; C: return count(...)  (the recursive call, as a back edge)

14:                                               ; preds = %6
  ret i32 %8    ; C: return n;
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree noinline nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
