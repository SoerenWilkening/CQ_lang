; control_peel_reject_nonmuxable_type.ll — DECLINE `control flow` (bd
; test_C_libtooling-b6ap, P5): the second merge phi is typed `i128`, which
; `isMuxableType` refuses — the 4.4/kjd1 controlled-copy family covers integers
; <= 64 bits and the four scalar fp widths, and nothing else.
;
; P5 asks `PredMuxFlatten`'s OWN `isMuxableType` (de-anonymized for this stage
; rather than re-spelled — Rule 14), so the peel and PredMux's W5/W7 witnesses can
; never disagree about what the merge substrate can copy. Peeling an unmuxable phi
; would hand `SelectMergeEmit` a select it cannot lower, turning a clean structural
; decline into a half-lowered region.
;
; ⚠ HAND IR: `-O1` does not produce an i128 merge mux from natural C here.;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`), one
; row of its P1-P9 DECLINE PARTITION. The peel is ACCEPT-ONLY and NEVER diagnoses:
; a shape that fails any clause is left BYTE-UNTOUCHED and reaches its existing
; loud owner unchanged. Over-declining is safe (Prime Directive); the peel's job is
; to remove a BOOKKEEPING over-decline, not to widen the accept class.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

define i32 @example() {
entry:
  %b0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %c = icmp eq i32 %b0, 1
  br i1 %c, label %m, label %a
a:
  %t = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %m
m:
  %b1 = phi i32 [ %t, %a ], [ 0, %entry ]
  %w = phi i128 [ 5, %a ], [ 2, %entry ]
  %wt = trunc i128 %w to i32
  %x0 = tail call i32 @cq_measure_si32(i32 noundef %b1)
  %s = add nsw i32 %x0, %wt
  ret i32 %s
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

; CHECK: <unknown>:0:0: in function example i32 (): cq controlled lowering: control flow under quantum control
