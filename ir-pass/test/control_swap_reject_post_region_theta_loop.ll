; control_swap_reject_post_region_theta_loop.ll — DECLINE: the LOOP half of the
; Inc-4 position-aware accept's proof obligation (bd test_C_libtooling-lom0).
;
; A phase region and the chained `cq_theta` on its condition's wire in ONE loop
; body — Grover written the way anyone would naturally write repetition:
;     for (i = 0; i < 4; ++i) { if (q > 5) q = cq_phi(q, a); q = cq_theta(q, .25); }
;
; MEASURED IDENTICAL at HEAD (b4e329b) and in this tree:
;     cq controlled lowering: control flow inside a loop body under quantum control
; and the OWNER is `ControlDetect`'s `regionEntryInLoop` (the d8jl guard), which
; fires in `handleBranchRegion`'s Diamond/IfElse arm BEFORE `classifyArms` is
; ever called. Increment 4 cannot reach this shape at all.
;
; WHY THE FIXTURE STILL EARNS ITS PLACE — it records that the two guards agree
; rather than merely that one of them wins the race. The Inc-4 proof is
; `provablyBefore(BI, T)` = `DT.dominates(BI, T) && !isPotentiallyReachable(T,
; BI)`; the second half exists precisely because a back edge replays the mint at
; `BI` against a wire the Ry already relabelled on iteration 2. And the two
; conditions cannot both be dodged: if `T` can reach `BI` while `BI` dominates
; `T`, then `BI`'s own block is on a CFG cycle — which is exactly what
; `regionEntryInLoop` computes (can any successor of the entry block reach the
; entry block). So inside `classifyArms` the reachability half is
; defence-in-depth, not the live decider, and if the loop guard is ever narrowed
; (7.3/7.4 widenings, bd 8h7d) this fixture is where that shows up: it must
; either keep declining or move to the "condition predates" message, never to
; `opt` exit 0.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0, double %a) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head

head:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %q = phi i32 [ %q0, %entry ], [ %w, %latch ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %latch

arm:
  %g = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %latch

latch:
  %p = phi i32 [ %g, %arm ], [ %q, %head ]
  %w = call i32 @cq_theta_si32(i32 %p, double 2.500000e-01)  ; POST-region Ry, in the body
  %inext = add nsw i32 %i, 1
  %done = icmp eq i32 %inext, 4
  br i1 %done, label %out, label %head

out:
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: control flow inside a loop body under quantum control
