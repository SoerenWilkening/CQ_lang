; control_swap_inloop_post_region_theta.ll — ACCEPT (bd test_C_libtooling-8h7d.5,
; Phase 7.3 Increment 3). A phase region and the chained `cq_theta` on its
; condition's wire in ONE classically-bounded loop body — Grover written the way
; anyone would naturally write repetition:
;
;     for (i = 0; i < 4; ++i) { if (q > 5) q = cq_phi(q, a); q = cq_theta(q, .25); }
;
; THIS FILE WAS `control_swap_reject_post_region_theta_loop.ll`, AND ITS OWN
; CLOSING PARAGRAPH ASKED FOR THIS COMMIT. It said the fixture "must either keep
; declining or move to the 'condition predates' message, never to `opt` exit 0",
; on the reading that Increment 4's reachability half — `!isPotentiallyReachable(
; T, BI)` — is a genuine soundness requirement inside a loop: "a back edge
; replays the mint at `BI` against a wire the Ry already relabelled on iteration
; 2". THAT SENTENCE IS TRUE OF THE WIRE AND FALSE OF THE RECORD, and the
; difference is what this increment turns on:
;
;   * the wire DOES move: iteration 2's `cqrt_ry` fires on the same rail;
;   * but the value the compare reads is the LOOP-HEADER PHI `%q`, which is
;     RE-BOUND every trip to `%w` — the body's last write. So at iteration 2 the
;     SSA operand and the physical rail agree, exactly as they did at iteration 1.
;     The flag minted at `BI` equals the source compare on every trip.
;
; The proof is now spelled per activation (`WireWalk::gateIsHarmless` leg 2): a
; gate that can reach the mint only by re-executing the record's own definition
; is the NEXT iteration's producer, not this one's staler. `phiTracksWire` is the
; fence that keeps that reading honest — a header phi whose latch incoming is NOT
; the body's last wire write gets no such exemption
; (lowering_reject_stale_record_loop_nontracking_phi.ll, RED).
;
; So the fixture keeps its job with the sign flipped: it is where a REGRESSION in
; either guard shows up. If the barrier reading is ever weakened this goes back to
; `condition predates a non-diagonal gate`; if it is ever widened wrongly, the
; nontracking sibling goes green.
;
; SINCE bd test_C_libtooling-drbq Increment 2a the flat phase arm lowers
; CONTROL-IN-PLACE (§6a): the arm's `Rz` is ONE
; `cqrt_rz_i32_controlled(flag, register, theta)` and the swap route (work-rail
; alloc, both `cqrt_cswap`s, the rail free) is gone. Nothing else moves — the flag
; mint, the strip, the flag free and every downstream gate are unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
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

; ONE rail, minted outside; ONE rolled stream; the post-region Ry in the body:
; CHECK:     entry:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     head:
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double %a)
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; The strip and the flag free precede the chained Ry — the Inc-4 accept's own
; claim, now holding per iteration:
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:     br i1 %{{.*}}, label %out, label %head
; CHECK:     out:
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
;
; CHECK-NOT: condition predates a non-diagonal gate
; CHECK-NOT: control flow inside a loop body
; The swap route must not come back for this flat phase shape. NOROUTE carries NO
; positive anchor, so its window is the whole module — not a dead trailing span
; (bd memory [filecheck-check-not-window-trap]):
; NOROUTE-NOT: call void @cqrt_cswap
