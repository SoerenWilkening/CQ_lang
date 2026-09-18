; control_predmux_reject_classical_table_trip_exceeds_table.ll — DECLINE (bd fn1q
; increment 4). ⚠ THE BOUNDARY CONTROL FOR E4's PROOF, AND IT IS THE FIXTURE THAT
; SHOWS THE PROOF IS REAL RATHER THAN DECORATIVE.
;
; This file is `control_predmux_accept_inloop_classical_table.ll` with ONE
; character changed: the loop runs FOUR trips over a THREE-element table. Measured,
; on the same binary:
;     trip == 3 (table size)  ->  ACCEPT
;     trip == 4               ->  DECLINE, gate=E4-gep
;     trip == 10              ->  DECLINE, gate=E4-gep
; The admission boundary sits exactly at the table size, which is what a real
; dereferenceability proof looks like from the outside.
;
; WHY IT MATTERS MORE THAN AN ORDINARY DECLINE FIXTURE. The flatten HOISTS the
; arm's load so it runs on every trip. On trip 3 of a 4-trip loop, `g_z[3]` is one
; element past the end. `isDereferenceableAndAlignedInLoop` computes the access
; RANGE over the whole loop and refuses, so the speculated read can never reach
; memory the source's own indices did not. A green run here is evidence the proof
; is load-bearing; if this file ever flips to an accept, E4's admission has
; stopped proving anything and the fault is reachable.
;
; ⚠ RELATED SHAPES MEASURED AT THE SAME TIME, ALL DECLINING AT `E4-gep`, none of
; them fixtured because this one subsumes them as a pin: an index bounded only by
; a CLASSICAL GUARD (`if (i < 3 && q > 2)`) inside a RUNTIME-trip loop; the same
; bound expressed as a `select` (`j = i < 3 ? i : 0`) in a 100-trip loop. In both
; the bound is real in the source and invisible to a per-iteration proof, and in
; both the safe direction is the one taken.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
;
; DBG: gate=E4-gep
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; (No IR-text negatives: a decline writes 0 bytes to stdout — Rule 12 (b).)
@g_z = local_unnamed_addr global [3 x i32] [i32 1, i32 2, i32 3], align 4
@g_p = local_unnamed_addr global [3 x i32] [i32 3, i32 2, i32 1], align 4
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe() {
entry:
  br label %head
head:
  %i = phi i64 [ 0, %entry ], [ %in, %latch ]
  %Z = phi i32 [ 5, %entry ], [ %Zn, %latch ]
  %P = phi i32 [ 0, %entry ], [ %Pn, %latch ]
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 2
  br i1 %c, label %arm, label %latch
arm:
  %gz = getelementptr inbounds [3 x i32], ptr @g_z, i64 0, i64 %i
  %z = load i32, ptr %gz, align 4
  %Z1 = sub i32 %Z, %z
  %gp = getelementptr inbounds [3 x i32], ptr @g_p, i64 0, i64 %i
  %p = load i32, ptr %gp, align 4
  %P1 = add i32 %P, %p
  br label %latch
latch:
  %Zn = phi i32 [ %Z, %head ], [ %Z1, %arm ]
  %Pn = phi i32 [ %P, %head ], [ %P1, %arm ]
  %in = add nuw nsw i64 %i, 1
  %d = icmp eq i64 %in, 4
  br i1 %d, label %exit, label %head
exit:
  %m1 = call i32 @cq_measure_si32(i32 %Zn)
  %m2 = call i32 @cq_measure_si32(i32 %Pn)
  %s = add i32 %m1, %m2
  ret i32 %s
}
