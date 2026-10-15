; railwindow_version_trip_bound_probe.ll — ADVERSARIAL distinctness probe (bd `test_C_libtooling-01po.19` S7;
; bd memory `scev-vacuous-trip-bounds`).
;
; The pair q[k] vs q[40] inside a shift-until-zero loop. In @bounded `x >>= 1`
; runs at most 32 trips (k <= 31 < 40): SCEV's trip bound is REAL and proves
; the pair distinct (no versioning). In @unbounded the shift amount s is a
; runtime value (s == 0 never shifts x to zero; `k < 64` is the only exit), so
; k reaches 40: no bound, the pair is versioned. A recognizer that gave the
; runtime-shift loop the 32-trip "type width" bound would leave @unbounded
; unversioned. (A shift amount >= the width is UB in C, out of scope.)
;
; SOURCE (clang -O1, verbatim below):
;   __attribute__((noinline)) int unbounded(unsigned v, unsigned s) {
;     bool q[64] = {0};
;     unsigned k = 0;
;     for (unsigned x = v; x && k < 64; x >>= s, k++) {
;       cq_theta(&q[k], .3);
;       cq_theta(&q[40], .5);
;     }
;     int r = 0;
;     for (int i = 0; i < 4; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;   __attribute__((noinline)) int bounded(unsigned v) {
;     ... the same body with `x >>= 1` and no `k < 64` ...
;   }
;   int main(int argc, char **argv) { (void)argv; return unbounded((unsigned)argc, 0) + bounded((unsigned)argc); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null
; RUN: env CQ_RAILWINDOW_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; WIN: CQ_RAILWINDOW_DBG: @unbounded claims
; WIN-NEXT: CQ_RAILWINDOW_DBG: version region %10 on {%.rails,+,1}<nw><%10> != (40 + %.rails)<nuw>
; WIN-NOT: CQ_RAILWINDOW_DBG: version region
; WIN: CQ_RAILWINDOW_DBG: @bounded claims
; WIN-NOT: CQ_RAILWINDOW_DBG: version region

source_filename = "shiftboth.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @unbounded(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [64 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %3) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(64) %3, i8 0, i64 64, i1 false)
  %4 = icmp eq i32 %0, 0
  br i1 %4, label %5, label %6

5:                                                ; preds = %8, %2
  br label %26

6:                                                ; preds = %2
  %7 = getelementptr inbounds i8, ptr %3, i64 40
  br label %8

8:                                                ; preds = %6, %8
  %9 = phi i64 [ 0, %6 ], [ %21, %8 ]
  %10 = phi i32 [ %0, %6 ], [ %20, %8 ]
  %11 = getelementptr inbounds [64 x i8], ptr %3, i64 0, i64 %9
  %12 = load i8, ptr %11, align 1, !tbaa !6, !range !10, !noundef !11
  %13 = trunc nuw i8 %12 to i1
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %13, double noundef 3.000000e-01) #7
  %15 = zext i1 %14 to i8
  store i8 %15, ptr %11, align 1, !tbaa !6
  %16 = load i8, ptr %7, align 8, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %17, double noundef 5.000000e-01) #7
  %19 = zext i1 %18 to i8
  store i8 %19, ptr %7, align 8, !tbaa !6
  %20 = lshr i32 %10, %1
  %21 = add nuw nsw i64 %9, 1
  %22 = icmp ne i32 %20, 0
  %23 = icmp ult i64 %9, 63
  %24 = and i1 %22, %23
  br i1 %24, label %8, label %5, !llvm.loop !12

25:                                               ; preds = %26
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %3) #6
  ret i32 %35

26:                                               ; preds = %5, %26
  %27 = phi i64 [ %36, %26 ], [ 0, %5 ]
  %28 = phi i32 [ %35, %26 ], [ 0, %5 ]
  %29 = shl nsw i32 %28, 1
  %30 = getelementptr inbounds [64 x i8], ptr %3, i64 0, i64 %27
  %31 = load i8, ptr %30, align 1, !tbaa !6, !range !10, !noundef !11
  %32 = trunc nuw i8 %31 to i1
  %33 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %32) #6
  %34 = zext i1 %33 to i32
  %35 = or disjoint i32 %29, %34
  %36 = add nuw nsw i64 %27, 1
  %37 = icmp eq i64 %36, 4
  br i1 %37, label %25, label %26, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

; Function Attrs: noinline nounwind ssp uwtable
define i32 @bounded(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [64 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %2) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(64) %2, i8 0, i64 64, i1 false)
  %3 = icmp eq i32 %0, 0
  br i1 %3, label %4, label %5

4:                                                ; preds = %9, %1
  br label %25

5:                                                ; preds = %1
  %6 = getelementptr inbounds i8, ptr %2, i64 40
  %7 = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %0, i1 true)
  %8 = sub nuw nsw i32 32, %7
  br label %9

9:                                                ; preds = %5, %9
  %10 = phi i64 [ 0, %5 ], [ %21, %9 ]
  %11 = phi i32 [ %8, %5 ], [ %22, %9 ]
  %12 = getelementptr inbounds [64 x i8], ptr %2, i64 0, i64 %10
  %13 = load i8, ptr %12, align 1, !tbaa !6, !range !10, !noundef !11
  %14 = trunc nuw i8 %13 to i1
  %15 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %14, double noundef 3.000000e-01) #7
  %16 = zext i1 %15 to i8
  store i8 %16, ptr %12, align 1, !tbaa !6
  %17 = load i8, ptr %6, align 8, !tbaa !6, !range !10, !noundef !11
  %18 = trunc nuw i8 %17 to i1
  %19 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %18, double noundef 5.000000e-01) #7
  %20 = zext i1 %19 to i8
  store i8 %20, ptr %6, align 8, !tbaa !6
  %21 = add nuw nsw i64 %10, 1
  %22 = add nsw i32 %11, -1
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %4, label %9, !llvm.loop !16

24:                                               ; preds = %25
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %2) #6
  ret i32 %34

25:                                               ; preds = %4, %25
  %26 = phi i64 [ %35, %25 ], [ 0, %4 ]
  %27 = phi i32 [ %34, %25 ], [ 0, %4 ]
  %28 = shl nsw i32 %27, 1
  %29 = getelementptr inbounds [64 x i8], ptr %2, i64 0, i64 %26
  %30 = load i8, ptr %29, align 1, !tbaa !6, !range !10, !noundef !11
  %31 = trunc nuw i8 %30 to i1
  %32 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %31) #6
  %33 = zext i1 %32 to i32
  %34 = or disjoint i32 %28, %33
  %35 = add nuw nsw i64 %26, 1
  %36 = icmp eq i64 %35, 4
  br i1 %36, label %24, label %25, !llvm.loop !17
}

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #4 {
  %3 = tail call i32 @unbounded(i32 noundef %0, i32 noundef 0)
  %4 = tail call i32 @bounded(i32 noundef %0)
  %5 = add nsw i32 %4, %3
  ret i32 %5
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.ctlz.i32(i32, i1 immarg) #5

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
!17 = distinct !{!17, !13, !14}
