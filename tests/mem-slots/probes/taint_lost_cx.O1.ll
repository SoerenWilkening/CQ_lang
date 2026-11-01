; ModuleID = 'taint_lost_cx.c'
source_filename = "taint_lost_cx.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@yg = global i32 0, align 4
@G = global ptr @yg, align 8
@xg = global i32 0, align 4

; Function Attrs: mustprogress nofree noinline norecurse nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define ptr @swap() local_unnamed_addr #0 {
  %1 = cmpxchg ptr @G, i64 ptrtoint (ptr @yg to i64), i64 ptrtoint (ptr @xg to i64) seq_cst seq_cst, align 8
  %2 = extractvalue { i64, i1 } %1, 1
  %3 = extractvalue { i64, i1 } %1, 0
  %4 = inttoptr i64 %3 to ptr
  %5 = select i1 %2, ptr @yg, ptr %4
  ret ptr %5
}

; Function Attrs: nounwind ssp uwtable
define i32 @taint_lost_cx(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  store i32 %3, ptr @xg, align 4, !tbaa !6
  %4 = tail call ptr @swap()
  %5 = tail call ptr @swap()
  %6 = load i32, ptr %5, align 4, !tbaa !6
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  ret i32 %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { mustprogress nofree noinline norecurse nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
; EXPECT-ERROR: cq: unimplemented: mem-slots: a classical pointer into
