; control_predmux_accept_flat_classical_table_masked.ll — ACCEPT (bd fn1q
; increment 4). The LOOP-FREE half of E4's classical admission: no loop to bound
; the index, so the bound is an explicit MASK and the proof is known bits.
;
; ⚠ THIS FIXTURE EXISTS BECAUSE THE ARM IT COVERS WOULD OTHERWISE NEVER FIRE, and
; shipping a clause that cannot fire is the defect the previous increment's
; Rule-13 round 2 flagged twice. Measured while building it: LLVM's
; `isDereferenceableAndAlignedPointer` walks a gep by ACCUMULATING A CONSTANT
; OFFSET, so a variable index defeats it outright — the masked index below returns
; FALSE from that arm. What admits it is arm (1b),
; `classicalTableIndexKnownInBounds`, which is the SAME known-bits proof QROM's
; own `Provable` verdict uses, exported rather than re-derived (Rule 14).
;
; ⚠ THE GLOBAL MUST BE `constant` HERE AND MUST NOT BE IN THE IN-LOOP SIBLING.
; Arm (1b) reaches the proof through `matchQramAccess`, which requires
; `Origin.GV->isConstant()`; arm (1a) calls LLVM directly and does not. That
; asymmetry is INHERITED, not designed, and it is in the safe direction — see
; `…_reject_classical_table_mutable_masked.ll`, which is this same program over a
; MUTABLE global and declines.
;
; ⚠ THE COUNT AND NEGATIVE RUN LINES BELOW WERE ADDED BY Rule-13 round 1 (R4-P3-2),
; which mutation-tested this file and found it MISSED 3 OF 5 INJECTIONS — including
; an injected `cqrt_alloc_i32(i32 %z)`, the very §5.2 property the header says the
; file exists to pin. It had only CHECK-DAG lines on operand position, which an
; ADDED gate cannot disturb. Counts are closed with `grep | count N` rather than a
; count directive, because a count directive matches sequentially and a following
; negative closes only the range after it, not the file.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: grep "call void @cqrt_copy_i32_controlled" %t.cqd0.ll | count 4
; RUN: grep "call i32 @cqrt_alloc_i32" %t.cqd0.ll | count 5
; RUN: grep "call i32 @cq_template_icmp_sle_i32_hl(" %t.cqd0.ll | count 2
; ⚠ EVERY GATE FAMILY IS COUNTED, NOT NEGATED, AND THAT DISTINCTION IS THE FINDING.
; Rule-13 round 2 ran a 14-gate injection matrix (with a null control and two
; positive controls) against this fixture and its sibling: **9 of 14 injections
; were MISSED**, including an injected `cqrt_ry` on a user register (Rule 7), an
; injected `cqrt_measure` (Rule 5 — the compiler never inserts a measurement the
; user did not write) and an injected `cqrt_free` (Rule 6). Round 1 had closed only
; the five injections it happened to try.
;
; A NEGATIVE CANNOT CLOSE THESE, because this shape legitimately emits `cqrt_ry`,
; `cqrt_x`, `cqrt_free` and `cqrt_measure` — a first attempt at a broad
; `NEG-NOT` list contradicted the fixture's own output and went red. What closes
; them is an EXACT COUNT per family: `count N` fails on N+1 as loudly as on N-1, so
; an injected gate of an already-present kind trips it. Families that must be
; ABSENT entirely stay as negatives below.
; RUN: grep "call void @cqrt_ry" %t.cqd0.ll | count 3
; RUN: grep "call void @cqrt_x(" %t.cqd0.ll | count 4
; RUN: grep "call void @cqrt_free(" %t.cqd0.ll | count 2
; RUN: grep "@cqrt_measure" %t.cqd0.ll | count 3
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; The classical value reaches the `_hl` LITERAL slot of the mixed Q+C op, not a
; qubit handle (§5.2). ⚠ That is a claim about the OPERAND SLOT. A table value used
; as an ARM OF THE MERGE is materialised on a rail by the ordinary 4.4 data mux and
; that is sound — see the in-loop sibling's header (Rule-13 round 1 R4-P2-2).
; CHECK-DAG: %z.stable = freeze i32 %z
; CHECK-DAG: %p.stable = freeze i32 %p
; CHECK-DAG: call i32 @cq_template_sub_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 %z.stable)
; CHECK-DAG: call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 %p.stable)
; Families that must be ABSENT entirely — these CAN be negatives.
; NEG-NOT: cqrt_rz
; NEG-NOT: cqrt_cswap
; NEG-NOT: cqrt_toffoli
; NEG-NOT: cqrt_cnot
; NEG-NOT: cqrt_qram
; NEG-NOT: cqrt_alloc_i1
; ⚠ The §5.2 property, as a negative an INJECTED gate actually trips: the table
; value must not be allocated onto a rail in this shape.
; NEG-NOT: cqrt_alloc_i32(i32 %z
; NEG-NOT: cqrt_alloc_i32(i32 %p

@c_z = internal constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16
@c_p = internal constant [4 x i32] [i32 3, i32 2, i32 1, i32 0], align 16
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
  %gz = getelementptr inbounds [4 x i32], ptr @c_z, i64 0, i64 %j
  %z = load i32, ptr %gz, align 4
  %Z1 = sub i32 %Z, %z
  %gp = getelementptr inbounds [4 x i32], ptr @c_p, i64 0, i64 %j
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
