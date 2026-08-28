; lowering_reject_live_record_post_gate_record_loop.ll — DECLINE: the F2
; existence skip must NOT fire across a loop back edge (M-A, bd
; test_C_libtooling-6uqc; 2026-08-28).
;
; SOURCE — the loop twin of lowering_live_record_post_gate_record_accept.ll:
;     for (int i = 0; i < n; i++) {
;         int q = cq_theta(x, 0.25);     // a fresh source rail per iteration
;         int w = q * 2;                 // THE WIRE
;         w = cq_theta(w, 0.5);          // T — chained, in-place Ry, IN THE BODY
;         int z = q * 3;                 // minted after T ... and T runs again
;         int y = q * 5;
;         cq_measure(y); cq_measure(w);
;     }
;
; WHAT IT PINS. The F2 skip is `provablyBefore(T, R)` =
; `DT.dominates(T, R) && !isPotentiallyReachable(R, T)`. The straight-line twin
; passes both halves and lowers. Here the FIRST half still holds — `%z` is
; textually after the gate and dominated by it — but the back edge makes `T`
; reachable again from `%z`, so the second half fails and the record keeps
; counting. Weaken the test to bare dominance and this module's post-gate record
; would be skipped: the guard would stop looking at a rail that really is standing
; when the next iteration's `Ry` fires.
;
; THE SECOND HALF IS MUTANT-VERIFIED, NOT ASSERTED. Replacing
; `provablyBefore(T, R)` with `DT->dominates(T, R)` in the driver and re-running
; this fixture was measured during the F2 round; it is recorded here because a
; guard clause nobody has tried to defeat is a clause nobody should trust
; (the `tools/free_pairing_check_test.py` argument).
;
; HONEST SCOPE — READ THIS BEFORE USING THE FIXTURE AS A WITNESS. The decline is
; NOT carried by `%z` alone, and it CANNOT be made to be, because clause 3 has a
; position test of its own: `provablyBefore(T, use)` fails for EVERY use inside a
; loop body (the back edge again), so no record in a loop body can ever be
; exempted by an observation and the ancestor rail `%h` declines here too. That
; makes this file a REGRESSION pin — "a chained theta in a loop body does not
; silently accept" — rather than an isolating witness for the F2 clause. An
; isolating one is not constructible at this increment; if a later increment makes
; clause 3 loop-aware, this fixture becomes the isolating witness for free, which
; is exactly why it is worth keeping.
;
; It also declines in BOTH directions of the fix (pre- and post-F1/F2, measured),
; for the same reason: nothing about a loop body was accepted before either.
;
; ── AND THAT SCOPE NOTE HAS A C-REACHABLE COST. NAME IT, DO NOT LEAVE IT AS A
; PROPERTY OF THIS FIXTURE (the reviewer's N4, round 2 of the Inc-3 Rule-13 round,
; 2026-08-28). The "no record in a loop body can be exempted by an in-body
; observation" sentence above is not a curiosity of the constructed SSA below; it
; is a REGRESSION Increment 3 introduced, measured end to end on ordinary C:
;
;     for (int i = 0; i < n; i++) {
;         int q = cq_theta(u0, 0.25);
;         int w = q * 2;
;         w = cq_theta(w, 0.5);                    // T
;         acc += cq_measure(q) + cq_measure(w);    // BOTH rails measured, in body
;     }
;
; Every record here is measured in the same iteration that mints it, so there is
; nothing dead at the gate at all — and it DECLINES, because clause 3 cannot see an
; observation it cannot place after `T`. MEASURED: HEAD (d2828e3) `opt` exit 0;
; Increment 3 (round 1 AND round 2) `opt` exit 1. The ancestor rail `%h` carries it,
; exactly as it carries this fixture's decline.
;
; It is an OVER-decline, so it is the safe direction and not a Prime-Directive
; defect — but it is a real capability loss on the shape Grover repetition is
; written in, it is NOT closed by round 2, and it is tracked in bd rather than here.
; A fix belongs with a loop-aware clause 3 (an observation anywhere in the same
; iteration's body, or a post-dominance reading that admits the back edge), which is
; a scope decision, not a bug fix.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define void @slice(i32 %x, i32 %n) {
entry:
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i   = phi i32 [ 0, %entry ], [ %inext, %loop ] ; classical induction
  %q   = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)  ; fresh rail per iteration
  %w   = mul i32 %q, 2                                          ; THE WIRE
  %q2  = call i32 @cq_theta_si32(i32 %w, double 5.000000e-01)   ; T — in the body
  %z   = mul i32 %q, 3                            ; minted after T, re-run over it
  %y   = mul i32 %q, 5
  %my  = call i32 @cq_measure_si32(i32 %y)
  %mw  = call i32 @cq_measure_si32(i32 %q2)
  %inext = add nuw nsw i32 %i, 1
  %done  = icmp eq i32 %inext, %n                 ; classical exit condition
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %entry, %loop
  ret void
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
