; railwindow_p16_pending.ll — DECLINE (bd `test_C_libtooling-01po.19` S1-S3).
;
; p16: a straight-line store beside a walk that reads cell i-1 and writes cell i.
;
; Before S1-S3 this array declined in the one-store rail bank. Now the rolled
; window model (RailWindow.h; owner rulings `owner-ruling-01po19-rolled-not-
; unrolled-2026-10-15`, `owner-ruling-01po19-rolled-design-2026-10-15`) claims it
; (S1), places its quantization point (S2) and promotes its windows (S3), and then
; declines with exactly the steps it still needs. The WIN prefix pins the claim,
; the quantization point and every promoted cell class.
; RETIREMENT TRIGGER: each of S4-S7 that lands removes its name from the CHECK
; line; when none is left this file becomes an ACCEPT with an analytic trace check.
;
; SOURCE (clang -O1, verbatim below):
;   #include <stdbool.h>
;   int main(void) {
;     bool q[4] = {0};
;     cq_theta(&q[0], .5);
;     for (int i = 1; i < 4; i++)
;       if (q[i-1]) cq_theta(&q[i], .3 * (i + 1));
;     int r = 0;
;     for (int i = 0; i < 4; i++) r += cq_measure(q[i]);
;     return r;
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='cq rail bank' --implicit-check-not='tainted value stored to memory'
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; CHECK: cq rail window: quantum array not lowered yet (bd 01po.19), needs S4 borrowed-root cells, S6 quantum control on cells
; WIN: CQ_RAILWINDOW_DBG: @main claims %1 cells=i8 loads=3 stores=2 Q=  store i8 %3, ptr %1, align 4
; WIN: CQ_RAILWINDOW_DBG: promoted 0 cell class(es)

; ModuleID = 'p16.c'
source_filename = "p16.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #3
  store i32 0, ptr %1, align 4
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #4
  %3 = zext i1 %2 to i8
  store i8 %3, ptr %1, align 4, !tbaa !6
  br label %4

4:                                                ; preds = %0, %20
  %5 = phi i64 [ 1, %0 ], [ %21, %20 ]
  %6 = add nsw i64 %5, -1
  %7 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %6
  %8 = load i8, ptr %7, align 1, !tbaa !6, !range !10, !noundef !11
  %9 = trunc nuw i8 %8 to i1
  br i1 %9, label %10, label %20

10:                                               ; preds = %4
  %11 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %5
  %12 = load i8, ptr %11, align 1, !tbaa !6, !range !10, !noundef !11
  %13 = trunc nuw i8 %12 to i1
  %14 = trunc i64 %5 to i32
  %15 = add i32 %14, 1
  %16 = uitofp nneg i32 %15 to double
  %17 = fmul double %16, 3.000000e-01
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %13, double noundef %17) #4
  %19 = zext i1 %18 to i8
  store i8 %19, ptr %11, align 1, !tbaa !6
  br label %20

20:                                               ; preds = %4, %10
  %21 = add nuw nsw i64 %5, 1
  %22 = icmp eq i64 %21, 4
  br i1 %22, label %24, label %4, !llvm.loop !12

23:                                               ; preds = %24
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #3
  ret i32 %32

24:                                               ; preds = %20, %24
  %25 = phi i64 [ %33, %24 ], [ 0, %20 ]
  %26 = phi i32 [ %32, %24 ], [ 0, %20 ]
  %27 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %25
  %28 = load i8, ptr %27, align 1, !tbaa !6, !range !10, !noundef !11
  %29 = trunc nuw i8 %28 to i1
  %30 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %29) #3
  %31 = zext i1 %30 to i32
  %32 = add nuw nsw i32 %26, %31
  %33 = add nuw nsw i64 %25, 1
  %34 = icmp eq i64 %33, 4
  br i1 %34, label %23, label %24, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { nomerge nounwind }

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
