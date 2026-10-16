; loop_acc_reject_dead_moved_later_loop.ll — DECLINE (bd test_C_libtooling-01po.19.18.1;
; ruling ruling-01po19-18-dead-accumulator-leak-warn-2026-10-16, L3): the gate SET of
; the dead-accumulator postcondition includes gates inside LATER LOOPS.
;
; SOURCE (clang -O1, verbatim below):
;   int main(void) {
;       bool q[4] = {0};
;       for (int i = 0; i < 4; i++) cq_theta(&q[i], 1.0);
;       int c = 0;
;       for (int i = 0; i < 4; i++) { if (c == 1) cq_phi(0.4); c += q[i]; }
;       for (int i = 0; i < 4; i++) cq_theta(&q[i], 0.3);
;       for (int i = 0; i < 4; i++) printf("%d", cq_measure(q[i]));
;       printf("\n");
;       return 0;
;   }
;
; `c` is the seeded accumulator (one register, `cqrt_add_i32(zext(q[i]), c)` per
; trip) and is never read after its loop: a dead record of the cells. The THIRD
; loop then rotates those cells (the array family, Q4 granularity). A dead record
; standing at those Ry gates dephases the cells (the loop_acc_reject_dead_moved.ll
; measurement), and measurement-only (option (a), the warning) does not apply.
; The gate sits in a later loop, not straight after the accumulator's loop: the
; set is every post-loop consumer of the lineage, wherever it is. Loud.
; RETIREMENT TRIGGER: bd 8h7d.20's post-loop reverse loop uncomputes `c` before
; the third loop; this becomes an accept with a trace check.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: dead loop accumulator records a register moved after its last read

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #5
  store i32 0, ptr %1, align 4
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %9, %2 ]
  %4 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 1.000000e+00) #6
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %4, align 1, !tbaa !6
  %9 = add nuw nsw i64 %3, 1
  %10 = icmp eq i64 %9, 4
  br i1 %10, label %11, label %2, !llvm.loop !12

11:                                               ; preds = %2, %16
  %12 = phi i64 [ %21, %16 ], [ 0, %2 ]
  %13 = phi i32 [ %20, %16 ], [ 0, %2 ]
  %14 = icmp eq i32 %13, 1
  br i1 %14, label %15, label %16

15:                                               ; preds = %11
  tail call void @cq_phi(double noundef 4.000000e-01) #5
  br label %16

16:                                               ; preds = %15, %11
  %17 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %12
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !10, !noundef !11
  %19 = zext nneg i8 %18 to i32
  %20 = add nuw nsw i32 %13, %19
  %21 = add nuw nsw i64 %12, 1
  %22 = icmp eq i64 %21, 4
  br i1 %22, label %23, label %11, !llvm.loop !15

23:                                               ; preds = %16, %23
  %24 = phi i64 [ %30, %23 ], [ 0, %16 ]
  %25 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %24
  %26 = load i8, ptr %25, align 1, !tbaa !6, !range !10, !noundef !11
  %27 = trunc nuw i8 %26 to i1
  %28 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %27, double noundef 3.000000e-01) #6
  %29 = zext i1 %28 to i8
  store i8 %29, ptr %25, align 1, !tbaa !6
  %30 = add nuw nsw i64 %24, 1
  %31 = icmp eq i64 %30, 4
  br i1 %31, label %34, label %23, !llvm.loop !16

32:                                               ; preds = %34
  %33 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #5
  ret i32 0

34:                                               ; preds = %23, %34
  %35 = phi i64 [ %42, %34 ], [ 0, %23 ]
  %36 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %35
  %37 = load i8, ptr %36, align 1, !tbaa !6, !range !10, !noundef !11
  %38 = trunc nuw i8 %37 to i1
  %39 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %38) #5
  %40 = zext i1 %39 to i32
  %41 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %40)
  %42 = add nuw nsw i64 %35, 1
  %43 = icmp eq i64 %42, 4
  br i1 %43, label %32, label %34, !llvm.loop !17
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare void @cq_phi(double noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @putchar(i32 noundef) local_unnamed_addr #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree nounwind }
attributes #5 = { nounwind }
attributes #6 = { nomerge nounwind }


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
!17 = distinct !{!17, !13, !14}
