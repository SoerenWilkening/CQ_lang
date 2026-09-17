; control_inplace_ry_reject_crossblock_cond_wire_gate_in_gap.ll — DECLINE. bd
; `test_C_libtooling-drbq.12` (2026-09-17): the NEGATIVE that bounds the widening. It
; is the SAME shape as the accept
; `control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll` — a LICM-hoisted
; loop-invariant compare in the entry block, `Pred` the loop header, an in-place Ry
; arm on a disjoint register — with ONE addition: a SIBLING chained `cq_theta` on the
; CONDITION's own register `%1`, sitting in the LATCH.
;
;     int a = cq_theta(0, 0.5);
;     int r = cq_theta(0, 0.3);
;     int s = 0;
;     for (int i = 0; i < 2; ++i) {
;         if (a == 5) { r = cq_theta(r, 0.9); }
;         s = cq_theta(a, 0.1);              // <-- relabels `a`'s RAIL every trip
;     }
;     return cq_measure(r) + cq_measure(s);
;
; WHY IT MUST DECLINE, and it is a real wrong-unitary and not a bookkeeping worry.
; `%1`'s SSA NAME is loop-invariant, which is why LICM hoists the compare — but its
; RAIL is not: `%post` fires on every trip, so on trip 2 the flag minted at the header
; branch reads a basis the source compare never read, the wrong arm fires, and the
; `icmp_..._unc` strip cannot return the flag to |0>. That is the mint-at-branch
; hazard `condWireDisposition`'s whole header is about, arriving through a gate the
; hoist makes invisible to a naive positional reading.
;
; ⚠ IT DECLINES ON BOTH BINARIES AND THE REASONS ARE DIFFERENT — read that as a
; property of the FIXTURE, not as a reason to skip it. On the pre-bead ORACLE it dies
; at P4's unconditional cross-block bail, which never looks at the gate. Here it dies
; because `crossBlockCompareMintable` walked the gap and FOUND the gate on the
; condition's own rail closure. A fixture that is red on both binaries for different
; reasons pins nothing by itself, which is why it ships with the isolating control
; below and is validated by source MUTATION, not by re-reading its prefixes
; (Rule 12(c)).
;
; ISOLATING CONTROL, ONE LINE APART:
; `control_inplace_ry_crossblock_cond_wire_gate_after_loop.ll` is this module with
; `%post` MOVED from the latch to the exit block — same operand, same gate, same
; angle, same everything but position. It ACCEPTS (measured), because the gate is then
; provably after the whole emitted stream. So the discriminator this file pins is
; POSITION-IN-THE-GAP, and the control proves the decline is not merely "a gate on the
; condition rail exists somewhere".
;
; ⚠ WHY THE GAP IS THE WHOLE LOOP BODY. `crossBlockCompareMintable` calls
; `anyInstructionInGap`, which walks forward from the compare over every block that
; can still REACH `Pred`. The latch reaches the header around the BACK EDGE, so it is
; in the gap — this is the same reason Track P′'s `52og` half had to walk successors
; of `Pred`, and it is what makes a hoisted compare's gap bigger than an in-`Pred`
; one's.
;
;
; ⚠ RETIREMENT TRIGGERS (L8) — this file is HALF A PAIR, so its triggers are about the
; PAIR, not about itself. It stops discriminating, and the pair stops being evidence,
; the day ANY of these is true; re-derive BOTH files then, do not delete either:
;   (a) `condWireDisposition`'s cross-block prong is narrowed back — both halves
;       return to declining for the ORACLE's reason and the pair says nothing;
;   (b) `wireGainsNonDiagonalGate`'s position-aware prong stops refusing a gate that
;       can reach `BI` around a BACK EDGE (`provablyBefore`'s second conjunct) — the
;       in-gap half would then accept and the pair would invert its meaning;
;   (c) either module stops being `-O1`-shaped for the other reason — e.g. if the
;       exit-block half's gate were ever sunk or hoisted, the two would differ in more
;       than the ONE instruction position that is the whole point.
; ⚠ AND THE STANDING WARNING: on the ORACLE both halves DECLINE, for the same P4
; reason. The pair is evidence ONLY on a binary where the cross-block prong exists. A
; future reader who runs it on one binary alone learns nothing.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so IR-text negatives below a
; decline are VACUOUS (Rule 12(b)) — the property here is pinned by the `not`
; inversion on the RUN line and by the string above, nothing else. No `CHECK-NOT` is
; written, deliberately, so that nobody reads one as evidence.

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2
  %3 = icmp eq i32 %1, 5
  br label %hdr

exit:                                             ; preds = %latch
  %m1 = tail call i32 @cq_measure_si32(i32 noundef %merge) #2
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %post) #2
  %sum = add nsw i32 %m2, %m1
  ret i32 %sum

hdr:                                              ; preds = %0, %latch
  %ivphi = phi i32 [ 0, %0 ], [ %ivnext, %latch ]
  %rphi = phi i32 [ %2, %0 ], [ %merge, %latch ]
  br i1 %3, label %arm, label %latch

arm:                                              ; preds = %hdr
  %armt = tail call i32 @cq_theta_si32(i32 noundef %rphi, double noundef 9.000000e-01) #2
  br label %latch

latch:                                            ; preds = %arm, %hdr
  %merge = phi i32 [ %armt, %arm ], [ %rphi, %hdr ]
  %post = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e-01) #2
  %ivnext = add nuw nsw i32 %ivphi, 1
  %exitc = icmp eq i32 %ivphi, 0
  br i1 %exitc, label %hdr, label %exit, !llvm.loop !6
}

attributes #0 = { nounwind ssp uwtable }
attributes #2 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
