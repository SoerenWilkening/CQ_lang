; control_peel_reject_poison_incoming.ll — DECLINE `control flow` (bd
; test_C_libtooling-b6ap, P3b / SCOPE H-9): the data mux's pred incoming is a
; LITERAL `poison`. NOT PEELED.
;
; The explicit `poison` half of P3b's one `isa<UndefValue>` test (`PoisonValue`
; derives from `UndefValue`; `control_peel_reject_undef_incoming.ll` is the `undef`
; half). A peel would put the literal into a `select` arm and thence into TWO
; emitted gate slots — the controlled copy and its `_unc` — which is exactly the
; population `LiteralIntegrity`'s guard 1 counts: at the `-O0` stage-3 link the two
; slots may read as two DIFFERENT values, so the adjoint stops inverting its forward
; (Rules 6, 8). Refusing is the decline-keeping option.
;
; ⚠ IT IS ONE TOKEN FROM AN ACCEPT. `control_peel_freeze_incoming.ll` is this exact
; module with a `%frz = freeze i32 poison` named in the phi instead — and it PEELS,
; soundly, because a `freeze` is SINGLE-VALUED BY DEFINITION, which is the very
; property guard 1 counts. The pair is the measurement behind the P3b comment
; (Rule-13 round-1 review, DOC item); probes `x02_poison_incoming.s1.ll` /
; `x03_freeze_incoming.s1.ll`.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout — the `not` inversion on the RUN
; line plus the mirrored string is what pins it.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

define i32 @example()  {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %5, label %3

3:                                                ; preds = %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ 5, %3 ], [ poison, %0 ]
  %7 = phi i32 [ %4, %3 ], [ 0, %0 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %10 = add nsw i32 %9, %8
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %12 = add nsw i32 %10, %11
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

; CHECK: <unknown>:0:0: in function example i32 (): cq controlled lowering: control flow under quantum control
