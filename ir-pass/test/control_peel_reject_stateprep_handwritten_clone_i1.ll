; control_peel_reject_stateprep_handwritten_clone_i1.ll — DECLINE, AND THE
; FIXTURE THAT FAILS IF R-1 IS EVER RE-SPELLED AS A NAME OR A SHAPE TEST
; (bd `test_C_libtooling-rb9x`, increment R-1).
;
; This is `trackR/probes/b_HP_c_merge.ll`: the peel's OUTPUT written BY HAND —
; the merge carries ONE phi (the `i1` state prep), and the `a` mux is already a
; `select` on a second `icmp eq i32 %1, 1` sitting in the merge block. It is
; byte-for-byte the shape `peelIndependentMergePhis` produces from
; `control_peel_stateprep_bool_seed_int_cond.ll` — which ACCEPTS.
;
; ⚠ SO THE TWO MODULES ARE THE SAME CIRCUIT AND HAVE OPPOSITE VERDICTS, AND THAT
; IS THE POINT, NOT AN ACCIDENT. R-1's exclusion is a RECORD
; (`TaintSet::PeelClones`) written at the one site that KNOWS a value was
; manufactured — `MergePhiPeel.cpp`'s `S.CondCmp->clone()`. Here the merge has a
; single phi, so the peel never runs, nothing is recorded, and `%clone` is just
; a tainted compare that appeared in the module `clang` handed the pass. F2's
; question — *"could the source the author wrote have been
; `cq_theta(&<that register>, θ)`?"* — HAS an answer for this module: the author
; did write `%clone`, so the rival program exists and F2 keeps declining. It is
; an over-decline of a hand-written spelling, and it is the CONSERVATIVE side of
; the only line R-1 is willing to draw.
;
; ⚠ THE TWO SPELLINGS THIS FILE REFUSES, each measured:
;   (a) a NAME test (`V->getName() == "cq.peel.cond"`) — the corpus already
;       contains a HAND-WRITTEN `%cq.peel.cond`
;       (`control_peel_stateprep_datamux_peeled_control.ll`), so the clone's name
;       is reachable by a fixture author and the record is not;
;   (b) a STRUCTURAL test ("a tainted `icmp` whose predicate and operands are
;       byte-identical to `Region.Condition`'s") — a SECOND SPELLING of a
;       question the pass already owns (Rule 14, the drbq Inc-3 (b′) defect), and
;       strictly weaker: it cannot tell a clone from a compare the USER wrote
;       twice, which is exactly this module.
; Either spelling turns this file GREEN. That is what it is for.
;
; ⚠ RETIREMENT TRIGGER (L8): if a future increment argues that a hand-written
; post-peel spelling deserves the accept — e.g. because the peel is taught to
; NORMALISE such a module back into its pre-peel form, or because a
; provenance-free argument for "a second compare identical to the condition"
; is found and cleared — this file becomes an ACCEPT whose emitted stream is
; `control_peel_stateprep_bool_seed_int_cond.ll`'s, minus nothing. Re-derive it
; then; do not delete it.
;
; MEASURED: DECLINE on the ORACLE `fbbe0820ef4b176a` AND on the R-1 binary,
; with the same string and the same anchor.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control

define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %3, label %5
3:
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %5
5:
  %6 = phi i1 [ %4, %3 ], [ false, %0 ]
  %clone = icmp eq i32 %1, 1
  %sel = select i1 %clone, i32 2, i32 5
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6)
  %10 = zext i1 %9 to i32
  %11 = add nsw i32 %8, %10
  %12 = tail call i32 @cq_measure_si32(i32 noundef %sel)
  %13 = add nsw i32 %11, %12
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
