; lowering_inplace_rail_z36_inregion_add_accept.ll — ACCEPT. bd
; test_C_libtooling-eqpx (P1), ACCEPT CONTROL 8 of 8: the `add` against a
; 6.5-DERIVED immediate that `clang -O1` SINKS out of the loop, so no writer ever
; marks it and the correct out-of-place Q+Q lowering is what ships. It is the
; nearest neighbour of the `..._w3_add_derived.ll` DECLINE — same producer, same
; stem, same in-body region — separated only by whether the recurrence survives
; `-O1`'s exit-value rewrite.
;
;     int ext_f(int a);                        /* a second TU: `return a+100;` */
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
;       int y=5; if (q>5) y=ext_f(7);          /* 6.5 CLASSICAL-CALL ARM -> %out */
;       int w = y * 3;
;       for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); r = r + w; }
;       return cq_measure(r)+cq_measure(y); }
;
; `clang -O1`, two TUs `llvm-link`ed, `@main` dropped. `!llvm.loop` VERBATIM.
; IndVarSimplify closed-forms `r += w` over 3 trips into `r + 3*w` and SINKS it to
; the exit block (`%11 = add i32 %3, %10` there), so the `add` is not an in-loop
; rail op at all. This is the mechanism that made the whole `add` stem LOOK safe;
; the decline fixtures in this family are the four plain-C spellings that defeat
; it with one extra body op.
;
; MEASURED on frozen `main`@16b15b3 AND here: ZERO in-place gates, one
; out-of-place `cq_template_add_i32(i32 %h3, i32 %h_op)` against the mul rail,
; `railInImm=0`, STRICT stage 2b `0 violation(s)`, 47 trace lines, lowered module
; BYTE-IDENTICAL across the two binaries (`cmp`).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=IMMCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; The sunk recurrence: one mul rail off the merge, one out-of-place Q+Q add, and
; the mul rail discharged and freed.
; CHECK: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: %[[M:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[OUT]], i32 9)
; CHECK-NEXT: {{.*}} = call i32 @cq_template_add_i32(i32 %{{.*}}, i32 %[[M]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[M]], i32 %[[OUT]], i32 9)

; IMMCNT-NOT: call void @cqrt_addc_i32(
; IMMCNT-NOT: call void @cqrt_xorc_i32(
; IMMCNT-COUNT-1: call i32 @cq_template_add_i32(
; IMMCNT-NOT: call i32 @cq_template_add_i32(

; NOROUTE-NOT: in-place rail op no longer provable at lowering
; NOROUTE-NOT: pre-loop in-place op no longer provable at lowering
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: @cq_phi

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #3
  %4 = icmp sgt i32 %2, 5
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %7

7:                                                ; preds = %5, %1
  %8 = phi i32 [ %6, %5 ], [ 5, %1 ]
  br label %15

9:                                                ; preds = %21
  %10 = mul i32 %8, 9
  %11 = add i32 %3, %10
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %13 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %14 = add nsw i32 %13, %12
  ret i32 %14

15:                                               ; preds = %21, %7
  %16 = phi i32 [ 0, %7 ], [ %22, %21 ]
  %17 = shl nuw nsw i32 1, %16
  %18 = and i32 %17, %2
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %21, label %20

20:                                               ; preds = %15
  tail call void @cq_phi(double noundef 2.000000e-01) #3
  br label %21

21:                                               ; preds = %20, %15
  %22 = add nuw nsw i32 %16, 1
  %23 = icmp eq i32 %22, 3
  br i1 %23, label %9, label %15, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
