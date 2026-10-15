; railwindow_version_bound_8copies_accept.ll — ACCEPT AT THE BOUND (bd
; `test_C_libtooling-01po.19` S7, ruling `ruling-01po19-s7-version-bound-2026-10-15`:
; copies of one ORIGINAL window <= 8, counted across all its copies).
;
; Classes q[a], q[0], q[b], q[b+2] (a, b runtime in 0..3) in one window (the
; final `q[a]` keeps them in one versioned stretch). SCEV proves only
; q[b] != q[b+2]; the aliased copies prefer the CONSTANT cell as survivor.
; Measured on this mechanism: 7 versionings = EXACTLY 8 copies, accepted. The
; twin `railwindow_reject_version_blowup.ll` (q[a], q[b], q[0], q[b+1]) needs
; 8 versionings = 9 copies and is loud: together they pin the bound at 8 from
; both sides (an off-by-one bound in either direction flips one of them).
;
; Each copy is a straight-line sequence of in-place Ry gates on the cells its
; alias partition names (one rail per cell, every gate in source order); the
; per-copy reading is the same as railwindow_version_bound_3class_accept.ll.
;
; SOURCE (clang -O1, verbatim below):
;   __attribute__((noinline)) int f(int a, int b, int c, int d) {
;     bool q[16] = {0};
;     a &= 3; b &= 3; c &= 3; d &= 3;
;     cq_theta(&q[a], .1); cq_theta(&q[0], .2); cq_theta(&q[b], .3);
;     cq_theta(&q[b+2], .4); cq_theta(&q[a], .9);
;     int r = 0;
;     for (int k = 0; k < 16; k++) r = 2 * r + cq_measure(q[k]);
;     return r;
;   }
;   int main(int argc, char **argv) { (void)argv; return f(argc, argc + 1, argc + 2, argc + 3); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null
; RUN: env CQ_RAILWINDOW_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
;
; WIN: CQ_RAILWINDOW_DBG: @f claims
; WIN-COUNT-7: CQ_RAILWINDOW_DBG: version region
; WIN-NOT: CQ_RAILWINDOW_DBG: version region
; WIN: CQ_RAILWINDOW_DBG: promoted

source_filename = "sh_a_0_b_b_2_.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1, i32 %2, i32 %3) local_unnamed_addr #0 {
  %5 = alloca [16 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %5, i8 0, i64 16, i1 false)
  %6 = and i32 %0, 3
  %7 = and i32 %1, 3
  %8 = zext nneg i32 %6 to i64
  %9 = getelementptr inbounds [16 x i8], ptr %5, i64 0, i64 %8
  %10 = load i8, ptr %9, align 1, !tbaa !6, !range !10, !noundef !11
  %11 = trunc nuw i8 %10 to i1
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef 1.000000e-01) #6
  %13 = zext i1 %12 to i8
  store i8 %13, ptr %9, align 1, !tbaa !6
  %14 = load i8, ptr %5, align 16, !tbaa !6, !range !10, !noundef !11
  %15 = trunc nuw i8 %14 to i1
  %16 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %15, double noundef 2.000000e-01) #6
  %17 = zext i1 %16 to i8
  store i8 %17, ptr %5, align 16, !tbaa !6
  %18 = zext nneg i32 %7 to i64
  %19 = getelementptr inbounds [16 x i8], ptr %5, i64 0, i64 %18
  %20 = load i8, ptr %19, align 1, !tbaa !6, !range !10, !noundef !11
  %21 = trunc nuw i8 %20 to i1
  %22 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %21, double noundef 3.000000e-01) #6
  %23 = zext i1 %22 to i8
  store i8 %23, ptr %19, align 1, !tbaa !6
  %24 = add nuw nsw i32 %7, 2
  %25 = zext nneg i32 %24 to i64
  %26 = getelementptr inbounds [16 x i8], ptr %5, i64 0, i64 %25
  %27 = load i8, ptr %26, align 1, !tbaa !6, !range !10, !noundef !11
  %28 = trunc nuw i8 %27 to i1
  %29 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %28, double noundef 4.000000e-01) #6
  %30 = zext i1 %29 to i8
  store i8 %30, ptr %26, align 1, !tbaa !6
  %31 = load i8, ptr %9, align 1, !tbaa !6, !range !10, !noundef !11
  %32 = trunc nuw i8 %31 to i1
  %33 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %32, double noundef 9.000000e-01) #6
  %34 = zext i1 %33 to i8
  store i8 %34, ptr %9, align 1, !tbaa !6
  br label %36

35:                                               ; preds = %36
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #5
  ret i32 %45

36:                                               ; preds = %4, %36
  %37 = phi i64 [ 0, %4 ], [ %46, %36 ]
  %38 = phi i32 [ 0, %4 ], [ %45, %36 ]
  %39 = shl nsw i32 %38, 1
  %40 = getelementptr inbounds [16 x i8], ptr %5, i64 0, i64 %37
  %41 = load i8, ptr %40, align 1, !tbaa !6, !range !10, !noundef !11
  %42 = trunc nuw i8 %41 to i1
  %43 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %42) #5
  %44 = zext i1 %43 to i32
  %45 = or disjoint i32 %39, %44
  %46 = add nuw nsw i64 %37, 1
  %47 = icmp eq i64 %46, 16
  br i1 %47, label %35, label %36, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #4 {
  %3 = add nsw i32 %0, 1
  %4 = tail call i32 @f(i32 noundef %0, i32 noundef %3, i32 poison, i32 poison)
  ret i32 %4
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }
attributes #6 = { nomerge nounwind }

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
