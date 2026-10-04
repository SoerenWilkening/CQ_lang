
; railbank_readorder_accept_measured_guard.ll — ACCEPT (bd `xdu2.10`, Rule-13 round 3 F-2, P3).
;
; The write runs under `r > 0` and the read under `r > 1`, where `r` is a
; `cq_measure` RESULT — a classical value (the measurement is the sole sink). The
; round-2 taint conjunct walked the closure THROUGH the measure call into its
; tainted operand and refused `r`'s compares as facts, a regression against the
; round-1 binary (which accepted this and ran it correctly at argc 1 and 5). A
; `taint.MeasureCalls` result is now a classical LEAF of the closure (still asked
; the at-most-once question), so `r > 1` refutes the write guard's false edge.
; RED on `928eb206`: `cq rail bank: array has cells no iteration writes`.
;
; SOURCE (stage 1 below is `clang -O1` of it, verbatim):
; /* guard from a classical measurement result */
; __attribute__((noinline)) static int slice(int k) {
;     int q = k; cq_theta(&q, 0.4);
;     int r = cq_measure(q);
;     int b[3];
;     if (r > 0) for (int i = 0; i < 3; ++i) { b[i] = 0; cq_theta(&b[i], 0.5); }
;     int s = 0;
;     if (r > 1) for (int j = 0; j < 3; ++j) s += cq_measure(b[j]);
;     return s;
; }
; int main(int argc, char **argv) { (void)argv; return slice(argc - 2); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=NOTS --input-file=%t.ll %s
; RUN: env CQ_CTRL_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:     > /dev/null 2> %t.dbg
; RUN: %filecheck --check-prefix=DBG --input-file=%t.dbg %s \
; RUN:     --implicit-check-not='C6 read-order refused' --implicit-check-not='cq rail bank:'
;
; NOTS-NOT: @cq_theta_
; NOTS-NOT: @cq_measure_
; NOTS-NOT: cqrt_qram_
; NOTS-NOT: store i32 0, ptr %cq.bank.addr
;
; DBG: railbank [Bank]

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, -2
  %4 = tail call fastcc i32 @slice(i32 noundef %3)
  ret i32 %4
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0) unnamed_addr #1 {
  %2 = alloca [3 x i32], align 4
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 4.000000e-01) #4
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %2) #4
  %5 = icmp sgt i32 %4, 0
  br i1 %5, label %6, label %12

6:                                                ; preds = %1, %6
  %7 = phi i64 [ %10, %6 ], [ 0, %1 ]
  %8 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  %9 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %7
  store i32 %8, ptr %9, align 4, !tbaa !6
  %10 = add nuw nsw i64 %7, 1
  %11 = icmp eq i64 %10, 3
  br i1 %11, label %12, label %6, !llvm.loop !10

12:                                               ; preds = %6, %1
  %13 = icmp sgt i32 %4, 1
  br i1 %13, label %14, label %23

14:                                               ; preds = %12, %14
  %15 = phi i64 [ %21, %14 ], [ 0, %12 ]
  %16 = phi i32 [ %20, %14 ], [ 0, %12 ]
  %17 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %15
  %18 = load i32, ptr %17, align 4, !tbaa !6
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #4
  %20 = add nsw i32 %19, %16
  %21 = add nuw nsw i64 %15, 1
  %22 = icmp eq i64 %21, 3
  br i1 %22, label %23, label %14, !llvm.loop !13

23:                                               ; preds = %14, %12
  %24 = phi i32 [ 0, %12 ], [ %20, %14 ]
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %2) #4
  ret i32 %24
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
