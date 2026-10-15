; railwindow_trip_reject_ascending_measured_one_path.ll — DECLINE (bd
; `test_C_libtooling-01po.19.17` review (a) round 1, finding C-F1, the one
; SILENT miscompile of bea85adf; reviewer probe review_aC/p6/p6.c).
;
; ASCENDING: trip m reads q[m+1], q[m+2] into s, rotates q[m] under s == 3, and
; measures s only when bit m of argc is set. On the other path the s chain's
; `zext i8 -> i32` copy is never undone, and trip m+1 rotates q[m+1], a cell
; that copy recorded: the next trip's controlled Ry acts on a rail entangled
; with a stale record (measured: q1 P(1) .0907 vs the coherent model's .0967).
; bea85adf let that record pass because `recordAbsentAt` / `recordIsExemptAt`
; reason about the SAME trip's instance; now a record reached only through a
; distinct-cell read passes ONLY if it is discharged on every path to every
; latch and every loop exit (`recordTripLocal`). The WIN prefix pins that
; branch. Lowering the program (discharge the copy on the unmeasured path) is
; the eager-uncompute placement's job, not this fence's.
;
; SOURCE (clang -O1, verbatim below):
;   #include <stdbool.h>
;   int main(int argc, char **argv){ bool q[5]={0};
;     for(int i=0;i<5;i++) cq_theta(&q[i], .4+.2*i);
;     int r = 0;
;     for (int m=0; m<=2; m++) {
;       int s = 2*q[m+1] + q[m+2];
;       if (s == 3) cq_theta(&q[m], .7);
;       if ((argc >> m) & 1) r += cq_measure(s);
;     }
;     for(int i=0;i<5;i++) r=2*r+cq_measure(q[i]); return r; }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; CHECK: cq rail window: temporary read from a quantum-array cell is live at a non-diagonal gate on that array{{$}}
; WIN: CQ_RAILWINDOW_DBG: Q4 record of another cell not trip-local {{.*}}@cq_template_zext_i8_to_i32(

; ModuleID = 'railwindow_trip_reject_ascending_measured_one_path.c'
source_filename = "railwindow_trip_reject_ascending_measured_one_path.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = alloca [5 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 5, ptr nonnull %3) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(5) %3, i8 0, i64 5, i1 false)
  br label %4

4:                                                ; preds = %2, %4
  %5 = phi i64 [ 0, %2 ], [ %14, %4 ]
  %6 = getelementptr inbounds [5 x i8], ptr %3, i64 0, i64 %5
  %7 = load i8, ptr %6, align 1, !tbaa !6, !range !10, !noundef !11
  %8 = trunc nuw i8 %7 to i1
  %9 = trunc nuw nsw i64 %5 to i32
  %10 = uitofp nneg i32 %9 to double
  %11 = tail call double @llvm.fmuladd.f64(double %10, double 2.000000e-01, double 4.000000e-01)
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef %11) #6
  %13 = zext i1 %12 to i8
  store i8 %13, ptr %6, align 1, !tbaa !6
  %14 = add nuw nsw i64 %5, 1
  %15 = icmp eq i64 %14, 5
  br i1 %15, label %16, label %4, !llvm.loop !12

16:                                               ; preds = %4, %43
  %17 = phi i64 [ %19, %43 ], [ 0, %4 ]
  %18 = phi i32 [ %44, %43 ], [ 0, %4 ]
  %19 = add nuw nsw i64 %17, 1
  %20 = getelementptr inbounds [5 x i8], ptr %3, i64 0, i64 %19
  %21 = load i8, ptr %20, align 1, !tbaa !6, !range !10, !noundef !11
  %22 = shl nuw nsw i8 %21, 1
  %23 = add nuw nsw i64 %17, 2
  %24 = getelementptr inbounds [5 x i8], ptr %3, i64 0, i64 %23
  %25 = load i8, ptr %24, align 1, !tbaa !6, !range !10, !noundef !11
  %26 = or disjoint i8 %22, %25
  %27 = zext nneg i8 %26 to i32
  %28 = icmp eq i8 %26, 3
  br i1 %28, label %29, label %35

29:                                               ; preds = %16
  %30 = getelementptr inbounds [5 x i8], ptr %3, i64 0, i64 %17
  %31 = load i8, ptr %30, align 1, !tbaa !6, !range !10, !noundef !11
  %32 = trunc nuw i8 %31 to i1
  %33 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %32, double noundef 0x3FE6666666666666) #6
  %34 = zext i1 %33 to i8
  store i8 %34, ptr %30, align 1, !tbaa !6
  br label %35

35:                                               ; preds = %29, %16
  %36 = trunc nuw nsw i64 %17 to i32
  %37 = shl nuw nsw i32 1, %36
  %38 = and i32 %37, %0
  %39 = icmp eq i32 %38, 0
  br i1 %39, label %43, label %40

40:                                               ; preds = %35
  %41 = tail call i32 @cq_measure_si32(i32 noundef %27) #5
  %42 = add nsw i32 %41, %18
  br label %43

43:                                               ; preds = %40, %35
  %44 = phi i32 [ %42, %40 ], [ %18, %35 ]
  %45 = icmp eq i64 %19, 3
  br i1 %45, label %47, label %16, !llvm.loop !15

46:                                               ; preds = %47
  call void @llvm.lifetime.end.p0(i64 5, ptr nonnull %3) #5
  ret i32 %56

47:                                               ; preds = %43, %47
  %48 = phi i64 [ %57, %47 ], [ 0, %43 ]
  %49 = phi i32 [ %56, %47 ], [ %44, %43 ]
  %50 = shl nsw i32 %49, 1
  %51 = getelementptr inbounds [5 x i8], ptr %3, i64 0, i64 %48
  %52 = load i8, ptr %51, align 1, !tbaa !6, !range !10, !noundef !11
  %53 = trunc nuw i8 %52 to i1
  %54 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %53) #5
  %55 = zext i1 %54 to i32
  %56 = or disjoint i32 %50, %55
  %57 = add nuw nsw i64 %48, 1
  %58 = icmp eq i64 %57, 5
  br i1 %58, label %46, label %47, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nounwind }
attributes #6 = { nomerge nounwind }

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
