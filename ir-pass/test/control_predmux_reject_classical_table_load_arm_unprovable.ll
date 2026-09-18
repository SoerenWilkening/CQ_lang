; control_predmux_reject_classical_table_load_arm_unprovable.ll — DECLINE (bd fn1q
; increment 4, Rule-13 round 1 R4-P3-3). THE `E4-load` ARM'S ONLY PIN.
;
; ⚠ IT EXISTS BECAUSE THE INCREMENT SHIPPED THREE REJECT FIXTURES AND ALL THREE PIN
; `gate=E4-gep`. E4's classical admission has TWO decline sites — the gep arm and
; the load arm — and the load arm was reachable and unpinned. A clause with no
; fixture is the bd `e1gr` class; a clause with no fixture that nobody noticed is
; worse, because the gate name in the other three files makes it LOOK covered.
;
; THE SHAPE THAT REACHES IT: the `getelementptr` sits in `R.Entry` (so the gep arm
; of the walk never sees it — E4 skips the entry block's own instructions, which
; are not moved) while the LOAD sits in the arm and IS hoisted. The index is an
; unbounded parameter, so no proof arm can discharge it, and the refusal comes from
; the load site rather than the address site.
;
; The table is `constant` and the index is the only thing wrong with it — compare
; …_reject_classical_table_unbounded_index.ll, which is the same unprovable index
; reached through the GEP arm.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
;
; DBG: gate=E4-load
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; (No IR-text negatives: a decline writes 0 bytes to stdout — Rule 12 (b).)

@g = constant [3 x i32] [i32 1, i32 2, i32 3], align 4
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i64 %i) {
entry:
  %gz = getelementptr inbounds [3 x i32], ptr @g, i64 0, i64 %i
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %Z = call i32 @cq_theta_si32(i32 5, double 2.500000e-01)
  %P = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 2
  br i1 %c, label %arm, label %merge
arm:
  %z = load i32, ptr %gz, align 4
  %Z1 = sub i32 %Z, %z
  %P1 = add i32 %P, %z
  br label %merge
merge:
  %Zn = phi i32 [ %Z, %entry ], [ %Z1, %arm ]
  %Pn = phi i32 [ %P, %entry ], [ %P1, %arm ]
  %m1 = call i32 @cq_measure_si32(i32 %Zn)
  %m2 = call i32 @cq_measure_si32(i32 %Pn)
  %s = add i32 %m1, %m2
  ret i32 %s
}
