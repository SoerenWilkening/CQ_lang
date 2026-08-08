; control_predmux_reject_selectform_curated_poison_immarg.ll — DECLINE
; (bd 3c6m.14.2). ARM: `curatedIntrinsicCanBePoison`.
;
; *** FOUND BY THE RULE-13 ROUND *ON THIS TICKET'S OWN FIRST FIX*, AND IT IS THE
; REASON THE FIX CHANGED DIRECTION. *** The first draft kept the shielded-cone
; call admission and added a definedness proof over the callee body. That draft
; still ACCEPTED this shape, and the result was the same class of verify-clean
; silent miscompile the ticket was opened to close:
;
;   opt exit 0 · opt -verify clean · free_pairing_check STRICT 6/6 verified
;   define internal i32 @__cq_q_leaf_1(i32 %a) { %c = call i32 @llvm.ctlz.i32(i32 0, i1 true)  ret i32 %c }
;
; and, linked and run, the trace fired
;
;   cq_template_icmp_sgt_i32_hl(h32, 0) -> h4
;
; a gate on rail h32 — an index `cqrt_alloc_*` never returned — with its `_unc`
; adjoint naming the same phantom.
;
; WHY EVERY OTHER MECHANISM IN THE FILE MISSES IT. `llvm.ctlz(x, is_zero_poison)`
; and `llvm.cttz(x, is_zero_poison)` return poison for x==0, and
; `llvm.abs(x, is_int_min_poison)` for INT_MIN, when the trailing `i1` is true.
; That `i1` is an **immarg** — an OPERAND, not an annotation:
;   * `hasPoisonGeneratingAnnotations()` does not see it (it is not a flag,
;     metadata, or a return attribute);
;   * no `drop*` API can strip it, so `stripPoisonCone`'s promised drop
;     structurally cannot reach it;
;   * it is a `ConstantInt`, so `valueCarriesUndef` does not see it either.
; Refusal is the only sound handling, and the refusal must be conservative when
; the immarg is not a ConstantInt.
;
; The poison is written INLINE here, not behind a call, deliberately: the call
; clause now admits only the curated set, so this is the shape that still reaches
; the admission. Every other member of that set is genuinely total —
; bswap/bitreverse/ctpop, smin/smax/umin/umax, the four `*_sat`, fshl/fshr (the
; rotate amount is modulo the width), and the p119 hardware fp survivors (NaN is
; not poison). Its positive control is
; control_predmux_accept_selectform_curated_total.ll, the SAME module with the
; immarg flipped to `false`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.ctlz.i32(i32, i1 immarg)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %r = call i32 @llvm.ctlz.i32(i32 %q, i1 true)   ; poison at %q == 0
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
