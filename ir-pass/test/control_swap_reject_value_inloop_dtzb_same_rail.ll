; control_swap_reject_value_inloop_dtzb_same_rail.ll — bd test_C_libtooling-x5fp.
;
; THE RAIL-DISJOINTNESS (P3) PIN. This is the shape the back-edge pruning ALONE
; would wrongly grant, and the ONLY fixture in the tree that discriminates the
; conjunct — so it is a decline that MUST NOT MOVE.
;
; The construction, operand by operand. `%p` is a LOOP-CARRIED rail; the
; condition `icmp sgt i32 %p, 2` is evaluated at the top of the body; a dtzb
; IN-PLACE `%p2 = add nsw i32 %p, 1` sits between the compare and the branch;
; and the region routes `%p2`. `%p2` reaches the condition's cone ONLY around
; the back edge (`%p` -> `%pn` -> `%p2`), so the per-activation pruning alone
; would call the overlap a non-clobber — yet `%p2` names the SAME PHYSICAL RAIL
; as `%p` (`railWireClosure` crosses an `add` with exactly one tainted operand),
; the flag was minted from a basis the `addc` has already relabelled, and the
; arm relabels it again.
;
; ⚠ GATE 2c CANNOT COVER THIS, which is why the conjunct is not redundant: 2c's
; walker is spelled over `thetaOnPathTo`, which counts a `cq_theta` and does NOT
; count the dtzb in-place `add`/`xor` — the vocabulary gap written out at
; `WireWalk.h`'s `phiTracksWire` declaration and owned by bd
; `test_C_libtooling-a3z7` (P1, open). Before bd `x5fp` the §3c fence caught
; this shape BY ACCIDENT, through the back-edge path; (P3) keeps it caught on
; purpose, by CALLING `railWireClosure` (Rule 14) rather than re-deriving it.
;
; MUTATION-VALIDATED, and this is the whole reason the file exists (Rule 12(c) —
; validate by mutation, not by re-reading the prefixes). A source mutant that
; returns `false` immediately before the (P3) loop flips THIS module from the
; string below to `control flow inside a loop body`, and flips NOTHING else in
; the track's probe set: measured 2026-09-18 on mutant `cq-opt` e2bee9a8…,
; against subject 33bba13b…, over `h1`/`h3`/`h6`/`x01`. It is therefore the sole
; discriminator for the conjunct.
;
; ⚠ READ THE DIRECTION HONESTLY. With (P3) removed this module still DECLINES,
; one wall later, because an in-loop VALUE arm is refused by `ControlDetect`'s
; "IN-LOOP SCOPE FENCE, part 2". So the mutant is not an observable over-accept
; TODAY — it becomes one the day bd `3qlq.6` / bd `1dbk` item 1 lands and that
; fence lifts. That is exactly when this fixture is load-bearing, so do not
; retire it as "unreachable"; re-derive it then.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}arm rewrites a condition operand under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

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
