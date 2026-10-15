; railwindow_reject_alias_self_control.ll — DECLINE, PHYSICS (bd `test_C_libtooling-01po.19` S7,
; owner Q2 ruling `owner-ruling-01po19-rolled-design-2026-10-15`: control ==
; target stays loud).
;
; `if (q[i]) cq_theta(&q[j], .5)` with runtime i, j. At i == j the aliased copy
; would be `if (x) Ry(x)`: "rotate if set", a gate controlled by its own target,
; which is not unitary. Refused BEFORE any cloning, independent of S6 (the
; distinct copy, a controlled Ry, would be S6's), at the store the quantum
; condition controls. A MEASURED condition is classical and lowers: see
; railwindow_version_measured_control.ll. The message is mirrored
; CHARACTER-FOR-CHARACTER from kMsgSelfControl.
;
; SOURCE (clang -O1, verbatim below):
;   __attribute__((noinline)) int f(int i, int j) {
;     bool q[4] = {0};
;     i &= 3; j &= 3;
;     for (int k = 0; k < 4; k++) cq_theta(&q[k], .3);
;     if (q[i]) cq_theta(&q[j], .5);
;     int r = 0;
;     for (int k = 0; k < 4; k++) r = 2 * r + cq_measure(q[k]);
;     return r;
;   }
;   int main(int argc, char **argv) { (void)argv; return f(argc, argc + 1); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='quantum array not lowered yet'
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; CHECK: error: {{.*}}in function f i32 (i32, i32): cq rail window: aliased cell indices make a quantum control its own target (a self-controlled gate is not unitary)
; The refusal comes before the first versioning (nothing cloned).
; WIN: CQ_RAILWINDOW_DBG: @f claims
; WIN: CQ_RAILWINDOW_DBG: version region
; WIN-NOT: promote cell
; WIN-NOT: after window promotion

source_filename = "selfctl.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #4
  store i32 0, ptr %3, align 4
  %4 = and i32 %0, 3
  br label %11

5:                                                ; preds = %11
  %6 = zext nneg i32 %4 to i64
  %7 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %6
  %8 = load i8, ptr %7, align 1, !tbaa !6, !range !10, !noundef !11
  %9 = trunc nuw i8 %8 to i1
  br i1 %9, label %20, label %10

10:                                               ; preds = %20, %5
  br label %29

11:                                               ; preds = %2, %11
  %12 = phi i64 [ 0, %2 ], [ %18, %11 ]
  %13 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %12
  %14 = load i8, ptr %13, align 1, !tbaa !6, !range !10, !noundef !11
  %15 = trunc nuw i8 %14 to i1
  %16 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %15, double noundef 3.000000e-01) #5
  %17 = zext i1 %16 to i8
  store i8 %17, ptr %13, align 1, !tbaa !6
  %18 = add nuw nsw i64 %12, 1
  %19 = icmp eq i64 %18, 4
  br i1 %19, label %5, label %11, !llvm.loop !12

20:                                               ; preds = %5
  %21 = and i32 %1, 3
  %22 = zext nneg i32 %21 to i64
  %23 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %22
  %24 = load i8, ptr %23, align 1, !tbaa !6, !range !10, !noundef !11
  %25 = trunc nuw i8 %24 to i1
  %26 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %25, double noundef 5.000000e-01) #5
  %27 = zext i1 %26 to i8
  store i8 %27, ptr %23, align 1, !tbaa !6
  br label %10

28:                                               ; preds = %29
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #4
  ret i32 %38

29:                                               ; preds = %10, %29
  %30 = phi i64 [ %39, %29 ], [ 0, %10 ]
  %31 = phi i32 [ %38, %29 ], [ 0, %10 ]
  %32 = shl nsw i32 %31, 1
  %33 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %30
  %34 = load i8, ptr %33, align 1, !tbaa !6, !range !10, !noundef !11
  %35 = trunc nuw i8 %34 to i1
  %36 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %35) #4
  %37 = zext i1 %36 to i32
  %38 = or disjoint i32 %32, %37
  %39 = add nuw nsw i64 %30, 1
  %40 = icmp eq i64 %39, 4
  br i1 %40, label %28, label %29, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %0, 1
  %4 = tail call i32 @f(i32 noundef %0, i32 noundef %3)
  ret i32 %4
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

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
