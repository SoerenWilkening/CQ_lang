; lowering_inplace_rail_k01_arg_imm_xor_accept.ll — ACCEPT. bd
; test_C_libtooling-eqpx (P1), ACCEPT CONTROL 2 of 8, and one of the TWO that
; separate the shipped fence ("G2 alone, re-asked under FINAL taint") from the
; cheaper writer-side analogue ("`isa<Constant>(Imm)` at the loop writers",
; round 3's (1a) applied to W1/W2/W3). This program's immediate is a FUNCTION
; ARGUMENT — CLASSICAL, and not a `Constant`. An `isa<Constant>` fence at the
; writers would refuse it; G2 accepts it, today and after the fix.
;
;     __attribute__((noinline))
;     int run(int seed, int n){ int r=cq_theta(seed,0.3);
;       for(int i=0;i<3;i++){ r = r ^ n; }
;       return cq_measure(r); }
;
; `clang -O1`, `@main` dropped. `!llvm.loop` VERBATIM.
;
; `emitBreakForward`'s own comment (`LoopLowering.cpp:1528-1537`) records that
; dtzb DELIBERATELY accepts any untainted immediate, including a loop-variant one,
; refusing only what fails the reverse-play dominance test. Three measured
; capabilities (`k01` here, `k02`, `k03`) ride on that, against ZERO measured
; over-declines for the consumer-side re-ask — which is why the fix is a tripwire
; at the consumer and not a narrower predicate at the writers.
;
; MEASURED on frozen `main`@16b15b3 AND here: `cqrt_xorc_i32(i32 %h, i32 %1)` with
; `%1` the function's second ARGUMENT, `railInImm=0`, STRICT stage 2b
; `0 violation(s)`, 6 trace lines, lowered module BYTE-IDENTICAL across the two
; binaries (`cmp`).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=IMMCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; The in-place gate, with the classical ARGUMENT %1 in the immediate slot.
; CHECK: define i32 @run(i32 noundef %0, i32 noundef %1)
; CHECK: %[[R:.*]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK: call void @cqrt_xorc_i32(i32 %[[R]], i32 %1)

; EXACTLY ONE in-place gate, no out-of-place fallback rail for it, and — the
; point of the control — no rail-minting call anywhere for the immediate.
; IMMCNT-COUNT-1: call i32 @cqrt_alloc_i32(
; IMMCNT-NOT: call i32 @cqrt_alloc_i32(
; IMMCNT-COUNT-1: call void @cqrt_xorc_i32(
; IMMCNT-NOT: call void @cqrt_xorc_i32(
; IMMCNT-NOT: call i32 @cq_template_xor_i32(

; WHOLE-FILE PURE-NEGATIVE — the eqpx tripwire must NOT fire.
; NOROUTE-NOT: in-place rail op no longer provable at lowering
; NOROUTE-NOT: pre-loop in-place op no longer provable at lowering
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: call i32 @cq_template_

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/7bbdb89e-f7ed-43f7-80e1-bda20ba33640/scratchpad/progress/fix_eqpx_work/p/k01_xor_arg_imm.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/7bbdb89e-f7ed-43f7-80e1-bda20ba33640/scratchpad/progress/fix_eqpx_work/p/k01_xor_arg_imm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @run(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #3
  br label %6

4:                                                ; preds = %6
  %5 = tail call i32 @cq_measure_si32(i32 noundef %9) #3
  ret i32 %5

6:                                                ; preds = %2, %6
  %7 = phi i32 [ 0, %2 ], [ %10, %6 ]
  %8 = phi i32 [ %3, %2 ], [ %9, %6 ]
  %9 = xor i32 %8, %1
  %10 = add nuw nsw i32 %7, 1
  %11 = icmp eq i32 %10, 3
  br i1 %11, label %4, label %6, !llvm.loop !6
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
