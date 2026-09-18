; loop_pairing_reject_round2_falsified_postloop_read.ll — DECLINE (bd
; `test_C_libtooling-4jok`, 2026-09-21).  THE REPLACEMENT WITNESS FOR
; `declineRound2FalsifiedRailGrants`, AND IT EXISTS BECAUSE THE OLD ONE STOPPED
; BEING ONE.
;
; ⚠ READ THIS WITH `loop_pairing_reject_round2_falsified.ll`, WHICH IS NOW AN
; ACCEPT.  That file was the L1 fence's ONLY pin and its own header gave the
; decline a ground — *"`%m2`'s forward gate is in the loop PREHEADER and runs
; ONCE, while a marked body's discharge point runs K times … K adjoints against
; ONE forward gate"* — which bd `tu9q`'s P1 (`multiplicityAgrees`) and P2 (the
; loop-exit anchor) RETIRE: measured on the composed binary, that module mints
; `cq_template_mul_i32_hl` ONCE in the preheader and adjoints it ONCE in the
; loop-EXIT block, stage-2b `4 template rail mint(s) of which 0 left dirty`.
; The hazard is refuted by construction, so the decline had to go.
;
; ⚠ BUT THE FENCE DID NOT GO.  `declineRound2FalsifiedRailGrants` is still called
; at BOTH entry points (`CQLoweringPass.cpp:829` / `:1313`), and the old file's
; header names a SECOND job that the accept destroys: *"AND IT PROVES THE WINDOW
; IS REACHABLE.  A fence written for an L1 window nobody can construct is a
; prediction, not a test (`CLAUDE.md` L10)."*  Landing `tu9q` P0+P3 without this
; file would leave a LIVE Rule-13 L1 fence with ZERO fixtures in 2109 — the
; test-debt class bd `6uqc` already carries one instance of.
;
; THE ONE EDIT, and it is chosen at (ii-d)'s own subject.  Clause (ii-d) requires
; `allUsersInside(V, L)`, a conjunct its comment calls *"NOT CONSERVATISM — IT IS
; THE CLAUSE'S SUBJECT"*: the rail it reasons about is one `-O1` hoisted OUT of
; the body whose only reader is the body.  `%after = and i32 %m2, 1` in `%out`
; gives `%m2` a reader AFTER the loop, so (ii-d) refuses the root, the round-1
; grant stays falsified, and the fence speaks again.  Nothing else is touched.
;
; MEASURED 2026-09-21 on BOTH binaries — MAIN `8280ea8d…` (the shipped compiler,
; where the old file also still declines) and COMPOSED `3368af12…` (MAIN + `tu9q`
; P0+P3): exit 1, this exact string.  ⚠ That it declines on MAIN TOO is the point,
; not a defect: this file pins the fence on the tree as it stands AND on the tree
; after the landing, so it cannot be vacuous on either side of it.
;
; ⚠ L8 RETIREMENT TRIGGER: this file moves the day `allUsersInside` is widened to
; admit a post-loop reader, or the day (ii-d) gains a spelling that does not ask
; it.  RE-DERIVE it then — and do NOT predict which string it lands on, because
; every trigger in this bead's history that named the next wall has been a LOWER
; BOUND (session protocol item 4).
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
  %after = and i32 %m2, 1
  %y2 = call i32 @cq_theta_si32(i32 %y, double 9.000000e-01)
  %mm = call i32 @cq_measure_si32(i32 %y2)
  %t0 = add i32 %s2, %mm
  %t = add i32 %t0, %after
  ret i32 %t
}

attributes #0 = { nounwind willreturn memory(none) }
