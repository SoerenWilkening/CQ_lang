; control_swap_accept_two_iterations.ll — ACCEPT (bd test_C_libtooling-lom0
; Increment 4): TWO COMPLETE GROVER ITERATIONS, four chained `cq_theta`s, four
; sequential tainted-condition phase regions, one physical register.
;
; This is the fixture the increment exists for. `clang -O1` of:
;     volatile int off = 3;
;     int q = 0;
;     q = cq_theta(q, 0.5);  q += off;                 /* S      */
;     if (q == 5) q = cq_phi(q, PI);                   /* O      */
;     q -= off;  q = cq_theta(q, -0.5);                /* S†     */
;     if (q == 0) q = cq_phi(q, PI);                   /* R0     */
;     q = cq_theta(q, 0.5);  q += off;                 /* S      */
;     if (q == 5) q = cq_phi(q, PI);                   /* O      */
;     q -= off;  q = cq_theta(q, -0.5);                /* S†     */
;     if (q == 0) q = cq_phi(q, PI);                   /* R0     */
;     q = cq_theta(q, 0.5);  q += off;                 /* re-prep */
;     return cq_measure(q);
;
; MEASURED at HEAD (b4e329b): declines,
;     cq controlled lowering: condition predates a non-diagonal gate
; and nothing else — bd lom0's own comment records that a 2-iteration Grover
; hits this one diagnostic and no other. It is the single wall.
;
; FOUR CHAINED THETAS, TWO OF WHICH DRIVE THE ACCEPT. The two `S†` thetas and
; the two `S` re-preps are all chained (arg-0 is a live quantum wire). The
; ORACLE regions never needed the widening: their conditions read an `add`
; result, the walk crosses the merge phi but not the following `sub`, so the
; S-dagger theta behind it is never reached and no gate is found on their wire
; at all (measured on the one-iteration twin: swapping an oracle arm for a value
; op yields the value-arm string, not the deferred wire-gate one). The two REFLECTION regions are
; the ones that declined: each reads a chained theta directly, and each one's
; forward wire runs through its merge phi into the NEXT `cq_theta`. Both of
; those are dominated by their region's branch and cannot reach back to it, so
; `provablyBefore(BI, T)` holds twice and both regions accept as PHASE arms.
;
; WHAT THE STREAM BELOW WITNESSES, in order, and it is the whole correctness
; claim of the increment: for EVERY region the flag is minted, routed, Rz'd,
; routed back, the work rail freed, the flag `_unc`-STRIPPED and FREED — and only
; THEN does the next `cqrt_ry_i32` fire. Four strips, four flag frees, four rail
; frees, and no `cqrt_ry_i32` between a mint and its strip. A regression that let
; a re-prep Ry slide before a strip would still verify clean and still pair every
; free; only this ordering catches it.
;
; ONE REGISTER (M-C, bd 6uqc Inc 2): every `+= off` / `-= off` is an in-place
; `cqrt_addc_i32`, so exactly FIVE `cqrt_alloc_i32` appear — the wire plus one
; work rail per region — and nothing else is entangled with the wire when any of
; the four non-diagonal gates fires. That is the property the e2e customer
; `slice_control_grover_2iter` re-checks at the trace level with strict
; free-pairing (`5 rail mint(s) of which 1 left allocated`, the measured register).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT2 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT3 < %t.cqd0.ll
@off = global i32 3, align 4

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
  %1 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %2 = load volatile i32, ptr @off, align 4
  %3 = add nsw i32 %2, %1
  %4 = icmp eq i32 %3, 5
  br i1 %4, label %5, label %7

5:                                                ; preds = %0
  %6 = call i32 @cq_phi_si32(i32 5, double 0x400921FB54442D18)
  br label %7

7:                                                ; preds = %5, %0
  %8 = phi i32 [ %6, %5 ], [ %3, %0 ]
  %9 = load volatile i32, ptr @off, align 4
  %10 = sub nsw i32 %8, %9
  %11 = call i32 @cq_theta_si32(i32 %10, double -5.000000e-01)
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %15

13:                                               ; preds = %7
  %14 = call i32 @cq_phi_si32(i32 0, double 0x400921FB54442D18)
  br label %15

