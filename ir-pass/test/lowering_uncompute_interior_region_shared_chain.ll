; lowering_uncompute_interior_region_shared_chain.ll — ACCEPT (M-B Increment 6,
; clause (d2); bd test_C_libtooling-160a Rule-13 round, finding F1c). TWO regions
; whose derived conditions SHARE a chain rail — one component spanning both.
;
; PROVENANCE: `clang -O1` output of
;
;     int q = cq_theta(u, 0.5);
;     int d = q * 5;
;     if ((d >> 2) == 5) q = cq_phi(q, PI);     /* -> (d & -4) == 20, i.e. q == 4 */
;     if ((d >> 3) == 2) q = cq_phi(q, 0.25);   /* -> (d & -8) == 16, also q == 4 */
;     q = cq_theta(q, -0.5);  return cq_measure(q);
;
; THE SHAPE, AND WHY IT IS ONE COMPONENT. `%h_op` (the `mul`) is the producer
; operand of BOTH `and` rails, so `link` unions all three into a single interior
; component. Its `At` is the LAST strip's next node, which puts REGION 1's entire
; route group inside the interval of the `mul` rail — a base-touching pair the
; two straight-line disjuncts (LEFT / RIGHT) cannot exempt. Clause (d2) exempts
; it as a UNIT: both halves are inside, so the group is a no-op on `%h`'s BASIS
; LABEL over the interval, and the `mul_unc` placed after it reads the same wire
; the forward `mul` read.
;
; AND NOTE WHAT SURVIVES REGION 2 UNTOUCHED: region 1's `and` rail (`%h_op3`) is
; a live RECORD of `%h` across region 2's `cqrt_rz`. That is sound because `Rz`
; is DIAGONAL — it multiplies a phase onto a basis label it does not move — so
; the record still names the same label when its `_unc` runs. A `cqrt_ry` there
; instead is the `a5` shape and DECLINES ("condition predates a non-diagonal
; gate"); the discrimination is not incidental.
;
; The unwind order is the LIFO of the recovered DAG, not of the source: region
; 2's `and` first, then region 1's, then the shared `mul`.
;
; RED-CHECKED against an `f27c7fd` (pre-Increment-6) plugin: the chain is refused
; there (a strip is not an interior consumer), nothing discharges, and the
; program DECLINES at the M-A guard on the S-dagger.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @shared_chain_two_regions(i32 noundef %0) {
  %2 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %3 = mul nsw i32 %2, 5
  %4 = and i32 %3, -4
  %5 = icmp eq i32 %4, 20
  br i1 %5, label %6, label %8

6:                                                ; preds = %1
  %7 = call i32 @cq_phi_si32(i32 noundef %2, double noundef 0x400921FB54442D18)
  br label %8

8:                                                ; preds = %6, %1
  %9 = phi i32 [ %7, %6 ], [ %2, %1 ]
  %10 = and i32 %3, -8
  %11 = icmp eq i32 %10, 16
  br i1 %11, label %12, label %14

12:                                               ; preds = %8
  %13 = call i32 @cq_phi_si32(i32 noundef %9, double noundef 2.500000e-01)
  br label %14

14:                                               ; preds = %12, %8
  %15 = phi i32 [ %13, %12 ], [ %9, %8 ]
  %16 = call i32 @cq_theta_si32(i32 noundef %15, double noundef -5.000000e-01)
  %17 = call i32 @cq_measure_si32(i32 noundef %16)
  ret i32 %17
}

; CHECK-LABEL: define i32 @shared_chain_two_regions(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[A1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[D]], i32 -4)

; Region 1 — its route group is what clause (d2) must exempt, since the shared
; `mul` rail's discharge lands past it:
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A1]], i32 20)
; CHECK-NEXT: %[[R1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F1]], i32 %[[H]], i32 %[[R1]])
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[R1]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F1]], i32 %[[H]], i32 %[[R1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R1]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[A1]], i32 20)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])

; Region 2 mints its own `and` off the SAME `mul` rail; region 1's `and` rail is
; still allocated across region 2's diagonal Rz:
; CHECK-NEXT: %[[A2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[D]], i32 -8)
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A2]], i32 16)
; CHECK-NEXT: %[[R2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F2]], i32 %[[H]], i32 %[[R2]])
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[R2]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F2]], i32 %[[H]], i32 %[[R2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R2]])

; Then the whole component unwinds LIFO after strip 2 — and the shared `mul_unc`
; reads %[[H]] ACROSS both recorded route groups:
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[A2]], i32 16)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A2]], i32 %[[D]], i32 -8)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A2]])
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A1]], i32 %[[D]], i32 -4)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A1]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[D]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
