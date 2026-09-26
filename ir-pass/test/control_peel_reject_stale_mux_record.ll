; control_peel_reject_stale_mux_record.ll — DECLINE `cq opcode lowering: operand
; predates a non-diagonal gate` (bd test_C_libtooling-b6ap, Rule-13 ROUND-2 item
; **M-D**). THIS IS THE ONLY FIXTURE THAT PINS CALL 5 OF `adjudicateTaintDelta`,
; `declineStaleRecordOps`, and it exists because the round-1 fix could NOT
; construct a customer for it and said so (`FIX_b6ap_R1.md` open question 1). The
; round-2 review found one, from plain C at `-O1`.
;
; Transcribed from probe `S02_stale_mux_record.c`:
;
;     int m = 5, n = 1;
;     if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
;     int r = cq_theta(m, 0.2);   // SOURCE prep at :337 (m is a classical phi);
;                                 // CHAINED at lowerRotations (m is the mux rail)
;     int s = m + 1;              // reads the PRE-Ry record of that same rail
;
; The staleness is CREATED BY THE PEEL and by nothing else. At
; `declineStaleRecordOps`' own slot (`CQLoweringPass.cpp:337`) `%8` is a CLASSICAL
; `phi`, so `%11 = add i32 %8, 1` is a classical `add` that is not even in
; `inLowerOpsScope` — the once-only sweep structurally cannot see it. The peel then
; turns `%8` into a tainted `select`, which flips `cq_theta(m, 0.2)` from a SOURCE
; mint into a CHAINED in-place `Ry` on the mux rail, and the `add` becomes a read
; of that rail's pre-rotation record. Only call 5, re-run over the delta, asks.
;
; MUTANT M-D (the pin): delete `declineStaleRecordOps` from `adjudicateTaintDelta`
; and rebuild — this fixture goes to `opt` exit 0 and is the ONLY fixture in the
; corpus that moves. (At the round-1 fix that mutant moved NOTHING, which is why
; the clause was recorded as unpinned.)
;
; CONTAINMENT of the message: `checkStaleOp` has exactly one caller
; (`OpcodeLowering.cpp`, inside `declineStaleRecordOps`), and
; `declineLiftedStaleRecordOps` is gated on a one-register merge-phi lift having
; occurred (since bd ec7r the lift EVENT `LiftedMergePhis`; before, the equivalent
; non-empty `LiftedConsumers`), which this module cannot produce — so the string
; below comes from call 5 and from nowhere else.
;
; RED-GREEN, MEASURED: `control flow under quantum control` on `main` 0c7380c (the
; 2-φ merge declines there); the string below on the round-1 fix tree b7d646c and
; here. The ORACLE gives this module's HAND-PEELED twin the SAME string at its own
; `:337`, which is the increment's contract — the peel reproduces the hand peel's
; disposition, decline included.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

define noundef i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %3 = icmp eq i32 %1, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01)
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i32 [ 2, %4 ], [ 1, %0 ]
  %8 = phi i32 [ 7, %4 ], [ 5, %0 ]
  %9 = phi i32 [ %5, %4 ], [ %2, %0 ]
  %10 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01)
  %11 = add nuw nsw i32 %8, 1
  %12 = tail call i32 @cq_measure_si32(i32 noundef %9)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %10)
  %14 = add nsw i32 %13, %12
  %15 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %16 = add nsw i32 %14, %15
  %17 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %18 = add nsw i32 %16, %17
  ret i32 %18
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; CHECK: cq opcode lowering: operand predates a non-diagonal gate
