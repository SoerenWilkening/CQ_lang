; loop_condtree_select_reject_nulled_root_rederived_escape.ll — DECLINE (bd
; test_C_libtooling-xdu2.16). A TOTAL RE-DERIVATION IS NECESSARY, NOT SUFFICIENT.
;
; The second neighbour the xdu2.16 predicate must still refuse. Its sibling
; `loop_condtree_select_reject_nulled_root_not_rederivable.ll` fails the
; re-derivation (clause (ii-d) cannot admit a round-2 root); THIS one passes it and
; fails `railLocalQualifies` itself, which the nulled path re-asks on the fresh set:
;   * a hoisted `(v > 1) & (u < 5)` tree feeds an in-loop 4.4 data select, so the
;     round-1 grant's `%d` root is erased by the emitter and goes NULL;
;   * a 6.5 classical-call arm OUTSIDE the loop merges `%m`, read in the body by
;     `%w = mul %m, %k`, and `%w` is read AFTER the loop. At round 1 `%m`/`%w` are
;     classical, so the grant is made; round 2 re-seeds from the 6.5 `%out`, `%w`
;     becomes a TAINTED iteration-local temp that ESCAPES the loop.
;   * the FINAL-taint re-derivation is TOTAL (`%v`, `%u` root mints; `%out` a
;     clause-(ii-b) merge out-rail), and `railLocalQualifies` then refuses on the
;     escaping temp — "an iteration-local temp escaping the loop".
; MEASURED: the pre-change ORACLE `438c77bf45c02e3e` declines it too (exit 1, this
; string, via the old unconditional nulled-root refusal), so the verdict is pinned
; on both sides of the change.
;
; ⚠ WHAT IT KILLS: the mutant that accepts a nulled grant on a total re-derivation
; ALONE (skipping `railLocalQualifies`). The `not_rederivable` sibling cannot kill
; it — that module never reaches the re-ask.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; ⚠ The `not` inversion is what pins the decline (Rule 12 hygiene (b)).
; CHECK: cq loop lowering: round-1 iteration-local marking falsified by round-2 taint

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @slice(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 2, double 2.500000e-01)
  %u = call i32 @cq_theta_si32(i32 3, double 7.500000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %m = phi i32 [ %r, %arm ], [ 5, %entry ]
  %d1 = icmp sgt i32 %v, 1
  %d2 = icmp slt i32 %u, 5
  %d = and i1 %d1, %d2
  br label %loop
loop:
  %k = phi i32 [ 1, %merge ], [ %k2, %loop ]
  %acc = phi i32 [ 0, %merge ], [ %s3, %loop ]
  %w = mul i32 %m, %k
  %sel = select i1 %d, i32 %k, i32 55
  %msel = call i32 @cq_measure_si32(i32 %sel)
  %s3 = add i32 %acc, %msel
  %k2 = add i32 %k, 1
  %e = icmp eq i32 %k2, 3
  br i1 %e, label %out, label %loop
out:
  %mw = call i32 @cq_measure_si32(i32 %w)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mv = call i32 @cq_measure_si32(i32 %v)
  %mu = call i32 @cq_measure_si32(i32 %u)
  %t0 = add i32 %s3, %mw
  %t1 = add i32 %t0, %mq
  %t2 = add i32 %t1, %mv
  %t = add i32 %t2, %mu
  ret i32 %t
}

attributes #0 = { nounwind willreturn memory(none) }
