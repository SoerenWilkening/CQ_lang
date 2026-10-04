; lowering_inplace_rail_ctlA_const_imm_accept.ll — ACCEPT. bd
; test_C_libtooling-eqpx (P1), ACCEPT CONTROL 1 of 8. The BASELINE in-place rail
; op: a `lowerLoops`-proven `r = r ^ 7` whose immediate is a `ConstantInt` and can
; never become tainted. If the consumer tripwire fired here it would not be a
; fence, it would be a blanket refusal of the whole dtzb capability.
;
;     int slice(int u){ int q=u; cq_theta(&q,0.5); int r=u; cq_theta(&r,0.3);
;       for(int i=0;i<3;i++){ r = r ^ 7; }
;       return cq_measure(r)+cq_measure(q); }
;
; `clang -O1`, `@main` dropped. `!llvm.loop` VERBATIM.
;
; MEASURED on frozen `main`@16b15b3 AND here: ONE `cqrt_xorc_i32(i32 %h1, i32 7)`
; in the rolled body, `railInImm=0`, STRICT stage 2b `0 violation(s)`, 9 trace
; lines, and the whole lowered module BYTE-IDENTICAL across the two binaries
; (`cmp`).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=IMMCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll

; The rolled body's in-place gate, with a REAL constant in the immediate slot.
; CHECK: %[[Q:.*]] = call i32 @cqrt_alloc_i32(
; CHECK: %[[R:.*]] = call i32 @cqrt_alloc_i32(
; CHECK: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK: call void @cqrt_xorc_i32(i32 %[[R]], i32 7)

; EXACTLY ONE in-place gate, and no out-of-place fallback rail for it.
; IMMCNT-COUNT-1: call void @cqrt_xorc_i32(
; IMMCNT-NOT: call void @cqrt_xorc_i32(
; IMMCNT-NOT: call i32 @cq_template_xor_i32(
; IMMCNT-NOT: call i32 @cq_template_xor_i32_hl(

; WHOLE-FILE PURE-NEGATIVE — the eqpx tripwire must NOT fire, and no rail may
; reach the classical-immediate slot of any in-place gate.
; NOROUTE-NOT: in-place rail op no longer provable at lowering
; NOROUTE-NOT: pre-loop in-place op no longer provable at lowering
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: @cq_phi

; ── round-1 lens F-E1-3: the accept controls under-asserted. 48 injections
; over these 8 fixtures (a rail-immediate `cqrt_xorc_i32(i32 %h, i32 %rail)`,
; an extra out-of-place `cq_template_xor_i32`, an extra `cqrt_free`, each at
; head and tail) were caught 20/48 — every free MISSED by all 8, because no
; accept fixture carried a free count. The blocks below close that; the counts
; are DERIVED from this fixture's own pass output, not guessed.
; ⭐ THIS fixture — alone among the eight — can carry BOTH stems' rail-immediate
; negative, because its own legitimate gate's immediate is the LITERAL `i32 7`:
; a `ConstantInt` prints without a `%`, so `i32 %…, i32 %…` cannot match it and
; the negative says exactly "no rail in the immediate slot", whole-file, for
; either stem. (`k01`/`k02`/`k03` cannot — their immediate is an Argument or a
; volatile load, i.e. the non-Constant classical immediate dtzb deliberately
; accepts, so the same pattern would fire on the gate the control exists to keep.
; They pin the count instead — see their XCNT blocks.)
; NOROUTE-NOT: call void @cqrt_xorc_i{{[0-9]+}}(i32 %{{.*}}, i32 %{{.*}})
; NOROUTE-NOT: call void @cqrt_addc_i
; NOROUTE-NOT: call void @cqrt_addc_i{{[0-9]+}}(i32 %{{.*}}, i32 %{{.*}})
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
; XCNT-COUNT-1: call void @cqrt_xorc_i32(
; XCNT-NOT: call void @cqrt_xorc_i32(

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/7bbdb89e-f7ed-43f7-80e1-bda20ba33640/scratchpad/progress/fix_eqpx_work/p/ctlA_clean_xor_const.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/7bbdb89e-f7ed-43f7-80e1-bda20ba33640/scratchpad/progress/fix_eqpx_work/p/ctlA_clean_xor_const.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #2
  br label %8

4:                                                ; preds = %8
  %5 = tail call i32 @cq_measure_si32(i32 noundef %11) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %2) #2
  %7 = add nsw i32 %6, %5
  ret i32 %7

8:                                                ; preds = %1, %8
  %9 = phi i32 [ 0, %1 ], [ %12, %8 ]
  %10 = phi i32 [ %3, %1 ], [ %11, %8 ]
  %11 = xor i32 %10, 7
  %12 = add nuw nsw i32 %9, 1
  %13 = icmp eq i32 %12, 3
  br i1 %13, label %4, label %8, !llvm.loop !6
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
