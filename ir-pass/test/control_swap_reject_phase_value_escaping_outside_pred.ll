; control_swap_reject_phase_value_escaping_outside_pred.ll — DECLINE, a GAP pin (bd
; test_C_libtooling-dm7f.5 review round 1). The OffPattern partition's (C-iii) row,
; `phase-class value escaping`, lost its pin when dm7f.5 re-derived
; control_swap_reject_phase_value_escaping.ll (its module now merges to the twin's
; `impure phase arm`); this SINGLE-`ret` module, untouched by the `ret` merge, pins it.
; `if (k) return q; if (q > 5) cq_phi(.25); return q;` spelled as a phase TRIANGLE
; `%cont -> {%a, %m}` whose merge `%m` (the one `ret`) has a third, OUTSIDE predecessor
; (the classical `%k` edge from `entry`). The kickback classifier does not take a merge
; with an outside predecessor; `recoverRegion` then sees the arm `%m` `ret` a tainted
; value in a function carrying a branch phase, and (C-iii) fires — measured to come from
; `detectControlRegions`' OffPattern path (CQ_CTRL_BT), not from the abort park, which
; fires the same string. The program is valid, so this is an OVER-decline, kept loud.
; Retirement trigger: a kickback region whose merge has outside predecessors (split
; the merge, as the dm7f.5 merge now does for multi-exit functions — see
; control_multiexit_classical_exit_phase.ll, the same program with a `ret` per exit,
; which ACCEPTS) — re-derive this file then.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: phase-class value escaping under quantum control

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)

define i32 @example(i32 %u0, i1 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 %k, label %m, label %cont
cont:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %a, label %m
a:
  call void @cq_phi(double 2.500000e-01)
  br label %m
m:
  ret i32 %q
}
