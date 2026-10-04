; control_measure_classical_bool_owner.ll — ACCEPT: THE OWNER'S FILE. bd
; test_C_libtooling-21mg, the customer the increment exists for.
;
; THE SOURCE, verbatim — the owner's 2026-09-11 22:18 edit of
; `example/grover/grover_oracle_uncompute.c` with the SECOND region commented out,
; which leaves `b1` declared, never assigned, and measured (probe
; `trackC/probes/owner_2026-09-11_2218.c`):
;
;     int a = 5; bool b0 = 0; bool b1 = 0;
;     if (a >= 3) { cq_theta(&b0, 0.5); }
;     if (b0 == 1) a -= 3;
;     return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
;
; The body below is that file's `clang -O1` `main`, dbg metadata stripped: `-O1`
; const-folds `a >= 3`, so the rotation is unconditional, and folds the whole
; `if (b0 == 1) a -= 3` diamond into ONE `select i1 %1, i32 2, i32 5` — the 4.4
; tainted-condition data select on a BARE `_Bool` RAIL condition (bd 3qlq.4 /
; l4x4.b: the register IS the flag, so the rail root takes the CNOT-copy ancilla,
; never an `x` bracket on a user register). `cq_measure(b1)` is the CLASSICAL
; measure — `i1 false`, no quantum lineage anywhere.
;
; RED-GREEN: on the ORACLE (`main` e96f89c / 86c0d25) this module DECLINES with
; `cq_measure_<sfx> operand not recognized; expected a tainted i32 handle` at the
; measure of `b1` — measured 2026-09-13. The 4.4 select region, the rail-root
; CNOT copy merge and the two real measurements were all already accepted there;
; the ONE classical measure refused the whole program.
;
; ⚠ THE WITNESS IS BYTE IDENTITY WITH THE TWIN, and it is an e2e gate rather than
; a `CHECK` here: `e2e-slice-measure-classical-bool` links and runs this program
; and `e2e-slice-measure-classical-bool-twin-identical` byte-diffs its 15-line
; trace against the trace of the same file with `cq_measure(b1)` DELETED. The
; classical measure must be worth exactly zero gates — identity, not "close".
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
  %1 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %2 = select i1 %1, i32 2, i32 5
  %3 = call i1 @cq_measure_i1(i1 %1)       ; QUANTUM   — b0, the rail
  %4 = zext i1 %3 to i32
  %5 = call i1 @cq_measure_i1(i1 false)    ; CLASSICAL — b1, never assigned
  %6 = zext i1 %5 to i32
  %7 = add nuw nsw i32 %6, %4
  %8 = call i32 @cq_measure_si32(i32 %2)   ; QUANTUM   — a, the select's out rail
  %9 = add nsw i32 %7, %8
  ret i32 %9
}

; the whole stream, in order. b0's rail; the CNOT-copied ancilla for the rail-root
; condition; the |0> out rail; the two X-bracketed controlled copies; the CNOT
; back (x ^ x = 0, which is what makes the ONE free a proven-|0> one); then the
; two real measurements:
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H]], i32 %[[BF]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[A]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[B]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H]], i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF]])
; CHECK-NEXT: %[[M1:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H]])
;
; ⚠ AND THIS IS THE LINE THE INCREMENT IS FOR: the classical measure of `b1`
; contributes the BARE LITERAL — no gate between the two real measurements:
; CHECK-NEXT: %[[Z1:[a-zA-Z0-9_.]+]] = zext i1 %[[M1]] to i32
; CHECK-NEXT: %[[Z2:[a-zA-Z0-9_.]+]] = zext i1 false to i32
; CHECK-NEXT: %[[S1:[a-zA-Z0-9_.]+]] = add nuw nsw i32 %[[Z2]], %[[Z1]]
; CHECK-NEXT: %[[M2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])

; ── WHOLE-FILE COUNTS, each in its own prefix (Rule 12 (a)) ─────────────────────
;
; FIVE rails and no more: b0, the CNOT-copy ancilla, the |0> out rail, and the two
; materialized select operands (2 and 5). A SIXTH would be a rail minted for the
; CLASSICAL `i1 false` — the f64/angle miscompile family, and the single worst
; outcome this change could have:
; ACNT-COUNT-5: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
;
; EXACTLY TWO measurement gates — b0 and a. A THIRD is the classical measure
; having minted one; the classical bit is not a qubit and has nothing to collapse:
; MCNT-COUNT-2: call {{.*}} @cqrt_measure_
; MCNT-NOT:     call {{.*}} @cqrt_measure_
;
; EXACTLY TWO `cqrt_x`, both on the ANCILLA `%bf` and never on the user register
; `%h` (the §16.3 bracket-count pin — a stray third computes the swapped/dirty-flag
; unitary with an identical symbol multiset):
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
;
; EXACTLY ONE free, the ancilla. `%h` is read only as a CONTROL and measured once —
; never bracketed, never freed (Rule 6: Ry(θ)|0> ≠ |0>):
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(

; ACC-NOT: operand not recognized
; ACC-NOT: under quantum control
; ACC-NOT: undef/poison literal
