; control_peel_reject_escape_store.ll — DECLINE `cq taint escape: tainted value
; stored to memory` (bd test_C_libtooling-b6ap, Rule-13 ROUND-1 finding F-B6-1 —
; the ADJUDICATION of the peel's own taint growth).
;
; ⚠ THIS FIXTURE IS A CONFIRMED SILENT MISCOMPILE, FIXED. At the hand-back tree the
; peel made this mux QUANTUM ~90 lines after `declineTaintEscapes` had already run,
; so the store below was never adjudicated: `opt` exited 0, verify-clean, STRICT
; stage 2b `0 violation(s)`, and the emitted program STORED THE RUNTIME HANDLE TAG
; of the 4.4 merge out-rail into `@g_probe` — the C source prints `4` (probe
; `r04_escape_store.c`, plain C at `-O1`). The HAND-PEELED twin of the same module
; (`r05_handpeel_store.s1.ll`) declines with the string below on the ORACLE, which
; is what makes this the PEEL's defect and not `-O1`'s: a source-written or
; `-O1`-built select is tainted at `propagate` time and therefore visible to the
; guard (probes `r16`/`r17` decline on both binaries).
;
; THE FIX is not in this stage — the peel stays ACCEPT-ONLY and still never
; diagnoses. `peelIndependentMergePhis` now REPORTS its taint delta and the caller
; hands it to `adjudicateTaintDelta` (`TaintPropagation.cpp`), which is the
; four-call sequence `repropagateControlMerges` has always run for its own delta
; (`replanReseedSpecialization`, `detectSpecializations(&reseed)`,
; `declineTaintEscapes`, `declineStaleRecordOps`) lifted into ONE named function so
; there is exactly one spelling of it (Rule 14). CLAUDE.md's standing lesson "a
; stage that runs ONCE has a round-2-FALSE premise", for a stage that GROWS TAINT.
;
; RED-GREEN, MEASURED: `control flow under quantum control` on `main` 0c7380c (the
; 2-phi merge declines there, so the shape never reached the store); exit 0 with the
; handle-tag store on the hand-back tree; the string below now.
;
; MUTANT M-C (the pin): deleting `declineTaintEscapes` from `adjudicateTaintDelta`
; returns this fixture — and `..._reject_escape_ptrstore`,
; `..._reject_escape_unknown_callee`, `..._reject_escape_clone_store` — to `opt`
; exit 0. Measured, all four.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

@g_probe = local_unnamed_addr global i32 0, align 4

define noundef i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %3 = icmp eq i32 %1, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01)
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i32 [ %5, %4 ], [ %2, %0 ]
  %8 = phi i32 [ 7, %4 ], [ 5, %0 ]
  store i32 %8, ptr @g_probe, align 4
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7)
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; CHECK: cq taint escape: tainted value stored to memory
