; ModuleID = 'deep_nest_wide_tree.c'
source_filename = "deep_nest_wide_tree.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @depth3_phase_nest(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5, double noundef %6, double noundef %7) local_unnamed_addr #0 {
  %9 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %10 = icmp sgt i32 %9, %2    ; C: x > k1
  br i1 %10, label %11, label %16    ; C: if (x > k1)

11:                                               ; preds = %8
  tail call void @cq_phi(double noundef %5) #3    ; C: cq_phi(p1);
  %12 = icmp slt i32 %9, %3    ; C: x < k2
  br i1 %12, label %13, label %16    ; C: if (x < k2)

13:                                               ; preds = %11
  tail call void @cq_phi(double noundef %6) #3    ; C: cq_phi(p2);
  %14 = icmp eq i32 %9, %4    ; C: x == k3  (the branch is on its negation)
  br i1 %14, label %16, label %15    ; C: if (x != k3)

15:                                               ; preds = %13
  tail call void @cq_phi(double noundef %7) #3    ; C: cq_phi(p3);
  br label %16

16:                                               ; preds = %11, %15, %13, %8
  %17 = tail call i32 @cq_measure_si32(i32 noundef %9) #3    ; C: cq_measure(x)
  ret i32 %17    ; C: return cq_measure(x);
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @nine_leaf_tree(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5, i32 noundef %6, i32 noundef %7, i32 noundef %8, i32 noundef %9, i32 noundef %10, double noundef %11) local_unnamed_addr #0 {
  %13 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %14 = icmp sgt i32 %13, %2    ; C: x > k1
  %15 = icmp slt i32 %13, %3    ; C: x < k2
  %16 = and i1 %14, %15    ; C: && (short-circuit folded to a plain and: every leaf is pure)
  %17 = icmp ne i32 %13, %4    ; C: x != k3
  %18 = and i1 %17, %16    ; C: && (short-circuit folded to a plain and: every leaf is pure)
  %19 = icmp sgt i32 %13, %5    ; C: x > k4
  %20 = and i1 %19, %18    ; C: && (short-circuit folded to a plain and: every leaf is pure)
  %21 = icmp slt i32 %13, %6    ; C: x < k5
  %22 = and i1 %21, %20    ; C: && (short-circuit folded to a plain and: every leaf is pure)
  %23 = icmp ne i32 %13, %7    ; C: x != k6
  %24 = and i1 %23, %22    ; C: && (short-circuit folded to a plain and: every leaf is pure)
  %25 = icmp sgt i32 %13, %8    ; C: x > k7
  %26 = and i1 %25, %24    ; C: && (short-circuit folded to a plain and: every leaf is pure)
  %27 = icmp slt i32 %13, %9    ; C: x < k8
  %28 = and i1 %27, %26    ; C: && (short-circuit folded to a plain and: every leaf is pure)
  %29 = icmp ne i32 %13, %10    ; C: x != k9
  %30 = and i1 %29, %28    ; C: && (short-circuit folded to a plain and: every leaf is pure)
  br i1 %30, label %31, label %32    ; C: if (...)

31:                                               ; preds = %12
  tail call void @cq_phi(double noundef %11) #3    ; C: cq_phi(p);
  br label %32

32:                                               ; preds = %31, %12
  %33 = tail call i32 @cq_measure_si32(i32 noundef %13) #3    ; C: cq_measure(x)
  ret i32 %33    ; C: return cq_measure(x);
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
