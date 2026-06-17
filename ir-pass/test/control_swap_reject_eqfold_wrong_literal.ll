; control_swap_reject_eqfold_wrong_literal.ll — D4 decline (4.5 WI-5).
;
; The equality compare tests `q == 7`, but the arm's const-folded gate base is a
; DIFFERENT literal (`cq_phi(i32 9, θ)`). `clang -O1` would never produce this
; (the fold derives the constant FROM `q==7`, so it is always 7) — it is the
; adversarial near-miss that exercises `tryEqFoldArm` D4: the icmp literal must
; equal the folded spine constant by APInt/width. With 9 != 7, D4 returns false,
; `tryEqFoldArm` does NOT accept, and the const-folded base falls through to the
; generic decline. A const base has NO other accept path (only `tryEqFoldArm`
; recognizes one), so the region declines loudly — never silently lowered routing
; the wrong literal (Prime Directive: over-decline is safe).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 7
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 9, double %a)   ; folded const 9 != icmp literal 7
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
