; lowering_uncompute_interior_two_components.ll — ACCEPT, and the ONLY fixture
; that discriminates the PER-COMPONENT interior anchor (bd
; test_C_libtooling-if1e, the Rule-13 reviewer's Q2 recommendation from M-B
; Increment 5, landed with Increment 6 because its Grover customer needs it).
;
;     int q  = u; cq_theta(&q, 0.5);
;     int a  = q * 5;   int m1 = cq_measure(a & 12);
;     cq_theta(&q, 0.25);          /* the chained Ry, in the middle */
;     int b  = q * 7;   int m2 = cq_measure(b & 20);
;
; TWO INTERIOR RAILS, `a` and `b`, with NO producer edge between them: neither
; is an operand of the other's producer, so no recovered DAG can contain both.
; They are two COMPONENTS. Each is consumed by its own `and` (which is measured
; and therefore not itself interior), and the two consumers sit on OPPOSITE
; sides of a chained `cq_theta` on the shared source wire.
;
; MEASURED AT 439dae3 (the pre-change plugin): this program DECLINES with
;     cq rotation lowering: non-diagonal gate over a live derived record
; and that decline is the bug. One `At` per FUNCTION is the nearest common
; post-dominator of EVERY consumer of EVERY interior rail, so it landed after
; `b`'s `and` — and the chained `cqrt_ry` on the borrowed source wire was then
; STRICTLY INSIDE the clause-(d) interval of `a`'s group. Neither disjunct holds
; there (correctly: an `_unc` scheduled after a non-diagonal wire gate reads a
; post-Ry basis — the owner's 2026-08-27 ruling), so the WHOLE function leaked,
; `a` stood as a dead record at the Ry, and the M-A guard refused the program.
;
; PER COMPONENT each rail anchors at its own consumer: `a` discharges BEFORE the
; Ry (where the wire still holds its pre-Ry basis) and `b` AFTER it (where the
; Ry is to the LEFT of `b`'s whole interval). Both `_unc`s read exactly the basis
; their forward gate read, and the program lowers.
;
; NEVER FINER THAN A COMPONENT. `a` and `b` are split because a producer edge
; does not join them. Two rails that ARE joined — the `sitofp/fadd/sqrt` chain of
; lowering_uncompute_interior_straightline.ll — stay in ONE component and one
; LIFO reversal, because splitting them would free a parent before its child's
; adjoint reads it (Rule 8's shared prefix).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @two_components(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a  = mul nsw i32 %q, 5
  %a2 = and i32 %a, 12
  %m1 = call i32 @cq_measure_si32(i32 %a2)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)
  %b  = mul nsw i32 %q2, 7
  %b2 = and i32 %b, 20
  %m2 = call i32 @cq_measure_si32(i32 %b2)
  %s  = add i32 %m1, %m2
  ret i32 %s
}

; CHECK-LABEL: define i32 @two_components(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; COMPONENT 1 — discharged at ITS consumer, strictly BEFORE the chained Ry:
; CHECK-NEXT: %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[A2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[A]], i32 12)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[A]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[A2]])
; the chained Ry — the gate the single-`At` version could never get past:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; COMPONENT 2 — its own anchor, with the Ry now entirely to the LEFT:
; CHECK-NEXT: %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 7)
; CHECK-NEXT: %[[B2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[B]], i32 20)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[B]], i32 %[[H]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[B]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[B2]])

; The source wire is a BORROWED parent of both components and is never freed by
; either — it carries the superposition `cqrt_ry` minted (the "decisive
; corollary"), and no adjoint returns it to |0>:
; CHECK-NOT: call void @cqrt_free(i32 %[[H]])

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
