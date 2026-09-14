; lowering_reject_stale_reader_merge_phi_prep.ll — DECLINE (bd
; test_C_libtooling-3d8q, P1). THE TRACK-M CUSTOMER: the stale reader whose seed
; is a controlled STATE-PREP's MERGE φ.
;
;   int a=5; bool b0=0, b1=0;
;   if (a>=3) b0 = cq_theta(b0,0.5);
;   if (b0==1) a -= 3;
;   if (a>=3) b1 = cq_theta(b1,0.5);       /* the prep — its merge φ is `%p` */
;   if (b1) a -= 3;
;   bool c = cq_theta(b1,0.25);            /* CONSUMES the name `b1` */
;   return cq_measure(b0)+cq_measure(b1)+cq_measure(c)+cq_measure(a);
;                        ^^^^^^^^^^^^^^ the stale read
;
; Reduced here to the φ and its two readers; the full plain-C module is
; `$SES/trackD/probes/src/p3d8q_sibling.c` (and `…/r15_p3d8q_sibling.c`), which
; ACCEPTED at 31 trace lines on the frozen session ORACLE and declines here. The
; rail spelling `p3d8q_sibling_rail.c` (an UNCONDITIONAL prep, no φ at all)
; accepted at 30 on the PRE-Track-M oracle, which is what makes this a
; PRE-EXISTING P1 hole that Track M added customers to rather than created — bd
; 3d8q NOTES, and Track M's own F-M3 decline is pinned with "land the 3d8q fence"
; as its retirement trigger.
;
; WHY IT DECLINES, precisely: `%c = cq_theta(%p, .25)` is an in-place Ry on the
; φ's rail, and `cq_measure(%p)` after it names the pre-Ry record. Leg 2 cannot
; save it — `phiTracksWire(%p)` REFUSES a φ with a CONSTANT incoming ("the value
; at that edge is not a wire record at all"), which is exactly right here: on the
; straight-through edge `%p` is the seed `false`, not a rotated register.
;
; ⚠ The ANALYSIS runs before `MergePhiPeel` and before control detection, so `%p`
; is the `-O1` merge φ the SOURCE wrote, not a peeled `select` or a flattened
; RAUW target. That ordering is the fence's own accept-side safety (see
; `TaintSet::StaleQuantumReaders`); it is also why this file's verdict does not
; depend on whether Track M's rail-φ leaf claims the region.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: rotation/measure operand predates a non-diagonal gate

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example(i1 %u) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u, double 5.000000e-01)
  br i1 %b0, label %prep, label %merge
prep:
  %b1 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %merge
merge:
  %p  = phi i1 [ %b1, %prep ], [ false, %entry ]
  %c  = call i1 @cq_theta_i1(i1 %p, double 2.500000e-01)
  %m1 = call i1 @cq_measure_i1(i1 %p)
  %m2 = call i1 @cq_measure_i1(i1 %c)
  %z1 = zext i1 %m1 to i32
  %z2 = zext i1 %m2 to i32
  %s  = add i32 %z1, %z2
  ret i32 %s
}
