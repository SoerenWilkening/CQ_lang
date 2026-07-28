; control_swap_select_f16.ll — ACCEPT (RE-PINNED from the staged-out decline, a
; deliberate Rule-12 baseline action): the f16 fp-DATA select
; (fp-data-select-PRD §5; formerly control_swap_reject_select_f16.ll). The old
; fixture pinned "adding f16 as a recognized width must NOT open this door";
; the door is now opened DELIBERATELY, for `select` alone, by the §2
; three-legged angle fence (gate-3 carrier walk + escape guards +
; declineTaintedAngle backstop) — not by the width becoming recognized. The
; accept goes through the select-local `copyControlledFpFn` minting
; `cqrt_copy_f16_controlled`; the shared `copyControlledFn` integer fence is
; byte-identical (the 6.5 classical-call arm still declines fp via its null).
;
; Shape-for-shape the f16 analog of control_swap_select_fpdata.ll: both
; operands tainted, fcmp-ogt-minted flag, result measured (data, not an angle).
; 0xH4500 = 5.0, 0xH3C00 = 1.0 (exact in f16).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck --check-prefix=UNC %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

declare half @cq_theta_f16(half, double)
declare half @cq_measure_f16(half)

define half @example(half %u0) {
entry:
  %q   = call half @cq_theta_f16(half %u0, double 5.000000e-01)
  %qb  = fadd half %q, 0xH3C00                 ; a distinct tainted f16 data value
  %c   = fcmp ogt half %q, 0xH4500             ; tainted condition (ogt in scope)
  %sel = select i1 %c, half %q, half %qb       ; f16 DATA mux
  %m   = call half @cq_measure_f16(half %sel)  ; data sink (NOT an angle)
  ret half %m
}

; all-f16 stream; handles i32, classical operands at their real f16 width:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f16(half %u0)
; CHECK:     %[[QB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f16_hl(i32 %[[Q]], half 0xH3C00)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f16_hl(i32 %[[Q]], half 0xH4500)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f16(half 0xH0000)
; CHECK:     call void @cqrt_copy_f16_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_copy_f16_controlled(i32 %[[F]], i32 %[[QB]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_fcmp_ogt_f16_hl_unc(i32 %[[F]], i32 %[[Q]], half 0xH4500)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call half @cqrt_measure_f16(i32 %[[OUT]])
; bd `8txa`: the flag STRIP is itself a `_unc` now, so the pre-8txa blanket
; `CHECK-NOT: _unc` cannot be restored verbatim. Pin the exact population
; instead — EXACTLY ONE `_unc` call in the module, and it is the compare
; strip. Strictly stronger than the blanket form for the double-strip case
; (a second strip on an already-freed rail is a UAF + wrong unitary), and
; it still forbids any DATA uncompute (that would be a second `_unc` call).
; UNC-COUNT-1: call void @cq_template_{{[if]}}cmp_{{[a-zA-Z0-9_]+}}_unc(
; UNC-NOT:     call {{.*}}_unc(
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: cqrt_copy_i
