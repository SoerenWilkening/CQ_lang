; lowering_stale_reader_inloop_once_guarded_accept.ll — ACCEPT.
;
; THE Rule-13 ROUND-2 FINDING (bd test_C_libtooling-3d8q, F-D2-2), pinned in the
; ACCEPT direction. A reader on a loop-INVARIANT quantum name, inside a loop, in a
; block that executes EXACTLY ONCE:
;
;   int q = 0; cq_theta(&q, 0.3);
;   for (int i = 0; i < 3; i++)
;     if (i == 0) { int b = q; cq_theta(&b, 0.1); s += cq_measure(b); } else s += 1;
;
; ⚠ ITS ONE-TOKEN SIBLING IS A DECLINE and that is the whole discrimination:
; `lowering_reject_stale_reader_inloop_invariant_seed.ll` is this module with the
; guard REMOVED (the reader runs every trip, three states of one register named by
; one consumed name), and
; `lowering_reject_stale_reader_inloop_repeatable_guard.ll` is this module with
; `i == 0` replaced by a RUNTIME comparison that can hold on many trips. Both
; decline; this accepts. Neither the accept nor the repeatable-guard decline was
; pinned before these files existed.
;
; WHY IT IS WELL FORMED. The 2026-09-14 owner ruling declined the in-loop
; invariant re-read because the source admits TWO realizable circuits (a chain,
; or a fresh per-trip preparation) and names NEITHER. A reader that executes once
; admits exactly ONE — the two readings coincide — so the ruling's own rationale
; is absent, and declining it is an over-decline (an over-decline is a DEFECT,
; owner ruling 2026-09-11). Measured: on the pre-fence compiler this module
; emitted `alloc; ry(.25); ry(.9); measure`, which is the correct circuit, and
; that is the stream pinned below.
;
; THE PROOF THE PASS RUNS (`WireWalk.cpp`, leg 1b of `readerStalesItself`): the
; header's guard `icmp eq %i, 0` is rewritten to the value it takes ON THE LATCH
; EDGE (`%i` ← `%inext`) and ScalarEvolution proves `%inext != 0` for EVERY
; iteration, so the guard is false on every arrival from the latch; the reader's
; block has the header as its ONLY predecessor; and the preheader is not
; reachable from the reader, so the loop is never re-entered. Hence at most one
; execution of the reader, hence nothing for it to stale.
;
; ⚠ WHAT THE LEG DOES **NOT** PROVE, measured on this exact module rather than
; argued (probes in `trackD/fix_r2_probes/adv/`, binary `4394b3495c1c539f`):
;   * `if (i == 1)` (`a3_guard_eq1.ll`) — still DECLINES. The reader runs exactly
;     once there too, but not on the FIRST trip, and the leg proves "the guard is
;     false on every arrival from the latch", which is strictly narrower than "the
;     guard holds on at most one iteration". A known, SAFE residual over-decline,
;     filed with F-D2-2; widening it means a monotonic-add-recurrence argument and
;     its own Rule-13 round, because that is an ACCEPT-direction relaxation.
;   * `if (i < 2)` (`a4_guard_slt2.ll`) — DECLINES, and CORRECTLY: the reader runs
;     on two trips and genuinely stales itself. This is the control that shows the
;     leg is not "any constant-compare guard accepts".
;   * a RUNTIME start value for `%i` (`a5_runtime_start.ll`) — DECLINES, and
;     CORRECTLY: with `%u1 == -1` the guard is true again on trip 2. This is the
;     soundness control for the ScalarEvolution step; if it ever accepts, leg 1b
;     has become an OVER-ACCEPT in the unforgivable class.
;   * the inverted polarity (`a6_polarity_swapped.ll`, `icmp ne` with the
;     successors swapped) — ACCEPTS, byte-identical stream. Rule 9: `-O1` swaps
;     branch polarity routinely and the leg reads `Want` off the successor, never
;     off the predicate.
;   * a TAINTED guard (`trackD/fix_r2_probes/src/ob1e_tainted_guard.c`) — DECLINES on
;     the ORACLE, on B12 and on B13 with the same `cq controlled lowering: condition
;     predates a non-diagonal gate under quantum control`. Leg 1b refuses it at clause
;     (C1), but the condition-wire fence gets there FIRST, so (C1) is defence in depth
;     rather than the deciding fence — say it that way.
; Dropping the `nuw`/`nsw` flags below does NOT move this file
; (`a1_noflags.ll` accepts) and neither does a runtime trip count
; (`a2_runtime_trip.ll` accepts) — both measured, because both were guessed wrong
; first.
;
; ⚠ RETIREMENT TRIGGER: this file's ACCEPT depends on ScalarEvolution proving the
; rewritten guard `icmp eq %inext, 0` FALSE for every iteration. If that answer is
; ever lost, this becomes a DECLINE — a REGRESSION of F-D2-2, not a new fence.
; Re-derive it then; do not "fix" it by weakening the leg.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOQ < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %s = phi i32 [ 0, %entry ], [ %snext, %latch ]
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %g = icmp eq i32 %i, 0
  br i1 %g, label %read, label %latch
read:
  %b = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %b)
  br label %latch
latch:
  %add   = phi i32 [ %m, %read ], [ 1, %loop ]
  %snext = add nsw i32 %s, %add
  %inext = add nuw nsw i32 %i, 1
  %done  = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %snext
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 9.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[H]])

; Counts in their OWN whole-file prefixes (Rule 12 fixture-hygiene (a)).
; ACNT-COUNT-1: call i32 @cqrt_alloc_i32(
; ACNT-NOT: call i32 @cqrt_alloc_i32(

; RCNT-COUNT-2: call void @cqrt_ry_i32(
; RCNT-NOT: call void @cqrt_ry_i32(

; MCNT-COUNT-1: call i32 @cqrt_measure_i32(
; MCNT-NOT: call i32 @cqrt_measure_i32(

; NOQ-NOT: cq_theta_si32
; NOQ-NOT: cq_measure_si32
