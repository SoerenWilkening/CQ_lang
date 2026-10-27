; ModuleID = 'callee_with_loop.c'
source_filename = "callee_with_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @callee_with_loop(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %6 = tail call fastcc i32 @polyval(i32 noundef %5, ptr noundef %2, i32 noundef %3)    ; C: polyval(x, c, n)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #4    ; C: cq_measure(...)
  ret i32 %7    ; C: return
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(argmem: read) uwtable
define internal fastcc i32 @polyval(i32 noundef %0, ptr nocapture noundef readonly %1, i32 noundef %2) unnamed_addr #2 {
  %4 = load i32, ptr %1, align 4, !tbaa !6    ; C: int s = c[0];
  %5 = icmp sgt i32 %2, 1    ; C: i < n  (first test, i = 1)
  br i1 %5, label %6, label %8    ; C: for (...)  (enter?)

6:                                                ; preds = %3
  %7 = zext nneg i32 %2 to i64    ; C: n as the 64-bit trip bound
  br label %10    ; C: loop head

8:                                                ; preds = %10, %3
  %9 = phi i32 [ %4, %3 ], [ %16, %10 ]    ; C: s after the loop
  ret i32 %9    ; C: return s;

10:                                               ; preds = %6, %10
  %11 = phi i64 [ 1, %6 ], [ %17, %10 ]    ; C: i
  %12 = phi i32 [ %4, %6 ], [ %16, %10 ]    ; C: s
  %13 = mul nsw i32 %12, %0    ; C: s * x
  %14 = getelementptr inbounds i32, ptr %1, i64 %11    ; C: &c[i]
  %15 = load i32, ptr %14, align 4, !tbaa !6    ; C: c[i]
  %16 = add nsw i32 %15, %13    ; C: s = s * x + c[i];
  %17 = add nuw nsw i64 %11, 1    ; C: i++
  %18 = icmp eq i64 %17, %7    ; C: i < n  (re-test)
  br i1 %18, label %8, label %10, !llvm.loop !10    ; C: another trip?
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree noinline norecurse nosync nounwind ssp memory(argmem: read) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
