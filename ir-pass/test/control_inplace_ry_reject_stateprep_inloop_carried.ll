; control_inplace_ry_reject_stateprep_inloop_carried.ll — DECLINE (F1): an
; in-loop state prep whose `r` is LOOP-CARRIED (`int r = 0;` OUTSIDE the loop).
;
;     int r = 0;
;     for (int i = 0; i < 3; i++) { if (q == 5) { r = 0; cq_theta(&r, .9); } }
;                                                        // probe `p18a`, from C
;
; ⚠ IT NEVER REACHES R7. The merge φ's Pred-edge incoming is the LOOP'S HEADER φ
; — a value, not a `Constant` — so F1 kills it as a data mux first, and the
; message says so. That is the right answer physically: on trip 2 the
; straight-through value is whatever trip 1 left in `r`, which is not |SEED>.
;
; ⚠ THIS FILE REPLACES `control_inplace_ry_reject_inloop_stateprep.ll`, WHICH WAS
; THE ONLY FIXTURE IN THE 1494-FILE CORPUS THAT INC 4 TURNED RED. Its old header
; said the shape "is certainly not in scope inside a loop where the alloc would
; repeat per trip" and asserted the generic `control flow` string; after Inc 4
; the recognizer sees the arm and F1 adjudicates. Renamed rather than edited in
; place so the move is visible in `git log --follow`.
; PRD §14.5 — R7's LOOP half is UNCHANGED by Inc 4 and refuses both in-loop
; spellings, FOR TWO DIFFERENT REASONS, which is why both are pinned: "in-loop
; state prep" sounds like one thing and is two.
;
;
; ⚠ THE STRING MOVED 2026-09-05 (round-1 Rule-13 review, lens L5 finding
; F-L5-1): F1's second sub-clause now says `state prep merged with a quantum
; register` when the PRED INCOMING IS TAINTED, and keeps
; `state prep seed does not match the merge incoming` for every other mismatch
; (a constant that is not the seed, `undef`/`poison`, a `select`, a
; `ConstantExpr`, a runtime value). The split exists because the one string
; described the IR rather than the program: on the plain-C R4 shape
; `for (…) { if (a == 5) cq_theta(&a, .9); }` — an in-place Ry on the
; CONDITION register, with no state prep and no seed anywhere in the source — it
; named a "seed" that only exists because `-O1` substituted `5` for `a` on the
; proving edge, and its implied fix ("make the straight-through value the seed")
; is not the fix. A TAINTED incoming is a NO-CLONING MUX (Rule 8), and that is
; what the new string names.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep merged with a quantum register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %r = phi i32 [ 0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
