; control_predmux_reject_classical_table_unbounded_index.ll — DECLINE (bd fn1q
; increment 4). THE OWNER'S RULING, PINNED: a classical const-table read is
; admitted into a tainted arm ONLY WITH A PROOF of in-bounds-ness, and an
; UNPROVABLE index keeps today's decline. `%i` is a function PARAMETER with no
; bound anywhere, so `g_z[%i]` is genuinely out of bounds for %i >= 3 or %i < 0.
;
; ⚠ THE SOURCE ONLY PERFORMS THIS READ WHEN THE QUANTUM CONDITION HOLDS, AND THAT
; IS EXACTLY WHY IT CANNOT BE SPECULATED. The flatten hoists the arm body to run
; unconditionally; a guard that is quantum is not a bound on %i. Admitting it
; would introduce a fault (and UB) on a path the source never takes — which is
; also why increment 1's `flat_qc_load` ruling stands unchanged.
;
; This is the decline-direction half of the increment's red-green pair; its
; accepting twins are …_accept_inloop_classical_table.ll (bounded by the loop trip
; count, proved by SCEV) and …_accept_flat_classical_table_masked.ll (bounded by
; an explicit mask, proved by known bits).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
;
; DBG: gate=E4-gep
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; (No IR-text negatives: a decline writes 0 bytes to stdout — Rule 12 (b). The
; `not` inversion pins the decline; the debug-prefix line pins the gate.)

@g_z = local_unnamed_addr global [3 x i32] [i32 1, i32 2, i32 3], align 4
@g_p = local_unnamed_addr global [3 x i32] [i32 3, i32 2, i32 1], align 4
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i64 %i) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 2
  br i1 %c, label %arm, label %merge
arm:
  %gz = getelementptr inbounds [3 x i32], ptr @g_z, i64 0, i64 %i
  %z = load i32, ptr %gz, align 4
  %Z1 = sub i32 5, %z
  %gp = getelementptr inbounds [3 x i32], ptr @g_p, i64 0, i64 %i
  %p = load i32, ptr %gp, align 4
  %P1 = add i32 0, %p
  br label %merge
merge:
  %Zn = phi i32 [ 5, %entry ], [ %Z1, %arm ]
  %Pn = phi i32 [ 0, %entry ], [ %P1, %arm ]
  %m1 = call i32 @cq_measure_si32(i32 %Zn)
  %m2 = call i32 @cq_measure_si32(i32 %Pn)
  %s = add i32 %m1, %m2
  ret i32 %s
}
