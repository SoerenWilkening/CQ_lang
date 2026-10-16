; railwindow_nested_ladder_reject_self_control.ll — DECLINE (bd
; `test_C_libtooling-01po.19.34.4`, decline twin of
; railwindow_nested_ladder_accept.ll).
;
; The same triangular nest with `j <= i`: the last inner trip runs with j == i,
; so `if (q[i]) Ry(q[i], .)` is a quantum control on its own target — not a
; unitary (owner ruling 2026-10-15 Q2: control == target stays loud). The
; difference {-i,+,1}<j-loop> now ends at 0, so `nonZeroOverLoop` must refuse,
; the window versions the pair, and the aliased copy is refused loudly.
;
; SOURCE (clang -O1, verbatim below):
;   /* H5: nested ladder, cross-trip aliasing (q[j] targets of earlier outer trips become controls) */
;   #include <stdio.h>
;   #include <math.h>
;   int main(void) {
;       bool q[4];
;       for (int i = 0; i < 4; i++) q[i] = 0;
;       cq_theta(&q[0], 1.1);
;       for (int i = 1; i < 4; i++) {
;           for (int j = 0; j <= i; j++) {
;               if (q[j]) cq_theta(&q[i], 0.3 + 0.7 * i + 0.2 * j);
;           }
;       }
;       for (int i = 0; i < 4; i++) printf("%d", cq_measure(q[i]));
;       printf("\n");
;       return 0;
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: <unknown>:0:0: in function main i32 (): cq rail window: aliased cell indices make a quantum control its own target (a self-controlled gate is not unitary)

; ModuleID = 'ladder_le.c'
source_filename = "ladder_le.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #6
  store i32 0, ptr %1, align 4
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.100000e+00) #7
  %3 = zext i1 %2 to i8
  store i8 %3, ptr %1, align 4, !tbaa !6
  br label %4

4:                                                ; preds = %0, %11
  %5 = phi i64 [ 1, %0 ], [ %12, %11 ]
  %6 = phi i64 [ 2, %0 ], [ %13, %11 ]
  %7 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %5
  %8 = trunc nuw nsw i64 %5 to i32
  %9 = uitofp nneg i32 %8 to double
  %10 = tail call double @llvm.fmuladd.f64(double %9, double 0x3FE6666666666666, double 3.000000e-01)
  br label %15

11:                                               ; preds = %28
  %12 = add nuw nsw i64 %5, 1
  %13 = add nuw nsw i64 %6, 1
  %14 = icmp eq i64 %12, 4
  br i1 %14, label %33, label %4, !llvm.loop !10

15:                                               ; preds = %4, %28
  %16 = phi i64 [ 0, %4 ], [ %29, %28 ]
  %17 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %16
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !13, !noundef !14
  %19 = trunc nuw i8 %18 to i1
  br i1 %19, label %20, label %28

20:                                               ; preds = %15
  %21 = load i8, ptr %7, align 1, !tbaa !6, !range !13, !noundef !14
  %22 = trunc nuw i8 %21 to i1
  %23 = trunc nuw nsw i64 %16 to i32
  %24 = uitofp nneg i32 %23 to double
  %25 = tail call double @llvm.fmuladd.f64(double %24, double 2.000000e-01, double %10)
  %26 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %22, double noundef %25) #7
  %27 = zext i1 %26 to i8
  store i8 %27, ptr %7, align 1, !tbaa !6
  br label %28

28:                                               ; preds = %15, %20
  %29 = add nuw nsw i64 %16, 1
  %30 = icmp eq i64 %29, %6
  br i1 %30, label %11, label %15, !llvm.loop !15

31:                                               ; preds = %33
  %32 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #6
  ret i32 0

33:                                               ; preds = %11, %33
  %34 = phi i64 [ %41, %33 ], [ 0, %11 ]
  %35 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %34
  %36 = load i8, ptr %35, align 1, !tbaa !6, !range !13, !noundef !14
  %37 = trunc nuw i8 %36 to i1
  %38 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %37) #6
  %39 = zext i1 %38 to i32
  %40 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %39)
  %41 = add nuw nsw i64 %34, 1
  %42 = icmp eq i64 %41, 4
  br i1 %42, label %31, label %33, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #4

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @putchar(i32 noundef) local_unnamed_addr #5

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree nounwind }
attributes #6 = { nounwind }
attributes #7 = { nomerge nounwind }

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
!13 = !{i8 0, i8 2}
!14 = !{}
!15 = distinct !{!15, !11, !12}
!16 = distinct !{!16, !11, !12}
