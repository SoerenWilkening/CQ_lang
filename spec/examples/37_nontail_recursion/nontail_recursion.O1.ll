; ModuleID = 'nontail_recursion.c'
source_filename = "nontail_recursion.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @nontail_recursion(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %6 = tail call fastcc i32 @sumdown(i32 noundef %5, i32 noundef %2, i32 noundef %3)    ; C: sumdown(x, k, a)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #4    ; C: cq_measure(...)
  ret i32 %7    ; C: return
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nofree noinline nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @sumdown(i32 noundef %0, i32 noundef %1, i32 noundef %2) unnamed_addr #2 {
  br label %4    ; C: entry (recursion turned into an accumulator loop by -O1)

4:                                                ; preds = %8, %3
  %5 = phi i32 [ 0, %3 ], [ %10, %8 ]    ; C: accumulated sum of the x values seen so far
  %6 = phi i32 [ %0, %3 ], [ %9, %8 ]    ; C: x  (parameter / recursive argument x / a)
  %7 = icmp ugt i32 %6, %1    ; C: x <= k  (negated)
  br i1 %7, label %8, label %11    ; C: if (x <= k) return x;  else recurse

8:                                                ; preds = %4
  %9 = udiv i32 %6, %2    ; C: x / a  (argument of the recursive call)
  %10 = add i32 %5, %6    ; C: x + ...  (the pending addition, accumulated)
  br label %4    ; C: return x + sumdown(...)  (as a back edge)

11:                                               ; preds = %4
  %12 = add i32 %5, %6    ; C: accumulated sum + x  (the base case return x, plus the pending additions)
  ret i32 %12    ; C: return
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
