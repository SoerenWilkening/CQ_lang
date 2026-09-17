; control_inplace_ry_crossblock_cond_wire_gate_after_loop.ll — ACCEPT, and it exists
; ONLY as the ISOLATING CONTROL for
; `control_inplace_ry_reject_crossblock_cond_wire_gate_in_gap.ll` (bd
; `test_C_libtooling-drbq.12`, 2026-09-17). The two modules differ by the POSITION of
; exactly one instruction: `%post = cq_theta(%1, 0.1)` — the sibling chained Ry on the
; CONDITION's own register — sits in the LATCH there and in the EXIT block here.
;
; That one move is the whole discriminator. In the latch the gate is inside the gap
; `[hoisted compare, mint at the header branch)` — the latch reaches the header around
; the BACK EDGE — so `crossBlockCompareMintable` finds it on the condition's rail and
; the module declines. In the exit block it is provably after the entire emitted
; stream (the exit cannot reach the header), so the wire walk's position-aware prong
; clears it and the ordinary in-place-Ry arm lowers.
;
; ⚠ WITHOUT THIS FILE THE NEGATIVE PINS NOTHING. Its twin declines on the pre-bead
; ORACLE too, at P4's unconditional cross-block bail — a different fence that never
; looks at the gate. Only the pair says that what the new prong refuses is a gate IN
; THE GAP rather than a cross-block compare as such.
;
; ⚠ DO NOT "TIDY" THE TWO MODULES APART. Every other token must stay identical or the
; pair stops isolating one variable, which is the only thing it is for.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTCRY %s < %t.cqd0.ll
; ---- MUTATION-MATRIX HARDENING (bd `test_C_libtooling-drbq.12`, 2026-09-17) ----
; Rule 12(c): a fixture is validated by MUTATION, not by re-reading its prefixes.
; The first injection-matrix run over this batch reported 21 MISSED over 9 accept
; fixtures — a stray `cqrt_ry` before the `ret`, a duplicated mint, a duplicated
; free, and a `cqrt_x` injected onto the USER REGISTER all slipped through, because
; no whole-file prefix counted those symbols here. The block below is the closure:
; an EXACT count per symbol (a `COUNT-n` followed by its own `-NOT`, which is what
; turns "at least n" into "exactly n"), ONE PREFIX PER SYMBOL because consecutive
; `COUNT`s under a shared prefix scan FORWARD and fall through to the trailing
; `declare` lines, and a pure-negative prefix for the two gates that must never
; appear. Counts are MEASURED off this fixture's own lowered output, never guessed.
; RUN: %filecheck --check-prefix=MXALLOC %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXRY %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXRYC %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMINT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXSTRIP %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXFREE %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMEAS %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXNONE --implicit-check-not="call void @cqrt_x(" --implicit-check-not="call void @cqrt_cswap(" --implicit-check-not="call void @cqrt_cnot(" %s < %t.cqd0.ll

; MXALLOC-COUNT-2: = call i32 @cqrt_alloc_
; MXALLOC-NOT: = call i32 @cqrt_alloc_
; MXRY-COUNT-3: call void @cqrt_ry_i32(
; MXRY-NOT: call void @cqrt_ry_i32(
; MXRYC-COUNT-1: call void @cqrt_ry_i32_controlled(
; MXRYC-NOT: call void @cqrt_ry_i32_controlled(
; MXMINT-COUNT-1: = call i32 @cq_template_icmp_
; MXMINT-NOT: = call i32 @cq_template_icmp_
; MXSTRIP-COUNT-1: call void @cq_template_icmp_
; MXSTRIP-NOT: call void @cq_template_icmp_
; MXFREE-COUNT-1: call void @cqrt_free(
; MXFREE-NOT: call void @cqrt_free(
; MXMEAS-COUNT-2: = call i32 @cqrt_measure_
; MXMEAS-NOT: = call i32 @cqrt_measure_
; MXNONE-NOT: call{{.*}}@cq_theta_
; MXNONE-NOT: call{{.*}}@cq_measure_si32
; MXNONE-NOT: call{{.*}}@cq_phi


; ⚠ THE CHECK ORDER IS TEXTUAL BLOCK ORDER, NOT EXECUTION ORDER. `RegionFlatten`
; leaves the EXIT block printed before the header, so the post-region gate appears
; ABOVE the loop body in the lowered module even though it runs after it. Reading this
; block as a trace is a mistake; the execution claim is in the header above.
; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; The post-region gate on the CONDITION register — the one instruction that moved.
; CHECK: call void @cqrt_ry_i32(i32 %[[H]], double 1.000000e-01)
; The shipped in-place-Ry arm stream, per trip, inside the ROLLED body.
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK: call void @cqrt_free(i32 %[[F]])

; CNTCRY-COUNT-1: call void @cqrt_ry_i32_controlled(
; CNTCRY-NOT: call void @cqrt_ry_i32_controlled(

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2
  %3 = icmp eq i32 %1, 5
  br label %hdr

exit:                                             ; preds = %latch
  %post = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e-01) #2
  %m1 = tail call i32 @cq_measure_si32(i32 noundef %merge) #2
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %post) #2
  %sum = add nsw i32 %m2, %m1
  ret i32 %sum

hdr:                                              ; preds = %0, %latch
  %ivphi = phi i32 [ 0, %0 ], [ %ivnext, %latch ]
  %rphi = phi i32 [ %2, %0 ], [ %merge, %latch ]
  br i1 %3, label %arm, label %latch

arm:                                              ; preds = %hdr
  %armt = tail call i32 @cq_theta_si32(i32 noundef %rphi, double noundef 9.000000e-01) #2
  br label %latch

latch:                                            ; preds = %arm, %hdr
  %merge = phi i32 [ %armt, %arm ], [ %rphi, %hdr ]
  %ivnext = add nuw nsw i32 %ivphi, 1
  %exitc = icmp eq i32 %ivphi, 0
  br i1 %exitc, label %hdr, label %exit, !llvm.loop !6
}

attributes #0 = { nounwind ssp uwtable }
attributes #2 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
