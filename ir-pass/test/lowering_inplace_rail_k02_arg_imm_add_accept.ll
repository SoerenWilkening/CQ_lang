; lowering_inplace_rail_k02_arg_imm_add_accept.ll — ACCEPT. bd
; test_C_libtooling-eqpx (P1), ACCEPT CONTROL 3 of 8: the `add` STEM of the
; argument-immediate capability. Same claim as `k01`, other opcode — the fix must
; not become stem-selective, because `inPlaceValueRailOperand` never was
; (`LoopLowering.cpp:145` admits `Add` and `Xor` identically).
;
;     __attribute__((noinline))
;     int run(int seed, int n){ int r=cq_theta(seed,0.3);
;       for(int i=0;i<3;i++){ r = r + n; r = cq_theta(r,0.1); }
;       return cq_measure(r); }
;
; `clang -O1`, `@main` dropped. `!llvm.loop` VERBATIM. The body rotation is what
; defeats `-O1`'s exit-value rewrite of the affine add-recurrence, so the `add`
; survives into the loop body where a writer can see it.
;
; MEASURED on frozen `main`@16b15b3 AND here: `cqrt_addc_i32(i32 %h, i32 %1)`,
; `railInImm=0`, STRICT stage 2b `0 violation(s)`, 9 trace lines, lowered module
; BYTE-IDENTICAL across the two binaries (`cmp`).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=IMMCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll

; The in-place gate followed by the body rotation, both on the ONE rail.
; CHECK: define i32 @run(i32 noundef %0, i32 noundef %1)
; CHECK: %[[R:.*]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK: call void @cqrt_addc_i32(i32 %[[R]], i32 %1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)

; IMMCNT-COUNT-1: call i32 @cqrt_alloc_i32(
; IMMCNT-NOT: call i32 @cqrt_alloc_i32(
; IMMCNT-COUNT-1: call void @cqrt_addc_i32(
; IMMCNT-NOT: call void @cqrt_addc_i32(
; IMMCNT-NOT: call i32 @cq_template_add_i32(

; NOROUTE-NOT: in-place rail op no longer provable at lowering
; NOROUTE-NOT: pre-loop in-place op no longer provable at lowering
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: call i32 @cq_template_

; ── round-1 lens F-E1-3: the accept controls under-asserted. 48 injections
; over these 8 fixtures (a rail-immediate `cqrt_xorc_i32(i32 %h, i32 %rail)`,
; an extra out-of-place `cq_template_xor_i32`, an extra `cqrt_free`, each at
; head and tail) were caught 20/48 — every free MISSED by all 8, because no
; accept fixture carried a free count. The blocks below close that; the counts
; are DERIVED from this fixture's own pass output, not guessed.
; NOROUTE-NOT: call void @cqrt_xorc_i
; NOROUTE-NOT: call void @cqrt_xorc_i{{[0-9]+}}(i32 %{{.*}}, i32 %{{.*}})
; (No `addc` rail-immediate negative: THIS fixture's own legitimate gate is
; `cqrt_addc_i32(i32 %h, i32 %1)` with `%1` an ARGUMENT — the non-Constant
; classical immediate dtzb deliberately accepts (`inPlaceValueRailOperand`, `LoopLowering.cpp:143` — G2 constrains the
; immediate ONLY by "not tainted"; W1's break lane says it outright at (E10),
; `LoopLowering.cpp:1568-1570`)
; and the reason the fix is G2-alone and NOT a writer-side `isa<Constant>(Imm)`
; — so `i32 %…, i32 %…` would fire on the very gate this control keeps. The
; XCNT block below pins the COUNT instead, whole-file, which is what catches an
; injected extra gate at either end. `ctlA`, whose immediate is the literal 7,
; is the one fixture of the eight that CAN carry both rail-immediate negatives.)
; NOROUTE-NOT: call i32 @cq_template_xor_i32(
; NOROUTE-NOT: call i32 @cq_template_add_i32(
;
; FCNT — whole-file, MEASURED: this module frees NOTHING.
; FCNT-NOT: call void @cqrt_free(
;
; XCNT — whole-file EXACT in-place-gate count, MEASURED 1. The COUNT is the
; prefix's FIRST directive, so it matches the first occurrence in the file and
; the trailing NOT covers everything after it: an injected gate is caught at
; head AND at tail. NEVER put this positive count in NOROUTE (Inc-3 F-L6-1).
; XCNT-COUNT-1: call void @cqrt_addc_i32(
; XCNT-NOT: call void @cqrt_addc_i32(

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/7bbdb89e-f7ed-43f7-80e1-bda20ba33640/scratchpad/progress/fix_eqpx_work/p/k02_add_arg_imm.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/7bbdb89e-f7ed-43f7-80e1-bda20ba33640/scratchpad/progress/fix_eqpx_work/p/k02_add_arg_imm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @run(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #3
  br label %6

4:                                                ; preds = %6
  %5 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  ret i32 %5

6:                                                ; preds = %2, %6
  %7 = phi i32 [ 0, %2 ], [ %11, %6 ]
  %8 = phi i32 [ %3, %2 ], [ %10, %6 ]
  %9 = add nsw i32 %8, %1
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 1.000000e-01) #3
  %11 = add nuw nsw i32 %7, 1
  %12 = icmp eq i32 %11, 3
  br i1 %12, label %4, label %6, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
