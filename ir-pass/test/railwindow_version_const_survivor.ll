; railwindow_version_const_survivor.ll — ACCEPT (bd `test_C_libtooling-01po.19` S7;
; the S4 round-1 reviewer's probe `p3_init.c`, then refused with "needs S7
; index alias versioning").
;
; `a[i]` (runtime i) is rotated, then `memcpy(a, &v, 4)` overwrites the whole
; array after Q, which S4 splits into per-cell REBIND stores to the CONSTANT
; cells a[0..3]. q[i] vs q[0] is unproven by SCEV, so the window is versioned;
; the aliased copy keeps the CONSTANT cell as the survivor (`q[i]` -> `q[0]` at
; i == 0), so its remaining pairs are constant offsets SCEV proves outright:
; ONE versioning, not a chain. The cells a[1..3] are written after the join (a
; window of its own). The i16 array b needs no versioning.
;
; ANALYTIC TRACE: h = the rail of a[i], Ry(.5).
;   distinct (i != 0): a[i] := h, Ry(.25) on b[i], then a[0] := alloc(1);
;     after the join a[1] := alloc(0), a[2] := alloc(1), a[3] := alloc(0): the
;     memcpy overwrites a[i] too, h is abandoned (never freed, R5).
;   aliased (i == 0): Ry(.25) on b[i], a[0] := alloc(1) (h abandoned), then
;     the same join.
;   b: every cell rebound to 257 after the join (the memset), b[i]'s rotated
;   rail abandoned.
;
; SOURCE (clang -O1, verbatim below; `scratchpad/review_s4B/p3_init.c`):
;   #include <stdbool.h>
;   #include <string.h>
;   #include <stdint.h>
;   int f(int i, int n) {
;     bool a[4] = {0};
;     short b[4] = {0};
;     i &= 3;
;     cq_theta(&a[i], 0.5);
;     cq_theta(&b[i], 0.25);
;     uint32_t v = 0x00010001u;
;     memcpy(a, &v, 4);
;     memset(b, 1, sizeof b);
;     int s = 0;
;     for (int k = 0; k < n && k < 4; k++)
;       s += cq_measure(a[k]) + cq_measure(b[k]);
;     return s;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %filecheck %s --input-file=%t.ll
; RUN: env CQ_RAILWINDOW_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
;
; WIN: CQ_RAILWINDOW_DBG: @f claims %3 cells=i8
; WIN-NEXT: CQ_RAILWINDOW_DBG: version region %.split.split on ((zext i2 (trunc i32 %0 to i2) to i64) + %.rails) != %.rails
; WIN-NOT: CQ_RAILWINDOW_DBG: version region
;
; CHECK-LABEL: define i32 @f(
; CHECK: [[H:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i1(
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[H]], double 5.000000e-01)
; CHECK: br i1 %cq.win.ne, label %[[D:[^,]+]], label %[[AL:[^,]+]], !cq.railwindow.version
; CHECK: {{^}}[[D]]:
; CHECK-NEXT: store i32 [[H]], ptr
; CHECK: call void @cqrt_ry_i16(
; CHECK: call i32 @cqrt_alloc_i1(i1 true)
; CHECK: call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call i32 @cqrt_alloc_i1(i1 true)
; CHECK: call i32 @cqrt_alloc_i1(i1 false)
; CHECK-COUNT-4: call i32 @cqrt_alloc_i16(i16 257)
; CHECK: {{^}}[[AL]]:
; CHECK-NOT: store i32 [[H]],
; CHECK: call void @cqrt_ry_i16(
; CHECK: call i32 @cqrt_alloc_i1(i1 true)
; CHECK: br label

source_filename = "p3_init.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 4
  %4 = alloca [4 x i16], align 8
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #4
  store i32 0, ptr %3, align 4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #4
  store i64 0, ptr %4, align 8
  %5 = and i32 %0, 3
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %6
  %8 = load i8, ptr %7, align 1, !tbaa !6, !range !10, !noundef !11
  %9 = trunc nuw i8 %8 to i1
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %9, double noundef 5.000000e-01) #5
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %7, align 1, !tbaa !6
  %12 = getelementptr inbounds [4 x i16], ptr %4, i64 0, i64 %6
  %13 = load i16, ptr %12, align 2, !tbaa !12
  %14 = tail call signext i16 @cq_theta_si16(i16 noundef signext %13, double noundef 2.500000e-01) #5
  store i16 %14, ptr %12, align 2, !tbaa !12
  store i32 65537, ptr %3, align 4
  store i64 72340172838076673, ptr %4, align 8
  %15 = icmp sgt i32 %1, 0
  br i1 %15, label %16, label %21

16:                                               ; preds = %2
  %17 = add nsw i32 %1, -1
  %18 = tail call i32 @llvm.umin.i32(i32 %17, i32 3)
  %19 = add nuw nsw i32 %18, 1
  %20 = zext nneg i32 %19 to i64
  br label %23

21:                                               ; preds = %23, %2
  %22 = phi i32 [ 0, %2 ], [ %36, %23 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #4
  ret i32 %22

23:                                               ; preds = %16, %23
  %24 = phi i64 [ 0, %16 ], [ %37, %23 ]
  %25 = phi i32 [ 0, %16 ], [ %36, %23 ]
  %26 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %24
  %27 = load i8, ptr %26, align 1, !tbaa !6, !range !10, !noundef !11
  %28 = trunc nuw i8 %27 to i1
  %29 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %28) #4
  %30 = zext i1 %29 to i32
  %31 = getelementptr inbounds [4 x i16], ptr %4, i64 0, i64 %24
  %32 = load i16, ptr %31, align 2, !tbaa !12
  %33 = tail call signext i16 @cq_measure_si16(i16 noundef signext %32) #4
  %34 = sext i16 %33 to i32
  %35 = add i32 %25, %30
  %36 = add i32 %35, %34
  %37 = add nuw nsw i64 %24, 1
  %38 = icmp eq i64 %37, %20
  br i1 %38, label %21, label %23, !llvm.loop !14
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare signext i16 @cq_theta_si16(i16 noundef signext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

declare signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!12 = !{!13, !13, i64 0}
!13 = !{!"short", !8, i64 0}
!14 = distinct !{!14, !15, !16}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{!"llvm.loop.unroll.disable"}
