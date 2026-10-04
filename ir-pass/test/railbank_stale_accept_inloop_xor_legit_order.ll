; railbank_stale_accept_inloop_xor_legit_order.ll — bd `xdu2.1` (Track B),
; Rule-13 round-2 finding F-1's GREEN half (the reviewer's P1_legit.c).
;
; The F-1 program with the bank measure loop moved ABOVE the in-place `xor` loop:
; every cell is read before any relabel, so the circuit is valid and the rolled
; collapse may convert `q ^= 3` in place. The fix (`staleReadOfValue` asking
; every bank cell LOAD) must NOT decline it: from the parked value's def, no
; path reaches a load through the xor loop (it has no back edge into the
; measure loop). Pre-fix and post-fix binaries emit this module BYTE-IDENTICALLY
; (measured, `TRACK_B.md` §6b).
;
; What is pinned, so the accept is not the fence never looking: the in-place
; `cqrt_xorc_i32(%h, 3)` IS emitted (the collapse converted the relabel), the
; bank loads feed the measures, and the measure loop's EXIT block is the one
; that enters the xor loop — i.e. every cell read precedes every relabel.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, verbatim:
;   #include <stdlib.h>
;   int main(int argc, char **argv) {
;     int n = atoi(argv[1]); if (n <= 0) return 1;
;     int q = argc; cq_theta(&q, 0.5); int b[n]; int s = 0;
;     for (int i = 0; i < n; ++i) b[i] = q;
;     for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
;     for (int k = 0; k < n; ++k) { if (q > k) cq_phi(0.3); q ^= 3; }
;     return s + cq_measure(q);
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR    --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CXOR  --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CMEAS --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS  --input-file=%t.ll %s
;
; IR: %h = call i32 @cqrt_alloc_i32(
; IR: alloca i32, i64 %{{[0-9]+}}, align 16, !cq.railbank
; IR: store i32 %h, ptr
; IR: [[MEXIT:[0-9]+]]: ; preds = %[[MLOOP:[0-9]+]]{{$}}
; IR-NEXT: = tail call i32 @llvm.smax.i32(
; IR-NEXT: br label %[[XLOOP:[0-9]+]]
; IR: [[MLOOP]]:
; IR: [[CELL:%[0-9]+]] = load i32, ptr
; IR-NEXT: call i32 @cqrt_measure_i32(i32 [[CELL]])
; IR: br i1 %{{[0-9]+}}, label %[[MEXIT]], label %[[MLOOP]]
; IR: [[XLOOP]]:
; IR: call void @cqrt_xorc_i32(i32 %h, i32 3)
;
; ⚠ One whole-file prefix per count (Rule 12 (a)).
; CXOR-COUNT-1: call void @cqrt_xorc_i32(
; CMEAS-COUNT-2: call i32 @cqrt_measure_i32(
;
; NOTS-NOT: cqrt_qram_
; NOTS-NOT: cqrt_free(i32 %h)

source_filename = "probes2/P1_legit.bank.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = icmp slt i32 %5, 1
  br i1 %6, label %43, label %7

7:                                                ; preds = %2
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #5
  %9 = zext nneg i32 %5 to i64
  %10 = tail call ptr @llvm.stacksave.p0()
  %11 = alloca i32, i64 %9, align 16
  %12 = zext nneg i32 %5 to i64
  br label %15

13:                                               ; preds = %15
  %14 = zext nneg i32 %5 to i64
  br label %22

15:                                               ; preds = %7, %15
  %16 = phi i64 [ 0, %7 ], [ %18, %15 ]
  %17 = getelementptr inbounds i32, ptr %11, i64 %16
  store i32 %8, ptr %17, align 4, !tbaa !10
  %18 = add nuw nsw i64 %16, 1
  %19 = icmp eq i64 %18, %12
  br i1 %19, label %13, label %15, !llvm.loop !12

20:                                               ; preds = %22
  %21 = tail call i32 @llvm.smax.i32(i32 %5, i32 1)
  br label %34

22:                                               ; preds = %13, %22
  %23 = phi i64 [ 0, %13 ], [ %29, %22 ]
  %24 = phi i32 [ 0, %13 ], [ %28, %22 ]
  %25 = getelementptr inbounds i32, ptr %11, i64 %23
  %26 = load i32, ptr %25, align 4, !tbaa !10
  %27 = tail call i32 @cq_measure_si32(i32 noundef %26) #5
  %28 = add nsw i32 %27, %24
  %29 = add nuw nsw i64 %23, 1
  %30 = icmp eq i64 %29, %14
  br i1 %30, label %20, label %22, !llvm.loop !15

31:                                               ; preds = %39
  %32 = tail call i32 @cq_measure_si32(i32 noundef %40) #5
  %33 = add nsw i32 %32, %28
  tail call void @llvm.stackrestore.p0(ptr %10)
  br label %43

34:                                               ; preds = %20, %39
  %35 = phi i32 [ %41, %39 ], [ 0, %20 ]
  %36 = phi i32 [ %40, %39 ], [ %8, %20 ]
  %37 = icmp sgt i32 %36, %35
  br i1 %37, label %38, label %39

38:                                               ; preds = %34
  tail call void @cq_phi(double noundef 3.000000e-01) #5
  br label %39

39:                                               ; preds = %38, %34
  %40 = xor i32 %36, 3
  %41 = add nuw nsw i32 %35, 1
  %42 = icmp eq i32 %41, %21
  br i1 %42, label %31, label %34, !llvm.loop !16

43:                                               ; preds = %2, %31
  %44 = phi i32 [ %33, %31 ], [ 1, %2 ]
  ret i32 %44
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare void @cq_phi(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