15:                                               ; preds = %13, %7
  %16 = phi i32 [ %14, %13 ], [ %11, %7 ]
  %17 = call i32 @cq_theta_si32(i32 %16, double 5.000000e-01)
  %18 = load volatile i32, ptr @off, align 4
  %19 = add nsw i32 %18, %17
  %20 = icmp eq i32 %19, 5
  br i1 %20, label %21, label %23

21:                                               ; preds = %15
  %22 = call i32 @cq_phi_si32(i32 5, double 0x400921FB54442D18)
  br label %23

23:                                               ; preds = %21, %15
  %24 = phi i32 [ %22, %21 ], [ %19, %15 ]
  %25 = load volatile i32, ptr @off, align 4
  %26 = sub nsw i32 %24, %25
  %27 = call i32 @cq_theta_si32(i32 %26, double -5.000000e-01)
  %28 = icmp eq i32 %27, 0
  br i1 %28, label %29, label %31

29:                                               ; preds = %23
  %30 = call i32 @cq_phi_si32(i32 0, double 0x400921FB54442D18)
  br label %31

31:                                               ; preds = %29, %23
  %32 = phi i32 [ %30, %29 ], [ %27, %23 ]
  %33 = call i32 @cq_theta_si32(i32 %32, double 5.000000e-01)
  %34 = load volatile i32, ptr @off, align 4
  %35 = add nsw i32 %34, %33
  %36 = call i32 @cq_measure_si32(i32 %35)
  ret i32 %36
}

; ONE register for the whole program.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 %{{[a-zA-Z0-9_.]+}})
;
; ---- iteration 1, oracle ----
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK:     %[[R1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[H]], i32 %[[R1]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R1]], double 0x400921FB54442D18)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[H]], i32 %[[R1]])
; CHECK:     call void @cqrt_free(i32 %[[R1]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
;
; ---- iteration 1, S-dagger (in place, on the same rail) ----
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
;
; ---- iteration 1, reflection about |0> ----
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 0)
; CHECK:     %[[R2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F2]], i32 %[[H]], i32 %[[R2]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R2]], double 0x400921FB54442D18)
; CHECK:     call void @cqrt_cswap(i32 %[[F2]], i32 %[[H]], i32 %[[R2]])
; CHECK:     call void @cqrt_free(i32 %[[R2]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[H]], i32 0)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
;
; ---- iteration 2, S (THE line bd lom0 was filed for) ----
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 %{{[a-zA-Z0-9_.]+}})
;
; ---- iteration 2, oracle ----
; CHECK:     %[[F3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK:     %[[R3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F3]], i32 %[[H]], i32 %[[R3]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R3]], double 0x400921FB54442D18)
; CHECK:     call void @cqrt_cswap(i32 %[[F3]], i32 %[[H]], i32 %[[R3]])
; CHECK:     call void @cqrt_free(i32 %[[R3]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F3]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F3]])
;
; ---- iteration 2, S-dagger ----
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
;
; ---- iteration 2, reflection about |0> ----
; CHECK:     %[[F4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 0)
; CHECK:     %[[R4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F4]], i32 %[[H]], i32 %[[R4]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R4]], double 0x400921FB54442D18)
; CHECK:     call void @cqrt_cswap(i32 %[[F4]], i32 %[[H]], i32 %[[R4]])
; CHECK:     call void @cqrt_free(i32 %[[R4]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F4]], i32 %[[H]], i32 0)
; CHECK:     call void @cqrt_free(i32 %[[F4]])
;
; ---- final re-prep + the ONE measurement the user wrote ----
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
;
; All four diamonds flattened; no residual quantum control.
; CHECK-NOT: phi
; CHECK-NOT: br i1
;
; FIVE allocations: the wire + one work rail per region. Nothing else is ever
; entangled with the wire.
; CNT-COUNT-5:  call i32 @cqrt_alloc_i32(
; CNT-NOT:      call i32 @cqrt_alloc_i32(
; Four flag strips, and eight frees (four rails + four flags) — every ancilla
; discharged before the next non-diagonal gate.
; CNT2-COUNT-4: call void @cq_template_icmp_eq_i32_hl_unc(
; CNT2-NOT:     call void @cq_template_icmp_eq_i32_hl_unc(
; CNT3-COUNT-8: call void @cqrt_free(
; CNT3-NOT:     call void @cqrt_free(
