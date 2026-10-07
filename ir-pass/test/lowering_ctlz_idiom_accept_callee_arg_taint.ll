; lowering_ctlz_idiom_accept_callee_arg_taint.ll — ACCEPT (bd p3kd.7.8; formerly
; lowering_ctlz_idiom_reject_callee_arg_taint.ll, bd ww4c.4's Z8 ARGUMENT-TAINT
; boundary). The accepted idiom, byte for byte, hosted in a CALLEE whose taint
; arrives ONLY through the call argument.
;
; WHY IT FLIPPED. The old fixture recorded an ORDERING fact: the ctlz pre-pass ran
; once, before `detectSpecializations` minted argument taint, so Z8 saw an
; untainted `%v` and the clone later declined on its loop. Its header named the
; widening path ("re-run the ctlz fixpoint after detectSpecializations … owed its
; own review round — do not do it as a side effect"). bd p3kd.7.8 is that widening,
; on purpose (owner direction 2026-10-07): a lifted clone runs MAIN'S stage list
; (StageList.h) under its own `cloneTaint`, whose roots ARE its params, so the ctlz
; pre-pass claims the idiom in `@__cq_q_callee_1`. The claim is the same Z1-Z9
; contract as lowering_ctlz_idiom_generic_seed.ll (that body with a local taint
; source); only the taint root differs (a param instead of a `cq_theta` result).
;
; Closed form (checked by hand): the loop returns -1022 - i, i the first shift
; count with `(v << i) <= 0` signed; that is -1023 - (ctlz(v << 1) & 31) for
; negative, zero and positive `v << 1` alike. The clone body is that straight-line
; template chain, then the Bennett copy-out and the mirror reverse.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @caller(
; CHECK:       call i32 @__cq_q_callee_1(
; CHECK-LABEL: define internal i32 @__cq_q_callee_1(i32 %v)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[S:[^ ]+]] = call i32 @cq_template_shl_i32_hl(i32 %v, i32 1)
; CHECK-NEXT:  %[[Z:[^ ]+]] = call i32 @cq_template_ctlz_i32(i32 %[[S]])
; CHECK-NEXT:  %[[M:[^ ]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Z]], i32 31)
; CHECK-NEXT:  %[[C:[^ ]+]] = call i32 @cq_template_sub_i32_lh(i32 -1023, i32 %[[M]])
; CHECK-NEXT:  %[[O:[^ ]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[C]], i32 %[[O]])
; CHECK-NEXT:  call void @cq_template_sub_i32_lh_unc(i32 %[[C]], i32 -1023, i32 %[[M]])
; CHECK-NEXT:  call void @cq_template_and_i32_hl_unc(i32 %[[M]], i32 %[[Z]], i32 31)
; CHECK-NEXT:  call void @cq_template_ctlz_i32_unc(i32 %[[Z]], i32 %[[S]])
; CHECK-NEXT:  call void @cq_template_shl_i32_hl_unc(i32 %[[S]], i32 %v, i32 1)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[S]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[Z]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[M]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT:  ret i32 %[[O]]
;
; No loop survives in the clone (the classical @callee keeps its own):
; RUN: %filecheck --check-prefix=NOLOOP %s < %t.ll
; NOLOOP-LABEL: define internal i32 @__cq_q_callee_1(
; NOLOOP-NOT:   {{phi|br }}
; NOLOOP:       ret i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; Structurally the accepted idiom in every respect — two phis, `shl <rec>, 1`,
; `add <ctr>, -1`, `icmp sgt <latch value>, 0`, six instructions, one escapee,
; i32, top-level, not in a cycle. ONLY the provenance of the taint differs.
define internal i32 @callee(i32 %v) {
entry:
  br label %scan

scan:                                             ; preds = %entry, %scan
  %k = phi i32 [ -1022, %entry ], [ %dec, %scan ]
  %w = phi i32 [ %v, %entry ], [ %sh, %scan ]
  %dec = add nsw i32 %k, -1
  %sh = shl nuw i32 %w, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %scan, label %out

out:                                              ; preds = %scan
  ret i32 %dec
}

define i32 @caller(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 1.250000e-01)
  %r = call i32 @callee(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
