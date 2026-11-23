; a select arm that is a classical pointer below its object, spelled without inbounds (hand-edited from C: B - 8); native 97.
; cqcc sel_noinbounds.ll --backend -L../lib/backend-replay --backend -lcq_backend --backend -lcq_gates_replay --backend -Wl,-undefined,dynamic_lookup
; ModuleID = 'out/g1.c'
source_filename = "out/g1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@A = internal unnamed_addr global [64 x i64] zeroinitializer, align 16
@B = internal unnamed_addr global [64 x i64] zeroinitializer, align 16
@C = internal unnamed_addr global [64 x i64] zeroinitializer, align 16
@.memset_pattern = private unnamed_addr constant [2 x i64] [i64 50, i64 50], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  tail call void @memset_pattern16(ptr nonnull @C, ptr nonnull @.memset_pattern, i64 512), !tbaa !6
  br label %22

1:                                                ; preds = %22
  %2 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 7, double noundef 0.000000e+00) #3
  %3 = zext i8 %2 to i32
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  %6 = select i1 %5, ptr @C, ptr getelementptr (i8, ptr @B, i64 -64)
  %7 = lshr i32 %3, 1
  %8 = and i32 %7, 3
  %9 = or disjoint i32 %8, 8
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds i64, ptr %6, i64 %10
  %12 = load i64, ptr %11, align 8, !tbaa !6
  %13 = and i32 %3, 63
  %14 = zext nneg i32 %13 to i64
  %15 = getelementptr inbounds [64 x i64], ptr @A, i64 0, i64 %14
  %16 = load i64, ptr %15, align 8, !tbaa !6
  %17 = add i64 %12, 120
  %18 = add i64 %17, %16
  %19 = and i64 %18, 127
  %20 = tail call i64 @cq_measure_sl(i64 noundef %19) #4
  %21 = trunc i64 %20 to i32
  ret i32 %21

22:                                               ; preds = %0, %22
  %23 = phi i64 [ 0, %0 ], [ %24, %22 ]
  %24 = add nuw nsw i64 %23, 1
  %25 = getelementptr inbounds [64 x i64], ptr @A, i64 0, i64 %23
  store i64 %24, ptr %25, align 8, !tbaa !6
  %26 = sub nuw nsw i64 100, %23
  %27 = getelementptr inbounds [64 x i64], ptr @B, i64 0, i64 %23
  store i64 %26, ptr %27, align 8, !tbaa !6
  %28 = icmp eq i64 %24, 64
  br i1 %28, label %1, label %22, !llvm.loop !10
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #1

; Function Attrs: nofree nounwind willreturn memory(argmem: readwrite)
declare void @memset_pattern16(ptr nocapture writeonly, ptr nocapture readonly, i64) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind willreturn memory(argmem: readwrite) }
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
!7 = !{!"long", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
