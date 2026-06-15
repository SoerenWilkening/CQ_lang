; control_swap_reject_select_qqcond.ll — DECLINE: a tainted-condition
; integer-data `select` whose condition is a Q+Q compare (BOTH operands tainted).
; The WI-3 adversarial-review NIT (gate-2b message-brand fix).
;
; `(q > y) ? q : x` with `%q` and `%y` both `cq_theta` handles — the condition
; `icmp sgt %q, %y` is a quantum-quantum compare. `lowerCompareToFlag` is HL-only
; (handle + literal); there is no Q+Q flag-mint template, so the select declines.
; Gate 2b catches it at DETECTION and brands it `control flow` (the control
; dialect), rather than letting `emitSelectRegion`'s step-1 mint reach the
; straight-line data-path `no template` bail (which would mis-brand a control-flow
; decline as an arithmetic-lowering failure). Over-decline-safe; a Q+Q select
; condition is out of scope this increment regardless.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; the control dialect fires, NOT the straight-line data-path 'no template' brand:
; CHECK-NOT: no template
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %y   = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c   = icmp sgt i32 %q, %y                ; Q+Q condition (both tainted)
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
