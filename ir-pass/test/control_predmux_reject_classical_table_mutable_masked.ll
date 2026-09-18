; control_predmux_reject_classical_table_mutable_masked.ll — DECLINE (bd fn1q
; increment 4). THE INHERITED ASYMMETRY, PINNED SO IT CANNOT DRIFT SILENTLY.
;
; This is `control_predmux_accept_flat_classical_table_masked.ll` with ONE change:
; the two tables are `global` instead of `constant`. The index is bounded by the
; same mask and the access is just as in-bounds — and it DECLINES.
;
; WHY, and it is a property of the route rather than of the hazard. E4's classical
; admission has two proof arms. Arm (1a), `isDereferenceableAndAlignedInLoop`,
; asks LLVM directly and does not care whether the object is mutable — which is
; why the IN-LOOP sibling reads a MUTABLE global and accepts. Arm (1b), the
; known-bits proof, is reached through `classicalTableIndexKnownInBounds` ->
; `matchQramAccess`, which requires `Origin.GV->isConstant()` because it is QROM's
; matcher.
;
; ⚠ SO THIS FIXTURE DECLINES BECAUSE ITS INDEX IS *VARIABLE*, NOT BECAUSE ITS TABLE
; IS MUTABLE, and an earlier version of this header said "a loop-free mutable table
; therefore has no arm that can prove it" — which is false (Rule-13 round 1,
; R4-P3-1). Arm (1c) admits a MUTABLE table at a CONSTANT index, a bare global load
; with no gep, and an uninitialised alloca. Mutability alone is never the reason.
;
; ⚠ THIS IS AN OVER-DECLINE, NOT A HAZARD, and by the owner's 2026-09-11 ruling an
; over-decline is a defect to remove rather than a safety margin. It is left
; standing deliberately: widening it means giving `matchQramAccess` the option,
; which is a change to QROM's shared matcher with its own accept surface and its
; own Rule-12/13 round. ⚠ DO NOT widen it by growing a second bounds proof inside
; `PredMuxFlatten` — that is the drbq Inc-3 (b') defect (Rule 14).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
;
; DBG: gate=E4-gep
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; (No IR-text negatives: a decline writes 0 bytes to stdout — Rule 12 (b).)

@m_z = internal global [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16
@m_p = internal global [4 x i32] [i32 3, i32 2, i32 1, i32 0], align 16
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i64 %i) {
entry:
  %j = and i64 %i, 3
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  ; ⚠ `%Z`/`%P` MUST BE TAINTED or the whole arm is classical and the table value
  ; never reaches an `_hl` slot — which is the property this fixture exists to
  ; pin. (The first draft seeded them with literals and tested nothing.)
  %Z = call i32 @cq_theta_si32(i32 5, double 2.500000e-01)
  %P = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 2
  br i1 %c, label %arm, label %merge
arm:
  %gz = getelementptr inbounds [4 x i32], ptr @m_z, i64 0, i64 %j
  %z = load i32, ptr %gz, align 4
  %Z1 = sub i32 %Z, %z
  %gp = getelementptr inbounds [4 x i32], ptr @m_p, i64 0, i64 %j
  %p = load i32, ptr %gp, align 4
  %P1 = add i32 %P, %p
  br label %merge
merge:
  %Zn = phi i32 [ %Z, %entry ], [ %Z1, %arm ]
  %Pn = phi i32 [ %P, %entry ], [ %P1, %arm ]
  %m1 = call i32 @cq_measure_si32(i32 %Zn)
  %m2 = call i32 @cq_measure_si32(i32 %Pn)
  %s = add i32 %m1, %m2
  ret i32 %s
}
