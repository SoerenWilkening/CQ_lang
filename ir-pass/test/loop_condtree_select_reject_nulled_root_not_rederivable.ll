; loop_condtree_select_reject_nulled_root_not_rederivable.ll — DECLINE (bd
; test_C_libtooling-xdu2.16). A NULLED ROOT DOES NOT EXCUSE THE RE-ASK.
;
; bd xdu2.16 stopped treating a nulled round-1 root as a refusal BY ITSELF: the
; grant is instead RE-DERIVED from scratch under FINAL taint by
; `invariantRegisterRoots`, and that re-derivation must be TOTAL. This file is the
; neighbour the widened predicate must still refuse: a nulled root AND a
; re-derivation that is NOT total.
;
; It is `loop_pairing_reject_round2_falsified_postloop_read.ll` (the tu9q L1
; fence's live witness) with ONE addition: a hoisted compound condition over two
; fresh registers `%v`, `%u`, read in the loop by a 4.4 data select. So:
;   * ROUND 1 grants the body on {`%y`, `%d`} — `%d` the hoisted `and`, admitted by
;     clause (ii-d); `%m2` is still classical (the 6.5 merge is untainted).
;   * The 4.4 emitter erases `%d`, `%d1`, `%d2` — the round-1 record for `%d` goes
;     NULL (the xdu2.16 shape).
;   * ROUND 2 taints `%m2` through the 6.5 `%out`, and `%m2` has a reader AFTER
;     the loop (`%after`), so clause (ii-d)'s `allUsersInside` refuses it and the
;     FINAL-taint re-derivation is NOT total.
; Both halves must decline, and do, with the fence's own string. MEASURED on the
; pre-change ORACLE `438c77bf45c02e3e` (exit 1, this string — reached through the
; old unconditional nulled-root refusal) and on the xdu2.16 binary (exit 1, this
; string — reached through the totality requirement). So the verdict is pinned on
; both sides of the change and cannot be vacuous on either.
;
; ⚠ WHAT IT KILLS: the mutant that WITHDRAWS a nulled grant silently (skips the
; loop, or re-asks only the surviving round-1 roots without re-deriving): the
; body would then accept with a round-2-tainted derived rail read per trip and
; never discharged — the L1 PREDICATE species this fence exists for.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; ⚠ The `not` inversion on the RUN line is what pins the decline: a `DS_Error`
; writes 0 bytes to stdout, so an IR-text `CHECK-NOT` here would be VACUOUS
; (Rule 12 fixture-hygiene defect (b)).
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
  %y = call i32 @cq_theta_si32(i32 7, double 3.000000e-01)
  %v = call i32 @cq_theta_si32(i32 2, double 2.500000e-01)
  %u = call i32 @cq_theta_si32(i32 3, double 7.500000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %m = phi i32 [ %r, %arm ], [ 5, %entry ]
  %m2 = mul i32 %m, 2
  %d1 = icmp sgt i32 %v, 1
  %d2 = icmp slt i32 %u, 5
  %d = and i1 %d1, %d2
  br label %loop
loop:
  %k = phi i32 [ 1, %merge ], [ %k2, %loop ]
  %acc = phi i32 [ 0, %merge ], [ %s3, %loop ]
  %sh = lshr i32 %y, %k
  %an = and i32 %sh, %m2
  %ms = call i32 @cq_measure_si32(i32 %an)
  %sel = select i1 %d, i32 %k, i32 55
  %msel = call i32 @cq_measure_si32(i32 %sel)
  %s2 = add i32 %ms, %acc
  %s3 = add i32 %s2, %msel
  %k2 = add i32 %k, 1
  %e = icmp eq i32 %k2, 3
  br i1 %e, label %out, label %loop
out:
  %after = and i32 %m2, 1
  %y2 = call i32 @cq_theta_si32(i32 %y, double 9.000000e-01)
  %mm = call i32 @cq_measure_si32(i32 %y2)
  %mv = call i32 @cq_measure_si32(i32 %v)
  %mu = call i32 @cq_measure_si32(i32 %u)
  %t0 = add i32 %s3, %mm
  %t1 = add i32 %t0, %after
  %t2 = add i32 %t1, %mv
  %t = add i32 %t2, %mu
  ret i32 %t
}

attributes #0 = { nounwind willreturn memory(none) }
