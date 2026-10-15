; railwindow_trip_reject_leaked_record.ll — DECLINE (bd `test_C_libtooling-01po.19.17`;
; the CROSS-TRIP guard of the per-cell exemption).
;
; `s = q[m] + q[m-1]`, an Ry on q[m-2] (another cell: exempt IN THIS TRIP), then
; `cq_measure(s * 3)`. The measured product is kept, and the chain's
; `zext i8 -> i32` operand of it is not discharged in its trip (a leak). The
; exemption demands every such record be discharged in its own trip
; (`recordTripLocal`), so Q4 refuses (the WIN prefix pins the trip-local
; branch). ⚠ CORRECTED (review (a) C-F2): this loop DESCENDS — later trips
; rotate q[m-3], q[m-4], ..., never a cell this trip read — so here the leak
; meets no gate on its source and the refusal is the FAIL-CLOSED policy, an
; over-decline (bd 01po.19.34), not a hazard. The hazard is the ASCENDING
; shape, railwindow_trip_reject_ascending_measured_one_path.ll.
;
; SOURCE (clang -O1, verbatim below):
;   #include <stdbool.h>
;   int main(void){ bool q[6]={0};
;     for(int i=0;i<6;i++) cq_theta(&q[i], .4+.2*i);
;     int r = 0;
;     for (int m=5; m>=2; m--) {
;       int s = q[m] + q[m-1];
;       cq_theta(&q[m-2], .5);
;       r += cq_measure(s * 3);
;     }
;     for(int i=0;i<6;i++) r=2*r+cq_measure(q[i]); return r; }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; CHECK: cq rail window: temporary read from a quantum-array cell is live at a non-diagonal gate on that array{{$}}
; WIN: CQ_RAILWINDOW_DBG: Q4 record of another cell not trip-local {{.*}}@cq_template_zext_i8_to_i32(

; ModuleID = 'railwindow_trip_reject_leaked_record.c'
source_filename = "railwindow_trip_reject_leaked_record.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [6 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 6, ptr nonnull %1) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(6) %1, i8 0, i64 6, i1 false)
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %12, %2 ]
  %4 = getelementptr inbounds [6 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = trunc nuw nsw i64 %3 to i32
  %8 = uitofp nneg i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %8, double 2.000000e-01, double 4.000000e-01)
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef %9) #6
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %4, align 1, !tbaa !6
  %12 = add nuw nsw i64 %3, 1
  %13 = icmp eq i64 %12, 6
  br i1 %13, label %14, label %2, !llvm.loop !12

14:                                               ; preds = %2, %14
  %15 = phi i64 [ %19, %14 ], [ 5, %2 ]
  %16 = phi i32 [ %32, %14 ], [ 0, %2 ]
  %17 = getelementptr inbounds [6 x i8], ptr %1, i64 0, i64 %15
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !10, !noundef !11
  %19 = add nsw i64 %15, -1
  %20 = getelementptr inbounds [6 x i8], ptr %1, i64 0, i64 %19
  %21 = load i8, ptr %20, align 1, !tbaa !6, !range !10, !noundef !11
  %22 = add nuw nsw i8 %21, %18
  %23 = add nsw i64 %15, -2
  %24 = getelementptr inbounds [6 x i8], ptr %1, i64 0, i64 %23
  %25 = load i8, ptr %24, align 1, !tbaa !6, !range !10, !noundef !11
  %26 = trunc nuw i8 %25 to i1
  %27 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %26, double noundef 5.000000e-01) #6
  %28 = zext i1 %27 to i8
  store i8 %28, ptr %24, align 1, !tbaa !6
  %29 = mul nuw nsw i8 %22, 3
  %30 = zext nneg i8 %29 to i32
  %31 = tail call i32 @cq_measure_si32(i32 noundef %30) #5
  %32 = add nsw i32 %31, %16
  %33 = icmp ugt i64 %15, 2
  br i1 %33, label %14, label %35, !llvm.loop !15

34:                                               ; preds = %35
  call void @llvm.lifetime.end.p0(i64 6, ptr nonnull %1) #5
  ret i32 %44

35:                                               ; preds = %14, %35
  %36 = phi i64 [ %45, %35 ], [ 0, %14 ]
  %37 = phi i32 [ %44, %35 ], [ %32, %14 ]
  %38 = shl nsw i32 %37, 1
  %39 = getelementptr inbounds [6 x i8], ptr %1, i64 0, i64 %36
  %40 = load i8, ptr %39, align 1, !tbaa !6, !range !10, !noundef !11
  %41 = trunc nuw i8 %40 to i1
  %42 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %41) #5
  %43 = zext i1 %42 to i32
  %44 = or disjoint i32 %38, %43
  %45 = add nuw nsw i64 %36, 1
  %46 = icmp eq i64 %45, 6
  br i1 %46, label %34, label %35, !llvm.loop !16
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
