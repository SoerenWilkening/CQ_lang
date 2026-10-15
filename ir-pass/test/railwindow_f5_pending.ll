; railwindow_f5_pending.ll — DECLINE (bd `test_C_libtooling-01po.19` S1-S3).
;
; CQ_FINDINGS F5: the walk re-executed by an enclosing loop.
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
;   #include <stdio.h>
;   #include <math.h>
;   #define N 4
;   #define K 2
;   int main(void) {
;       bool q[N] = {0};
;       int c = 0;
;       for (int i = 0; i < N; i++) {
;           for (int v = 0; v <= K; v++) {
;               double p = (double)(K - v) / (N - i);
;               if (p < 0) p = 0;
;               if (p > 1) p = 1;
;               if (c == v) cq_theta(&q[i], 2.0 * asin(sqrt(p)));
;           }
;           if (q[i]) c = c + 1;
;       }
;       for (int i = 0; i < N; i++) printf("%d", cq_measure(q[i]));
;       printf("\n");
;       return 0;
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='cq rail bank' --implicit-check-not='tainted value stored to memory'
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; (bd 01po.19 S6, 2026-10-15: S6 is built and leaves the needs list; this
; array now reaches the control chain, which refuses it loudly as below —
; the cell-controlled Ry lowers; the loop-carried counter `c += q[i]` is
; bd 01po.19.18 (Case A in-place add).)
; CHECK: cq loop lowering: loop-carried tainted value crosses iterations
; WIN: CQ_RAILWINDOW_DBG: @main claims %1 cells=i8 loads=3 stores=1 Q=  br label %2
; WIN: CQ_RAILWINDOW_DBG: promoted 0 cell class(es)

; ModuleID = 'f5.c'
source_filename = "f5.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #6
  store i32 0, ptr %1, align 4
  br label %2

2:                                                ; preds = %0, %9
  %3 = phi i64 [ 0, %0 ], [ %14, %9 ]
  %4 = phi i32 [ 0, %0 ], [ %13, %9 ]
  %5 = trunc i64 %3 to i32
  %6 = sub i32 4, %5
  %7 = uitofp nneg i32 %6 to double
  %8 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %3
  br label %16

9:                                                ; preds = %32
  %10 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %3
  %11 = load i8, ptr %10, align 1, !tbaa !6, !range !10, !noundef !11
  %12 = zext nneg i8 %11 to i32
  %13 = add nuw nsw i32 %4, %12
  %14 = add nuw nsw i64 %3, 1
  %15 = icmp eq i64 %14, 4
  br i1 %15, label %37, label %2, !llvm.loop !12

16:                                               ; preds = %2, %32
  %17 = phi i32 [ 0, %2 ], [ %33, %32 ]
  %18 = icmp eq i32 %4, %17
  br i1 %18, label %19, label %32

19:                                               ; preds = %16
  %20 = sub nuw nsw i32 2, %17
  %21 = uitofp nneg i32 %20 to double
  %22 = fdiv double %21, %7
  %23 = fcmp ogt double %22, 1.000000e+00
  %24 = select i1 %23, double 1.000000e+00, double %22
  %25 = load i8, ptr %8, align 1, !tbaa !6, !range !10, !noundef !11
  %26 = trunc nuw i8 %25 to i1
  %27 = tail call double @llvm.sqrt.f64(double %24)
  %28 = tail call double @llvm.asin.f64(double %27)
  %29 = fmul double %28, 2.000000e+00
  %30 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %26, double noundef %29) #7
  %31 = zext i1 %30 to i8
  store i8 %31, ptr %8, align 1, !tbaa !6
  br label %32

32:                                               ; preds = %19, %16
  %33 = add nuw nsw i32 %17, 1
  %34 = icmp eq i32 %33, 3
  br i1 %34, label %9, label %16, !llvm.loop !15

35:                                               ; preds = %37
  %36 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #6
  ret i32 0

37:                                               ; preds = %9, %37
  %38 = phi i64 [ %45, %37 ], [ 0, %9 ]
  %39 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %38
  %40 = load i8, ptr %39, align 1, !tbaa !6, !range !10, !noundef !11
  %41 = trunc nuw i8 %40 to i1
  %42 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %41) #6
  %43 = zext i1 %42 to i32
  %44 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %43)
  %45 = add nuw nsw i64 %38, 1
  %46 = icmp eq i64 %45, 4
  br i1 %46, label %35, label %37, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.asin.f64(double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

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
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
