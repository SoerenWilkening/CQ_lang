; spec_accept_gate_sub_under_control.ll — ACCEPT (bd test_C_libtooling-p3kd.21).
; A gate subroutine called under the CALLER'S quantum control:
;
;   __attribute__((noinline)) static void rot(bool *t) { cq_theta(t, 0.4); }
;   cq_theta(&a, 0.5); cq_theta(&t, 0.2);
;   if (a) rot(&t);
;
; Before: `cq taint escape: tainted value stored to memory`. The gate must fire
; only on the `a` branch, i.e. controlled by `a`'s rail: an UNCONTROLLED
; `cqrt_ry_i1(…, 0.4)` would be the verify-clean silent miscompile (the gate
; fired on both branches). The call is compiled at its site
; (SpecializeGateInline.h), so main's control chain sees `if (a) t = Ry(t, .4)`
; and emits the in-place controlled Ry, controlled by the `a` rail.
; `clang -O1 -include CQ.h` output verbatim.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK: [[A:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(
; CHECK: call void @cqrt_ry_i1(i32 [[A]], double 5.000000e-01)
; CHECK: [[T:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(
; CHECK: call void @cqrt_ry_i1(i32 [[T]], double 2.000000e-01)
; CHECK-NOT: call void @cqrt_ry_i1(i32 {{.*}}, double 4.000000e-01)
; CHECK: call void @cqrt_ry_i1_controlled(i32 {{.*}}[[A]], i32 [[T]], double 4.000000e-01)
; CHECK-NOT: call void @cqrt_ry_i1(i32 {{.*}}, double 4.000000e-01)
; CHECK: ret i32 0

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [7 x i8] c"%d %d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca i8, align 1
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %1) #5
  store i8 0, ptr %1, align 1, !tbaa !6
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #6
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 2.000000e-01) #6
  %4 = zext i1 %3 to i8
  store i8 %4, ptr %1, align 1, !tbaa !6
  br i1 %2, label %5, label %6

5:                                                ; preds = %0
  call fastcc void @rot(ptr noundef nonnull %1)
  br label %6

6:                                                ; preds = %5, %0
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #5
  %8 = zext i1 %7 to i32
  %9 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %10 = trunc nuw i8 %9 to i1
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %10) #5
  %12 = zext i1 %11 to i32
  %13 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %8, i32 noundef %12)
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %1) #5
  ret i32 0
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

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

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

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
