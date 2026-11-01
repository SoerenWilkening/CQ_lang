; cq-nd2i: CR rule 3 with rule 20. A _Bool slot cell holds an i1 rail behind i8 memory; q[j] ^= q[i]
; over two cell loads is -O1's icmp ne i8 of the loads (114's %37). The compare narrows to xor_i1 of
; the two cells' i1 rails (the loads are views of them), never icmp_ne_i8 of widened copies.
source_filename = "bool_cell_xor.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @boolxor(i32 noundef %0, double noundef %1, double noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = zext i32 %0 to i64
  %7 = alloca i8, i64 %6, align 16
  %8 = icmp sgt i32 %0, 0
  br i1 %8, label %9, label %11

9:                                                ; preds = %5
  %10 = zext nneg i32 %0 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %7, i8 0, i64 %10, i1 false), !tbaa !6
  br label %11

11:                                               ; preds = %9, %5
  %12 = sext i32 %3 to i64
  %13 = getelementptr inbounds i8, ptr %7, i64 %12
  %14 = load i8, ptr %13, align 1, !tbaa !6, !range !10, !noundef !11
  %15 = trunc nuw i8 %14 to i1
  %16 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %15, double noundef %1) #3
  %17 = zext i1 %16 to i8
  store i8 %17, ptr %13, align 1, !tbaa !6
  %18 = sext i32 %4 to i64
  %19 = getelementptr inbounds i8, ptr %7, i64 %18
  %20 = load i8, ptr %19, align 1, !tbaa !6, !range !10, !noundef !11
  %l = load i8, ptr %13, align 1, !tbaa !6, !range !10, !noundef !11
  %21 = icmp ne i8 %20, %l
  %22 = zext i1 %21 to i8
  store i8 %22, ptr %19, align 1, !tbaa !6
  %23 = icmp sgt i32 %0, 0
  br i1 %23, label %24, label %26

24:                                               ; preds = %11
  %25 = zext nneg i32 %0 to i64
  br label %28

26:                                               ; preds = %28, %11
  %27 = phi i32 [ 0, %11 ], [ %38, %28 ]
  ret i32 %27

28:                                               ; preds = %24, %28
  %29 = phi i64 [ 0, %24 ], [ %39, %28 ]
  %30 = phi i32 [ 0, %24 ], [ %38, %28 ]
  %31 = getelementptr inbounds i8, ptr %7, i64 %29
  %32 = load i8, ptr %31, align 1, !tbaa !6, !range !10, !noundef !11
  %33 = trunc nuw i8 %32 to i1
  %34 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %33) #4
  %35 = zext i1 %34 to i32
  %36 = trunc nuw nsw i64 %29 to i32
  %37 = shl nuw i32 %35, %36
  %38 = or i32 %37, %30
  %39 = add nuw nsw i64 %29, 1
  %40 = icmp eq i64 %39, %25
  br i1 %40, label %26, label %28, !llvm.loop !12
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }
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
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
; CHECK-COUNT boolxor: @cq_template_xor_i1( 1
; CHECK-COUNT boolxor: @cq_template_icmp_ne_i8( 0
