; ModuleID = 'state_prep_overwrite.c'
source_filename = "state_prep_overwrite.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @prep_const_incoming(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %6 = icmp eq i32 %5, %2    ; C: x == k
  br i1 %6, label %7, label %9    ; C: if (x == k)

7:                                                ; preds = %4
  %8 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %3) #2    ; C: r = 0; cq_theta(&r, t);
  br label %9    ; C: end of if

9:                                                ; preds = %7, %4
  %10 = phi i32 [ %8, %7 ], [ 7, %4 ]    ; C: r  (7 on the straight-through path)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #3    ; C: cq_measure(r)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %5) #3    ; C: cq_measure(x)
  %13 = add nsw i32 %12, %11    ; C: cq_measure(r) + cq_measure(x)
  ret i32 %13    ; C: return ...;
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @prep_beside_phase(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %8 = icmp sgt i32 %7, %2    ; C: x > k
  br i1 %8, label %9, label %11    ; C: if (x > k) ... else ...

9:                                                ; preds = %6
  %10 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %4) #2    ; C: r = 0; cq_theta(&r, t);
  br label %12

11:                                               ; preds = %6
  tail call void @cq_phi(double noundef %5) #3    ; C: cq_phi(p);  (else arm)
  br label %12

12:                                               ; preds = %11, %9
  %13 = phi i32 [ %10, %9 ], [ %3, %11 ]    ; C: r  (r0 on the else path)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #3    ; C: cq_measure(r)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %7) #3    ; C: cq_measure(x)
  %16 = add nsw i32 %15, %14    ; C: cq_measure(r) + cq_measure(x)
  ret i32 %16    ; C: return ...;
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @prep_twice(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5, double noundef %6) local_unnamed_addr #0 {
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %9 = icmp sgt i32 %8, %2    ; C: x > k1
  br i1 %9, label %10, label %12    ; C: if (x > k1)

10:                                               ; preds = %7
  %11 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %5) #2    ; C: r = 0; cq_theta(&r, t1);
  br label %12

12:                                               ; preds = %10, %7
  %13 = phi i32 [ %11, %10 ], [ %4, %7 ]    ; C: r after the first if
  %14 = icmp slt i32 %8, %3    ; C: x < k2
  br i1 %14, label %15, label %17    ; C: if (x < k2)

15:                                               ; preds = %12
  %16 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %6) #2    ; C: r = 0; cq_theta(&r, t2);
  br label %17

17:                                               ; preds = %15, %12
  %18 = phi i32 [ %16, %15 ], [ %13, %12 ]    ; C: r after the second if
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #3    ; C: cq_measure(r)
  %20 = tail call i32 @cq_measure_si32(i32 noundef %8) #3    ; C: cq_measure(x)
  %21 = add nsw i32 %20, %19    ; C: cq_measure(r) + cq_measure(x)
  ret i32 %21    ; C: return ...;
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
