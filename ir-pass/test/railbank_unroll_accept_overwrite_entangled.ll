; ACCEPT + ADVERSARIAL (bd `test_C_libtooling-01po.19`): a cell holding a LIVE,
; ENTANGLED rail is overwritten.
;
; All four cells are rotated, `q[i+2] ^= q[i]` entangles q2/q3 with q0/q1, then the
; walk `q[i] = 0` overwrites q0 and q1. The store of a new value into a cell that holds a
; rail must be an SSA rebind, never an overwrite that drops a live rail (R7) or a free of
; a dirty one (R5). Pinned: q2' = q0 ^ q2 and q3' = q1 ^ q3 are out-of-place
; `cq_template_xor_i1` rails, the overwritten cells measure as the classical 0, and no
; `cqrt_free` is emitted (the four rotated rails feed the measured xor results and are
; left allocated, never reset).
;
;
; ⚠ L7 RETIREMENT TRIGGER (bd r2j3.33, review round 1 item 7): this file pins the
; OUT-OF-PLACE `cq_template_xor_i1` for an array `^=`, which keeps the old target
; rail live. That is the r2j3.33 population (a later rotation of the control dephases
; it; lane C's dm7f.51 replaces it with an in-place CNOT). When dm7f.51 lands, the
; xor lines below change to the in-place CNOT stream: re-derive them then, with an
; analytic check, and do NOT read this file as evidence the out-of-place form is right.
;
; SOURCE (clang -O1, verbatim below; `f` is inlined into `main`):
;   /* adversarial: overwrite live, ENTANGLED cells. q[i] feeds q[i+2] (CNOT), then the
;      source cells are overwritten with a classical 0 inside a walk. The old rails must
;      not be freed dirty (R5) and q[2..3]'s lineage must not be uncomputed. */
;   int f(void) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .7 + .1 * i);
;     for (int i = 0; i < 2; i++) q[i + 2] ^= q[i];
;     for (int i = 0; i < 2; i++) q[i] = 0;
;     int r = 0;
;     for (int i = 0; i < 4; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;   int main(void) { return f(); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s --implicit-check-not='call {{.*}}@cq'
; CHECK-LABEL: define {{.*}} @f(
; CHECK: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h, double 0x3FE6666666666666)
; CHECK: %[[B:h[0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %[[B]], double 0x3FE9999999999999)
; CHECK: %[[C:h[0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %[[C]], double 0x3FECCCCCCCCCCCCC)
; CHECK: %[[D:h[0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %[[D]], double 1.000000e+00)
; CHECK: %[[X:.+]] = call i32 @cq_template_xor_i1(i32 %h, i32 %[[C]])
; CHECK: %[[Y:.+]] = call i32 @cq_template_xor_i1(i32 %[[B]], i32 %[[D]])
; CHECK: call i1 @cqrt_measure_i1(i32 %[[X]])
; CHECK: call i1 @cqrt_measure_i1(i32 %[[Y]])
; CHECK: ret i32
; `f` is inlined into `main` at -O1, so `main` carries the same stream:
; CHECK-LABEL: define {{.*}} @main(
; CHECK: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h, double 0x3FE6666666666666)
; CHECK: %[[B:h[0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %[[B]], double 0x3FE9999999999999)
; CHECK: %[[C:h[0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %[[C]], double 0x3FECCCCCCCCCCCCC)
; CHECK: %[[D:h[0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %[[D]], double 1.000000e+00)
; CHECK: %[[X:.+]] = call i32 @cq_template_xor_i1(i32 %h, i32 %[[C]])
; CHECK: %[[Y:.+]] = call i32 @cq_template_xor_i1(i32 %[[B]], i32 %[[D]])
; CHECK: call i1 @cqrt_measure_i1(i32 %[[X]])
; CHECK: call i1 @cqrt_measure_i1(i32 %[[Y]])
; CHECK: ret i32
; CHECK-NOT: cqrt_free

; ModuleID = 'overwrite2.c'
source_filename = "overwrite2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #4
  store i32 0, ptr %1, align 4
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %12, %2 ]
  %4 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = trunc nuw nsw i64 %3 to i32
  %8 = uitofp nneg i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %8, double 1.000000e-01, double 0x3FE6666666666666)
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef %9) #5
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %4, align 1, !tbaa !6
  %12 = add nuw nsw i64 %3, 1
  %13 = icmp eq i64 %12, 4
  br i1 %13, label %14, label %2, !llvm.loop !12

14:                                               ; preds = %2, %14
  %15 = phi i64 [ %23, %14 ], [ 0, %2 ]
  %16 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !6, !range !10, !noundef !11
  %18 = or disjoint i64 %15, 2
  %19 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %18
  %20 = load i8, ptr %19, align 1, !tbaa !6, !range !10, !noundef !11
  %21 = icmp ne i8 %20, %17
  %22 = zext i1 %21 to i8
  store i8 %22, ptr %19, align 1, !tbaa !6
  %23 = add nuw nsw i64 %15, 1
  %24 = icmp eq i64 %15, 0
  br i1 %24, label %14, label %25, !llvm.loop !15

25:                                               ; preds = %14
  store i16 0, ptr %1, align 4
  br label %27

26:                                               ; preds = %27
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #4
  ret i32 %36

27:                                               ; preds = %25, %27
  %28 = phi i64 [ 0, %25 ], [ %37, %27 ]
  %29 = phi i32 [ 0, %25 ], [ %36, %27 ]
  %30 = shl nsw i32 %29, 1
  %31 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %28
  %32 = load i8, ptr %31, align 1, !tbaa !6, !range !10, !noundef !11
  %33 = trunc nuw i8 %32 to i1
  %34 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %33) #4
  %35 = zext i1 %34 to i32
  %36 = or disjoint i32 %30, %35
  %37 = add nuw nsw i64 %28, 1
  %38 = icmp eq i64 %37, 4
  br i1 %38, label %26, label %27, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #4
  store i32 0, ptr %1, align 4
  br label %2

2:                                                ; preds = %2, %0
  %3 = phi i64 [ 0, %0 ], [ %12, %2 ]
  %4 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = trunc nuw nsw i64 %3 to i32
  %8 = uitofp nneg i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %8, double 1.000000e-01, double 0x3FE6666666666666)
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef %9) #5
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %4, align 1, !tbaa !6
  %12 = add nuw nsw i64 %3, 1
  %13 = icmp eq i64 %12, 4
  br i1 %13, label %14, label %2, !llvm.loop !12

14:                                               ; preds = %2, %14
  %15 = phi i64 [ %23, %14 ], [ 0, %2 ]
  %16 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !6, !range !10, !noundef !11
  %18 = or disjoint i64 %15, 2
  %19 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %18
  %20 = load i8, ptr %19, align 1, !tbaa !6, !range !10, !noundef !11
  %21 = icmp ne i8 %20, %17
  %22 = zext i1 %21 to i8
  store i8 %22, ptr %19, align 1, !tbaa !6
  %23 = add nuw nsw i64 %15, 1
  %24 = icmp eq i64 %15, 0
  br i1 %24, label %14, label %25, !llvm.loop !15

25:                                               ; preds = %14
  store i16 0, ptr %1, align 4
  br label %26

26:                                               ; preds = %26, %25
  %27 = phi i64 [ 0, %25 ], [ %36, %26 ]
  %28 = phi i32 [ 0, %25 ], [ %35, %26 ]
  %29 = shl nsw i32 %28, 1
  %30 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %27
  %31 = load i8, ptr %30, align 1, !tbaa !6, !range !10, !noundef !11
  %32 = trunc nuw i8 %31 to i1
  %33 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %32) #4
  %34 = zext i1 %33 to i32
  %35 = or disjoint i32 %29, %34
  %36 = add nuw nsw i64 %27, 1
  %37 = icmp eq i64 %36, 4
  br i1 %37, label %38, label %26, !llvm.loop !16

38:                                               ; preds = %26
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #4
  ret i32 %35
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
