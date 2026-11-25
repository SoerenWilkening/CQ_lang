; /* tests/spine probe (CR rules 14, 19; cq-tyj2l): an entry returns the pointer a quantum-exit loop leaves (a walk back
;  * over a buffer holding a quantum store). The value read at the return is the exit value, quantum, returned as its i32
;  * handle, though the loop's pointer phi is classical inside the loop. */
; ModuleID = 'tests/spine/probes/entry_ptr_return_exit.c'
source_filename = "tests/spine/probes/entry_ptr_return_exit.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@buf = global [6 x i8] c"abcde\00", align 1

; Function Attrs: nounwind ssp uwtable
define nonnull ptr @basename_q(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %5 = and i32 %4, 3
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [6 x i8], ptr @buf, i64 0, i64 %6
  store i8 47, ptr %7, align 1, !tbaa !6
  %8 = and i32 %2, 1
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds i8, ptr @buf, i64 %9
  %11 = getelementptr inbounds i8, ptr %10, i64 4
  br label %12

12:                                               ; preds = %15, %3
  %13 = phi ptr [ %11, %3 ], [ %16, %15 ]
  %14 = icmp ugt ptr %13, %10
  br i1 %14, label %15, label %19

15:                                               ; preds = %12
  %16 = getelementptr inbounds i8, ptr %13, i64 -1
  %17 = load i8, ptr %16, align 1, !tbaa !6
  %18 = icmp eq i8 %17, 47
  br i1 %18, label %19, label %12, !llvm.loop !9

19:                                               ; preds = %12, %15
  ret ptr %13
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}

; No USERCHECK: the checker's driver does not log a pointer result (drivers._ret_type), so the returned rail reads as a
; leak there. Probed by hand: the returned rail holds the C program's pointer and no other rail is left live.
; CHECK basename_q: define i32 @basename_q(
; CHECK basename_q: ret i32 %{{r}}
