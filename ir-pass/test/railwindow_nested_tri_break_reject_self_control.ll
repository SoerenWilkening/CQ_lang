; railwindow_nested_tri_break_reject_self_control.ll — DECLINE (bd
; `test_C_libtooling-01po.19.34.8`, decline twin of
; railwindow_nested_tri_break_accept.ll).
;
; The same top-tested down triangle with `j = i`: the first inner trip runs
; with j == i, a quantum control on its own target (owner ruling 2026-10-15
; Q2: stays loud). At the use the index is j itself, and j - i reaches 0.
;
; SOURCE (clang -O1, verbatim below):
;   #include <stdio.h>
;   int main(void) {
;       bool q[5];
;       for (int i = 0; i < 5; i++) q[i] = 0;
;       cq_theta(&q[0], 1.1);
;       for (int i = 0; i < 5; i++)
;           for (int j = i; j >= 0; j--) {
;               if (q[j]) cq_theta(&q[i], 0.3 + 0.7 * i + 0.2 * j);
;               if (j == 2) break;
;           }
;       for (int i = 0; i < 5; i++) printf("%d", cq_measure(q[i]));
;       printf("\n");
;       return 0;
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: <unknown>:0:0: in function main i32 (): cq rail window: aliased cell indices make a quantum control its own target (a self-controlled gate is not unitary)

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/506bd29d-3cdd-4ab9-8e19-764fbdc14f66/scratchpad/laneN/fx/brk_self.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/506bd29d-3cdd-4ab9-8e19-764fbdc14f66/scratchpad/laneN/fx/brk_self.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [5 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 5, ptr nonnull %1) #7
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(5) %1, i8 0, i64 5, i1 false), !tbaa !6
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.100000e+00) #8
  %3 = zext i1 %2 to i8
  store i8 %3, ptr %1, align 1, !tbaa !6
  br label %4

4:                                                ; preds = %0, %28
  %5 = phi i64 [ 0, %0 ], [ %29, %28 ]
  %6 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %5
  %7 = trunc nuw nsw i64 %5 to i32
  %8 = uitofp nneg i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %8, double 0x3FE6666666666666, double 3.000000e-01)
  br label %10

10:                                               ; preds = %23, %4
  %11 = phi i64 [ %25, %23 ], [ %5, %4 ]
  %12 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %11
  %13 = load i8, ptr %12, align 1, !tbaa !6, !range !10, !noundef !11
  %14 = trunc nuw i8 %13 to i1
  br i1 %14, label %15, label %23

15:                                               ; preds = %10
  %16 = load i8, ptr %6, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = trunc nuw i64 %11 to i32
  %19 = uitofp nneg i32 %18 to double
  %20 = tail call double @llvm.fmuladd.f64(double %19, double 2.000000e-01, double %9)
  %21 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %17, double noundef %20) #8
  %22 = zext i1 %21 to i8
  store i8 %22, ptr %6, align 1, !tbaa !6
  br label %23

23:                                               ; preds = %15, %10
  %24 = icmp ne i64 %11, 2
  %25 = add nsw i64 %11, -1
  %26 = icmp sgt i64 %11, 0
  %27 = and i1 %24, %26
  br i1 %27, label %10, label %28, !llvm.loop !12

28:                                               ; preds = %23
  %29 = add nuw nsw i64 %5, 1
  %30 = icmp eq i64 %29, 5
  br i1 %30, label %33, label %4, !llvm.loop !15

31:                                               ; preds = %33
  %32 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 5, ptr nonnull %1) #7
  ret i32 0

33:                                               ; preds = %28, %33
  %34 = phi i64 [ %41, %33 ], [ 0, %28 ]
  %35 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %34
  %36 = load i8, ptr %35, align 1, !tbaa !6, !range !10, !noundef !11
  %37 = trunc nuw i8 %36 to i1
  %38 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %37) #7
  %39 = zext i1 %38 to i32
  %40 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %39)
  %41 = add nuw nsw i64 %34, 1
  %42 = icmp eq i64 %41, 5
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

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #6

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree nounwind }
attributes #6 = { nocallback nofree nounwind willreturn memory(argmem: write) }
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
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
