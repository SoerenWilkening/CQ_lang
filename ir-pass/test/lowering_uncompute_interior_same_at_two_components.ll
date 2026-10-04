; lowering_uncompute_interior_same_at_two_components.ll — ACCEPT (M-B Increment
; 6a, the per-component interior anchor; bd test_C_libtooling-160a Rule-13
; round, finding F1d — and the implementer's own recorded unknown #3, "no
; fixture where two components land on the same instruction").
;
; PROVENANCE: `clang -O1` output of
;
;     int q = u; cq_theta(&q, 0.5);
;     int a = q * 5;  int b = q * 7;
;     int s = (a & 12) + (b & 20);
;     return cq_measure(s);
;
; THE SHAPE. `{mul 5, and 12}` and `{mul 7, and 20}` are two components — no
; producer edge joins them, and their only shared value is the BORROWED source
; rail `%h`, which is owned by neither (a `cqrt_alloc`-minted `cqrt_ry` rail is
; never an interior candidate: it carries the superposition, so no adjoint
; returns it to |0>). Both components' consumers end at the same `add`, so both
; compute the SAME `At` — the add's next node. This is the one arrangement the
; per-component driver had no pin for.
;
; WHAT IT PROVES. The two blocks are emitted BACK TO BACK, not interleaved, and
; each is internally LIFO with its free immediately after its own `_unc`. That is
; the visible consequence of PLAN-ALL-THEN-EMIT-ALL: component A's `_unc`s READ
; the shared borrowed parent `%h`, and if A were emitted before B was PLANNED,
; those reads would sit inside B's clause-(d) interval, where the scan cannot
; tell a read from a write and would leak B for no physics. Planning both first
; and emitting both after is what keeps them independent.
;
; AND WHY BACK-TO-BACK IS SAFE. Component ownership is disjoint by construction
; (a shared Anchorable operand would have been LINKED into one component), so A's
; emission only READS shared borrowed parents, WRITES A-owned rails and FREES
; A-owned rails — none of which can change a label B reads. `%h` is read by both
; and written by neither; the `add` rail `%h_op4` is the measured terminal and is
; owned by no component.
;
; RED-CHECKED against a `439dae3` (pre-Increment-6a) plugin: there the single
; function-wide `At` merges the two into one group and the emitted order differs
; — the adjacency below is what discriminates.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @same_at_two_components(i32 noundef %0) {
  %2 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %3 = mul nsw i32 %2, 5
  %4 = mul nsw i32 %2, 7
  %5 = and i32 %3, 12
  %6 = and i32 %4, 20
  %7 = add nuw nsw i32 %5, %6
  %8 = call i32 @cq_measure_si32(i32 noundef %7)
  ret i32 %8
}

; CHECK-LABEL: define i32 @same_at_two_components(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 7)
; CHECK-NEXT: %[[A2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[A]], i32 12)
; CHECK-NEXT: %[[B2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[B]], i32 20)
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[A2]], i32 %[[B2]])
; Component 1, whole, then component 2, whole — no interleave, and every free is
; adjacent to its own adjoint:
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A2]], i32 %[[A]], i32 12)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A2]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[A]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[B2]], i32 %[[B]], i32 20)
; CHECK-NEXT: call void @cqrt_free(i32 %[[B2]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[B]], i32 %[[H]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[B]])
; …and only then the measure of the surviving sum rail:
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[S]])
