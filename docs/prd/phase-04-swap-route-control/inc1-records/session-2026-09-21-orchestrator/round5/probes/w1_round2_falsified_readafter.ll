; W1 — `loop_pairing_reject_round2_falsified.ll` with ONE line changed: `%m2` is
; ALSO read AFTER the loop (`%t2 = add %t, %m2`), so clause (ii-d)'s `allUsersInside`
; conjunct is FALSE and the round-2 re-derivation cannot rescue the round-1 grant.
;
; WHY IT EXISTS.  On the COMPOSED binary the shipped fixture ACCEPTS, so
; `declineRound2FalsifiedRailGrants` — the L1 cure for the round-1 root-mint grant —
; loses its ONLY witness.  A fence nobody can make fire is a prediction, not a test
; (CLAUDE.md L10).  This module asks whether the fence is still REACHABLE at all.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
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
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %m = phi i32 [ %r, %arm ], [ 5, %entry ]
  %m2 = mul i32 %m, 2
  br label %loop
loop:
  %k = phi i32 [ 1, %merge ], [ %k2, %loop ]
  %acc = phi i32 [ 0, %merge ], [ %s2, %loop ]
  %sh = lshr i32 %y, %k
  %an = and i32 %sh, %m2
  %ms = call i32 @cq_measure_si32(i32 %an)
  %s2 = add i32 %ms, %acc
  %k2 = add i32 %k, 1
  %e = icmp eq i32 %k2, 3
  br i1 %e, label %out, label %loop
out:
  %y2 = call i32 @cq_theta_si32(i32 %y, double 9.000000e-01)
  %mm = call i32 @cq_measure_si32(i32 %y2)
  %t = add i32 %s2, %mm
  %mo = call i32 @cq_measure_si32(i32 %m2)
  %t2 = add i32 %t, %mo
  ret i32 %t2
}

attributes #0 = { nounwind willreturn memory(none) }
