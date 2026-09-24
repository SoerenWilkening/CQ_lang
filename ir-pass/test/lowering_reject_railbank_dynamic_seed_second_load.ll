; lowering_reject_railbank_dynamic_seed_second_load.ll — DECLINE (bd test_C_libtooling-xdu2.4, Rule-13 finding 1).
; 
; The runtime bank's conditional in-arm prep would get a MINTED |0> seed rail. Here a
; SECOND load of the same cell (%xl), distinct from the theta's seed load and not CSE'd
; with it (hand IR: clang -O1 would merge the two), sits BEFORE the branch and feeds host
; arithmetic. Forwarding would turn it into the opaque seed HANDLE inside classical
; `add`s. The promoter's other-loads dominance conjunct must refuse the plan, so the store
; keeps its generic decline. Kills injection mutant M4 (the conjunct deleted).
; ⚠ A DS_Error decline writes 0 bytes to stdout; the property is pinned by the `not` inversion (Rule 12 (b)). Positive control: tests/e2e/slice_railbank_dynamic_int.c, the unmutated module, ACCEPTS.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq taint escape: tainted value stored to memory
; CHECK-NOT: tainted value muxed

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, -1
  tail call fastcc void @run_bank(i32 noundef %3)
  tail call fastcc void @run_bank(i32 noundef %0)
  ret i32 0
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @run_bank(i32 noundef %0) unnamed_addr #1 {
  %2 = icmp slt i32 %0, 1
  br i1 %2, label %61, label %3

3:                                                ; preds = %1
  %4 = zext nneg i32 %0 to i64
  %5 = tail call ptr @llvm.stacksave.p0()
  %6 = alloca i32, i64 %4, align 16
  %7 = alloca i32, i64 %4, align 16
  %8 = zext nneg i32 %0 to i64
  br label %13

9:                                                ; preds = %13
  %10 = alloca i32, i64 %4, align 16
  %11 = shl nsw i32 %0, 2
  %12 = zext nneg i32 %0 to i64
  br label %26

13:                                               ; preds = %3, %13
  %14 = phi i64 [ 0, %3 ], [ %21, %13 ]
  %15 = getelementptr inbounds i32, ptr %6, i64 %14
  %16 = trunc i64 %14 to i32
  %17 = add i32 %16, 3
  store i32 %17, ptr %15, align 4, !tbaa !6
  %18 = getelementptr inbounds i32, ptr %7, i64 %14
  %19 = trunc i64 %14 to i32
  %20 = add i32 %19, 2
  store i32 %20, ptr %18, align 4, !tbaa !6
  %21 = add nuw nsw i64 %14, 1
  %22 = icmp eq i64 %21, %8
  br i1 %22, label %9, label %13, !llvm.loop !10

23:                                               ; preds = %46
  %24 = tail call i32 @llvm.smax.i32(i32 %0, i32 1)
  %25 = zext nneg i32 %24 to i64
  br label %54

26:                                               ; preds = %9, %46
  %27 = phi i64 [ 0, %9 ], [ %49, %46 ]
  %28 = phi i32 [ %11, %9 ], [ %48, %46 ]
  %29 = phi i32 [ 0, %9 ], [ %47, %46 ]
  %30 = getelementptr inbounds i32, ptr %7, i64 %27
  %31 = load i32, ptr %30, align 4, !tbaa !6
  %32 = icmp slt i32 %28, %31
  %xg = getelementptr inbounds i32, ptr %10, i64 %27
  %xl = load i32, ptr %xg, align 4, !tbaa !6
  br i1 %32, label %37, label %33

33:                                               ; preds = %26
  %34 = getelementptr inbounds i32, ptr %10, i64 %27
  %35 = load i32, ptr %34, align 4, !tbaa !6
  %36 = tail call i32 @cq_theta_si32(i32 noundef %35, double noundef 5.000000e-01) #5
  store i32 %36, ptr %34, align 4, !tbaa !6
  br label %37

37:                                               ; preds = %33, %26
  %38 = getelementptr inbounds i32, ptr %10, i64 %27
  %39 = load i32, ptr %38, align 4, !tbaa !6
  %40 = icmp eq i32 %39, 0
  br i1 %40, label %46, label %41

41:                                               ; preds = %37
  %42 = getelementptr inbounds i32, ptr %6, i64 %27
  %43 = load i32, ptr %42, align 4, !tbaa !6
  %xa = add nsw i32 %43, %xl
  %44 = add nsw i32 %xa, %29
  %45 = sub nsw i32 %28, %31
  br label %46

46:                                               ; preds = %37, %41
  %47 = phi i32 [ %44, %41 ], [ %29, %37 ]
  %48 = phi i32 [ %45, %41 ], [ %28, %37 ]
  %49 = add nuw nsw i64 %27, 1
  %50 = icmp eq i64 %49, %12
  br i1 %50, label %23, label %26, !llvm.loop !13

51:                                               ; preds = %54
  %52 = tail call i32 @cq_measure_si32(i32 noundef %47) #5
  %53 = tail call i32 @cq_measure_si32(i32 noundef %48) #5
  tail call void @llvm.stackrestore.p0(ptr %5)
  br label %61

54:                                               ; preds = %23, %54
  %55 = phi i64 [ 0, %23 ], [ %59, %54 ]
  %56 = getelementptr inbounds i32, ptr %10, i64 %55
  %57 = load i32, ptr %56, align 4, !tbaa !6
  %58 = tail call i32 @cq_measure_si32(i32 noundef %57) #5
  %59 = add nuw nsw i64 %55, 1
  %60 = icmp eq i64 %59, %25
  br i1 %60, label %51, label %54, !llvm.loop !14

61:                                               ; preds = %1, %51
  ret void
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
!14 = distinct !{!14, !11, !12}
