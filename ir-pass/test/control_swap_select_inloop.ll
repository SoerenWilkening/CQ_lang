; control_swap_select_inloop.ll — ACCEPT pin (bd 9ymx, owner decision
; 2026-07-03: conditionals in loops are ALLOWED — option (a), per-iteration
; semantics documented as intended): a tainted-condition data select INSIDE a
; classical loop body, compare and select in the SAME block. There is no
; select analog of the d8jl `regionEntryInLoop` decline BY DESIGN: a select
; has no CFG surgery (no flatten across a backedge — the structural hazard
; d8jl guards against does not exist), and the per-iteration stream is
; faithful — each iteration mints a fresh flag from the unchanged q, copies
; into a FRESH |0> out rail (a fresh runtime handle per iteration), strips,
; and frees exactly the flag; the per-iteration measure is user-written
; (Rule 5). q stays allocated across iterations (leaked, Rule 6).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @slice(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i2, %loop ]
  %t = fadd double %q, 1.000000e+00
  %c = fcmp ogt double %q, 5.000000e-01
  %sel = select i1 %c, double %t, double 2.500000e-01
  %m = call double @cq_measure_f64(double %sel)
  %i2 = add i32 %i, 1
  %ic = icmp slt i32 %i2, 3
  br i1 %ic, label %loop, label %exit
exit:
  ret double 0.000000e+00
}

; the six-step merge lands INSIDE the intact loop block (no flatten):
; CHECK:     loop:
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f64_hl(
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[T]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %[[F]], 
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[OUT]])
; the loop CFG survives (per-iteration semantics — the backedge is intact):
; CHECK:     br i1 %{{[a-zA-Z0-9_.]+}}, label %loop, label %exit
