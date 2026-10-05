; lowering_uncompute_interior_qram_parent_measured_after.ll — ACCEPT (M-B
; Increment 5, bd test_C_libtooling-4p7j Rule-13 round, finding F4e). CLAUSE (d)'s
; RIGHT DISJUNCT OVER A MEASUREMENT: the borrowed parent is a 7.5 QROM load rail
; that is MEASURED after the discharge point.
;
;     v = tbl[a & 3];  x = v * 3;  y = x * x;  return measure(y) + measure(v);
;
; WHAT IT EXERCISES THAT NOTHING ELSE DOES. `preservesBorrowedParent` is a
; deliberately narrow whitelist, two rows when this was written and four today
; (Uncomputation.cpp: (1) a diagonal `cqrt_rz_<W>` on the parent, (1b) its
; `_controlled` twin, vacuous since 3qlq, (2) a forward reassigning producer,
; (3) since bd rhk5 a Phase-6 clone call proven read-only on the parent);
; everything else — `cqrt_measure_*` included —
; counts as a MUTATION and must then clear the positional interval scan. The
; shipped RIGHT-disjunct fixtures all clear a `cqrt_ry` (the chained theta) or,
; pre-3qlq, a Phase-4 route. This is the third kind of "mutation": a COLLAPSE.
;
; WHY ADMITTING IT IS SOUND, and note the argument is positional, not physical.
; The `_unc`s are inserted BEFORE `At`, and `provablyBefore(At, measure)` says
; every path to the measurement runs through `At` and never comes back. So the
; whole reversal has already executed when the collapse happens: the adjoints
; read `%v` at its pre-measurement basis, which is exactly the basis the forward
; gates read. Nothing here claims it would be safe to read a register across a
; measurement — the point is that no adjoint does.
;
; THE LOAD RAIL ITSELF IS NEVER OWNED. `cqrt_qram_load_<W>` is excluded from
; interior CANDIDACY by scope (Inc 5 leaves the 7.5 Shadow surface alone —
; lowering_uncompute_interior_leak_qram_load.ll), so it can only ever appear on
; the BORROWED frontier, read-only, never adjointed and never freed. It is
; admitted as a CONSUMER in the other direction (an index rail it reads is
; dischargeable — lowering_uncompute_interior_qram_index.ll); this fixture is the
; parent-side twin.
;
; RE-DISPOSITIONED BY THE PER-COMPONENT ANCHOR (bd test_C_libtooling-if1e, M-B
; Increment 6) — the ACCEPT is unchanged, the PLACEMENT moved and the CHECK
; order with it. The index rail `%i & 3` and the load-derived rail `%v * 3` have
; NO producer edge between them (the QROM load that joins them is not an interior
; gate — the 7.5 surface is out of scope), so they are two COMPONENTS. Each now
; anchors at its OWN consumer: the index discharges immediately after the
; `cqrt_qram_load` that read it, instead of waiting for the unrelated second
; chain's last use. That is strictly earlier and strictly less entangled, and the
; RIGHT-disjunct-over-a-measurement property this fixture exists for is untouched
; (the `%v` measure is still after both discharges). Increment 5 emitted both in
; one LIFO block because it had one `At` per function.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEV < %t.cqd0.ll
@tbl = private unnamed_addr constant [4 x i32] [i32 7, i32 11, i32 13, i32 17]

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @interior_qram_parent(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = and i32 %q, 3
  %i64 = sext i32 %i to i64
  %g = getelementptr inbounds [4 x i32], ptr @tbl, i64 0, i64 %i64
  %v = load i32, ptr %g
  %x = mul i32 %v, 3
  %y = mul i32 %x, %x
  %m = call i32 @cq_measure_si32(i32 %y)
  %m2 = call i32 @cq_measure_si32(i32 %v)
  %s = add i32 %m, %m2
  ret i32 %s
}

; CHECK-LABEL: define i32 @interior_qram_parent(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[IDX:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[IDX]])
; the INDEX component discharges at ITS OWN consumer, the load that read it:
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[IDX]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[IDX]])
; CHECK-NEXT: %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[V]], i32 3)
; CHECK-NEXT: %[[Y:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %[[X]], i32 %[[X]])
; …and the LOAD-RESULT component at its own, still BEFORE the measure of %[[V]]:
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[X]], i32 %[[V]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[X]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Y]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[V]])

; The borrowed QROM load rail is never adjointed and never freed — nor is the
; array token, nor the source wire (one anchor, one prefix ⇒ window anchor ->
; EOF; bd memory [filecheck-check-not-window-trap]):
; NOFREEV:     %[[V2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(
; NOFREEV-NOT: @cqrt_qram_load_i32_unc(
; NOFREEV-NOT: call void @cqrt_free(i32 %[[V2]])
