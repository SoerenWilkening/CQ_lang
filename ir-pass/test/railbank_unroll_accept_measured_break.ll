; ACCEPT (bd `test_C_libtooling-01po.19`, review round 1 item 3): an early exit on a
; MEASURED cell (reviewer probe rvH/p5.c). The exact trip is not computable, the
; constant MAX trip (4) is; `UnrollLoop` with `Count == MaxTripCount` keeps each exit as
; a conditional branch on the classical measurement, so the program is unchanged.
; Pinned: the four measures stay in order, each guarded by the previous result.
;
; ⚠ L7 RETIREMENT TRIGGER (bd r2j3.33): the `^=` walk lowers to the OUT-OF-PLACE
; `cq_template_xor_i1`, which keeps the old target rail live (the r2j3.33 population;
; harmless here because no later gate rotates a control). When lane C's dm7f.51
; replaces it with an in-place CNOT, re-derive the xor lines with an analytic check.
;
; SOURCE (clang -O1, verbatim below):
;   /* H1: loop exit on a measured cell; second store site keeps it off the bank. */
;   int main(void) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .5);
;     for (int i = 1; i < 4; i++) q[i] ^= q[i - 1];
;     int n = 0;
;     for (int i = 0; i < 4; i++) { if (cq_measure(q[i])) break; n++; }
;     return n;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s --implicit-check-not='call {{.*}}@cq'
; CHECK-LABEL: define {{.*}} @main(
; CHECK: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; CHECK: %h1 = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h1, double 5.000000e-01)
; CHECK: %h2 = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h2, double 5.000000e-01)
; CHECK: %h3 = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h3, double 5.000000e-01)
; CHECK: %h_op = call i32 @cq_template_xor_i1(i32 %h, i32 %h1)
; CHECK: %h_op4 = call i32 @cq_template_xor_i1(i32 %h2, i32 %h_op)
; CHECK: %h_op5 = call i32 @cq_template_xor_i1(i32 %h3, i32 %h_op4)
; CHECK: %m = call i1 @cqrt_measure_i1(i32 %h)
; CHECK-NEXT: br i1 %m, label %.loopexit1, label %0
; CHECK: %m6 = call i1 @cqrt_measure_i1(i32 %h_op)
; CHECK-NEXT: br i1 %m6, label %.loopexit1, label %1
; CHECK: %m7 = call i1 @cqrt_measure_i1(i32 %h_op4)
; CHECK-NEXT: br i1 %m7, label %.loopexit1, label %2
; CHECK: %m8 = call i1 @cqrt_measure_i1(i32 %h_op5)
; CHECK: phi i32 [ 0, %.loopexit ], [ 1, %0 ], [ 2, %1 ], [ %spec.select, %2 ]
; CHECK-NOT: cqrt_free

; ModuleID = 'rvH_p5.c'
source_filename = "rvH_p5.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #3
  store i32 0, ptr %1, align 4
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %9, %2 ]
  %4 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 5.000000e-01) #4
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %4, align 1, !tbaa !6
  %9 = add nuw nsw i64 %3, 1
  %10 = icmp eq i64 %9, 4
  br i1 %10, label %11, label %2, !llvm.loop !12

11:                                               ; preds = %2
  %12 = load i8, ptr %1, align 4
  br label %13

13:                                               ; preds = %11, %13
  %14 = phi i8 [ %12, %11 ], [ %19, %13 ]
  %15 = phi i64 [ 1, %11 ], [ %20, %13 ]
  %16 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !6, !range !10, !noundef !11
  %18 = icmp ne i8 %17, %14
  %19 = zext i1 %18 to i8
  store i8 %19, ptr %16, align 1, !tbaa !6
  %20 = add nuw nsw i64 %15, 1
  %21 = icmp eq i64 %20, 4
  br i1 %21, label %22, label %13, !llvm.loop !15

22:                                               ; preds = %13, %28
  %23 = phi i64 [ %29, %28 ], [ 0, %13 ]
  %24 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %23
  %25 = load i8, ptr %24, align 1, !tbaa !6, !range !10, !noundef !11
  %26 = trunc nuw i8 %25 to i1
  %27 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %26) #3
  br i1 %27, label %31, label %28

28:                                               ; preds = %22
  %29 = add nuw nsw i64 %23, 1
  %30 = icmp eq i64 %29, 4
  br i1 %30, label %33, label %22, !llvm.loop !16

31:                                               ; preds = %22
  %32 = trunc i64 %23 to i32
  br label %33

33:                                               ; preds = %28, %31
  %34 = phi i32 [ %32, %31 ], [ 4, %28 ]
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #3
  ret i32 %34
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { nomerge nounwind }

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
