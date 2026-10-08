; control_predmux_accept_inloop_classical_table.ll — ACCEPT (bd fn1q increment 4,
; PredMux E4's CLASSICAL const-table read). A classical table indexed by the LOOP
; COUNTER, read inside a tainted-condition value arm. This is the bead's headline
; over-decline: `Z -= z[i]; P += p[i];` under `if (q > 2)`.
;
; ⚠ IT IS NOT QROM, AND THE DISTINCTION IS THE WHOLE SAFETY ARGUMENT. QROM is a
; QUANTUM-indexed table read that lowers to `cqrt_qram_load_<W>`; its index-TAINT
; gate is load-bearing and was measured refusing this shape even on a power-of-two
; table, so the table size was never the issue. Here the index is CLASSICAL, and
; the loaded value stays classical all the way down — in a mixed Q+C op it occupies
; the sanctioned `_hl` LITERAL slot and is not promoted to a qubit handle
; (`quantum-classical-handling.md` §5.2, non-negotiable). The checks below are what
; pin that: `%z`/`%p` appear as the SECOND operand of an `_hl` template and never as
; the operand of a `cqrt_alloc`.
;
; ⚠ "NEVER PROMOTED TO A QUBIT HANDLE" IS TRUE *OF THIS SHAPE* AND FALSE AS A
; GENERAL CLAIM, and its first draft here said the latter (Rule-13 round 1
; R4-P2-2). Where the table value is an ARM OF THE MERGE (`c ? tbl[i] : 7`) the 4.4
; data mux materialises it on a rail — `cqrt_alloc_i32(i32 %z)` — because a
; controlled copy needs something to copy from. That is the ordinary merge idiom
; (a literal arm gets `cqrt_alloc_i32(i32 5)` the same way, and a classical
; ARGUMENT does on the pre-increment ORACLE), it is sound, and it is not the §5.2
; hazard. This fixture pins the MIXED-OP slot, which is the property §5.2 names.
;
; THE ADMISSION IS PROOF-GATED (owner ruling 2026-09-23): the load is hoisted out
; of the arm, so it must not FAULT where the source did not perform it. Arm (1a),
; `isDereferenceableAndAlignedInLoop`, answers exactly that — "dereferenceable on
; every iteration regardless of its placement within the loop". Failure to prove
; keeps the old decline; see …_reject_classical_table_unbounded_index.ll.
;
; ⚠ THE GLOBAL HERE IS MUTABLE ON PURPOSE (`global`, not `constant`). Arm (1a)
; asks LLVM only about dereferenceability, so immutability is not required — and
; the loop-free arm (1b) DOES require it, an inherited asymmetry recorded at the
; predicate. Do not "tidy" this to `constant`: that would silently move the
; fixture onto the other arm.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: grep "call void @cqrt_copy_i32_controlled" %t.cqd0.ll | count 4
; RUN: grep "call i32 @cqrt_alloc_i32" %t.cqd0.ll | count 5
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
; RUN: grep "call void @cqrt_ry" %t.cqd0.ll | count 1
; RUN: grep "call void @cqrt_x(" %t.cqd0.ll | count 4
; RUN: grep "call void @cqrt_free(" %t.cqd0.ll | count 2
; RUN: grep "@cqrt_measure" %t.cqd0.ll | count 3
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; The classical loads survive as LOADS and feed the literal slot of an `_hl`
; template. The handle is operand 0; the classical value is operand 1.
; CHECK-DAG: load i32, ptr %{{.*}}
; CHECK-DAG: %z.stable = freeze i32 %z
; CHECK-DAG: %p.stable = freeze i32 %p
; CHECK-DAG: call i32 @cq_template_sub_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 %z.stable)
; CHECK-DAG: call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 %p.stable)
;
; The loop stays ROLLED.
; CHECK: br i1 %{{.*}}, label %exit, label %head
;
; ⚠ NOTHING QUANTUM IS MINTED FOR THE TABLE. No qram call, and no allocation of
; the loaded value onto a rail — that would be the §5.2 violation this whole
; admission turns on.
; Families that must be ABSENT entirely — these CAN be negatives.
; NEG-NOT: cqrt_rz
; NEG-NOT: cqrt_cswap
; NEG-NOT: cqrt_toffoli
; NEG-NOT: cqrt_cnot
; NEG-NOT: cqrt_qram
; NEG-NOT: cqrt_alloc_i1
; NEG-NOT: cqrt_alloc_i32(i32 %z
; NEG-NOT: cqrt_alloc_i32(i32 %p
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
  %d = icmp eq i64 %in, 3
  br i1 %d, label %exit, label %head
exit:
  %m1 = call i32 @cq_measure_si32(i32 %Zn)
  %m2 = call i32 @cq_measure_si32(i32 %Pn)
  %s = add i32 %m1, %m2
  ret i32 %s
}
