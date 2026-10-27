; ModuleID = 'quantum_depth_recursion.c'
source_filename = "quantum_depth_recursion.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @quantum_depth_recursion(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&n, th);
  %5 = and i32 %4, 3    ; C: n & 3
  %6 = tail call fastcc i32 @chain(i32 noundef %5, i32 noundef %2)    ; C: chain(n & 3, a)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #4    ; C: cq_measure(chain(n & 3, a))
  ret i32 %7    ; C: return
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nofree noinline nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @chain(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  %3 = icmp slt i32 %0, 1    ; C: if (n <= 0)
  br i1 %3, label %4, label %6    ; C: if (n <= 0)

4:                                                ; preds = %2, %6
  %5 = phi i32 [ %10, %6 ], [ %1, %2 ]    ; C: (the returned value)
  ret i32 %5    ; C: return

6:                                                ; preds = %2
  %7 = add nsw i32 %0, -1    ; C: n - 1
  %8 = add nsw i32 %1, 1    ; C: a + 1
  %9 = tail call fastcc i32 @chain(i32 noundef %7, i32 noundef %8)    ; C: chain(n - 1, a + 1)
  %10 = sub nsw i32 %1, %9    ; C: a - chain(...)
  br label %4    ; C: return a - chain(...)
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
