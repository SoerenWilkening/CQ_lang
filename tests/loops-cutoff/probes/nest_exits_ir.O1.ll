; tests/loops-cutoff probe in IR (cq-1jev3, CR rule 14 nested K-loops, "same chain"): nest_exits.c's nest_cont with its
; empty outer latch folded into the outer header, as -O1 leaves TinyEMU main's getopt loop: the inner loop's live exits are
; a block of the outer trip and the outer back edge itself, in an outer loop with no exit that carries a value (base:
; 'a mirror item reads a value defined in a segment that does not dominate its own', Rolled.cpp). Hand-edited from
; nest_exits.O1.ll (llvm-extract of nest_hdr and tick); checked §6 against itself as the C program (cqcheck user).

source_filename = "nest_exits.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noreturn nounwind ssp uwtable
define void @nest_hdr(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #6
  store i32 0, ptr %3, align 4, !tbaa !6
  br label %5

5:                                                ; preds = %14, %9, %2
  %6 = phi i32 [ 1, %2 ], [ %15, %14 ], [ 0, %9 ]
  %7 = phi i32 [ %4, %2 ], [ %12, %14 ], [ %12, %9 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %6) #6
  call fastcc void @tick(ptr noundef nonnull %3)
  br label %9

9:                                                ; preds = %9, %5
  %10 = phi i32 [ %7, %5 ], [ %12, %9 ]
  %11 = mul nsw i32 %10, 5
  %12 = add nsw i32 %11, 1
  %13 = and i32 %12, 3
  switch i32 %13, label %9 [
    i32 0, label %14
    i32 1, label %5
  ], !llvm.loop !10

14:                                               ; preds = %9
  %15 = add nsw i32 %6, 2
  br label %5, !llvm.loop !10
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @tick(ptr nocapture noundef %0) unnamed_addr #3 {
  %2 = load i32, ptr %0, align 4, !tbaa !6
  %3 = add nsw i32 %2, 1
  store i32 %3, ptr %0, align 4, !tbaa !6
  %4 = icmp eq i32 %3, 3
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  tail call void @exit(i32 noundef 0) #7
  unreachable

6:                                                ; preds = %1
  ret void
}

; Function Attrs: noreturn
declare void @exit(i32 noundef) local_unnamed_addr #4

attributes #0 = { noreturn nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }
attributes #7 = { noreturn nounwind }

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
!10 = distinct !{!10, !11}
!11 = !{!"llvm.loop.unroll.disable"}
