; lowering_reject_phase_kickback_cmp_blind_staler.ll — DECLINE, and it is the
; PARITY REFERENCE for `lowering_reject_io_controlled_cmp_blind_staler.ll` (Track
; A.1, Rule-13 ROUND-2 finding F-A1R2-1; probe `review_a1_r2_probes/io4.c`).
;
;     void emit(int seed) {
;       int r  = cq_theta(seed, 0.25);
;       int r2 = cq_theta(r, 0.9);      /* staler ON r's WIRE */
;       if (r > 5) cq_phi(0.3);         /* the flat phase kickback */
;       (void) cq_measure(r2);
;     }
;
; THIS IS THE PROJECT'S OWN VERDICT ON THAT WIRE SHAPE, and it has been for as
; long as `condWireDisposition` has existed: the flat kickback declines it on the
; ORACLE (`main` 0c7380c) and here, with the same string. It is committed in this
; batch not as new coverage but as the DISCRIMINATOR that makes the I/O-sink
; decline beside it a PARITY repair rather than a new policy — the two files are
; the same wire, the same question, and now the same answer. Read them together.
;
; GREEN ON BOTH BINARIES (oracle rc 1, here rc 1). A fixture that is green on the
; oracle pins a PRE-EXISTING property and says so; the red-green witness for what
; this round CHANGED is the I/O-sink file, which the oracle accepts.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define void @emit(i32 %seed) {
entry:
  %r  = call i32 @cq_theta_si32(i32 %seed, double 2.500000e-01)
  %r2 = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  %c  = icmp sgt i32 %r, 5
  br i1 %c, label %arm, label %merge

arm:                                              ; preds = %entry
  call void @cq_phi(double 3.000000e-01)
  br label %merge

merge:                                            ; preds = %arm, %entry
  %m = call i32 @cq_measure_si32(i32 %r2)
  ret void
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
