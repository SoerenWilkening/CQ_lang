; /* tests/spine probe (NORTHSTAR principle 1, CLAUDE.md pipeline; cq-mjw9): fix-irreducible and step 2's other CFG rewrites
;  * serve the clones only. @irr has an irreducible cycle, a quantum clone (qfun passes it a rail) and a classical caller:
;  * its own symbol stays as compiled (no irr.guard block), its clones are made reducible.
;  * Regenerate classical_original_irreducible.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h classical_original_irreducible.c */
; USERCHECK classical_caller
; USERCHECK qfun
; CHECK-COUNT irr: irr.guard 0
; ModuleID = 'classical_original_irreducible.c'
source_filename = "classical_original_irreducible.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define i32 @irr(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = and i32 %0, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %6, label %10

6:                                                ; preds = %10, %3
  %7 = phi i32 [ %12, %10 ], [ 0, %3 ]
  %8 = add nsw i32 %7, 2
  %9 = icmp sgt i32 %8, %1
  br i1 %9, label %14, label %10

10:                                               ; preds = %6, %3
  %11 = phi i32 [ 0, %3 ], [ %8, %6 ]
  %12 = add nsw i32 %11, 3
  %13 = icmp slt i32 %11, 47
  br i1 %13, label %6, label %14

14:                                               ; preds = %10, %6
  %15 = phi i32 [ %8, %6 ], [ %12, %10 ]
  %16 = xor i32 %15, %2
  ret i32 %16
}

; Function Attrs: noinline nounwind ssp uwtable
define i32 @qfun(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #4
  %3 = tail call i32 @irr(i32 noundef %0, i32 noundef 9, i32 noundef %2)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  ret i32 %4
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @classical_caller(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call i32 @irr(i32 noundef %0, i32 noundef 9, i32 noundef %0)
  %3 = tail call i32 @qfun(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

attributes #0 = { nofree noinline norecurse nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
