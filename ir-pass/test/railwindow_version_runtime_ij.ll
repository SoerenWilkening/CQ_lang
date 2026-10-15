; railwindow_version_runtime_ij.ll — ACCEPT (bd `test_C_libtooling-01po.19` S7,
; owner ruling `owner-ruling-01po19-rolled-design-2026-10-15` Q2 (a)).
;
; Two in-place rotations through RUNTIME indices `q[i]`, `q[j]` (i, j masked to
; 0..3). SCEV cannot prove `&q[i] != &q[j]`, so S7 VERSIONS the window on the
; classical test of the two cell offsets: the guard branch carries
; `!cq.railwindow.version`, the original stretch is the DISTINCT copy and its
; clone the ALIASED copy, where both classes name ONE cell.
;
; ANALYTIC TRACE (both copies; h = the rail minted for q[i] by Ry(.3) on |0>):
;   distinct (i != j): Ry(.3) on h = cell i, Ry(.5) on cell j's own rail:
;     q[i] = Ry(.3)|0>, q[j] = Ry(.5)|0>, product state.
;   aliased  (i == j): Ry(.3) then Ry(.5) on h: q[i] = Ry(.8)|0>, which is
;     what C says (`cq_theta(&q[i], .3); cq_theta(&q[i], .5)`).
; Pinned below: both copies, the guard, and that the aliased copy rotates h
; itself (no second rail is read there).
;
; SOURCE (clang -O1, verbatim below):
;   __attribute__((noinline)) int f(int i, int j) {
;     bool q[4] = {0};
;     i &= 3; j &= 3;
;     cq_theta(&q[i], .3);
;     cq_theta(&q[j], .5);
;     int r = 0;
;     for (int k = 0; k < 4; k++) r = 2 * r + cq_measure(q[k]);
;     return r;
;   }
;   int main(int argc, char **argv) { (void)argv; return f(argc, argc + 1); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %filecheck %s --input-file=%t.ll
; RUN: env CQ_RAILWINDOW_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
;
; WIN: CQ_RAILWINDOW_DBG: @f claims
; WIN: CQ_RAILWINDOW_DBG: version region
; WIN-NOT: CQ_RAILWINDOW_DBG: version region
; WIN: CQ_RAILWINDOW_DBG: promoted
;
; CHECK-LABEL: define i32 @f(
; CHECK: [[H:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i1(
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[H]], double 3.000000e-01)
; CHECK: %cq.win.ne = icmp ne ptr
; CHECK-NEXT: br i1 %cq.win.ne, label %[[D:[^,]+]], label %[[AL:[^,]+]], !cq.railwindow.version
; CHECK: {{^}}[[D]]:
; CHECK-NEXT: store i32 [[H]], ptr
; CHECK-NEXT: [[RJ:%[a-z0-9.]+]] = load i32, ptr
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[RJ]], double 5.000000e-01)
; CHECK: {{^}}[[AL]]:
; CHECK-NOT: cqrt_ry_i1
; CHECK: call void @cqrt_ry_i1(i32 [[H]], double 5.000000e-01)
; CHECK-NEXT: store i32 [[H]], ptr

source_filename = "rt_ij.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #4
  store i32 0, ptr %3, align 4
  %4 = and i32 %0, 3
  %5 = and i32 %1, 3
  %6 = zext nneg i32 %4 to i64
  %7 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %6
  %8 = load i8, ptr %7, align 1, !tbaa !6, !range !10, !noundef !11
  %9 = trunc nuw i8 %8 to i1
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %9, double noundef 3.000000e-01) #5
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %7, align 1, !tbaa !6
  %12 = zext nneg i32 %5 to i64
  %13 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %12
  %14 = load i8, ptr %13, align 1, !tbaa !6, !range !10, !noundef !11
  %15 = trunc nuw i8 %14 to i1
  %16 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %15, double noundef 5.000000e-01) #5
  %17 = zext i1 %16 to i8
  store i8 %17, ptr %13, align 1, !tbaa !6
  br label %19

18:                                               ; preds = %19
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #4
  ret i32 %28

19:                                               ; preds = %2, %19
  %20 = phi i64 [ 0, %2 ], [ %29, %19 ]
  %21 = phi i32 [ 0, %2 ], [ %28, %19 ]
  %22 = shl nsw i32 %21, 1
  %23 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %20
  %24 = load i8, ptr %23, align 1, !tbaa !6, !range !10, !noundef !11
  %25 = trunc nuw i8 %24 to i1
  %26 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %25) #4
  %27 = zext i1 %26 to i32
  %28 = or disjoint i32 %22, %27
  %29 = add nuw nsw i64 %20, 1
  %30 = icmp eq i64 %29, 4
  br i1 %30, label %18, label %19, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %0, 1
  %4 = tail call i32 @f(i32 noundef %0, i32 noundef %3)
  ret i32 %4
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

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
