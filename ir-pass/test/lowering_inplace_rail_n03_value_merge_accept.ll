; lowering_inplace_rail_n03_value_merge_accept.ll — ACCEPT. bd
; test_C_libtooling-eqpx (P1), ACCEPT CONTROL 7 of 8: the same discriminator for
; the OTHER non-producing merge, the 3qlq Inc-2 controlled-copy VALUE merge.
;
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
;       int y = 5; if (q>5) y = q*3;           /* Inc-2 VALUE MERGE -> %out */
;       int w = y & 7;
;       for(int i=0;i<3;i++){ r = r ^ w; }
;       return cq_measure(r)+cq_measure(y)+cq_measure(q); }
;
; `clang -O1`, `@main` dropped. `!llvm.loop` VERBATIM. The arm value `q*3` is
; QUANTUM, so the merged `%out` is tainted at ROUND 1 — the arm's chain is hoisted
; and merged by two `cqrt_copy_i32_controlled` — and again nothing is marked.
;
; Contrast the flagship decline, whose arm value is `ext_f(7)`: a pure ALL-CLASSICAL
; call, which is what makes it the 6.5 classical-call arm and its `%out` CLASSICAL
; at round 1. The difference between this accept and that decline is exactly one
; question — is the merged value tainted when the writer looks? — and that is the
; question the fix re-asks at the consumer.
;
; MEASURED on frozen `main`@16b15b3 AND here: ZERO in-place gates, one
; out-of-place Q+Q `cq_template_xor_i32`, `railInImm=0`, STRICT stage 2b
; `0 violation(s)`, 21 trace lines, lowered module BYTE-IDENTICAL across the two
; binaries (`cmp`).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=IMMCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll

; The hoisted arm chain, the Inc-2 controlled-copy merge, then the Q+Q xor.
; CHECK: %[[M:.*]] = call i32 @cq_template_mul_i32_hl(i32 %{{.*}}, i32 3)
; CHECK: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %{{.*}}, i32 %[[M]], i32 %[[OUT]])
; CHECK: %[[W:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[OUT]], i32 7)
; CHECK: {{.*}} = call i32 @cq_template_xor_i32(i32 %{{.*}}, i32 %[[W]])

; IMMCNT-NOT: call void @cqrt_xorc_i32(
; IMMCNT-NOT: call void @cqrt_addc_i32(
; IMMCNT-COUNT-1: call i32 @cq_template_xor_i32(
; IMMCNT-NOT: call i32 @cq_template_xor_i32(

; NOROUTE-NOT: in-place rail op no longer provable at lowering
; NOROUTE-NOT: pre-loop in-place op no longer provable at lowering
; NOROUTE-NOT: @cq_theta

; ── round-1 lens F-E1-3: the accept controls under-asserted. 48 injections
; over these 8 fixtures (a rail-immediate `cqrt_xorc_i32(i32 %h, i32 %rail)`,
; an extra out-of-place `cq_template_xor_i32`, an extra `cqrt_free`, each at
; head and tail) were caught 20/48 — every free MISSED by all 8, because no
; accept fixture carried a free count. The blocks below close that; the counts
; are DERIVED from this fixture's own pass output, not guessed.
; NOROUTE-NOT: call void @cqrt_xorc_i
; NOROUTE-NOT: call void @cqrt_xorc_i{{[0-9]+}}(i32 %{{.*}}, i32 %{{.*}})
; NOROUTE-NOT: call void @cqrt_addc_i
; NOROUTE-NOT: call void @cqrt_addc_i{{[0-9]+}}(i32 %{{.*}}, i32 %{{.*}})
; NOROUTE-NOT: call i32 @cq_template_add_i32(
;
; FCNT — whole-file EXACT free count, MEASURED 2 (`grep -c 'call void @cqrt_free(' <pass output>`).
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/7bbdb89e-f7ed-43f7-80e1-bda20ba33640/scratchpad/progress/fix_eqpx_work/p/n03_valuemerge_xor_noregion.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/7bbdb89e-f7ed-43f7-80e1-bda20ba33640/scratchpad/progress/fix_eqpx_work/p/n03_valuemerge_xor_noregion.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #2
  %4 = icmp sgt i32 %2, 5
  %5 = mul nuw nsw i32 %2, 3
  %6 = select i1 %4, i32 %5, i32 5
  %7 = and i32 %6, 7
  br label %14

8:                                                ; preds = %14
  %9 = tail call i32 @cq_measure_si32(i32 noundef %17) #2
  %10 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  %11 = add nsw i32 %10, %9
  %12 = tail call i32 @cq_measure_si32(i32 noundef %2) #2
  %13 = add nsw i32 %11, %12
  ret i32 %13

14:                                               ; preds = %1, %14
  %15 = phi i32 [ 0, %1 ], [ %18, %14 ]
  %16 = phi i32 [ %3, %1 ], [ %17, %14 ]
  %17 = xor i32 %16, %7
  %18 = add nuw nsw i32 %15, 1
  %19 = icmp eq i32 %18, 3
  br i1 %19, label %8, label %14, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
