; railwindow_nested_tri_down_reject_self_control.ll — DECLINE (bd
; `test_C_libtooling-01po.19.34.7`, decline twin of
; railwindow_nested_tri0_down_accept.ll).
;
; The down-counting triangle with `j = i` (not i - 1): the first inner trip
; runs with j == i, so `if (q[i]) Ry(q[i], .)` is a quantum control on its own
; target — not a unitary (owner ruling 2026-10-15 Q2: control == target stays
; loud). The difference now starts at 0, so the end-point argument refuses and
; the aliased copy is refused loudly.
;
; SOURCE (clang -O1, verbatim below):
;   #include <stdio.h>
;   int main(void) {
;       bool q[4];
;       for (int i = 0; i < 4; i++) q[i] = 0;
;       cq_theta(&q[0], 1.1);
;       for (int i = 0; i < 4; i++) {
;           for (int j = i; j >= 0; j--) {
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

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/506bd29d-3cdd-4ab9-8e19-764fbdc14f66/scratchpad/laneN/fx/down_le_0.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/506bd29d-3cdd-4ab9-8e19-764fbdc14f66/scratchpad/laneN/fx/down_le_0.c"
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

4:                                                ; preds = %0, %10
  %5 = phi i64 [ 0, %0 ], [ %11, %10 ]
  %6 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %5
  %7 = trunc nuw nsw i64 %5 to i32
  %8 = uitofp nneg i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %8, double 0x3FE6666666666666, double 3.000000e-01)
  br label %13

10:                                               ; preds = %26
  %11 = add nuw nsw i64 %5, 1
  %12 = icmp eq i64 %11, 4
  br i1 %12, label %31, label %4, !llvm.loop !10

13:                                               ; preds = %4, %26
  %14 = phi i64 [ %5, %4 ], [ %27, %26 ]
  %15 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %14
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !13, !noundef !14
  %17 = trunc nuw i8 %16 to i1
  br i1 %17, label %18, label %26

18:                                               ; preds = %13
  %19 = load i8, ptr %6, align 1, !tbaa !6, !range !13, !noundef !14
  %20 = trunc nuw i8 %19 to i1
  %21 = trunc nuw i64 %14 to i32
  %22 = uitofp nneg i32 %21 to double
  %23 = tail call double @llvm.fmuladd.f64(double %22, double 2.000000e-01, double %9)
  %24 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %20, double noundef %23) #7
  %25 = zext i1 %24 to i8
  store i8 %25, ptr %6, align 1, !tbaa !6
  br label %26

26:                                               ; preds = %13, %18
  %27 = add nsw i64 %14, -1
  %28 = icmp sgt i64 %14, 0
  br i1 %28, label %13, label %10, !llvm.loop !15

29:                                               ; preds = %31
  %30 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #6
  ret i32 0

31:                                               ; preds = %10, %31
  %32 = phi i64 [ %39, %31 ], [ 0, %10 ]
  %33 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %32
  %34 = load i8, ptr %33, align 1, !tbaa !6, !range !13, !noundef !14
  %35 = trunc nuw i8 %34 to i1
  %36 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %35) #6
  %37 = zext i1 %36 to i32
  %38 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %37)
  %39 = add nuw nsw i64 %32, 1
  %40 = icmp eq i64 %39, 4
  br i1 %40, label %29, label %31, !llvm.loop !16
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
