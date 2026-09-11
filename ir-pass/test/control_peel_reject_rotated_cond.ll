; control_peel_reject_rotated_cond.ll — DECLINE `condition predates a non-diagonal
; gate` (bd test_C_libtooling-b6ap, SCOPE H-2): the peel FIRES — the data mux is
; peeled and the region is recovered — and the peeled select is then refused by
; `SelectClassify`'s GATE 2c, because the arm ROTATES the very register the
; condition reads. Probe `p85_v8int` / hand peel `h85`.
;
; ⚠ THIS IS THE FIXTURE THAT SHOWS THE CLONE CANNOT LAUNDER A STALE CONDITION.
; The peel puts a SECOND tainted `icmp` on the condition wire, and the wire fences
; are asked of it exactly as they are of the first: gate 2c prong (a) is
; POSITION-FREE, so an off-ancestry theta on the condition's provenance wire
; declines wherever the compare sits. On `main` 0c7380c this module says
; `control flow` (the 2-phi wall, before any of this is reached); the string it
; fires now is the one the fence owns, which is the RIGHT fence and not an
; accidental one.;
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

define i32 @example()  {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) 
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %5, label %3

3:                                                ; preds = %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) 
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ 5, %3 ], [ 2, %0 ]
  %7 = phi i32 [ %4, %3 ], [ %1, %0 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) 
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) 
  %10 = add nsw i32 %9, %8
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) 

declare i32 @cq_measure_si32(i32 noundef)

; CHECK: <unknown>:0:0: in function example i32 (): cq controlled lowering: condition predates a non-diagonal gate under quantum control
