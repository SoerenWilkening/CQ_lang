
; railbank_readorder_accept_fixed_merged_tainted_diamond_pre.ll — ACCEPT (bd `xdu2.10`, Rule-13 round 3 F-1).
;
; The FIXED-bank form of `railbank_readorder_accept_merged_tainted_diamond.ll`:
; a tainted `if (c) cq_phi(pi);` diamond merges BEFORE the `k > 0`-guarded write;
; the read runs under `k > 1`, which implies the write guard. The read lies in no
; tainted branch's region, so the classical guards decide.
; RED on `928eb206`: `cq rail bank: array has cells no iteration writes`.
; Traced: at k=2 it prepares and measures three cells; at k<=1 it measures only `c`.
;
; SOURCE (stage 1 below is `clang -O1` of it, verbatim):
; __attribute__((noinline)) static int slice(int k) {
;     _Bool c = cq_theta((_Bool)0, 0.3);
;     if (c) cq_phi(3.14159);
;     int b[3];
;     if (k > 0) for (int i = 0; i < 3; ++i) b[i] = cq_theta(0, 0.5);
;     int s = cq_measure(c);
;     if (k > 1) for (int j = 0; j < 3; ++j) s += cq_measure(b[j]);
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
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01) #4
  br i1 %3, label %4, label %5

4:                                                ; preds = %1
  tail call void @cq_phi(double noundef 3.141590e+00) #4
  br label %5

5:                                                ; preds = %4, %1
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %2) #4
  %6 = icmp sgt i32 %0, 0
  br i1 %6, label %7, label %13

7:                                                ; preds = %5, %7
  %8 = phi i64 [ %11, %7 ], [ 0, %5 ]
  %9 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  %10 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %8
  store i32 %9, ptr %10, align 4, !tbaa !6
  %11 = add nuw nsw i64 %8, 1
  %12 = icmp eq i64 %11, 3
  br i1 %12, label %13, label %7, !llvm.loop !10

13:                                               ; preds = %7, %5
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #4
  %15 = zext i1 %14 to i32
  %16 = icmp sgt i32 %0, 1
  br i1 %16, label %17, label %26

17:                                               ; preds = %13, %17
  %18 = phi i64 [ %24, %17 ], [ 0, %13 ]
  %19 = phi i32 [ %23, %17 ], [ %15, %13 ]
  %20 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %18
  %21 = load i32, ptr %20, align 4, !tbaa !6
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #4
  %23 = add nsw i32 %22, %19
  %24 = add nuw nsw i64 %18, 1
  %25 = icmp eq i64 %24, 3
  br i1 %25, label %26, label %17, !llvm.loop !13

26:                                               ; preds = %17, %13
  %27 = phi i32 [ %15, %13 ], [ %23, %17 ]
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %2) #4
  ret i32 %27
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

declare void @cq_phi(double noundef) local_unnamed_addr #3

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

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
