; control_swap_reject_inloop_stalecond_invariant.ll — DECLINE, and the
; ArmClassify twin of PRD 7.3 §2.9 (bd test_C_libtooling-8h7d.5).
;
; A tainted-condition phase region inside a classically-bounded loop — the shape
; Increment 3 ADMITS — whose condition reads a register minted OUTSIDE the loop
; and re-rotated INSIDE it:
;
;     int q = u0; cq_theta(&q, .5);
;     for (...) { if (q > 5) cq_phi(a);      cq_theta(&q, t); }
;                     ^^^^^ loop-INVARIANT   ^^^^^^^^^^^^^^^ on q's own wire
;
; THIS IS THE ONE THE INCREMENT MUST NOT ACCEPT, and it is one edge away from the
; one it must. `control_swap_inloop_post_region_theta.ll` is the SAME picture with
; the condition reading the loop-HEADER PHI, and it lowers. The difference is not
; the loop, the region, or the gate — it is WHICH SSA VALUE the compare denotes:
;
;   * a header phi is RE-BOUND every trip to the body's last wire write, so at
;     iteration 2 the flag mint and the source compare agree — accept;
;   * `%q` here is bound ONCE, before the loop. At iteration 2 the wire has been
;     relabelled by the previous trip's `cqrt_ry` while `%q` still denotes the
;     pre-loop record, so the flag encodes a predicate of the WRONG basis: the
;     kickback lands on the wrong branch AND the `_unc` strip cannot clear the
;     flag (the stale-flag miscompile, oracle investigation_mint_at_compare.py P2).
;
; MECHANICALLY: `gateIsHarmless` leg 2 takes the SEED's own definition as its
; barrier, and `%q`'s definition sits in `%entry`, which is NOT on the back-edge
; path from the body theta to the mint. The walk therefore finds a barrier-free
; path and the gate stays flagged. Contrast a header-phi seed, whose definition IS
; on that path and cuts it.
;
; Widen the barrier to anything that is not re-executed per trip — a loop-invariant
; value, an argument, a constant — and this fixture goes green while the
; miscompile ships.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_cswap
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0, double %a, double %t, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %c = icmp sgt i32 %q, 5                            ; reads the LOOP-INVARIANT %q
  br i1 %c, label %arm, label %latch
arm:
  call void @cq_phi(double %a)
  br label %latch
latch:
  %w = call i32 @cq_theta_si32(i32 %q, double %t)    ; in-place Ry on %q's OWN wire
  %inext = add nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %out, label %head
out:
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}
