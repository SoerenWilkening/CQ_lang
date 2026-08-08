; control_predmux_reject_selectform_purecallee_poisonflag.ll — DECLINE
; (bd 3c6m.14.2). ARM: the DELETED pure-callee disjunct — the FLAG face.
;
; THE ARM, AND WHY IT IS *NOT* THE SAME AS THE INHERENT-POISON ONE. `add nsw` is
; on the whitelist — INLINE it is admitted, precisely because `stripPoisonCone`
; DROPS the `nsw` at flatten time and the value is then total. That drop reaches
; `I->operands()` only. It never enters a callee body, and no other stage of the
; pass strips a callee's flags before the Phase-6 clone is built from it. So
; inside a callee the flag cannot be dropped, only OBSERVED — and an `add nsw`
; that overflows returns poison exactly as a variable shift does.
;
; This file therefore pins a THIRD, independent face of the same defect, beside
; the inherent-poison one (..._inherentpoison.ll) and the vacuous-purity one
; (..._retpoison.ll): even a callee written entirely from whitelisted opcodes,
; with a defined return value, can return poison — because the poison lives in a
; FLAG. Any future re-widening of this clause has to answer all three, plus the
; curated immarg (..._curated_poison_immarg.ll), plus whatever LLVM adds next.
; That growing list is the argument for the deletion.
;
; The same face covers `nuw`, `exact`, `disjoint`, `nneg`, `inbounds`, the FMF
; flags, and `!range`/`!nonnull`/`!align` metadata.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leaf(i32 %a) {
e:
  %x = add nsw i32 %a, 1        ; poison at %a = INT_MAX; no drop reaches here
  ret i32 %x
}

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %r = call i32 @leaf(i32 %q)
  %b = icmp sgt i32 %r, 0
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; DBG: leave @probe entry=entry merge=merge gate=E6-condtree
