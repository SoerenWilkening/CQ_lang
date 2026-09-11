; control_peel_reject_escape_ptrstore.ll — DECLINE `cq taint escape: tainted value
; stored to memory` (bd test_C_libtooling-b6ap, Rule-13 ROUND-1 finding F-B6-1).
;
; The SECOND measured member of the escape-by-store class: the peeled mux is stored
; through a `getelementptr` into a global ARRAY rather than to a scalar global
; (probe `r11_escape_ptrstore.c`, plain C at `-O1`, `arr[1] = m`). It reaches the
; same `declineTaintEscapes` clause as `..._reject_escape_store.ll` and is kept as a
; separate fixture because it was a separately measured CONSUMER — at the hand-back
; tree it too ran to exit 0 and printed the runtime HANDLE TAG `4`.
;
; See `control_peel_reject_escape_store.ll` for the mechanism, the fix and the
; mutant pin. The peel remains ACCEPT-ONLY; what declines here is the pre-existing
; escape net, re-asked over the taint the peel created.
;
; RED-GREEN: `control flow under quantum control` on `main` 0c7380c.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; the `not` inversion on the RUN line plus
; the mirrored string is what pins it.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

@arr = local_unnamed_addr global [4 x i32] zeroinitializer, align 16

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
  store i32 %8, ptr getelementptr inbounds (i8, ptr @arr, i64 4), align 4
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7)
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; CHECK: cq taint escape: tainted value stored to memory
