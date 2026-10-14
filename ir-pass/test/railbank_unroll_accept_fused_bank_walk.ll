; ACCEPT (bd `test_C_libtooling-01po.19`, review round 1 item 2): a rolled-bank walk
; FUSED by `-O1` with another array's CNOT walk (reviewer probe rv/p2).
;
; `a[3]` alone is a rail bank (`cq_theta(&a[i], .5)` per trip); `q[3]` (q0 = Ry(pi/2),
; `q[i+1] ^= q[i]`) is not, and `-O1` put both walks in ONE loop. The bank's priority is
; per array: the first trial leaves the bank's walk rolled and fails (q's index is only
; resolved by that loop); the second trial may unroll it, but only because the bank is
; then scalarized too (no bank is left half rolled). Stream: q0 -> h, a0..a2 Ry(0.5),
; measures interleaved a_i, q_i with q1 = q2 = q0 (the SSA copy of `0 ^ q0`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s --implicit-check-not='call {{.*}}@cq'
; CHECK-LABEL: define {{.*}} @main(
; CHECK: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h, double 0x3FF921FB54442D18)
; CHECK: %h1 = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h1, double 5.000000e-01)
; CHECK: %h2 = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h2, double 5.000000e-01)
; CHECK: %h3 = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h3, double 5.000000e-01)
; CHECK: %m = call i1 @cqrt_measure_i1(i32 %h1)
; CHECK: %m4 = call i1 @cqrt_measure_i1(i32 %h)
; CHECK: %m5 = call i1 @cqrt_measure_i1(i32 %h2)
; CHECK: %m6 = call i1 @cqrt_measure_i1(i32 %h)
; CHECK: %m7 = call i1 @cqrt_measure_i1(i32 %h3)
; CHECK: %m8 = call i1 @cqrt_measure_i1(i32 %h)

; ModuleID = 'p2.c'
source_filename = "p2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  %2 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #4
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %2) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %2, i8 0, i64 3, i1 false)
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FF921FB54442D18) #5
  %4 = zext i1 %3 to i8
  store i8 %4, ptr %2, align 1, !tbaa !6
  br label %5

5:                                                ; preds = %0, %21
  %6 = phi i64 [ 0, %0 ], [ %22, %21 ]
  %7 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %6
  %8 = load i8, ptr %7, align 1, !tbaa !6, !range !10, !noundef !11
  %9 = trunc nuw i8 %8 to i1
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %9, double noundef 5.000000e-01) #5
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %7, align 1, !tbaa !6
  %12 = icmp eq i64 %6, 2
  br i1 %12, label %21, label %13

13:                                               ; preds = %5
  %14 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %6
  %15 = load i8, ptr %14, align 1, !tbaa !6, !range !10, !noundef !11
  %16 = add nuw nsw i64 %6, 1
  %17 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %16
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !10, !noundef !11
  %19 = icmp ne i8 %18, %15
  %20 = zext i1 %19 to i8
  store i8 %20, ptr %17, align 1, !tbaa !6
  br label %21

21:                                               ; preds = %5, %13
  %22 = add nuw nsw i64 %6, 1
  %23 = icmp eq i64 %22, 3
  br i1 %23, label %25, label %5, !llvm.loop !12

24:                                               ; preds = %25
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %2) #4
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #4
  ret i32 %39

25:                                               ; preds = %21, %25
  %26 = phi i64 [ %40, %25 ], [ 0, %21 ]
  %27 = phi i32 [ %39, %25 ], [ 0, %21 ]
  %28 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %26
  %29 = load i8, ptr %28, align 1, !tbaa !6, !range !10, !noundef !11
  %30 = trunc nuw i8 %29 to i1
  %31 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %30) #4
  %32 = zext i1 %31 to i32
  %33 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %26
  %34 = load i8, ptr %33, align 1, !tbaa !6, !range !10, !noundef !11
  %35 = trunc nuw i8 %34 to i1
  %36 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %35) #4
  %37 = select i1 %36, i32 2, i32 0
  %38 = add nuw nsw i32 %27, %32
  %39 = add nuw nsw i32 %38, %37
  %40 = add nuw nsw i64 %26, 1
  %41 = icmp eq i64 %40, 3
  br i1 %41, label %24, label %25, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
