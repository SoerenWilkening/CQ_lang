; control_peel_reject_stateprep_rail.ll — DECLINE `bare i1 register condition` (bd
; test_C_libtooling-b6ap, SCOPE H-2 / §16): the OWNER'S OWN FILE with `int b1` —
; `example/grover/grover_oracle_uncompute.c` at `-O1`, probe `p01_owner_intb1`.
; The peel FIRES (P7 clause (b) admits a bare RAIL condition, and the data mux is
; peeled), and what is left is the STATE-PREP ARM on a bare `_Bool` rail — bd
; `l4x4` (Inc 1b-C), which this increment deliberately does not build.
;
; ⚠ ITS HEADER SAYS SO ON PURPOSE, THE Inc-1b PRECEDENT: **this fixture FLIPS TO
; AN ACCEPT when bd `l4x4` lands.** On `main` 0c7380c it declines `control flow`
; (the 2-phi wall); here the wall it stops at is one increment further in, which
; is exactly the progress this increment claims. With `int b0` as well
; (`control_peel_stateprep_datamux.ll`) the peel alone is sufficient and the
; program compiles.;
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
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) 
  br i1 %1, label %4, label %2

2:                                                ; preds = %0
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) 
  br label %4

4:                                                ; preds = %2, %0
  %5 = phi i32 [ 5, %2 ], [ 2, %0 ]
  %6 = phi i32 [ %3, %2 ], [ 0, %0 ]
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) 
  %8 = zext i1 %7 to i32
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) 
  %10 = add nsw i32 %9, %8
  %11 = tail call i32 @cq_measure_si32(i32 noundef %5) 
  %12 = add nsw i32 %10, %11
  ret i32 %12
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) 

declare i32 @cq_theta_si32(i32 noundef, double noundef) 

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) 

declare i32 @cq_measure_si32(i32 noundef)

; CHECK: <unknown>:0:0: in function example i32 (): cq controlled lowering: bare i1 register condition under quantum control
