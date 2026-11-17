; ModuleID = 'controlled_rotation.c'
source_filename = "controlled_rotation.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @controlled_rotation(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, t1);
  %7 = icmp sgt i32 %6, %2    ; C: x > k
  br i1 %7, label %8, label %10    ; C: if (x > k)

8:                                                ; preds = %5
  %9 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %4) #2    ; C: cq_theta(&r, t2);  (r = r0)
  br label %10    ; C: end of if

10:                                               ; preds = %8, %5
  %11 = phi i32 [ %9, %8 ], [ %3, %5 ]    ; C: r
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #3    ; C: cq_measure(r)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %6) #3    ; C: cq_measure(x)
  %14 = add nsw i32 %13, %12    ; C: cq_measure(r) + cq_measure(x)
  ret i32 %14    ; C: return
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @controlled_rotation_ifelse(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, t1);
  %8 = icmp sgt i32 %7, %2    ; C: x > k
  br i1 %8, label %9, label %11    ; C: if (x > k) ... else ...

9:                                                ; preds = %6
  %10 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %4) #2    ; C: cq_theta(&r, ta);  (then)
  br label %13    ; C: end of then

11:                                               ; preds = %6
  %12 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %5) #2    ; C: cq_theta(&r, tb);  (else)
  br label %13    ; C: end of else

13:                                               ; preds = %11, %9
  %14 = phi i32 [ %10, %9 ], [ %12, %11 ]    ; C: r
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #3    ; C: cq_measure(r)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %7) #3    ; C: cq_measure(x)
  %17 = add nsw i32 %16, %15    ; C: cq_measure(r) + cq_measure(x)
  ret i32 %17    ; C: return
}

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
