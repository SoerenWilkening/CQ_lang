; railbank_stale_reject_condprep_beside_invariant_park.ll — bd `xdu2.1` (Track B,
; session 2026-09-24-railbank-parallel).
;
; The bd `xdu2.4` CONDITIONAL-PREP bank (`if (Z >= 2) cq_theta(&b[i], .5);
; if (b[i]) Z -= 2;` — the owner's `example/grover/main.c` shape, whose store
; value after promotion is a MERGE phi `[theta, %cq.bank.seed]`) sitting BESIDE a
; second runtime bank `d[]` that parks one loop-invariant rail `q`, relabelled
; by a 0.7 Ry before both banks are measured.  The conditional bank is the one
; the fence's leg-2 comment said would retire its "seed def re-executes the
; store" coincidence; this module asks the fence to decline the STALE bank
; while a conditional bank is present in the same function — the conditional
; bank alone is a shipped accept (matrix row 15 of
; `railbank_dynamic_matrix.c`, and row `h04` of `railbank_stale_matrix.c`).
;
; RE-MEASURED 2026-09-24 on `d0720cb1` (`cq-opt` c6f61f80a5d524c6): DECLINES with
; the 3d8q string; red under the hop-disabled source mutant (TRACK_B.md §4).
; Property pinned by the `not` inversion + the verbatim string (Rule 12 (b)).
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, verbatim:
;   __attribute__((noinline)) static int slice(int n) {
;     if (n <= 0) return 0;
;     int b[n]; int Z = 4 * n; int s = 0;
;     int q = n; cq_theta(&q, 0.3); int d[n];
;     for (int i = 0; i < n; ++i) { if (Z >= 2) cq_theta(&b[i], 0.5); if (b[i]) Z -= 2; }
;     for (int i = 0; i < n; ++i) d[i] = q;
;     cq_theta(&q, 0.7);
;     for (int i = 0; i < n; ++i) s += cq_measure(b[i]) + cq_measure(d[i]);
;     return s + cq_measure(q) + cq_measure(Z);
;   }
;   int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq opcode lowering: rotation/measure operand predates a non-diagonal gate

source_filename = "h06_condprep_plus_invariant_stale.bank.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, 2
  %4 = tail call fastcc i32 @slice(i32 noundef %3)
  ret i32 %4
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0) unnamed_addr #1 {
  %2 = icmp slt i32 %0, 1
  br i1 %2, label %56, label %3

3:                                                ; preds = %1
  %4 = zext nneg i32 %0 to i64
  %5 = tail call ptr @llvm.stacksave.p0()
  %6 = alloca i32, i64 %4, align 16
  %7 = shl nsw i32 %0, 2
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #5
  %9 = alloca i32, i64 %4, align 16
  %10 = zext nneg i32 %0 to i64
  br label %13

11:                                               ; preds = %21
  %12 = zext nneg i32 %0 to i64
  br label %33

13:                                               ; preds = %3, %21
  %14 = phi i64 [ 0, %3 ], [ %27, %21 ]
  %15 = phi i32 [ %7, %3 ], [ %26, %21 ]
  %16 = icmp sgt i32 %15, 1
  br i1 %16, label %17, label %21

17:                                               ; preds = %13
  %18 = getelementptr inbounds i32, ptr %6, i64 %14
  %19 = load i32, ptr %18, align 4, !tbaa !6
  %20 = tail call i32 @cq_theta_si32(i32 noundef %19, double noundef 5.000000e-01) #5
  store i32 %20, ptr %18, align 4, !tbaa !6
  br label %21

21:                                               ; preds = %17, %13
  %22 = getelementptr inbounds i32, ptr %6, i64 %14
  %23 = load i32, ptr %22, align 4, !tbaa !6
  %24 = icmp eq i32 %23, 0
  %25 = add nsw i32 %15, -2
  %26 = select i1 %24, i32 %15, i32 %25
  %27 = add nuw nsw i64 %14, 1
  %28 = icmp eq i64 %27, %10
  br i1 %28, label %11, label %13, !llvm.loop !10

29:                                               ; preds = %33
  %30 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 0x3FE6666666666666) #5
  %31 = tail call i32 @llvm.smax.i32(i32 %0, i32 1)
  %32 = zext nneg i32 %31 to i64
  br label %43

33:                                               ; preds = %11, %33
  %34 = phi i64 [ 0, %11 ], [ %36, %33 ]
  %35 = getelementptr inbounds i32, ptr %9, i64 %34
  store i32 %8, ptr %35, align 4, !tbaa !6
  %36 = add nuw nsw i64 %34, 1
  %37 = icmp eq i64 %36, %12
  br i1 %37, label %29, label %33, !llvm.loop !13

38:                                               ; preds = %43
  %39 = tail call i32 @cq_measure_si32(i32 noundef %30) #5
  %40 = add nsw i32 %39, %53
  %41 = tail call i32 @cq_measure_si32(i32 noundef %26) #5
  %42 = add nsw i32 %40, %41
  tail call void @llvm.stackrestore.p0(ptr %5)
  br label %56

43:                                               ; preds = %29, %43
  %44 = phi i64 [ 0, %29 ], [ %54, %43 ]
  %45 = phi i32 [ 0, %29 ], [ %53, %43 ]
  %46 = getelementptr inbounds i32, ptr %6, i64 %44
  %47 = load i32, ptr %46, align 4, !tbaa !6
  %48 = tail call i32 @cq_measure_si32(i32 noundef %47) #5
  %49 = getelementptr inbounds i32, ptr %9, i64 %44
  %50 = load i32, ptr %49, align 4, !tbaa !6
  %51 = tail call i32 @cq_measure_si32(i32 noundef %50) #5
  %52 = add i32 %48, %45
  %53 = add i32 %52, %51
  %54 = add nuw nsw i64 %44, 1
  %55 = icmp eq i64 %54, %32
  br i1 %55, label %38, label %43, !llvm.loop !14

56:                                               ; preds = %1, %38
  %57 = phi i32 [ %42, %38 ], [ 0, %1 ]
  ret i32 %57
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
!14 = distinct !{!14, !11, !12}
