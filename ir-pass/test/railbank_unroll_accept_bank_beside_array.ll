; ACCEPT (bd `test_C_libtooling-01po.19`, review round 1 item 2): a rolled-bank array
; and an unrelated multi-store array in ONE function (reviewer probe rvH/p4.c). On
; c7a734af the bank made the stage skip the WHOLE function (an L5 over-decline). The
; priority is now per array. Stream: a0..a3 Ry(0.5), q0..q3 Ry(0.4), the xor chain
; q_i ^= q_{i-1}, measures interleaved a_i, q_i.
;
; ⚠ L7 RETIREMENT TRIGGER (bd r2j3.33): the `^=` walk lowers to the OUT-OF-PLACE
; `cq_template_xor_i1`, which keeps the old target rail live (the r2j3.33 population;
; harmless here because no later gate rotates a control). When lane C's dm7f.51
; replaces it with an in-place CNOT, re-derive the xor lines with an analytic check.
;
; SOURCE (clang -O1, verbatim below):
;   /* H3: one rolled-bank array and one multi-store array in one function; and a
;      measured break in the second's loop. */
;   int main(void) {
;     bool a[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&a[i], .5);
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .4);
;     for (int i = 1; i < 4; i++) q[i] ^= q[i - 1];
;     int r = 0;
;     for (int i = 0; i < 4; i++) r += cq_measure(a[i]) + cq_measure(q[i]);
;     return r;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s --implicit-check-not='call {{.*}}@cq'
; CHECK-LABEL: define {{.*}} @main(
; CHECK: call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %1) #2
; CHECK: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h, double 4.000000e-01)
; CHECK: %h1 = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h1, double 4.000000e-01)
; CHECK: %h2 = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h2, double 4.000000e-01)
; CHECK: %h3 = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h3, double 4.000000e-01)
; CHECK: %h_op = call i32 @cq_template_xor_i1(i32 %h, i32 %h1)
; CHECK: %h_op5 = call i32 @cq_template_xor_i1(i32 %h2, i32 %h_op)
; CHECK: %h_op6 = call i32 @cq_template_xor_i1(i32 %h3, i32 %h_op5)
; CHECK: %m = call i1 @cqrt_measure_i1(i32 %2)
; CHECK: %m7 = call i1 @cqrt_measure_i1(i32 %h)
; CHECK: %m8 = call i1 @cqrt_measure_i1(i32 %7)
; CHECK: %m9 = call i1 @cqrt_measure_i1(i32 %h_op)
; CHECK: %m10 = call i1 @cqrt_measure_i1(i32 %13)
; CHECK: %m11 = call i1 @cqrt_measure_i1(i32 %h_op5)
; CHECK: %m12 = call i1 @cqrt_measure_i1(i32 %19)
; CHECK: %m13 = call i1 @cqrt_measure_i1(i32 %h_op6)
; CHECK: call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %1) #2
; CHECK: %h4 = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h4, double 5.000000e-01)

; ModuleID = 'rvH_p4.c'
source_filename = "rvH_p4.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  %2 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #3
  store i32 0, ptr %1, align 4
  br label %4

3:                                                ; preds = %4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #3
  store i32 0, ptr %2, align 4
  br label %13

4:                                                ; preds = %0, %4
  %5 = phi i64 [ 0, %0 ], [ %11, %4 ]
  %6 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %5
  %7 = load i8, ptr %6, align 1, !tbaa !6, !range !10, !noundef !11
  %8 = trunc nuw i8 %7 to i1
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 5.000000e-01) #4
  %10 = zext i1 %9 to i8
  store i8 %10, ptr %6, align 1, !tbaa !6
  %11 = add nuw nsw i64 %5, 1
  %12 = icmp eq i64 %11, 4
  br i1 %12, label %3, label %4, !llvm.loop !12

13:                                               ; preds = %3, %13
  %14 = phi i64 [ 0, %3 ], [ %20, %13 ]
  %15 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %14
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %17, double noundef 4.000000e-01) #4
  %19 = zext i1 %18 to i8
  store i8 %19, ptr %15, align 1, !tbaa !6
  %20 = add nuw nsw i64 %14, 1
  %21 = icmp eq i64 %20, 4
  br i1 %21, label %22, label %13, !llvm.loop !15

22:                                               ; preds = %13
  %23 = load i8, ptr %2, align 4
  br label %24

24:                                               ; preds = %22, %24
  %25 = phi i8 [ %23, %22 ], [ %30, %24 ]
  %26 = phi i64 [ 1, %22 ], [ %31, %24 ]
  %27 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %26
  %28 = load i8, ptr %27, align 1, !tbaa !6, !range !10, !noundef !11
  %29 = icmp ne i8 %28, %25
  %30 = zext i1 %29 to i8
  store i8 %30, ptr %27, align 1, !tbaa !6
  %31 = add nuw nsw i64 %26, 1
  %32 = icmp eq i64 %31, 4
  br i1 %32, label %34, label %24, !llvm.loop !16

33:                                               ; preds = %34
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #3
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #3
  ret i32 %48

34:                                               ; preds = %24, %34
  %35 = phi i64 [ %49, %34 ], [ 0, %24 ]
  %36 = phi i32 [ %48, %34 ], [ 0, %24 ]
  %37 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %35
  %38 = load i8, ptr %37, align 1, !tbaa !6, !range !10, !noundef !11
  %39 = trunc nuw i8 %38 to i1
  %40 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %39) #3
  %41 = zext i1 %40 to i32
  %42 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %35
  %43 = load i8, ptr %42, align 1, !tbaa !6, !range !10, !noundef !11
  %44 = trunc nuw i8 %43 to i1
  %45 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %44) #3
  %46 = zext i1 %45 to i32
  %47 = add nuw nsw i32 %36, %41
  %48 = add nuw nsw i32 %47, %46
  %49 = add nuw nsw i64 %35, 1
  %50 = icmp eq i64 %49, 4
  br i1 %50, label %33, label %34, !llvm.loop !17
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
!17 = distinct !{!17, !13, !14}
