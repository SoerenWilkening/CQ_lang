; control_angle_select_reject_loop_rail_exit_block.ll — DECLINE (S7, the RAIL
; CLOSURE prong): the compare, the select and the consumer are ALL outside the
; loop (they sit in its EXIT block), but the ROTATED REGISTER's rail lives INSIDE
; it — `%qn` is defined in the loop's latch block and is carried around the back
; edge by the header phi `%q`.
;
; ROUND-1 RULE-13 REVIEW FINDING (bd drbq Inc 2b, lens L2-1 = the second half of
; the S7 cross-lens synthesis). S7 shipped asking `LI->getLoopFor` of `T`'s,
; `Sel`'s and `Cond`'s blocks ONLY — all three are the exit block, so it was
; vacuous, and the angle select ACCEPTED.
;
; WHY THE TWIN CANNOT BE POSED AS A WITNESS, WHICH IS THE WHOLE POINT: the manual
; by-difference diamond (`q34t`) and the plain Inc-1 diamond over the same loop
; (`q34b`) BOTH decline `cq loop lowering: rail record read past an in-place gate
; on the same rail`, on this binary and on the pre-2b one. That fence lives in
; `LoopLowering::staleRailRecordRead`, which runs from `lowerLoops` at
; `CQLoweringPass.cpp:310` — BEFORE `detectControlRegions` (:322) and before
; `lowerControlRegions` (:323). 2b's unconditional twin `T0` is inserted THIRTEEN
; pipeline steps later, so the loop fence structurally cannot see it: the shape
; the twin declines is the shape 2b silently emitted. The 8h7d.5 lesson applies
; verbatim — a fence that runs before the emitter is not a fence on what the
; emitter adds.
;
; THE FIX: S7 now also computes `railWireClosure(RotBase, BothWays, Exclude=T)` —
; for BOTH stems, once, reused by S8/S9 on the Ry stem — and declines if ANY
; member is defined in a block that is in an `LI` loop or on a CFG cycle. Here
; `%qn` (the base itself) is in `merge`, an `LI` loop block, so the first member
; asked already answers. Over-declining is safe (Prime Directive); this is the
; shape bd drbq.4 (Increment 3) has to prove, not this one.
;
; CONTROL that must keep ACCEPTING: `q34a` — the same loop with a plain
; unconditional `cq_theta` in the exit block and no select at all. It has no
; region, so nothing here touches it.
;
; TWO ASYMMETRIES THE PRONG DOES NOT COVER, recorded here because this is one of
; the two fixtures a reader reaches for when asking what S7's rail prong means
; (bd drbq Inc 2b, ROUND-2 Rule-13 review, lens R1 item 2):
;   (1) it asks the ROTATED register's closure ONLY, never the CONDITION
;       register's. The mirror shape — the condition register is the loop rail,
;       read in the exit block, the rotated register outside — ACCEPTS
;       (`review2b_r2/R1/probes/s7/oa2_condrail_loop_{ry,rz}.ll`) and is
;       byte-identical to its manual twin on the pre-2b oracle. Sound; unasked.
;   (2) the closure carries `Exclude = T`, so the rail FORWARD of the consumer is
;       asked by no prong at all — see the accept fixture
;       `control_angle_select_forward_rail_cycle_frozen.ll`, which pins that gap
;       and the byte-identity argument that makes it sound.
; AND ONE CONTINGENCY, which is the mechanism this very fixture rests on (lens R1
; item 3): the prong sees `%qn` only because `lowerLoops`' Case-A persistent-rail
; COLLAPSE (`CQLoweringPass.cpp:310`, before detection) has already rewritten the
; header phi and re-anchored the in-loop gate onto the base. Without such a phi the
; identical forward read ACCEPTS (`nat_sel_rz.ll`). A future change to Case-A's
; collapse therefore silently NARROWS S7, and no fixture here would notice.
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: control flow inside a loop body under quantum control
; NEW: cq controlled lowering: control flow inside a loop body under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow inside a loop body under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p  = call i32 @cq_theta_si32(i32 %u1, double 1.250000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %qn, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %qn = call i32 @cq_theta_si32(i32 %q, double -5.000000e-01)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %c2 = icmp eq i32 %p, 7
  %ang = select i1 %c2, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %qn, double %ang)
  %m0 = call i32 @cq_measure_si32(i32 %t)
  %m1 = call i32 @cq_measure_si32(i32 %p)
  %s = add i32 %m0, %m1
  ret i32 %s
}
