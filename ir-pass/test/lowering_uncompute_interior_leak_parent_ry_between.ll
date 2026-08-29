; lowering_uncompute_interior_leak_parent_ry_between.ll — LEAK PROBE (M-B
; Increment 5a, bd test_C_libtooling-6uqc). CLAUSE (d), the NON-DIAGONAL case: a
; chained `cq_theta` re-rotates the borrowed source wire BETWEEN the forward gate
; and the discharge point.
;
; The mechanism is the same as the `addc` sibling and the consequence is worse: an
; `_unc` recomputing `3*%h` after `cqrt_ry_i32(%h, 0.25)` reads a wire whose basis
; the Ry has rotated, so the rail is not zeroed and its `cqrt_free` collapses `%h`.
; This is the exact shape owner ruling 2026-08-27 named for clause (d) — "a
; discharge scheduled AFTER a non-diagonal wire gate is itself unsound (the `_unc`
; would read a post-Ry basis); the spine must never place one there."
;
; IT STAYS A LEAK AT INCREMENT 5b, unlike bd 6uqc's P4. 5b admits a mutation that
; is provably AFTER the whole discharge (`provablyBefore(At, M)`); this Ry is
; strictly INSIDE the interval — the compare that anchors the discharge reads
; `%h_op` after it — so neither disjunct holds and it leaks under both.
;
; `opt` EXITS 0. The M-A guard does not fire, and that is correct rather than a
; gap: every record of the wire (`%h_op`, the compare, the zext) has a post-gate
; lineage reaching the `cqrt_measure_i32`, so all three are LIVE user data whose
; dephasing is source semantics (owner ruling 2026-08-27 (1), clause 3 as the
; observing-sink walk). Nothing is dead at the gate; nothing is loud.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leak_parent_rery(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)
  %c = icmp slt i32 %a, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %s = add i32 %m, %m2
  ret i32 %s
}

; CHECK-LABEL: define i32 @leak_parent_rery(
; CHECK: %[[A:.*]] = call i32 @cq_template_mul_i32_hl
; CHECK-NEXT: call void @cqrt_ry_i32
; CHECK-NEXT: call i32 @cq_template_icmp_slt_i32_hl(i32 %[[A]]
; CHECK-NOT: _unc
; CHECK-NOT: call void @cqrt_free
