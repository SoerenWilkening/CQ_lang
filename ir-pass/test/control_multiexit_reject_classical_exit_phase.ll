; control_multiexit_reject_classical_exit_phase.ll — DECLINE, a GAP fixture (bd
; test_C_libtooling-dm7f.5): a CLASSICAL-condition exit mixed with a tainted one,
;     if (k) return q;  if (q > 5) { cq_phi(.25); return q; }  return q;
; with a `ret` per exit (hand IR). `unifyTaintedReturns` merges the three `ret`s (the
; tainted `br %c` reaches two of them with no block on every path between), folds
; the all-`%q` φ, and folds both empty former-`ret` blocks: the result is a phase
; TRIANGLE `%cont -> {%a, %m}` whose merge `%m` (the one `ret`) has a THIRD,
; outside predecessor — the classical `%k` edge from `entry`. The kickback
; classifier does not take a merge with an outside predecessor, and the OffPattern
; partition then fires `phase-class value escaping` (the merge arm `ret`s a tainted
; value in a function carrying a branch phase). The program is valid (the phase is
; on the flag; q returns coherent), so this is an OVER-decline of the normalized
; shape, kept loud, and the fixture that keeps that fence pinned since
; control_swap_reject_phase_value_escaping.ll's module now reaches a different one.
; The plain-C spelling (`if (k) return q; if (q > 5) cq_phi(.25); return q;`) is not
; this CFG: `clang -O1` fuses the two branches into `br (k | q < 6)` and declines
; `control flow` (a classical leaf in a quantum condition), measured on main
; 7b4e6359. On main this multi-exit module already declined with the same string,
; reached from the un-merged arm `%a` (`ret %q`); since dm7f.5 the decline is reached
; at `br i1 %c, label %a, label %cq.retmerge` (CQ_CTRL_DBG, measured), i.e. AFTER the
; merge. Retirement trigger: a kickback region whose merge has outside
; predecessors (split the merge, or let the classifier ignore edges that do not
; leave the region's entry) — re-derive this file then.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: phase-class value escaping under quantum control

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)

define i32 @example(i32 %u0, i1 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 %k, label %early, label %cont
early:
  ret i32 %q
cont:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %a, label %b
a:
  call void @cq_phi(double 2.500000e-01)
  ret i32 %q
b:
  ret i32 %q
}
