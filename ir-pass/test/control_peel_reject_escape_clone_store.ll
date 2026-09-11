; control_peel_reject_escape_clone_store.ll — DECLINE `cq taint escape: tainted
; value stored to memory` (bd test_C_libtooling-b6ap, Rule-13 ROUND-1 finding
; F-B6-1), and it is the row that shows the re-asked guards COMPOSE.
;
; Probe `r07_escape_clone2.c`, plain C at `-O1`: `g_probe = helper(m)`, where
; `helper` is a visible-body `noinline static`. TWO of the four re-asked stages act
; here, in order: `detectSpecializations(&delta)` (bd 9paa) sees a wholly-new
; tainted-arg candidate and ACCEPTS it into `plan6.Pending` — so its result is a
; quantum value — and `declineTaintEscapes` then declines the STORE of that result.
; A fix that only re-ran the escape net would decline this site with the WRONG
; message (`tainted value consumed by an unknown callee`, on the call rather than on
; the store); a fix that only re-ran the spec detection would not decline it at all.
;
; At the hand-back tree it ran to exit 0 and printed `g=5` — `helper()` of the
; merge out-rail's runtime HANDLE TAG. Its HAND-PEELED twin
; (`r08_handpeel_clone.s1.ll`) declines with this exact string on the ORACLE.
;
; See `control_peel_reject_escape_store.ll` for the mechanism and the mutant pin;
; `control_peel_clone_measured.ll` is the ACCEPT that shows the same spec detection
; producing the CORRECT clone when nothing escapes.
;
; RED-GREEN: `control flow under quantum control` on `main` 0c7380c.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout — the `not` inversion on the RUN
; line plus the mirrored string is what pins it.
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
  %9 = tail call fastcc i32 @helper(i32 noundef %8)
  store i32 %9, ptr @g_probe, align 4
  %10 = tail call i32 @cq_measure_si32(i32 noundef %7)
  ret i32 %10
}

define internal fastcc i32 @helper(i32 noundef %0) unnamed_addr {
  %2 = add nuw nsw i32 %0, 1
  ret i32 %2
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; CHECK: cq taint escape: tainted value stored to memory
