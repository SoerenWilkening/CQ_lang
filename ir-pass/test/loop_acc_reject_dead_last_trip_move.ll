; loop_acc_reject_dead_last_trip_move.ll — DECLINE, an ADVERSARIAL WITNESS (bd 01po.19.18.6, R11 round 1
; rA1B-F3; ruling ruling-01po19-18-dead-accumulator-leak-warn-2026-10-16).
;
; SOURCE (clang -O1, verbatim below; the reviewer's pA.c):
;   #include <stdio.h>
;   int main(void) {
;       bool q[5] = {0};
;       for (int j = 0; j < 5; j++) cq_theta(&q[j], 1.0);
;       int c = 0;
;       for (int i = 0; i < 4; i++) {
;           if (c == 1) cq_phi(0.5);  /* the register's only read */
;           cq_theta(&q[i], 0.7);     /* q[i] was recorded into c by trip i-1 */
;           if (q[i + 1]) c = c + 1;
;       }
;       for (int j = 0; j < 5; j++) printf("%d", cq_measure(q[j]));
;       printf("\n");
;       return 0;
;   }
;
; THE HAZARD. `if (q[i+1]) c++` records cell i+1 in trip i; trip i+1 rotates that
; cell (`cq_theta(&q[i], .7)`) BEFORE its own step. In every trip but the last the
; counter is read again (the next trip's `c == 1`), but after the LAST trip's
; step it is dead, so on that path the record stands at a move of a cell it
; recorded: a dead record dephasing the cell. The postcondition now asks gates in
; LATER trips too (not only after the step), per recorded CELL by SCEV (cell
; index of the gate vs the indices earlier steps read: here gate i, step i+1, so
; trip i+1's gate hits trip i's record), with the steps themselves not counting
; as reads of the register.
; MASKED TODAY (measured): the module is refused earlier, by
; `declineStrandedAccumulatorTemps` — the body's window-cell store is outside
; `railLocalQualifies`' (L3), bd 01po.19.18.2. The new clause is the backstop for
; the day that exemption lands; this file pins that the shape is loud.
; RETIREMENT TRIGGER: when the masking owner admits the shape, this file must
; then fail at the dead-accumulator postcondition (re-derive the CHECK there),
; and when bd 8h7d.20 reverses the counter after the loop it becomes an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: loop accumulator source temporaries cannot be discharged in the loop body

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [5 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 5, ptr nonnull %1) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(5) %1, i8 0, i64 5, i1 false)
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %9, %2 ]
  %4 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 1.000000e+00) #7
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %4, align 1, !tbaa !6
  %9 = add nuw nsw i64 %3, 1
  %10 = icmp eq i64 %9, 5
  br i1 %10, label %11, label %2, !llvm.loop !12

11:                                               ; preds = %2, %16
  %12 = phi i64 [ %22, %16 ], [ 0, %2 ]
  %13 = phi i32 [ %26, %16 ], [ 0, %2 ]
  %14 = icmp eq i32 %13, 1
  br i1 %14, label %15, label %16

15:                                               ; preds = %11
  tail call void @cq_phi(double noundef 5.000000e-01) #6
  br label %16

16:                                               ; preds = %15, %11
  %17 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %12
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !10, !noundef !11
  %19 = trunc nuw i8 %18 to i1
  %20 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %19, double noundef 0x3FE6666666666666) #7
  %21 = zext i1 %20 to i8
  store i8 %21, ptr %17, align 1, !tbaa !6
  %22 = add nuw nsw i64 %12, 1
  %23 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %22
  %24 = load i8, ptr %23, align 1, !tbaa !6, !range !10, !noundef !11
  %25 = zext nneg i8 %24 to i32
  %26 = add nuw nsw i32 %13, %25
  %27 = icmp eq i64 %22, 4
  br i1 %27, label %30, label %11, !llvm.loop !15

28:                                               ; preds = %30
  %29 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 5, ptr nonnull %1) #6
  ret i32 0

30:                                               ; preds = %16, %30
  %31 = phi i64 [ %38, %30 ], [ 0, %16 ]
  %32 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %31
  %33 = load i8, ptr %32, align 1, !tbaa !6, !range !10, !noundef !11
  %34 = trunc nuw i8 %33 to i1
  %35 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %34) #6
  %36 = zext i1 %35 to i32
  %37 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %36)
  %38 = add nuw nsw i64 %31, 1
  %39 = icmp eq i64 %38, 5
  br i1 %39, label %28, label %30, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare void @cq_phi(double noundef) local_unnamed_addr #3

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #4

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

; Function Attrs: nofree nounwind
declare noundef i32 @putchar(i32 noundef) local_unnamed_addr #5

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree nounwind }
attributes #6 = { nounwind }
attributes #7 = { nomerge nounwind }


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
