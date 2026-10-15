; railwindow_version_bound_3class_accept.ll — ACCEPT (bd `test_C_libtooling-01po.19` S7,
; ruling `ruling-01po19-s7-version-bound-2026-10-15`: copies of one ORIGINAL
; window <= 8).
;
; Three runtime indices a, b, c in ONE window (the final `q[a]` access keeps
; the three classes in one versioned stretch), every pair unproven by SCEV.
; Each copy of a versioned window is a window of its own, and a later pair is
; versioned only inside the copy where it is still unproven, so the copies are
; exactly the consistent alias partitions: Bell(3) = 5 copies, 4 versionings.
;
; ANALYTIC TRACE per copy (h = the rail of q[a], Ry(.1) on |0> before the walk;
; then Ry(.2) on q[b], Ry(.3) on q[c], Ry(.5) on q[a]):
;   a,b,c distinct : Ry(.2) cell b, Ry(.3) cell c, Ry(.5) h.
;   b == c != a    : Ry(.2), Ry(.3) on cell b; Ry(.5) h.
;   a == c != b    : Ry(.2) cell b; Ry(.3), Ry(.5) on h.
;   a == b != c    : Ry(.2) on h, Ry(.3) cell c, Ry(.5) on h.
;   a == b == c    : Ry(.2), Ry(.3), Ry(.5) all on h.
; Pinned: four versionings, no fifth, and the all-aliased copy's three gates on
; h (the copy whose correctness depends on both merges).
;
; SOURCE (clang -O1, verbatim below):
;   __attribute__((noinline)) int f(int a, int b, int c) {
;     bool q[4] = {0};
;     a &= 3; b &= 3; c &= 3;
;     cq_theta(&q[a], .1); cq_theta(&q[b], .2); cq_theta(&q[c], .3);
;     cq_theta(&q[a], .5);
;     int r = 0;
;     for (int k = 0; k < 4; k++) r = 2 * r + cq_measure(q[k]);
;     return r;
;   }
;   int main(int argc, char **argv) { (void)argv; return f(argc, argc + 1, argc + 2); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %filecheck %s --input-file=%t.ll
; RUN: env CQ_RAILWINDOW_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
;
; WIN: CQ_RAILWINDOW_DBG: @f claims
; WIN-COUNT-4: CQ_RAILWINDOW_DBG: version region
; WIN-NOT: CQ_RAILWINDOW_DBG: version region
; WIN: CQ_RAILWINDOW_DBG: promoted
;
; CHECK-LABEL: define i32 @f(
; CHECK: [[H:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i1(
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[H]], double 1.000000e-01)
; CHECK-COUNT-4: !cq.railwindow.version
; The all-aliased copy (the aliased copy of the a == b copy, by the clone
; suffixes): every gate on h, in source order.
; CHECK: {{^}}.split.split.split.cq.alias.split.cq.alias:
; CHECK-NOT: {{^}}{{[.a-z0-9]+}}:
; CHECK: call void @cqrt_ry_i1(i32 [[H]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[H]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[H]], double 5.000000e-01)

source_filename = "bound3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #4
  store i32 0, ptr %4, align 4
  %5 = and i32 %0, 3
  %6 = and i32 %1, 3
  %7 = and i32 %2, 3
  %8 = zext nneg i32 %5 to i64
  %9 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %8
  %10 = load i8, ptr %9, align 1, !tbaa !6, !range !10, !noundef !11
  %11 = trunc nuw i8 %10 to i1
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef 1.000000e-01) #5
  %13 = zext i1 %12 to i8
  store i8 %13, ptr %9, align 1, !tbaa !6
  %14 = zext nneg i32 %6 to i64
  %15 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %14
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %17, double noundef 2.000000e-01) #5
  %19 = zext i1 %18 to i8
  store i8 %19, ptr %15, align 1, !tbaa !6
  %20 = zext nneg i32 %7 to i64
  %21 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %20
  %22 = load i8, ptr %21, align 1, !tbaa !6, !range !10, !noundef !11
  %23 = trunc nuw i8 %22 to i1
  %24 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %23, double noundef 3.000000e-01) #5
  %25 = zext i1 %24 to i8
  store i8 %25, ptr %21, align 1, !tbaa !6
  %26 = load i8, ptr %9, align 1, !tbaa !6, !range !10, !noundef !11
  %27 = trunc nuw i8 %26 to i1
  %28 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %27, double noundef 5.000000e-01) #5
  %29 = zext i1 %28 to i8
  store i8 %29, ptr %9, align 1, !tbaa !6
  br label %31

30:                                               ; preds = %31
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #4
  ret i32 %40

31:                                               ; preds = %3, %31
  %32 = phi i64 [ 0, %3 ], [ %41, %31 ]
  %33 = phi i32 [ 0, %3 ], [ %40, %31 ]
  %34 = shl nsw i32 %33, 1
  %35 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %32
  %36 = load i8, ptr %35, align 1, !tbaa !6, !range !10, !noundef !11
  %37 = trunc nuw i8 %36 to i1
  %38 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %37) #4
  %39 = zext i1 %38 to i32
  %40 = or disjoint i32 %34, %39
  %41 = add nuw nsw i64 %32, 1
  %42 = icmp eq i64 %41, 4
  br i1 %42, label %30, label %31, !llvm.loop !12
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
  %4 = add nsw i32 %0, 2
  %5 = tail call i32 @f(i32 noundef %0, i32 noundef %3, i32 noundef %4)
  ret i32 %5
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
