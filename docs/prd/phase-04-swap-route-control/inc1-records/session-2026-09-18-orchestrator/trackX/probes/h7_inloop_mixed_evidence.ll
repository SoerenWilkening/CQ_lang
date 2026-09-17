; h7_inloop_mixed_evidence.ll — Track X (bd x5fp), session 2026-09-18.
; ROUND-2 ATTACK: MIXED EVIDENCE. h1 with the compare's FIRST operand changed
; from %q to %r, so the condition reads the routed register BOTH directly (in
; this activation) AND around the back edge (through the classical carrier %a).
; The pruning must not be fooled by the mere PRESENCE of a back-edge path: (P2)
; asks whether the evidence is ABSENT from the in-activation cone, and here it
; is present, so the fence must keep firing with the PERMANENT string.
define i32 @main() {
entry:
  br label %hdr

hdr:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %a = phi i32 [ 0, %entry ], [ %m, %latch ]
  %q = call i32 @cq_theta_si32(i32 9, double 3.000000e-01)
  %r = call i32 @cq_theta_si32(i32 7, double 2.000000e-01)
  %c = icmp sgt i32 %r, %a
  br i1 %c, label %arm, label %merge

arm:
  %r1 = add nsw i32 %r, 3
  br label %merge

merge:
  %rm = phi i32 [ %r1, %arm ], [ %r, %hdr ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  br label %latch

latch:
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %hdr

exit:
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %e = add nsw i32 %m, %m2
  ret i32 %e
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
