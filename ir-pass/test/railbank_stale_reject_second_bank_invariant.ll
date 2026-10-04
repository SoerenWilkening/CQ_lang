; railbank_stale_reject_second_bank_invariant.ll — bd `xdu2.1` (Track B,
; session 2026-09-24-railbank-parallel).
;
; TWO banks in one function: `d[]` holds the CAPABILITY (a distinct theta per
; cell, minted inside its walk loop — no later gate can name those wires), and
; `b[]` parks one LOOP-INVARIANT rail `q` that is then relabelled by a 0.7 Ry
; before both banks are read in ONE measure loop.  The fence's memory hop must
; seed each cell load with ITS OWN bank's parked rails: a hop that confused the
; two objects would either miss `b`'s stale read (seeding `d`'s per-cell mints,
; which no gate follows) or over-decline a `d`-only program.  Every shipped F-1
; fixture has exactly one bank, so neither confusion was observable before.
;
; RE-MEASURED 2026-09-24 on `d0720cb1` (`cq-opt` c6f61f80a5d524c6): DECLINES with
; the 3d8q string; red under the hop-disabled source mutant (TRACK_B.md §4).
; Property pinned by the `not` inversion + the verbatim string (Rule 12 (b)).
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, verbatim:
;   __attribute__((noinline)) int slice(int seed) {
;     int q = seed; cq_theta(&q, 0.5);
;     int b[3], d[3]; int s = 0;
;     for (int i = 0; i < 3; ++i) cq_theta(&d[i], 0.2);
;     for (int i = 0; i < 3; ++i) b[i] = q;
;     cq_theta(&q, 0.7);
;     for (int i = 0; i < 3; ++i) s += cq_measure(b[i]) + cq_measure(d[i]);
;     return s + cq_measure(q);
;   }
;   int main(void) { return slice(1); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq opcode lowering: rotation/measure operand predates a non-diagonal gate

source_filename = "s30_fixed_two_banks_one_stale.bank.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [3 x i32], align 4
  %3 = alloca [3 x i32], align 4
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #4
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %2) #4
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %3) #4
  br label %5

5:                                                ; preds = %1, %5
  %6 = phi i64 [ 0, %1 ], [ %10, %5 ]
  %7 = getelementptr inbounds [3 x i32], ptr %3, i64 0, i64 %6
  %8 = load i32, ptr %7, align 4, !tbaa !6
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01) #4
  store i32 %9, ptr %7, align 4, !tbaa !6
  %10 = add nuw nsw i64 %6, 1
  %11 = icmp eq i64 %10, 3
  br i1 %11, label %14, label %5, !llvm.loop !10

12:                                               ; preds = %14
  %13 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 0x3FE6666666666666) #4
  br label %22

14:                                               ; preds = %5, %14
  %15 = phi i64 [ %17, %14 ], [ 0, %5 ]
  %16 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %15
  store i32 %4, ptr %16, align 4, !tbaa !6
  %17 = add nuw nsw i64 %15, 1
  %18 = icmp eq i64 %17, 3
  br i1 %18, label %12, label %14, !llvm.loop !13

19:                                               ; preds = %22
  %20 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  %21 = add nsw i32 %20, %32
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %3) #4
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %2) #4
  ret i32 %21

22:                                               ; preds = %12, %22
  %23 = phi i64 [ 0, %12 ], [ %33, %22 ]
  %24 = phi i32 [ 0, %12 ], [ %32, %22 ]
  %25 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %23
  %26 = load i32, ptr %25, align 4, !tbaa !6
  %27 = tail call i32 @cq_measure_si32(i32 noundef %26) #4
  %28 = getelementptr inbounds [3 x i32], ptr %3, i64 0, i64 %23
  %29 = load i32, ptr %28, align 4, !tbaa !6
  %30 = tail call i32 @cq_measure_si32(i32 noundef %29) #4
  %31 = add i32 %27, %24
  %32 = add i32 %31, %30
  %33 = add nuw nsw i64 %23, 1
  %34 = icmp eq i64 %33, 3
  br i1 %34, label %19, label %22, !llvm.loop !14
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #3 {
  %1 = tail call i32 @slice(i32 noundef 1)
  ret i32 %1
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

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
