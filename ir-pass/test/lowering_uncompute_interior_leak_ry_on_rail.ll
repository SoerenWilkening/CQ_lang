; lowering_uncompute_interior_leak_ry_on_rail.ll — LEAK PROBE (M-B Increment 5a,
; bd test_C_libtooling-6uqc). INVARIANT: an interior rail that carries its OWN
; `cqrt_ry` is refused, and this is the exact boundary
; lowering_uncompute_interior_inplace_rz.ll sits on the other side of.
;
; `%h_op` is a `mul` rail the user then re-rotates with a chained `cq_theta`, an
; in-place NON-DIAGONAL gate on the rail itself. `ChainWalk::isInteriorConsumer`
; admits an in-place gate only when `preservesBasisUnderRecord` accepts it, and
; `cqrt_ry_<W>` is precisely what that predicate's fail-closed default exists to
; catch: cond(W) is empty (the angle is classical, Rule 3) and W is NOT trivial on
; |0> — it is the gate that MINTS superposition. A downstream record of such a
; rail is entanglement no adjoint can undo, so `Ry† C Ry |0>` is not |0> and the
; free would be a hidden measurement.
;
; The DISCRIMINATION is the point: the compare rail `%h_cmp` sitting on top of
; `%h_op` is still discharged. The refusal is PER RAIL, not per DAG.
;
; THE TRAILING `cq_measure(%q)` IS LOAD-BEARING, NOT DECORATION. Without it the
; module DECLINES at the late M-A guard ("non-diagonal gate over a live derived
; record") before this fixture can assert anything: the chained `cq_theta` on
; `%h_op` is a guard SITE, and the alloc-minted ancestor `%h` is then a record
; with no post-gate observing sink, i.e. dead at the gate. Measuring `%h`
; afterwards makes it live user data (clause 3, the observing-sink walk), which
; is the accept this fixture needs in order to be about M-B at all. That
; interaction is worth knowing: an M-B leak probe on a chained-theta shape has to
; keep the M-A guard quiet or it measures the wrong thing.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leak_ry_on_rail(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  %r = call i32 @cq_theta_si32(i32 %a, double 2.500000e-01)
  %c = icmp slt i32 %r, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m, %m2
  ret i32 %s
}

; CHECK-LABEL: define i32 @leak_ry_on_rail(
; CHECK: %[[A:.*]] = call i32 @cq_template_mul_i32_hl
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[A]], double 2.500000e-01)
; CHECK-NEXT: %[[C:.*]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[A]], i32 10)
; CHECK-NEXT: call i32 @cq_template_zext_i1_to_i32(i32 %[[C]])
; the compare rail IS discharged; the Ry-bearing rail is NOT
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[C]], i32 %[[A]], i32 10)
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: call i32 @cqrt_measure_i32
; CHECK-NOT: cq_template_mul_i32_hl_unc
; CHECK-NOT: call void @cqrt_free(i32 %[[A]])
