; railwindow_nested_reject_subloop_reads_outer.ll — DECLINE (bd
; `test_C_libtooling-01po.19.34`, the decline twin of
; railwindow_dicke_n5k3_nested_accept.ll).
;
; The N=5 K=3 Dicke module with ONE edit: the inner `l` loop's xor
; `q[m-1] ^= q[m-1-l]` reads the OUTER body's value `%37` (the cell q[m-1] as
; the outer trip stored it) instead of reloading the cell (`%48`, deleted).
; The inner subloop now reads a tainted operand defined OUTSIDE it, so it is not
; iteration-local on its own, and `markIfIterationLocal`'s recursion refuses the
; outer loop. That is the hazard the old blanket subloop refusal guarded (a
; value crossing the subloop boundary runs K times per outer trip while an
; outer-anchored reversal would run once — lowering_reject_loop_nested_quantum.ll
; is the other pin): the outer body stays unmarked and the outer region's R7
; grant is refused at the final-taint re-ask, loud, nothing lowered.
; ⚠ NOT A PERMANENT DECLINE (R1): a quantum subloop reading an outer-body
; temporary is a valid program; lowering it needs the outer temporary's
; discharge placed after the subloop (filed as a 01po.19 follow-up). When it
; lands this file becomes an accept with an analytic check.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: <unknown>:0:0: in function main i32 (): cq controlled lowering: control flow inside a loop body under quantum control

; ModuleID = 'dicke_n.c'
source_filename = "dicke_n.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [5 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 5, ptr nonnull %1) #7
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %7, %2 ]
  %4 = icmp ugt i64 %3, 1
  %5 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %3
  %6 = zext i1 %4 to i8
  store i8 %6, ptr %5, align 1, !tbaa !6
  %7 = add nuw nsw i64 %3, 1
  %8 = icmp eq i64 %7, 5
  br i1 %8, label %11, label %2, !llvm.loop !10

9:                                                ; preds = %69, %33
  %10 = icmp ugt i64 %12, 2
  br i1 %10, label %11, label %78, !llvm.loop !13

11:                                               ; preds = %2, %9
  %12 = phi i64 [ %13, %9 ], [ 5, %2 ]
  %13 = add nsw i64 %12, -1
  %14 = trunc nuw nsw i64 %13 to i32
  %15 = tail call i32 @llvm.smin.i32(i32 %14, i32 3)
  %16 = add nsw i64 %12, -2
  %17 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %16
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !14, !noundef !15
  %19 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %13
  %20 = load i8, ptr %19, align 1, !tbaa !6, !range !14, !noundef !15
  %21 = icmp ne i8 %20, %18
  %22 = zext i1 %21 to i8
  store i8 %22, ptr %19, align 1, !tbaa !6
  br i1 %21, label %23, label %33

23:                                               ; preds = %11
  %24 = trunc nuw i8 %18 to i1
  %25 = trunc nuw nsw i64 %12 to i32
  %26 = uitofp nneg i32 %25 to double
  %27 = fdiv double 1.000000e+00, %26
  %28 = tail call double @llvm.sqrt.f64(double %27)
  %29 = tail call double @llvm.acos.f64(double %28)
  %30 = fmul double %29, 2.000000e+00
  %31 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %24, double noundef %30) #8
  %32 = zext i1 %31 to i8
  store i8 %32, ptr %17, align 1, !tbaa !6
  br label %33

33:                                               ; preds = %23, %11
  %34 = load i8, ptr %17, align 1, !tbaa !6, !range !14, !noundef !15
  %35 = load i8, ptr %19, align 1, !tbaa !6, !range !14, !noundef !15
  %36 = icmp ne i8 %35, %34
  %37 = zext i1 %36 to i8
  store i8 %37, ptr %19, align 1, !tbaa !6
  %38 = icmp ult i64 %12, 3
  br i1 %38, label %9, label %39

39:                                               ; preds = %33
  %40 = trunc nuw nsw i64 %12 to i32
  %41 = uitofp nneg i32 %40 to double
  %42 = zext i32 %15 to i64
  br label %43

43:                                               ; preds = %39, %69
  %44 = phi i64 [ 2, %39 ], [ %74, %69 ]
  %45 = sub nsw i64 %13, %44
  %46 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %45
  %47 = load i8, ptr %46, align 1, !tbaa !6, !range !14, !noundef !15
  %49 = icmp ne i8 %37, %47
  %50 = zext i1 %49 to i8
  store i8 %50, ptr %19, align 1, !tbaa !6
  %51 = select i1 %49, i32 2, i32 0
  %52 = sub nsw i64 %12, %44
  %53 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %52
  %54 = load i8, ptr %53, align 1, !tbaa !6, !range !14, !noundef !15
  %55 = zext nneg i8 %54 to i32
  %56 = or disjoint i32 %51, %55
  %57 = icmp eq i32 %56, 3
  br i1 %57, label %58, label %69

58:                                               ; preds = %43
  %59 = load i8, ptr %46, align 1, !tbaa !6, !range !14, !noundef !15
  %60 = trunc nuw i8 %59 to i1
  %61 = trunc nuw nsw i64 %44 to i32
  %62 = uitofp nneg i32 %61 to double
  %63 = fdiv double %62, %41
  %64 = tail call double @llvm.sqrt.f64(double %63)
  %65 = tail call double @llvm.acos.f64(double %64)
  %66 = fmul double %65, 2.000000e+00
  %67 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %60, double noundef %66) #8
  %68 = zext i1 %67 to i8
  store i8 %68, ptr %46, align 1, !tbaa !6
  br label %69

69:                                               ; preds = %58, %43
  %70 = load i8, ptr %46, align 1, !tbaa !6, !range !14, !noundef !15
  %71 = load i8, ptr %19, align 1, !tbaa !6, !range !14, !noundef !15
  %72 = icmp ne i8 %71, %70
  %73 = zext i1 %72 to i8
  store i8 %73, ptr %19, align 1, !tbaa !6
  %74 = add nuw nsw i64 %44, 1
  %75 = icmp ult i64 %44, %42
  br i1 %75, label %43, label %9, !llvm.loop !16

76:                                               ; preds = %78
  %77 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 5, ptr nonnull %1) #7
  ret i32 0

78:                                               ; preds = %9, %78
  %79 = phi i64 [ %86, %78 ], [ 0, %9 ]
  %80 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %79
  %81 = load i8, ptr %80, align 1, !tbaa !6, !range !14, !noundef !15
  %82 = trunc nuw i8 %81 to i1
  %83 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %82) #7
  %84 = zext i1 %83 to i32
  %85 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %84)
  %86 = add nuw nsw i64 %79, 1
  %87 = icmp eq i64 %86, 5
  br i1 %87, label %76, label %78, !llvm.loop !17
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.acos.f64(double) #3

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #4

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @putchar(i32 noundef) local_unnamed_addr #5

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #6

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree nounwind }
attributes #6 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #7 = { nounwind }
attributes #8 = { nomerge nounwind }

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
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
!14 = !{i8 0, i8 2}
!15 = !{}
!16 = distinct !{!16, !11, !12}
!17 = distinct !{!17, !11, !12}
