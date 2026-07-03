; control_swap_select_inloop_hoisted_cond.ll — ACCEPT (bd 9ymx, owner decision
; 2026-07-03 option (a); RE-PINNED from the gate-2c cross-block conservative
; decline, a deliberate Rule-12 baseline action): the -O1-NATURAL in-loop
; ternary. clang -O1 LICM-hoists the loop-invariant fcmp into the loop guard
; block while the select (loop-variant false operand) stays in the body — so
; compare and select are in DIFFERENT blocks. Gate 2c's first cut declined
; every cross-block condition ("cannot bound the positional scan"); that
; blanket decline mis-branded this theta-free shape as a stale condition and
; blocked the owner-sanctioned loop conditional. The relaxation is SOUND
; because prong (a) — the position-free, router-crossing wire walk over the
; condition's tainted provenance — covers condition-wire staleness with NO
; window (any off-ancestry theta on the wire declines regardless of position),
; and the dropped positional prong only ever added other-wire conservatism
; (a theta on another register cannot move this condition's basis, so the
; per-iteration mint still equals the source compare); SSA dominance already
; guarantees the compare executes before the select on every path. Operand
; staleness stays owned by the wire-anchored gate 5 (off-ancestry rotations on
; the operand's lineage wires decline, position-free).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @slice(double %u0, i32 %n) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %preheader, label %exit
preheader:
  %c = fcmp ogt double %q, 5.000000e-01     ; LICM-hoisted, loop-invariant
  br label %loop
loop:
  %i = phi i32 [ 0, %preheader ], [ %i2, %loop ]
  %fi = uitofp i32 %i to double             ; loop-variant classical operand
  %sel = select i1 %c, double %q, double %fi
  %m = call double @cq_measure_f64(double %sel)
  %i2 = add i32 %i, 1
  %ic = icmp slt i32 %i2, %n
  br i1 %ic, label %loop, label %exit
exit:
  ret double 0.000000e+00
}

; CHECK:     loop:
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     %[[XH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %fi)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[XH]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call i32 @cq_template_fcmp_ogt_f64_hl_inv(
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[OUT]])
; CHECK:     br i1 %{{[a-zA-Z0-9_.]+}}, label %loop, label %exit
