; ModuleID = 'callee_switch_classical_select.c'
source_filename = "callee_switch_classical_select.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @callee_switch(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %6 = tail call fastcc i32 @dispatch(i32 noundef %5, i32 noundef %2, i32 noundef %3)    ; C: dispatch(x, a, b)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #4    ; C: cq_measure(...)
  ret i32 %7    ; C: return ...;
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc i32 @dispatch(i32 noundef %0, i32 noundef %1, i32 noundef %2) unnamed_addr #2 {
  %4 = and i32 %0, 3    ; C: v & 3
  switch i32 %4, label %11 [    ; C: switch (v & 3)
    i32 0, label %5
    i32 1, label %7
    i32 2, label %9
    i32 3, label %12
  ]

5:                                                ; preds = %3
  %6 = add nsw i32 %1, %0    ; C: case 0: return v + a;
  br label %12

7:                                                ; preds = %3
  %8 = mul nsw i32 %2, %0    ; C: case 1: return v * b;
  br label %12

9:                                                ; preds = %3
  %10 = sub nsw i32 %0, %1    ; C: case 2: return v - a;
  br label %12

11:                                               ; preds = %3
  unreachable    ; C: no other value of v & 3

12:                                               ; preds = %3, %9, %7, %5
  %13 = phi i32 [ %10, %9 ], [ %8, %7 ], [ %6, %5 ], [ %0, %3 ]    ; C: the returned value (default: v)
  ret i32 %13    ; C: return ...;
}

; Function Attrs: nounwind ssp uwtable
define i32 @callee_classical_select(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %5 = tail call fastcc i32 @pick(i32 noundef %4, i32 noundef %2)    ; C: pick(x, c)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #4    ; C: cq_measure(...)
  ret i32 %6    ; C: return ...;
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc i32 @pick(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  %3 = icmp eq i32 %1, 0    ; C: c == 0  (the classical condition)
  %4 = add nsw i32 %0, 1    ; C: v + 1
  %5 = shl nsw i32 %0, 1    ; C: v * 2
  %6 = select i1 %3, i32 %5, i32 %4    ; C: c ? v + 1 : v * 2
  ret i32 %6    ; C: return ...;
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
