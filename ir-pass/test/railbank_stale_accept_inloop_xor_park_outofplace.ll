; railbank_stale_accept_inloop_xor_park_outofplace.ll — bd `xdu2.1` (Track B),
; Rule-13 round-3 GREEN control (the reviewer's g4 shape, with a trip-invariant
; condition so the stream is IV-free).
;
; `for(k){ if(q>5) cq_phi(.3); q ^= 3; b[k] = q; q ^= 5; }` — the parked value is
; `q^3`, which `-O1` keeps as its own value because `q ^= 5` follows and the two
; xors fold to `q ^= 6` on the rail. So the collapse leaves the parked `q^3`
; OUT OF PLACE (`cq_template_xor_i32_hl` → a fresh rail per trip) and only the
; `^6` in place. The fresh rail is never relabelled, so the cell is not stale and
; the round-3 fix (`DefRefreshes=false` for bank reads) must NOT decline it.
; Measured correct by hand against the unrolled register program (cell k =
; q0 ^ (6k) ^ 3); the register twin is NOT byte-comparable (-O1 folds the
; unrolled xors across iterations — `TRACK_B.md` §6c), so the order is pinned
; here: per trip an out-of-place template xor BEFORE the in-place `xorc 6`,
; the template result stored, and every bank measure reading a cell load.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, verbatim:
;   #include <stdlib.h>
;   int main(int argc, char **argv) {
;     int n = atoi(argv[1]); if (n <= 0) return 1;
;     int q = cq_theta(argc, 0.5); int s = 0;
;     int b[n];
;     for (int k = 0; k < n; ++k) { if (q > 5) cq_phi(0.3); q ^= 3; b[k] = q; q ^= 5; }
;     for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
;     return s + cq_measure(q);
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR    --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CXORC --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CMEAS --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS  --input-file=%t.ll %s
;
; IR: %h = call i32 @cqrt_alloc_i32(
; IR: alloca i32, i64 %{{[0-9]+}}, align 16, !cq.railbank
; IR: [[T:%h_op[0-9]*]] = call i32 @cq_template_xor_i32_hl(i32 %h, i32 3)
; IR: store i32 [[T]], ptr
; IR: call void @cqrt_xorc_i32(i32 %h, i32 6)
; IR: [[CELL:%[0-9]+]] = load i32, ptr
; IR-NEXT: call i32 @cqrt_measure_i32(i32 [[CELL]])
;
; ⚠ One whole-file prefix per count (Rule 12 (a)).
; CXORC-COUNT-1: call void @cqrt_xorc_i32(
; CMEAS-COUNT-2: call i32 @cqrt_measure_i32(
;
; NOTS-NOT: cqrt_qram_
; NOTS-NOT: cqrt_free(i32 %h)

source_filename = "probes6/w1_xor_park_outofplace.bank.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = icmp slt i32 %5, 1
  br i1 %6, label %38, label %7

7:                                                ; preds = %2
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #4
  %9 = zext nneg i32 %5 to i64
  %10 = tail call ptr @llvm.stacksave.p0()
  %11 = alloca i32, i64 %9, align 16
  %12 = zext nneg i32 %5 to i64
  br label %15

13:                                               ; preds = %20
  %14 = zext nneg i32 %5 to i64
  br label %29

15:                                               ; preds = %7, %20
  %16 = phi i64 [ 0, %7 ], [ %24, %20 ]
  %17 = phi i32 [ %8, %7 ], [ %23, %20 ]
  %18 = icmp sgt i32 %17, 5
  br i1 %18, label %19, label %20

19:                                               ; preds = %15
  tail call void @cq_phi(double noundef 3.000000e-01) #4
  br label %20

20:                                               ; preds = %19, %15
  %21 = xor i32 %17, 3
  %22 = getelementptr inbounds i32, ptr %11, i64 %16
  store i32 %21, ptr %22, align 4, !tbaa !10
  %23 = xor i32 %17, 6
  %24 = add nuw nsw i64 %16, 1
  %25 = icmp eq i64 %24, %12
  br i1 %25, label %13, label %15, !llvm.loop !12

26:                                               ; preds = %29
  %27 = tail call i32 @cq_measure_si32(i32 noundef %23) #4
  %28 = add nsw i32 %27, %35
  tail call void @llvm.stackrestore.p0(ptr %10)
  br label %38

29:                                               ; preds = %13, %29
  %30 = phi i64 [ 0, %13 ], [ %36, %29 ]
  %31 = phi i32 [ 0, %13 ], [ %35, %29 ]
  %32 = getelementptr inbounds i32, ptr %11, i64 %30
  %33 = load i32, ptr %32, align 4, !tbaa !10
  %34 = tail call i32 @cq_measure_si32(i32 noundef %33) #4
  %35 = add nsw i32 %34, %31
  %36 = add nuw nsw i64 %30, 1
  %37 = icmp eq i64 %36, %14
  br i1 %37, label %26, label %29, !llvm.loop !15

38:                                               ; preds = %2, %26
  %39 = phi i32 [ %28, %26 ], [ 1, %2 ]
  ret i32 %39
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #3

declare void @cq_phi(double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #4 = { nounwind }

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
