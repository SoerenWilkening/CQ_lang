; h1_inloop_diamond_value_backedge.ll — Track X (bd x5fp), session 2026-09-18.
; WITNESS CANDIDATE 3 — the only shape that can reach the §3c prong at
; ArmClassify.cpp:5774 (the prong whose OUTER test gates an ACCEPT) with an
; overlap that exists ONLY around the back edge.
;   condProvenance(icmp %q, %a) walks the CLASSICAL carrier %a (untainted values
;   are traversed, only tainted ones collected) -> its latch incoming %m, the
;   measure result -> %rm -> {%r1, %r}, so Routed == StraightThrough == %r is in
;   Prov. Within ONE activation the flag is minted from %q/%a BEFORE the arm
;   writes %r; nothing tainted crosses the back edge (cq_measure is the sink).
define i32 @main() {
entry:
  br label %hdr

hdr:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %a = phi i32 [ 0, %entry ], [ %m, %latch ]
  %q = call i32 @cq_theta_si32(i32 9, double 3.000000e-01)
  %r = call i32 @cq_theta_si32(i32 7, double 2.000000e-01)
  %c = icmp sgt i32 %q, %a
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
  ret i32 %m
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
