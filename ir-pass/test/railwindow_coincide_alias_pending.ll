; railwindow_coincide_alias_pending.ll — ACCEPT (bd `test_C_libtooling-01po.19` S5 + S7; the
; file name is history: it declined pending S5/S7 until both landed).
;
; ADVERSARIAL alias probe: `q[i] ^= q[2-i]` names one cell twice at i == 1. SCEV
; cannot prove the two addresses distinct, so S7 (owner Q2 (a)) VERSIONS the
; window on the classical test of the two cell offsets (`%cq.win.ne`, branch
; tagged `!cq.railwindow.version`):
;   * DISTINCT copy (i != 2-i): S5's in-place CNOT, control cell[2-i], target
;     cell[i] (the target keeps its handle);
;   * ALIASED copy (i == 1): both classes name one cell, S3 promotes ONE name,
;     `x ^= x` reads `icmp ne v, v`, InstSimplify folds it to the classical
;     `false`, and the store is S4's REBIND `cqrt_alloc_i1(0)` (Q3; the old rail
;     abandoned, never reset or measured).
;
; ANALYTIC TRACE (h0, h1, h2 = the cells' rails after Ry(.4), Ry(.5), Ry(.6)):
;   i = 0 (distinct): CNOT(h2 -> h0)        q[0] = x0 ^ x2
;   i = 1 (aliased) : q[1] := alloc(0)      q[1] = 0, h1 abandoned (C: x ^= x)
;   i = 2 (distinct): CNOT(h0 -> h2)        q[2] = x2 ^ (x0 ^ x2) = x0
; which is exactly C's sequential semantics of the three updates.
;
; SOURCE (clang -O1, verbatim below):
;   /* adversarial: two indices that coincide on one trip (i == 2-i at i == 1):
;      q[1] ^= q[1] is x ^= x, i.e. q[1] = 0 with its old rail discarded. */
;   int main(void) {
;     bool q[3] = {0};
;     for (int i = 0; i < 3; i++) cq_theta(&q[i], .4 + .1 * i);
;     for (int i = 0; i < 3; i++) q[i] ^= q[2 - i];
;     int r = 0;
;     for (int i = 0; i < 3; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %filecheck %s --input-file=%t.ll
; RUN: env CQ_RAILWINDOW_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; WIN: CQ_RAILWINDOW_DBG: @main claims %1 cells=i8 loads=4 stores=2 Q=  br label %2
; WIN: CQ_RAILWINDOW_DBG: version region %13 on {(2 + %.rails)<nuw>,+,-1}<nw><%13> != {%.rails,+,1}<nw><%13>
; WIN-NOT: CQ_RAILWINDOW_DBG: version region
;
; CHECK-LABEL: define i32 @main(
; CHECK: [[SRC:%[a-z0-9.]+]] = getelementptr i32, ptr %.rails, i64 %14
; CHECK: br i1 %cq.win.ne, label %[[D:[^,]+]], label %[[AL:[^,]+]], !cq.railwindow.version
; CHECK: {{^}}[[D]]:
; CHECK-NEXT: [[C:%[a-z0-9.]+]] = load i32, ptr [[SRC]],
; CHECK-NEXT: [[T:%[a-z0-9.]+]] = load i32, ptr
; CHECK-NEXT: call void @cqrt_cnot(i32 [[C]], i32 [[T]])
; CHECK-NEXT: store i32 [[T]], ptr
; CHECK: {{^}}[[AL]]:
; CHECK-NEXT: [[Z:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: store i32 [[Z]], ptr [[SRC]],
; CHECK-NEXT: br label

; ModuleID = 'coincide.c'
source_filename = "coincide.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %12, %2 ]
  %4 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = trunc nuw nsw i64 %3 to i32
  %8 = uitofp nneg i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %8, double 1.000000e-01, double 4.000000e-01)
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef %9) #6
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %4, align 1, !tbaa !6
  %12 = add nuw nsw i64 %3, 1
  %13 = icmp eq i64 %12, 3
  br i1 %13, label %14, label %2, !llvm.loop !12

14:                                               ; preds = %2, %14
  %15 = phi i64 [ %23, %14 ], [ 0, %2 ]
  %16 = sub nuw nsw i64 2, %15
  %17 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %16
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !10, !noundef !11
  %19 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %15
  %20 = load i8, ptr %19, align 1, !tbaa !6, !range !10, !noundef !11
  %21 = icmp ne i8 %20, %18
  %22 = zext i1 %21 to i8
  store i8 %22, ptr %19, align 1, !tbaa !6
  %23 = add nuw nsw i64 %15, 1
  %24 = icmp eq i64 %23, 3
  br i1 %24, label %26, label %14, !llvm.loop !15

25:                                               ; preds = %26
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #5
  ret i32 %35

26:                                               ; preds = %14, %26
  %27 = phi i64 [ %36, %26 ], [ 0, %14 ]
  %28 = phi i32 [ %35, %26 ], [ 0, %14 ]
  %29 = shl nsw i32 %28, 1
  %30 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %27
  %31 = load i8, ptr %30, align 1, !tbaa !6, !range !10, !noundef !11
  %32 = trunc nuw i8 %31 to i1
  %33 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %32) #5
  %34 = zext i1 %33 to i32
  %35 = or disjoint i32 %29, %34
  %36 = add nuw nsw i64 %27, 1
  %37 = icmp eq i64 %36, 3
  br i1 %37, label %25, label %26, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
