; control_inplace_ry_reject_in_loop.ll — DECLINE: a control-in-place ROTATION arm
; inside a classically-bounded loop (control-in-place-PRD §4 R7; the epic's Inc 3
; owns it; bd test_C_libtooling-drbq).
;
;     for (i = 0; i <= 3; i++) { if (q > 5) r = cq_theta(r, .9); }
;
; THE SAME CFG WITH A PHASE ARM LOWERS ROLLED TODAY (bd test_C_libtooling-8h7d.5
; — see control_swap_inloop_diamond.ll), which is exactly why this fixture is a
; decline and not an omission: the loop guard ADMITS the region (`R.InLoop` is
; set, not declined), and the rotation class is then refused on its own.
;
; WHICH FENCE OWNS IT MOVED IN finding J (bd test_C_libtooling-drbq Inc 1). It
; used to be `handleBranchRegion`'s in-loop scope fence part 3, run AFTER
; `classifyArms` accepted. R6's rail-alias closure changed that: a loop-carried
; register's own header φ is a wire member reached around the BACK EDGE, so R6's
; FLAT position predicates (`provablyBefore` / `cannotFollowGate`, neither of
; which has the 8h7d.5 per-activation reading) read it as a stale record —
; measured, this module declined on the stale-record string, correctly but for a
; reason that mislabels the region. `classifyArms` therefore asks the loop
; question itself, immediately before R6 and nowhere earlier, and fires THIS
; string; part 3 is kept as the backstop. Either owner emits the same text, which
; is why this fixture is unchanged below the header.
;
; The 8h7d.5 clearance was for the PHASE arm, whose gates are DIAGONAL on the
; persistent register and whose every ancilla is minted, stripped and freed inside
; the iteration. A controlled Ry RELABELS the loop-carried register once per trip,
; which is precisely what `LoopLowering`'s rail-record machinery
; (`collectRailGates` / `railGateBetween` / `staleRailRecordRead`) reasons about —
; and all three recognize an in-place Ry by its `@cq_theta_` spelling with the wire
; at ARG 0, not the hoisted controlled one at arg 1. Inc 3 must re-ask them and add
; the shape as a `tools/loop_twin_matrix.py` axis FIRST. The loop history is 4-for-4
; on hidden over-accepts; this is the Prime Directive, not pessimism.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
