; control_inplace_ry_reject_stateprep_merge_edge_sideways.ll — DECLINE. THIS IS
; WHY F2 ASKS BOTH EDGES, spelled as a plain-C-reachable program rather than as
; a claim.
;
; This is the `-O1` image of `$S/fix3/q/z06_merge_edge_fold2.c`:
;
;     int q = cq_theta(3,0.3);
;     int t = q / 4;
;     int r = t;                          /* the STRAIGHT-THROUGH value is a
;                                            LIVE tainted register              */
;     if (t != 5) r = cq_theta(5, 0.9);
;     return (int) cq_measure(r) + (int) cq_measure(t);
;
; On the STRAIGHT-THROUGH (merge) edge `t` is 5, so `-O1` folds the φ's Pred
; incoming to the constant 5 and F1's seed-identity clause is satisfied by a
; constant that was a REGISTER in the source. Inc 4 RAUWs the merge φ to the
; PREPPED rail, so on the ¬f branch every downstream reader would see a fresh
; |5> rail instead of `t`'s — which is entangled with `q` and is separately
; measured. Different unitary.
;
; It is the F-R3-1 SIDEWAYS mechanism arriving on the other edge: the compare is
; `icmp eq (and q,-4), 20` and the rotated/straight-through register `sdiv q,4`
; is its SIBLING, so no forward walk from the compare's operand reaches it. The
; polarity-free "ask both edges" spelling F2 has carried since round 1 is what
; makes this one clause cover both the ARM's seed and the MERGE's incoming.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %m = and i32 %q, -4
  %c = icmp eq i32 %m, 20
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 5, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 5, %entry ]
  %t  = sdiv i32 %q, 4
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s  = add i32 %mr, %mt
  ret i32 %s
}
