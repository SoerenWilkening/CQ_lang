; control_peel_reject_escape_unknown_callee.ll — DECLINE `cq taint escape: tainted
; value consumed by an unknown callee` (bd test_C_libtooling-b6ap, Rule-13 ROUND-1
; finding F-B6-1).
;
; The DECLARATION-ONLY consumer of the class: the peeled mux is handed to an opaque
; extern (probe `r02_escape_sink.c`, plain C at `-O1`). A declaration has no IR, so
; the Phase-6 pre-pass leaves it in neither `Pending` nor `Diagnosed` (the DD-2
; no-IR contract) and `declineTaintEscapes` owns it with this precise message —
; which is why this fixture, unlike its sibling stores, pins a DIFFERENT string and
; therefore a different clause of the re-asked guard.
;
; At the hand-back tree it ran to exit 0 emitting `call void @cq_sink_probe(i32
; %out)`: a quantum rail handed to an unknown callee. Its HAND-PEELED twin
; (`r03_handpeel_escape.s1.ll`) declines with this exact string on the ORACLE.
;
; See `control_peel_reject_escape_store.ll` for the mechanism, the fix and the
; mutant pin. RED-GREEN: `control flow under quantum control` on `main` 0c7380c.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout — the `not` inversion on the RUN
; line plus the mirrored string is what pins it.
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
  %7 = phi i32 [ %5, %4 ], [ %2, %0 ]
  %8 = phi i32 [ 7, %4 ], [ 5, %0 ]
  tail call void @cq_sink_probe(i32 noundef %8)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7)
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare void @cq_sink_probe(i32 noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; CHECK: cq taint escape: tainted value consumed by an unknown callee
