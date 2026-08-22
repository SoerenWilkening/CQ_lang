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
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CLEAN %s < %t.cqd0.ll
;
; Two independent closed forms, one per loop. Order-insensitive: each constant is
; unique to its loop, so these assert presence, not sequence.
; CHECK-DAG: call i32 @cq_template_sub_i32_lh(i32 -1044, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-DAG: call i32 @cq_template_sub_i32_lh(i32 -1023, i32 %{{[a-zA-Z0-9_.]+}})
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
