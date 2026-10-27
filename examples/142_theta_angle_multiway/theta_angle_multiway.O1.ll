; ModuleID = 'theta_angle_multiway.c'
source_filename = "theta_angle_multiway.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@theta_table_angle.tab = internal unnamed_addr constant [4 x double] [double 1.000000e-01, double 2.000000e-01, double 3.000000e-01, double 4.000000e-01], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @theta_nested_angle_select(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5, double noundef %6, double noundef %7) local_unnamed_addr #0 {
  %9 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %10 = icmp sgt i32 %9, %2    ; C: x > k1
  %11 = icmp sgt i32 %9, %3    ; C: x > k2
  %12 = select i1 %11, double %6, double %7    ; C: x > k2 ? b : c
  %13 = select i1 %10, double %5, double %12    ; C: x > k1 ? a : (...)
  %14 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %13) #2    ; C: cq_theta(&r, x > k1 ? a : (x > k2 ? b : c));  (r = r0)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #3    ; C: cq_measure(r)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %9) #3    ; C: cq_measure(x)
  %17 = add nsw i32 %16, %15    ; C: cq_measure(r) + cq_measure(x)
  ret i32 %17    ; C: return ...;
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @theta_switch_angle(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, double noundef %4, double noundef %5, double noundef %6) local_unnamed_addr #0 {
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %9 = and i32 %8, 3    ; C: x & 3
  switch i32 %9, label %12 [    ; C: switch (x & 3)  (default is unreachable: x & 3 is always a case)
    i32 0, label %14
    i32 1, label %10
    i32 2, label %11
    i32 3, label %13
  ]

10:                                               ; preds = %7
  br label %14

11:                                               ; preds = %7
  br label %14

12:                                               ; preds = %7
  unreachable

13:                                               ; preds = %7
  br label %14

14:                                               ; preds = %7, %13, %11, %10
  %15 = phi double [ %6, %13 ], [ %5, %11 ], [ %4, %10 ], [ %3, %7 ]    ; C: ang = p0 / p1 / p2 / p3
  %16 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %15) #2    ; C: cq_theta(&r, ang);  (r = r0)
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #3    ; C: cq_measure(r)
  %18 = tail call i32 @cq_measure_si32(i32 noundef %8) #3    ; C: cq_measure(x)
  %19 = add nsw i32 %18, %17    ; C: cq_measure(r) + cq_measure(x)
  ret i32 %19    ; C: return ...;
}

; Function Attrs: nounwind ssp uwtable
define i32 @theta_table_angle(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %5 = and i32 %4, 3    ; C: x & 3
  %6 = zext nneg i32 %5 to i64    ; C: (index)
  %7 = getelementptr inbounds [4 x double], ptr @theta_table_angle.tab, i64 0, i64 %6    ; C: &tab[x & 3]
  %8 = load double, ptr %7, align 8, !tbaa !6    ; C: tab[x & 3]
  %9 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %8) #2    ; C: cq_theta(&r, tab[x & 3]);  (r = r0)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3    ; C: cq_measure(r)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %4) #3    ; C: cq_measure(x)
  %12 = add nsw i32 %11, %10    ; C: cq_measure(r) + cq_measure(x)
  ret i32 %12    ; C: return ...;
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
!6 = !{!7, !7, i64 0}
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
