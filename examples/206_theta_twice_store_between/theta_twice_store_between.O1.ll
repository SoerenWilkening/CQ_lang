; ModuleID = 'theta_twice_store_between.c'
source_filename = "theta_twice_store_between.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@cell = local_unnamed_addr global i32 1, align 4
@g = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @theta_twice_store_between(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = load i32, ptr @cell, align 4, !tbaa !6    ; C: cell  (the load of the first cq_theta)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %0) #2    ; C: cq_theta(&cell, t1);
  store i32 %4, ptr @cell, align 4, !tbaa !6    ; C: cell = (the rotated value): the first form's store
  %5 = load i32, ptr @g, align 4, !tbaa !6    ; C: g
  %6 = add nsw i32 %5, 1    ; C: g + 1
  store i32 %6, ptr @g, align 4, !tbaa !6    ; C: g++;
  %7 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %1) #2    ; C: cq_theta(&cell, t2);  (its operand is the value forwarded from the first store)
  store i32 %7, ptr @cell, align 4, !tbaa !6    ; C: cell = (the value rotated twice): the second form's store
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3    ; C: cq_measure(cell)
  ret i32 %8    ; C: return
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @theta_twice_store_between_ptr(ptr noalias nocapture noundef %0, ptr noalias nocapture noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = load i32, ptr %0, align 4, !tbaa !6    ; C: *p  (the load of the first cq_theta)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %2) #2    ; C: cq_theta(p, t1);
  store i32 %6, ptr %0, align 4, !tbaa !6    ; C: *p = (the rotated value): the first form's store
  %7 = load i32, ptr %1, align 4, !tbaa !6    ; C: *q
  %8 = add nsw i32 %7, 1    ; C: *q + 1
  store i32 %8, ptr %1, align 4, !tbaa !6    ; C: (*q)++;
  %9 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef %3) #2    ; C: cq_theta(p, t2);  (its operand is the value forwarded from the first store: restrict)
  store i32 %9, ptr %0, align 4, !tbaa !6    ; C: *p = (the value rotated twice): the second form's store
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3    ; C: cq_measure(*p)
  ret i32 %10    ; C: return
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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
