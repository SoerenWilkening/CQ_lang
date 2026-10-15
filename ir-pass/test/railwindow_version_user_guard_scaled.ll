; railwindow_version_user_guard_scaled.ll — ACCEPT (bd `test_C_libtooling-01po.19` S7,
; R11 round 1 B-F3, reviewer probe review_s7B/p3_userguard.c).
;
; `if (a * 4ul != j * 4ul) cq_theta(&q[j], .5)` over int cells: -O1 rewrites
; the test to `icmp eq i64 %a, %j` (i64 indices) while the cell addresses
; differ by 4 * (a - j). The user's test is honoured as a cell test when
; K * (ext X - ext Y) == A - B for K = 2^L and the product cannot wrap to 0:
; by the operand width, or by SCEV's signed range of X - Y (here both are
; `& 7`, so |a - j| < 8). Proven at every touch of q[j] (one access, never
; promoted), so NO versioning. An unmasked i64 `i != j` over 4-byte cells
; (K = 4, W = 64, range unknown) is NOT a cell test and is versioned instead.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null
; RUN: env CQ_RAILWINDOW_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; WIN: CQ_RAILWINDOW_DBG: @f claims
; WIN-NOT: CQ_RAILWINDOW_DBG: version region
; WIN: CQ_RAILWINDOW_DBG: promoted
;
; SOURCE (clang -O1, verbatim below):
;   __attribute__((noinline)) int f(unsigned long n, unsigned long i, unsigned long j) {
;     int q[8] = {0};
;     j &= 7;
;     for (unsigned long k = 0; k < n && k < 8; k++) {
;       unsigned long a = (i + k) & 7;
;       cq_theta(&q[a], .3);
;       if (a * 4ul != j * 4ul) cq_theta(&q[j], .5);
;     }
;     int r = 0;
;     for (int k = 0; k < 8; k++) r = 2 * r + cq_measure(q[k]);
;     return r;
;   }
;   int main(int argc, char **argv) { (void)argv; return f(argc + 3, argc, argc + 1); }

source_filename = "rB_p3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i64 noundef %0, i64 noundef %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %4) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %4, i8 0, i64 32, i1 false)
  %5 = and i64 %2, 7
  %6 = tail call i64 @llvm.umin.i64(i64 %0, i64 8)
  %7 = icmp eq i64 %0, 0
  br i1 %7, label %8, label %9

8:                                                ; preds = %22, %3
  br label %26

9:                                                ; preds = %3
  %10 = getelementptr inbounds [8 x i32], ptr %4, i64 0, i64 %5
  br label %11

11:                                               ; preds = %9, %22
  %12 = phi i64 [ 0, %9 ], [ %23, %22 ]
  %13 = add i64 %12, %1
  %14 = and i64 %13, 7
  %15 = getelementptr inbounds [8 x i32], ptr %4, i64 0, i64 %14
  %16 = load i32, ptr %15, align 4, !tbaa !6
  %17 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef 3.000000e-01) #7
  store i32 %17, ptr %15, align 4, !tbaa !6
  %18 = icmp eq i64 %14, %5
  br i1 %18, label %22, label %19

19:                                               ; preds = %11
  %20 = load i32, ptr %10, align 4, !tbaa !6
  %21 = tail call i32 @cq_theta_si32(i32 noundef %20, double noundef 5.000000e-01) #7
  store i32 %21, ptr %10, align 4, !tbaa !6
  br label %22

22:                                               ; preds = %19, %11
  %23 = add nuw nsw i64 %12, 1
  %24 = icmp eq i64 %23, %6
  br i1 %24, label %8, label %11, !llvm.loop !10

25:                                               ; preds = %26
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %4) #6
  ret i32 %33

26:                                               ; preds = %8, %26
  %27 = phi i64 [ %34, %26 ], [ 0, %8 ]
  %28 = phi i32 [ %33, %26 ], [ 0, %8 ]
  %29 = shl nsw i32 %28, 1
  %30 = getelementptr inbounds [8 x i32], ptr %4, i64 0, i64 %27
  %31 = load i32, ptr %30, align 4, !tbaa !6
  %32 = tail call i32 @cq_measure_si32(i32 noundef %31) #6
  %33 = add nsw i32 %32, %29
  %34 = add nuw nsw i64 %27, 1
  %35 = icmp eq i64 %34, 8
  br i1 %35, label %25, label %26, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #4 {
  %3 = add nsw i32 %0, 3
  %4 = sext i32 %3 to i64
  %5 = sext i32 %0 to i64
  %6 = add nsw i32 %0, 1
  %7 = sext i32 %6 to i64
  %8 = tail call i32 @f(i64 noundef %4, i64 noundef %5, i64 noundef %7)
  ret i32 %8
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umin.i64(i64, i64) #5

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #6 = { nounwind }
attributes #7 = { nomerge nounwind }

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
