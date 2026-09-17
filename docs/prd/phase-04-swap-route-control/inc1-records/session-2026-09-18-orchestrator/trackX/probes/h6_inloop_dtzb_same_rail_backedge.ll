; h6_inloop_dtzb_same_rail_backedge.ll — Track X (bd x5fp), session 2026-09-18.
; THE (P3) NEGATIVE CONTROL — the shape (P1)+(P2) alone would wrongly grant.
; A loop-carried rail %p; the condition reads %p at the top of the body; a dtzb
; IN-PLACE `%p2 = add %p, 1` sits between the compare and the branch; the region
; routes %p2. %p2 reaches the condition's cone ONLY around the back edge, so the
; back-edge pruning alone would call this a non-clobber — yet %p2 names the SAME
; PHYSICAL RAIL as %p, the flag was minted from a basis the addc already
; relabelled, and the arm relabels it again. Gate 2c cannot catch it (its walker
; counts a cq_theta and not a dtzb add — the WireWalk.h vocabulary gap, bd a3z7).
; MUST decline `arm rewrites a condition operand` on BOTH binaries.
define i32 @main() {
entry:
  %p0 = call i32 @cq_theta_si32(i32 9, double 3.000000e-01)
  br label %hdr

hdr:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %p = phi i32 [ %p0, %entry ], [ %pn, %latch ]
  %c = icmp sgt i32 %p, 2
  %p2 = add nsw i32 %p, 1
  br i1 %c, label %arm, label %merge

arm:
  %r1 = add nsw i32 %p2, 3
  br label %merge

merge:
  %pn = phi i32 [ %r1, %arm ], [ %p2, %hdr ]
  br label %latch

latch:
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %hdr

exit:
  %m = call i32 @cq_measure_si32(i32 %pn)
  ret i32 %m
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
