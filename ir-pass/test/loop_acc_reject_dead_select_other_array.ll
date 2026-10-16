; loop_acc_reject_dead_select_other_array.ll — DECLINE, an ADVERSARIAL WITNESS (bd 01po.19.18.6, R11 round 1
; rA1B-F4; ruling ruling-01po19-18-dead-accumulator-leak-warn-2026-10-16).
;
; SOURCE (clang -O1, verbatim below; the reviewer's pE.c):
;   #include <stdio.h>
;   int main(int argc, char **argv) {
;       bool q[4] = {0};
;       bool w[2] = {0};
;       for (int i = 0; i < 4; i++) cq_theta(&q[i], 1.0);
;       for (int i = 0; i < 2; i++) cq_theta(&w[i], 1.0);
;       int c = 0;
;       for (int i = 0; i < 4; i++) { if (c == 1) cq_phi(0.4); c += q[i]; }
;       bool *p = argc > 1 ? &q[1] : &w[0];   /* select over two DIFFERENT arrays */
;       cq_theta(p, 0.3);
;       for (int i = 0; i < 4; i++) printf("%d", cq_measure(q[i]));
;       for (int i = 0; i < 2; i++) printf("%d", cq_measure(w[i]));
;       printf("\n");
;       return 0;
;   }
;
; THE HAZARD. A cell pointer selected over TWO DIFFERENT arrays (`q`, recorded by
; the dead counter, and `w`) is rotated after the loop. Lineage keyed on one
; `getUnderlyingObject` identity named the `select`, not `q`, and missed it. The
; postcondition now collects every underlying object (`getUnderlyingObjects`),
; treats an unidentified one as lineage (fail closed), and counts any pointer
; escape of a lineage array (a call such as `memcpy`, a stored pointer, a cast
; to an integer) as an escape.
; MASKED TODAY (measured): the rail bank refuses the aliasing fan-out first. This
; file pins that the shape is loud.
; RETIREMENT TRIGGER: when the masking owner admits the shape, this file must
; then fail at the dead-accumulator postcondition (re-derive the CHECK there),
; and when bd 8h7d.20 reverses the counter after the loop it becomes an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq rail bank: cell address has aliasing fan-out

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 4
  %4 = alloca [2 x i8], align 2
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #5
  store i32 0, ptr %3, align 4
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %4) #5
  store i16 0, ptr %4, align 2
  br label %5

5:                                                ; preds = %2, %5
  %6 = phi i64 [ 0, %2 ], [ %12, %5 ]
  %7 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %6
  %8 = load i8, ptr %7, align 1, !tbaa !6, !range !10, !noundef !11
  %9 = trunc nuw i8 %8 to i1
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %9, double noundef 1.000000e+00) #6
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %7, align 1, !tbaa !6
  %12 = add nuw nsw i64 %6, 1
  %13 = icmp eq i64 %12, 4
  br i1 %13, label %14, label %5, !llvm.loop !12

14:                                               ; preds = %5, %14
  %15 = phi i64 [ %21, %14 ], [ 0, %5 ]
  %16 = getelementptr inbounds [2 x i8], ptr %4, i64 0, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !6, !range !10, !noundef !11
  %18 = trunc nuw i8 %17 to i1
  %19 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %18, double noundef 1.000000e+00) #6
  %20 = zext i1 %19 to i8
  store i8 %20, ptr %16, align 1, !tbaa !6
  %21 = add nuw nsw i64 %15, 1
  %22 = icmp eq i64 %15, 0
  br i1 %22, label %14, label %31, !llvm.loop !15

23:                                               ; preds = %36
  %24 = icmp sgt i32 %0, 1
  %25 = getelementptr inbounds i8, ptr %3, i64 1
  %26 = select i1 %24, ptr %25, ptr %4
  %27 = load i8, ptr %26, align 1, !tbaa !6, !range !10, !noundef !11
  %28 = trunc nuw i8 %27 to i1
  %29 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %28, double noundef 3.000000e-01) #6
  %30 = zext i1 %29 to i8
  store i8 %30, ptr %26, align 1, !tbaa !6
  br label %43

31:                                               ; preds = %14, %36
  %32 = phi i64 [ %41, %36 ], [ 0, %14 ]
  %33 = phi i32 [ %40, %36 ], [ 0, %14 ]
  %34 = icmp eq i32 %33, 1
  br i1 %34, label %35, label %36

35:                                               ; preds = %31
  tail call void @cq_phi(double noundef 4.000000e-01) #5
  br label %36

36:                                               ; preds = %35, %31
  %37 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %32
  %38 = load i8, ptr %37, align 1, !tbaa !6, !range !10, !noundef !11
  %39 = zext nneg i8 %38 to i32
  %40 = add nuw nsw i32 %33, %39
  %41 = add nuw nsw i64 %32, 1
  %42 = icmp eq i64 %41, 4
  br i1 %42, label %23, label %31, !llvm.loop !16

43:                                               ; preds = %23, %43
  %44 = phi i64 [ 0, %23 ], [ %51, %43 ]
  %45 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %44
  %46 = load i8, ptr %45, align 1, !tbaa !6, !range !10, !noundef !11
  %47 = trunc nuw i8 %46 to i1
  %48 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %47) #5
  %49 = zext i1 %48 to i32
  %50 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %49)
  %51 = add nuw nsw i64 %44, 1
  %52 = icmp eq i64 %51, 4
  br i1 %52, label %55, label %43, !llvm.loop !17

53:                                               ; preds = %55
  %54 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %4) #5
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #5
  ret i32 0

55:                                               ; preds = %43, %55
  %56 = phi i64 [ %63, %55 ], [ 0, %43 ]
  %57 = getelementptr inbounds [2 x i8], ptr %4, i64 0, i64 %56
  %58 = load i8, ptr %57, align 1, !tbaa !6, !range !10, !noundef !11
  %59 = trunc nuw i8 %58 to i1
  %60 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %59) #5
  %61 = zext i1 %60 to i32
  %62 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %61)
  %63 = add nuw nsw i64 %56, 1
  %64 = icmp eq i64 %56, 0
  br i1 %64, label %55, label %53, !llvm.loop !18
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
!18 = distinct !{!18, !13, !14}
