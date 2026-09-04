; control_inplace_ry_reject_inloop_nested_loop.ll — DECLINE (PRD §13.2 row L-c):
; the in-loop Ry arm inside an INNER loop, with the rotated rail carried across
; BOTH back edges.
;
; MEASURED, and the clause that owns it is not the one the PRD table predicted —
; corrected there in place. `flatRegionRollableInLoop` gates (A)-(D) all PASS for
; the INNER loop (natural, one depth, single latch, no second cycle), so
; `Region.InLoop` is set with `L` = the inner loop. What refuses it is R7-loop
; clause (b'): the inner header's rail phi has its EXTERNAL incoming coming from
; the OUTER header phi, and `peelInPlaceBase` STOPS at a phi — so the peel bottoms
; at a `PHINode`, not at a classical-arg-0 `cq_theta` mint, and
; `LoopPlan.h`'s `railPhiRootMint` (the round-2 collapse's OWN claim condition,
; asked here at detection) returns null.
;
; That is the right answer and it is the collapse's answer, not a second opinion:
; `collapseRailPhisIn` would not claim this phi either, so accepting the region
; would emit it and then leave a surviving tainted header phi for
; `declineClassicalMuxes` to refuse AFTER the diamond was erased — a decline
; downstream of mutation whose message calls a quantum register a classical mux.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %n) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %ohead
ohead:
  %ro = phi i32 [ %r0, %entry ], [ %ri, %oexit ]
  %oi = phi i32 [ 0, %entry ], [ %oin, %oexit ]
  br label %ihead
ihead:
  %r  = phi i32 [ %ro, %ohead ], [ %rm, %merge ]
  %ii = phi i32 [ 0, %ohead ], [ %iin, %merge ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm  = phi i32 [ %rt, %arm ], [ %r, %ihead ]
  %iin = add i32 %ii, 1
  %ic  = icmp slt i32 %iin, %n
  br i1 %ic, label %ihead, label %oexit
oexit:
  %ri  = phi i32 [ %rm, %merge ]
  %oin = add i32 %oi, 1
  %od  = icmp sgt i32 %oin, 3
  br i1 %od, label %exit, label %ohead
exit:
  %m = call i32 @cq_measure_si32(i32 %ri)
  ret i32 %m
}
