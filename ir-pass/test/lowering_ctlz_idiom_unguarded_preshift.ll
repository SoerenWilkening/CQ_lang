; lowering_ctlz_idiom_unguarded_preshift.ll — ACCEPT (bd ww4c Inc 1, the Z1–Z9
; fence in CtlzIdiomPrepass.cpp). The `s_ilogb.c:42` / `s_ilogbf.c:35` shape,
; measured at -O1 (PRD §3.1 loop B): UNCONDITIONAL entry — clang folded the
; source guard away, having proved the entry value positive — with the PRE-SHIFT
; `shl nuw nsw %hx, 11` sitting in the PREHEADER, outside the loop.
;
; This is PRD §5.4's accept-invariance pin, and the pair partner of
; lowering_ctlz_idiom_guarded_no_preshift.ll (loop A, which has NO pre-shift).
; The recognizer takes the shift recurrence's preheader incoming as an OPAQUE
; Value and must NEVER look through it: the closed form
; f(v) = 1 + (ctlz(v<<1) & (N-1)) is exact for ANY v on the whole domain, so the
; pre-shift is invisible to the fence. An implementation that tried to FOLD the
; pre-shift into the constant would get it wrong — that, not a decline, is the
; hazard here.
;
; C0 = -1022, so the emitted constant is C0-1 = -1023.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CLEAN %s < %t.cqd0.ll
;
; The preheader pre-shift survives UNTOUCHED as its own tainted op (by 11)...
; CHECK: call i32 @cq_template_shl_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 11)
; ...and the four-op closed form replaces the loop.
; CHECK: call i32 @cq_template_shl_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; CHECK: call i32 @cq_template_ctlz_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK: call i32 @cq_template_and_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 31)
; CHECK: call i32 @cq_template_sub_i32_lh(i32 -1023, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; The loop is GONE and no intrinsic survives.
; CLEAN-NOT: = phi
; CLEAN-NOT: br i1
; The intrinsic CALL is gone (the now-unused `declare` is left behind, as it is
; for every other lowered intrinsic — cf. lowering_intrinsic_ctlz_i32.ll).
; CLEAN-NOT: call {{.*}}@llvm.ctlz

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @ilogb_hx_loop(i32 %u) {
entry:
  %hx = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %pv = shl nuw nsw i32 %hx, 11
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %pv, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %exit, !llvm.loop !0

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %dec)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.mustprogress"}
