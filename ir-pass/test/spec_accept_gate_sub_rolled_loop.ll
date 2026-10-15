; spec_accept_gate_sub_rolled_loop.ll — ACCEPT (bd test_C_libtooling-p3kd.21, R11 r1
; item 2). A caller with a ROLLED constant-trip phase loop and one call compiled at
; its site:
;
;   __attribute__((noinline)) static void rot(bool *t) { cq_theta(t, 0.4); }
;   cq_theta(&a, 0.5);
;   for (int i = 0; i < 3; i++) if (a) cq_phi(0.2);
;   cq_theta(&a, 0.5); cq_theta(&t, 0.1); rot(&t);
;
; The caller is re-run through the -O1 function pipeline after the inline. Built
; with the default PipelineTuningOptions (LoopUnrolling = true), that pipeline's
; LoopFullUnrollPass unrolled the loop clang -O1 keeps rolled (reviewer
; measurement on 11adde57); with clang's -O1 options it stays rolled: ONE kickback
; `cqrt_rz_i1` inside a counted loop. `clang -O1 -include CQ.h` output verbatim.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK: [[A:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: [[T:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[T]], double 1.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[T]], double 4.000000e-01)
; CHECK: {{%[0-9]+}} = phi i32 [ 0, %{{[0-9]+}} ], [ {{%[0-9]+}}, %{{[0-9]+}} ]
; CHECK-NEXT: call void @cqrt_rz_i1(i32 [[A]], double 2.000000e-01), !cq.branchphase
; CHECK: br i1 {{%[0-9]+}}, label {{%[0-9]+}}, label {{%[0-9]+}}, !llvm.loop
; CHECK-NOT: call void @cqrt_rz_i1(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [7 x i8] c"%d %d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca i8, align 1
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %1) #5
  store i8 0, ptr %1, align 1, !tbaa !6
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #6
  br label %14

3:                                                ; preds = %17
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef 5.000000e-01) #6
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.000000e-01) #6
  %6 = zext i1 %5 to i8
  store i8 %6, ptr %1, align 1, !tbaa !6
  call fastcc void @rot(ptr noundef nonnull %1)
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #5
  %8 = zext i1 %7 to i32
  %9 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %10 = trunc nuw i8 %9 to i1
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %10) #5
  %12 = zext i1 %11 to i32
  %13 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %8, i32 noundef %12)
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %1) #5
  ret i32 0

14:                                               ; preds = %0, %17
  %15 = phi i32 [ 0, %0 ], [ %18, %17 ]
  br i1 %2, label %16, label %17

16:                                               ; preds = %14
  tail call void @cq_phi(double noundef 2.000000e-01) #5
  br label %17

17:                                               ; preds = %14, %16
  %18 = add nuw nsw i32 %15, 1
  %19 = icmp eq i32 %18, 3
  br i1 %19, label %3, label %14, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare void @cq_phi(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @rot(ptr nocapture noundef %0) unnamed_addr #3 {
  %2 = load i8, ptr %0, align 1, !tbaa !6, !range !10, !noundef !11
  %3 = trunc nuw i8 %2 to i1
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef 4.000000e-01) #6
  %5 = zext i1 %4 to i8
  store i8 %5, ptr %0, align 1, !tbaa !6
  ret void
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #4

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
