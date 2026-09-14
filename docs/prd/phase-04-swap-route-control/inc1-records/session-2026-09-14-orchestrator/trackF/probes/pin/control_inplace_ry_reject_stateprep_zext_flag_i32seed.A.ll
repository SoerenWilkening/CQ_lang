; control_inplace_ry_reject_stateprep_zext_flag_i32seed.ll — DECLINE, AND THE
; HONEST HALF OF R-1's PARTITION (bd `test_C_libtooling-rb9x`; `trackR/probes/r_R4`,
; SCOPE_R.md §3e).
;
; A second `icmp eq i32 %1, 1` on the condition's rail, ZERO-EXTENDED to `i32`
; and read as data, against an `i32` state-prep seed of `0`:
;
;     %1     = cq_theta(0, .5)
;     %2     = icmp eq %1, 1              ; the branch condition
;     if (%2) b1 = cq_theta(i32 0, .5);   ; seed i32 0
;     %clone = icmp eq %1, 1
;     %cz    = zext i1 %clone to i32      ; <- THE COLLIDER, not %clone
;
; ⚠ THE COLLIDER IS THE `zext`, NOT THE COMPARE, AND THAT IS A FINDING RATHER
; THAN A DETAIL. This module was written to demonstrate the `i1`-only character
; of bd `rb9x` — `:1616`'s `V->getType() == Seed->getType()` should have stopped
; an `i1` compare from ever matching an `i32` seed — and it DECLINED anyway. On
; the FALSE edge `%clone` folds to `false`, so `%cz` folds to `i32 0`, which is
; the single commonest seed in the corpus. `control_peel_reject_..._nozext`'s
; equivalent (`trackR/probes/r_R4c`, the same module with the `zext` removed)
; ACCEPTS, which isolates it. So *"`rb9x` is a `_Bool` defect"* is true of the C
; shapes measured and FALSE as a statement about F2: **any pinned flag that is
; zero-extended is an `i32` collider.**
;
; ⚠ AND R-1 DOES NOT FIX IT, DELIBERATELY. R-1 excludes the peel's compare
; clones at F2's equality TEST, which means the clone is still POPPED and its
; USERS are still modelled (`ArmClassify.cpp` — *"it filters an answer, it does
; not prune a seed"*). A value DERIVED from a clone is therefore still tested,
; and that is the conservative direction AND the argued one: `zext(<a clone>)`
; has the same fold image as `zext(<a compare the user wrote>)`, so it is NOT
; preimage-free and an exclusion covering it would be unargued. Moving R-1 to
; the seeding instead would change the walk and the step bound (the 2026-09-11
; anchor measurement: ALL 40 F2 fixtures flip) and would have to prove that every
; value derived from a clone is also preimage-free — it is not.
;
; ⚠ THIS MODULE'S `%clone` IS HAND-WRITTEN IN ANY CASE (the merge carries ONE
; phi, so `peelIndependentMergePhis` never runs and nothing is recorded), so the
; file declines for the `…_handwritten_clone_i1.ll` reason as well. Both reasons
; are stated because either alone would rot: if a future increment admits the
; hand-written spelling, this file must STILL decline on the `zext` reach, and
; if it ever accepts, the `zext` reach is what was silently widened.
;
; ⚠ RETIREMENT TRIGGER (L8): the day anyone proposes "exclude only `i1` values"
; as a spelling of R-1, this file is the counter-example — the collider class
; reaches EVERY width through a cast.
;
; MEASURED: DECLINE on the ORACLE `fbbe0820ef4b176a` AND on the R-1 binary,
; same string, same anchor.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so the IR-text negative below
; is VACUOUS documentation; the property is pinned by the `not` inversion on the
; RUN line plus the string, mirrored character-for-character.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %3, label %5
3:
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %5
5:
  %6 = phi i32 [ %4, %3 ], [ 1, %0 ]
  %clone = icmp eq i32 %1, 1
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %cz = zext i1 %clone to i32
  %11 = add nsw i32 %8, %9
  %12 = add nsw i32 %11, %cz
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
