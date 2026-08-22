; lowering_ctlz_idiom_both_loops.ll — ACCEPT ×2 (bd ww4c Inc 1). The real
; `s_ilogb.c` control structure: ONE function whose two mutually exclusive arms
; each carry one of the two STRUCTURALLY DIFFERENT target loops (PRD §3.1) —
; the guarded, un-pre-shifted `lx` loop (:40, C0 = -1043) and the unguarded,
; pre-shifted `hx` loop (:42, C0 = -1022) — joining at one return merge whose phi
; has THREE incomings.
;
; This is the fixpoint pin: the driver claims AT MOST ONE loop per call (so every
; claim sees fresh dominance/taint/LoopInfo state — the flattenPredMuxRegions
; idiom), so reaching both requires the caller's `while (recognize…)` loop to
; turn twice, with a full re-propagate in between. TWO claims, two distinct
; emitted constants (-1044 and -1023), one function.
;
; ONE pass invocation; `CQ_SPEC_DBG=1` adds no spawn and captures the
; pre-`detectSpecializations` module on stderr, where the immarg is still visible
; (stdout is byte-identical with the env var set — measured, bd ww4c.4).
; RUN: env CQ_SPEC_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.spec.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CLEAN %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=IMMARG %s < %t.spec.ll
;
; PRD §4.5(1): BOTH claims emit the literal `i1 false`, not just the first. LLVM's
; canonical form for this idiom family emits `i1 true`, which PoisonFacts would
; then report as can-be-poison; this is the only layer that can see the immarg
; (Rule 15's width-only ABI drops it before the lowered form on stdout exists).
; IMMARG: call i32 @llvm.ctlz.i32(i32 %{{[a-zA-Z0-9_.]+}}, i1 false)
; IMMARG: call i32 @llvm.ctlz.i32(i32 %{{[a-zA-Z0-9_.]+}}, i1 false)
; IMMARG-NOT: call i32 @llvm.ctlz.i32(i32 %{{[a-zA-Z0-9_.]+}}, i1 true)
;
; Two independent closed forms, one per loop, each CAPTURED end to end.
;
; *** THESE WERE `CHECK-DAG` ON THE `sub` ALONE UNTIL Inc 3 (bd ww4c.4), AND THAT
; WAS BLIND TWICE OVER. With wildcard operands, (a) any mis-wiring of a chain
; passed, and (b) SWAPPING WHICH LOOP EACH CONSTANT TERMINATES — the right
; constants attached to the wrong loops, a genuine miscompile — also passed,
; because DAG order-insensitivity is exactly what makes that mutant invisible.
; Capturing each chain separately ties the constant to its OWN `and` result, and
; the emission order is deterministic, so ordered CHECKs are correct here. ***
;
; Loop B (the unguarded, pre-shifted `hx` loop, C0 = -1022 -> -1023):
; CHECK: %[[PRE:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 11)
; CHECK: %[[BS1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i32_hl(i32 %[[PRE]], i32 1)
; CHECK: %[[BZ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ctlz_i32(i32 %[[BS1]])
; CHECK: %[[BM:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[BZ]], i32 31)
; CHECK: call i32 @cq_template_sub_i32_lh(i32 -1023, i32 %[[BM]])
;
; Loop A (the guarded, un-pre-shifted `lx` loop, C0 = -1043 -> -1044):
; CHECK: %[[AS1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; CHECK: %[[AZ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ctlz_i32(i32 %[[AS1]])
; CHECK: %[[AM:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[AZ]], i32 31)
; CHECK: call i32 @cq_template_sub_i32_lh(i32 -1044, i32 %[[AM]])
;
; The intrinsic CALL is gone (the now-unused `declare` is left behind, as it is
; for every other lowered intrinsic — cf. lowering_intrinsic_ctlz_i32.ll).
; CLEAN-NOT: call {{.*}}@llvm.ctlz
; CLEAN-NOT: = add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @ilogb_both(i32 %uh, i32 %ul) {
entry:
  %hx = call i32 @cq_theta_si32(i32 %uh, double 5.000000e-01)
  %lx = call i32 @cq_theta_si32(i32 %ul, double 2.500000e-01)
  %subnormal = icmp eq i32 %hx, 0
  br i1 %subnormal, label %lxpath, label %hxpath

lxpath:                                           ; preds = %entry
  %g = icmp sgt i32 %lx, 0
  br i1 %g, label %loopA, label %merge

loopA:                                            ; preds = %lxpath, %loopA
  %ixA = phi i32 [ -1043, %lxpath ], [ %decA, %loopA ]
  %xA = phi i32 [ %lx, %lxpath ], [ %shA, %loopA ]
  %decA = add nsw i32 %ixA, -1
  %shA = shl nuw i32 %xA, 1
  %posA = icmp sgt i32 %shA, 0
  br i1 %posA, label %loopA, label %merge, !llvm.loop !0

hxpath:                                           ; preds = %entry
  %pv = shl nuw nsw i32 %hx, 11
  br label %loopB

loopB:                                            ; preds = %hxpath, %loopB
  %ixB = phi i32 [ -1022, %hxpath ], [ %decB, %loopB ]
  %xB = phi i32 [ %pv, %hxpath ], [ %shB, %loopB ]
  %decB = add nsw i32 %ixB, -1
  %shB = shl nuw i32 %xB, 1
  %posB = icmp sgt i32 %shB, 0
  br i1 %posB, label %loopB, label %merge, !llvm.loop !2

merge:                                            ; preds = %lxpath, %loopA, %loopB
  %r = phi i32 [ -1043, %lxpath ], [ %decA, %loopA ], [ %decB, %loopB ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.mustprogress"}
!2 = distinct !{!2, !1}
