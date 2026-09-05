; control_inplace_ry_reject_stateprep_unrolled_k2.ll — DECLINE (F1): the
; HAND-UNROLLED K=2 twin of `..._inloop_carried.ll` (probe `p18b`).
;
; Region 1 accepts in isolation; region 2's merge φ has REGION 1's merge φ as its
; Pred incoming, so F1 declines it exactly as `..._prep_then_prep.ll` does. That
; agreement between the ROLLED and UNROLLED spellings is the point: this is the
; shape a `loop_twin_matrix` cell would compare, and both halves decline, so the
; matrix cell reads DECLINE-BOTH before and after Inc 4 rather than exposing a
; rolled-vs-unrolled divergence.
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
; `for (…) { if (a == 5) a = cq_theta(a, .9); }` — an in-place Ry on the
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
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %arm1, label %m1
arm1:
  %r1 = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %m1
m1:
  %rm1 = phi i32 [ %r1, %arm1 ], [ 0, %entry ]
  %c2 = icmp eq i32 %q, 5
  br i1 %c2, label %arm2, label %m2
arm2:
  %r2 = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %m2
m2:
  %rm2 = phi i32 [ %r2, %arm2 ], [ %rm1, %m1 ]
  %m = call i32 @cq_measure_si32(i32 %rm2)
  ret i32 %m
}
