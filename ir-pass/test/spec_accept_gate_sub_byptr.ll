; spec_accept_gate_sub_byptr.ll — ACCEPT (bd test_C_libtooling-p3kd.21).
; Non-inlined GATE SUBROUTINES taking the register BY POINTER, two of them applied
; to the same register, one with a negated condition (after CQ_FINDINGS F6's
; ~/Desktop/alg_test/dicke/t11.c, with `c = q0` so every condition is a rail):
;
;   #define CRY_EQ(name, V, TH) \
;     __attribute__((noinline)) static void name(int c, bool *t) { if (c == V) cq_theta(t, TH); }
;   CRY_EQ(r1, 1, 0.4) CRY_EQ(r2, 1, 0.1) CRY_EQ(r3, 0, 0.3)
;   r1(c, &q1);  r2(c, &q2);  r3(c, &q2);
;
; Before: `callee contains a non-reversibilizable construct under quantum lift
; (memory access)` (the register lives in a caller `alloca` because its address
; reaches a noinline call). Now each call is compiled at its site
; (SpecializeGateInline.h) and SROA promotes the cell, so the register is the
; caller's SSA value again: no memory traffic on a quantum value and no clone.
; `r3`'s `c == 0` is the negated rail, so its gate is R6's
; `ry(h, θ); ry_controlled(h_b, h, −θ)` (nothing non-diagonal fires under a ¬rail).
; The rotated registers escape through the pointer and are then measured.
; `clang -O1 -include CQ.h` output verbatim.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=CLONE < %t.ll
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK-NOT: alloca
; CHECK: [[Q0:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(
; CHECK: [[Q1:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(
; CHECK: call void @cqrt_ry_i1_controlled(i32 [[Q0]], i32 [[Q1]], double 4.000000e-01)
; CHECK: [[Q2:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(
; CHECK: call void @cqrt_ry_i1_controlled(i32 [[Q0]], i32 [[Q2]], double 1.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[Q2]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 [[Q0]], i32 [[Q2]], double -3.000000e-01)
; CHECK: call {{.*}}@cqrt_measure_i1(i32 [[Q1]])
; CHECK: call {{.*}}@cqrt_measure_i1(i32 [[Q2]])
; CLONE-NOT: @r1
; CLONE-NOT: @r2
; CLONE-NOT: @r3
; CLONE-NOT: @__cq_q_

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [10 x i8] c"%d %d %d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca i8, align 1
  %2 = alloca i8, align 1
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %1) #5
  store i8 0, ptr %1, align 1, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %2) #5
  store i8 0, ptr %2, align 1, !tbaa !6
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.000000e+00) #6
  %4 = zext i1 %3 to i32
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01) #6
  %6 = zext i1 %5 to i8
  store i8 %6, ptr %1, align 1, !tbaa !6
  call fastcc void @r1(i32 noundef %4, ptr noundef nonnull %1)
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.000000e-01) #6
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %2, align 1, !tbaa !6
  call fastcc void @r2(i32 noundef %4, ptr noundef nonnull %2)
  call fastcc void @r3(i32 noundef %4, ptr noundef nonnull %2)
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #5
  %10 = zext i1 %9 to i32
  %11 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %12 = trunc nuw i8 %11 to i1
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %12) #5
  %14 = zext i1 %13 to i32
  %15 = load i8, ptr %2, align 1, !tbaa !6, !range !10, !noundef !11
  %16 = trunc nuw i8 %15 to i1
  %17 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %16) #5
  %18 = zext i1 %17 to i32
  %19 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %10, i32 noundef %14, i32 noundef %18)
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %2) #5
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %1) #5
  ret i32 0
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @r1(i32 noundef %0, ptr nocapture noundef %1) unnamed_addr #3 {
  %3 = icmp eq i32 %0, 1
  br i1 %3, label %4, label %9

4:                                                ; preds = %2
  %5 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 4.000000e-01) #6
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %1, align 1, !tbaa !6
  br label %9

9:                                                ; preds = %4, %2
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @r2(i32 noundef %0, ptr nocapture noundef %1) unnamed_addr #3 {
  %3 = icmp eq i32 %0, 1
  br i1 %3, label %4, label %9

4:                                                ; preds = %2
  %5 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 1.000000e-01) #6
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %1, align 1, !tbaa !6
  br label %9

9:                                                ; preds = %4, %2
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @r3(i32 noundef %0, ptr nocapture noundef %1) unnamed_addr #3 {
  %3 = icmp eq i32 %0, 0
  br i1 %3, label %4, label %9

4:                                                ; preds = %2
  %5 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 3.000000e-01) #6
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %1, align 1, !tbaa !6
  br label %9

9:                                                ; preds = %4, %2
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
