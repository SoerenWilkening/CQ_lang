; ModuleID = 'param_quantum_index.c'
source_filename = "param_quantum_index.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @param_bounded(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %6 = urem i32 %5, %3    ; C: x % n
  %7 = zext i32 %6 to i64    ; C: x % n  (index widened for the address)
  %8 = getelementptr inbounds i32, ptr %2, i64 %7    ; C: &t[x % n]
  %9 = load i32, ptr %8, align 4, !tbaa !6    ; C: t[x % n]
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3    ; C: cq_measure(t[x % n])
  ret i32 %10    ; C: return
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @param_unbounded(i8 noundef zeroext %0, double noundef %1, ptr nocapture noundef readonly %2) local_unnamed_addr #0 {
  %4 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %5 = zext i8 %4 to i64    ; C: x  (index widened for the address)
  %6 = getelementptr inbounds i32, ptr %2, i64 %5    ; C: &t[x]
  %7 = load i32, ptr %6, align 4, !tbaa !6    ; C: t[x]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3    ; C: cq_measure(t[x])
  ret i32 %8    ; C: return
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

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
