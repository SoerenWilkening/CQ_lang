; DECLINE (bd `test_C_libtooling-01po.19`, review round 1 F3 (b)).
;
; A runtime-sized `int q[n]` beside an UNRELATED `int tmp[n]` in a later loop, whose
; stacksave/stackrestore releases only `tmp` (review probe h3_stackrestore_index.c).
; S1 used to refuse `q` because the function contains a `stackrestore` at all; the
; question is now per object (is a `stackrestore` reachable after `q`'s allocation
; and before one of its accesses?), so `q` is claimed exactly as in the probe
; without the second array (h3_nosr.c).
;

; ModuleID = 'h3_stackrestore_index.c'
; ⚠ bd `test_C_libtooling-01po.19` S4 (2026-10-15): DECLINE -> ACCEPT. The window
; model now LOWERS this array (RailWindow.h: handle array materialized at the
; quantization point, cell reads are borrowed roots, a cell rail is never freed
; or reverse-played). Reviewed by trace, not by green:
; an i32 VLA whose cells are addressed by BYTE geps (`shl i, 3`): the cell index is the byte offset >> 2 (`lshr exact`); every touched cell is rotated once and measured.
; The S4 prefix pins the whole emitted runtime stream and that no rail is freed.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not=cqrt_free --implicit-check-not='error:'
; S4-LABEL: define {{.*}} @main(
; S4: %.rails = alloca i32, i64 %2, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i32(i32 %cq.rail.init)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i32(i32 %.rail, double 5.000000e-01)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: %m = call i32 @cqrt_measure_i32(i32 %.rail2)
; RUN: env CQ_RAILWINDOW_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; WIN: CQ_RAILWINDOW_DBG: @main claims %3 cells=i32 loads=2 stores=1 Q=  br i1 %5, label %6, label %8
; WIN: CQ_RAILWINDOW_DBG: promoted 0 cell class(es)

source_filename = "h3_stackrestore_index.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0) local_unnamed_addr #0 {
  %2 = zext i32 %0 to i64
  %3 = alloca i32, i64 %2, align 16
  %4 = sdiv i32 %0, 2
  %5 = icmp sgt i32 %0, 1
  br i1 %5, label %6, label %8

6:                                                ; preds = %1
  %7 = zext nneg i32 %4 to i64
  br label %14

8:                                                ; preds = %14, %1
  %9 = icmp sgt i32 %0, 1
  br i1 %9, label %12, label %10

10:                                               ; preds = %22, %8
  %11 = phi i32 [ 0, %8 ], [ %29, %22 ]
  br label %33

12:                                               ; preds = %8
  %13 = zext nneg i32 %4 to i64
  br label %22

14:                                               ; preds = %6, %14
  %15 = phi i64 [ 0, %6 ], [ %20, %14 ]
  %16 = shl nsw i64 %15, 3
  %17 = getelementptr inbounds i8, ptr %3, i64 %16
  %18 = load i32, ptr %17, align 8, !tbaa !6
  %19 = tail call i32 @cq_theta_si32(i32 noundef %18, double noundef 5.000000e-01) #3
  store i32 %19, ptr %17, align 8, !tbaa !6
  %20 = add nuw nsw i64 %15, 1
  %21 = icmp eq i64 %20, %7
  br i1 %21, label %8, label %14, !llvm.loop !10

22:                                               ; preds = %12, %22
  %23 = phi i64 [ 0, %12 ], [ %30, %22 ]
  %24 = phi i32 [ 0, %12 ], [ %29, %22 ]
  %25 = shl nsw i64 %23, 3
  %26 = getelementptr inbounds i8, ptr %3, i64 %25
  %27 = load i32, ptr %26, align 8, !tbaa !6
  %28 = tail call i32 @cq_measure_si32(i32 noundef %27) #4
  %29 = add nsw i32 %28, %24
  %30 = add nuw nsw i64 %23, 1
  %31 = icmp eq i64 %30, %13
  br i1 %31, label %10, label %22, !llvm.loop !13

32:                                               ; preds = %33
  ret i32 %39

33:                                               ; preds = %10, %33
  %34 = phi i32 [ %40, %33 ], [ 0, %10 ]
  %35 = phi i32 [ %39, %33 ], [ %11, %10 ]
  %36 = call ptr @llvm.stacksave.p0()
  %37 = alloca i32, i64 %2, align 16
  %38 = call i32 @use(ptr noundef nonnull %37, i32 noundef %0) #4
  %39 = add nsw i32 %38, %35
  call void @llvm.stackrestore.p0(ptr %36)
  %40 = add nuw nsw i32 %34, 1
  %41 = icmp eq i32 %34, 0
  br i1 %41, label %33, label %32, !llvm.loop !14
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare i32 @use(ptr noundef, i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn }
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
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
!14 = distinct !{!14, !11, !12}
