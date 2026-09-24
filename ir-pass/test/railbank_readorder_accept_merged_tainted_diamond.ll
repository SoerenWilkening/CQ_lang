
; railbank_readorder_accept_merged_tainted_diamond.ll — ACCEPT (bd `xdu2.10`, Rule-13 round 3 F-1, P2).
;
; The Grover shape: a tainted `if (c) cq_phi(pi);` diamond that FULLY MERGES
; before an UNGUARDED runtime bank. `-O1` gives each bank loop its own `n > 0`
; guard, so the read does not post-dominate the tainted branch — and the round-2
; read-side conjunct, spelled with `instUnderTaintedControl` (dominates ∧ does not
; post-dominate — NOT control dependence), declined it at the read-order anchor.
; Its explicitly-guarded twin already compiled. The conjunct now asks whether the
; read lies INSIDE the tainted branch's REGION (reachable from the branch without
; passing its immediate post-dominator); a merged diamond's region ends before
; the read, so only the classical guards speak and the walk accepts.
; RED on `928eb206`: `cq rail bank: array has cells no iteration writes`.
;
; SOURCE (stage 1 below is `clang -O1` of it, verbatim):
; __attribute__((noinline)) static int slice(int n) {
;     _Bool c = cq_theta((_Bool)0, 0.3);
;     if (c) cq_phi(3.14159);
;     int b[n];
;     for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
;     int s = cq_measure(c);
;     for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
;     return s;
; }
; int main(int argc, char **argv) { (void)argv; return slice(argc - 1); }
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
  %3 = add nsw i32 %0, -1
  %4 = tail call fastcc i32 @slice(i32 noundef %3)
  ret i32 %4
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0) unnamed_addr #1 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01) #3
  br i1 %2, label %3, label %4

3:                                                ; preds = %1
  tail call void @cq_phi(double noundef 3.141590e+00) #3
  br label %4

4:                                                ; preds = %3, %1
  %5 = zext i32 %0 to i64
  %6 = alloca i32, i64 %5, align 16
  %7 = icmp sgt i32 %0, 0
  br i1 %7, label %8, label %10

8:                                                ; preds = %4
  %9 = zext nneg i32 %0 to i64
  br label %16

10:                                               ; preds = %16, %4
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #3
  %12 = zext i1 %11 to i32
  %13 = icmp sgt i32 %0, 0
  br i1 %13, label %14, label %23

14:                                               ; preds = %10
  %15 = zext nneg i32 %0 to i64
  br label %25

16:                                               ; preds = %8, %16
  %17 = phi i64 [ 0, %8 ], [ %21, %16 ]
  %18 = getelementptr inbounds i32, ptr %6, i64 %17
  %19 = load i32, ptr %18, align 4, !tbaa !6
  %20 = tail call i32 @cq_theta_si32(i32 noundef %19, double noundef 5.000000e-01) #3
  store i32 %20, ptr %18, align 4, !tbaa !6
  %21 = add nuw nsw i64 %17, 1
  %22 = icmp eq i64 %21, %9
  br i1 %22, label %10, label %16, !llvm.loop !10

23:                                               ; preds = %25, %10
  %24 = phi i32 [ %12, %10 ], [ %31, %25 ]
  ret i32 %24

25:                                               ; preds = %14, %25
  %26 = phi i64 [ 0, %14 ], [ %32, %25 ]
  %27 = phi i32 [ %12, %14 ], [ %31, %25 ]
  %28 = getelementptr inbounds i32, ptr %6, i64 %26
  %29 = load i32, ptr %28, align 4, !tbaa !6
  %30 = tail call i32 @cq_measure_si32(i32 noundef %29) #3
  %31 = add nsw i32 %30, %27
  %32 = add nuw nsw i64 %26, 1
  %33 = icmp eq i64 %32, %15
  br i1 %33, label %23, label %25, !llvm.loop !13
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare void @cq_phi(double noundef) local_unnamed_addr #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
