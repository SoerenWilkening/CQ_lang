; control_inplace_ry_reject_inloop_frozen_leading_gate.ll — DECLINE: a FROZEN
; ZERO-HOP SELF-CARRY under a LEADING gate (bd test_C_libtooling-drbq Increment 3,
; PRD §13.3).
;
; The rotated base is a leading gate `%g = cq_theta(%p, .25)` in the loop header,
; exactly as in the S11 ACCEPT — but the rail phi below it is
; `%p = phi [ %r0, entry ], [ %p, merge ]`, a frozen self-carry rather than a real
; carry. `%p` re-executes every iteration and yields the SAME value while the
; register moves under it (`%g` is lowered IN PLACE onto `%r0`'s handle), so on
; iteration 2 the emitted `cqrt_ry_i32(h, .25)` reads a wire iteration 1 already
; rotated while the source names `%p`'s frozen state — the classic iteration-2
; stale read (bd [[identity-carry-phi-does-not-refresh]], a CONFIRMED silent
; miscompile reached through exactly this shape).
;
; WHICH CLAUSE REFUSES IT — MEASURED, NOT ASSUMED, AND THE FIRST ANSWER WAS WRONG.
; This fixture was written to isolate R6's REFRESH FENCE (`phiTracksWire(%p)` is
; false, because `%g` — a `cq_theta` on `%p`'s own wire — runs between the latch
; incoming and the edge). It does NOT isolate it: with the refresh fence deleted
; the module declines with the IDENTICAL message, because the PHI-EDGE READ
; POSITION rule refuses it first — `%p` is its own user on the LATCH edge, whose
; read position is the merge terminator, and `BI -> arm -> merge` never re-enters
; the header to re-execute `%p`. Recorded here rather than quietly re-labelled,
; because a fixture whose header names the wrong clause is worse than no fixture.
;
; ⚠ AND THE REFRESH FENCE IS PINNED BY NOTHING. Deleting it turns **zero of 1459**
; fixtures red (measured). Every shape that reaches it is also refused by the
; phi-edge rule above or, post-flatten, by `LoopLowering` round 2's
; `staleRailRecordRead`. It stays, because it is a CONSERVATIVE disjunct (false
; only ever ADDS declines), because it is the same predicate 8h7d.5 needed for a
; confirmed silent miscompile, and because Rule 14 says reuse the one spelling —
; but a reviewer should know it is currently defence in depth, not a live wall.
;
; ⚠ NOR IS R6 THE ONLY THING BEHIND THIS PROGRAM. Disable R6's per-activation
; certificate entirely and it still declines, at a DIFFERENT stage and with a
; DIFFERENT owner: `LoopLowering` round 2, post-flatten, printing `cq loop
; lowering: rail record read past an in-place gate on the same rail`. R6's value
; here is that it declines BEFORE emission and the flatten (Rule 9) and owns the
; accurate message; if round 2 is ever narrowed, R6 becomes the only wall.
;
; hand IR: `clang -O1` folds a zero-hop identity carry away, so the shape is not
; reachable from C.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: stale rail record read past a controlled Ry under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %p = phi i32 [ %r0, %entry ], [ %p, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %g = call i32 @cq_theta_si32(i32 %p, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %g, double 9.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %g, %loop ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
