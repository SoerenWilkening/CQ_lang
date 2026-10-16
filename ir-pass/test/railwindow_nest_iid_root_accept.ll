; railwindow_nest_iid_root_accept.ll — ACCEPT (bd 8h7d.25.1, R11 round 1 rA1C-F1): a
; clause-(ii-d) ROOT read only inside an admitted quantum SUBLOOP.
;
; SOURCE (clang -O1, verbatim below; the reviewer's suggested probe, with the
; condition `p == v` — the `p == v + c` spelling stops at the QQ compare guard —
; and the counter read in the outer body, so the outer loop has a seeded
; accumulator whose per-trip `zext(q[i])` rails need the rail-local grant; with the
; OuterRoot admission removed the module declines, measured):
;   #include <stdio.h>
;   #include <math.h>
;   #define N 4
;   #define K 2
;   int main(void) {
;       bool q[N] = {0};
;       int y = 0;
;       cq_theta(&y, 0.8);
;       int p = y * 3;
;       int c = 0;
;       for (int i = 0; i < N; i++) {
;           for (int v = 0; v <= K; v++) {
;               double t = (double)(K - v) / (N - i);
;               if (t < 0) t = 0;
;               if (t > 1) t = 1;
;               if (p == v) cq_theta(&q[i], 2.0 * asin(sqrt(t)));
;           }
;           if (c == 2) cq_phi(0.2);
;           if (q[i]) c = c + 1;
;       }
;       printf("%d", cq_measure(y));
;       for (int i = 0; i < N; i++) printf("%d", cq_measure(q[i]));
;       printf("\n");
;       return 0;
;   }
;
; `p = y * 3` is a hoisted out-of-place template rail read only inside the loop
; nest: `invariantRegisterRoots` admits it as a (ii-d) root of the outer loop, and
; `railLocalQualifies`' subloop clause (OuterRoot = `onRail`) lets the v-subloop read
; it. Unlike a user mint, a (ii-d) root IS reversed — and the multiplicity is still
; one-to-one: its forward `cq_template_mul_i32_hl` runs ONCE, before the loop, and
; its `_unc` + free ONCE, in the loop's exit block (the exit-discharge ledger's
; anchor, outside the subloop); the subloop only reads it, and the flag it mints
; there is stripped and freed per inner trip. (The comment that claimed "a root is
; never reversed" was corrected with this file.)
; ANALYTIC CHECK (scratch state-vector replay of this lowering, linked and run):
; y = Ry(.8) on its low bit, so P(y=1) = sin^2(.4) = 0.151647, and then p = 3 equals
; no v: every cell stays 0 ("10000"). For y = 0, p = 0 matches v = 0 only: cell i
; gets 2 asin(sqrt(min(2/(4-i), 1))), i.e. P(q0=1) = 1/2, P(q1=1) = 2/3, q2 = q3 = 1:
; "00011" 0.141392, "00111" 0.282784, "01011" 0.141392, "01111" 0.282784 — exactly
; the replay (the `c == 2` kickback is diagonal and moves none of them). Every freed
; rail |0>; stage 2b 5 sites verified / 0 violations / 0 unproven; CENSUS 3
; rail-mint sites left allocated (y, the cells, the dead counter — WARN), 0
; template rails dirty.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; WARN: warning: {{.*}}dead loop accumulator left allocated
; RUN: %filecheck %s < %t.ll
; CHECK: %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
; CHECK-NEXT: br label %.split
; CHECK: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %h_op)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %h)
; CHECK: call void @cqrt_add_i32(i32 %[[S:h_cast[0-9]+]], i32 %cq.acc), !cq.inplace.qq
; CHECK-NEXT: call void @cq_template_zext_i8_to_i32_unc(i32 %[[S]],
; CHECK-NEXT: call void @cqrt_free(i32 %[[S]])
; CHECK: %[[F:h_cmp[0-9]*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[F]], i32 %cq.arm.in, double %{{[0-9]+}})
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %h_op, i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; RUN: %filecheck %s --check-prefix=ONCE < %t.ll
; ONCE-COUNT-1: call void @cq_template_mul_i32_hl_unc(
; ONCE-NOT: call void @cq_template_mul_i32_hl_unc(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #6
  store i32 0, ptr %1, align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 8.000000e-01) #7
  %3 = mul nsw i32 %2, 3
  br label %4

4:                                                ; preds = %0, %36
  %5 = phi i64 [ 0, %0 ], [ %41, %36 ]
  %6 = phi i32 [ 0, %0 ], [ %40, %36 ]
  %7 = trunc i64 %5 to i32
  %8 = sub i32 4, %7
  %9 = uitofp nneg i32 %8 to double
  %10 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %5
  br label %16

11:                                               ; preds = %36
  %12 = tail call i32 @cq_measure_si32(i32 noundef %2) #6
  %13 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %12)
  br label %45

14:                                               ; preds = %32
  %15 = icmp eq i32 %6, 2
  br i1 %15, label %35, label %36

16:                                               ; preds = %4, %32
  %17 = phi i32 [ 0, %4 ], [ %33, %32 ]
  %18 = icmp eq i32 %3, %17
  br i1 %18, label %19, label %32

19:                                               ; preds = %16
  %20 = sub nuw nsw i32 2, %17
  %21 = uitofp nneg i32 %20 to double
  %22 = fdiv double %21, %9
  %23 = fcmp ogt double %22, 1.000000e+00
  %24 = select i1 %23, double 1.000000e+00, double %22
  %25 = load i8, ptr %10, align 1, !tbaa !6, !range !10, !noundef !11
  %26 = trunc nuw i8 %25 to i1
  %27 = tail call double @llvm.sqrt.f64(double %24)
  %28 = tail call double @llvm.asin.f64(double %27)
  %29 = fmul double %28, 2.000000e+00
  %30 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %26, double noundef %29) #7
  %31 = zext i1 %30 to i8
  store i8 %31, ptr %10, align 1, !tbaa !6
  br label %32

32:                                               ; preds = %19, %16
  %33 = add nuw nsw i32 %17, 1
  %34 = icmp eq i32 %33, 3
  br i1 %34, label %14, label %16, !llvm.loop !12

35:                                               ; preds = %14
  tail call void @cq_phi(double noundef 2.000000e-01) #6
  br label %36

36:                                               ; preds = %35, %14
  %37 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %5
  %38 = load i8, ptr %37, align 1, !tbaa !6, !range !10, !noundef !11
  %39 = zext nneg i8 %38 to i32
  %40 = add nuw nsw i32 %6, %39
  %41 = add nuw nsw i64 %5, 1
  %42 = icmp eq i64 %41, 4
  br i1 %42, label %11, label %4, !llvm.loop !15

43:                                               ; preds = %45
  %44 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #6
  ret i32 0

45:                                               ; preds = %11, %45
  %46 = phi i64 [ 0, %11 ], [ %53, %45 ]
  %47 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %46
  %48 = load i8, ptr %47, align 1, !tbaa !6, !range !10, !noundef !11
  %49 = trunc nuw i8 %48 to i1
  %50 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %49) #6
  %51 = zext i1 %50 to i32
  %52 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %51)
  %53 = add nuw nsw i64 %46, 1
  %54 = icmp eq i64 %53, 4
  br i1 %54, label %43, label %45, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.asin.f64(double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare void @cq_phi(double noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @putchar(i32 noundef) local_unnamed_addr #5

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree nounwind }
attributes #6 = { nounwind }
attributes #7 = { nomerge nounwind }


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
