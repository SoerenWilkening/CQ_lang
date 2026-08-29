; control_swap_inloop_derived_cond.ll — ACCEPT (bd test_C_libtooling-8h7d.5, Phase
; 7.3 Increment 3). THE CUSTOMER SHAPE, reduced: a DERIVED-condition phase oracle
; and the S-dagger rotation, inside a classically-bounded loop.
;
;     int a = cq_theta(u0, 0.5);
;     for (int i = 0; i < 3; ++i) {
;         if (sqrt(a + 3.) <= 3.5) a = cq_phi(a, b);
;         a = cq_theta(a, -0.5);
;     }
;     return cq_measure(a);
;
; VERBATIM `clang -O1` OUTPUT (Rule 9 — note the polarity: `<= 3.5` is emitted as
; `fcmp ugt` with the gate arm as the FALSE successor, so the emitter brackets the
; route with `cqrt_x`).
;
; THIS FIXTURE IS ABOUT THE DISCHARGE, not the route. The condition builds a
; three-rail chain (`sitofp` → `fadd` → `sqrt`) that is ENTANGLED with the
; register; if it is still allocated when the S-dagger `cqrt_ry` fires, the
; rotation is dephased. The hand-unrolled twin reverses and frees all three
; between the flag strip and the flag free — the M-B interior partition (bd 160a).
; Getting the ROLLED loop to emit the same thing needed four `canRepeat` fences
; and three `provablyBefore` readings to be re-asked PER ACTIVATION, each gated on
; the affirmative `IterationLocalBlocks` mark that `markIfRailLocal` grants:
;   * the chain is minted, consumed, reversed and freed inside ONE iteration, so
;     the adjoint count matches the forward count trip for trip;
;   * the register is the loop's PERSISTENT rail — read from anywhere, never a
;     recovered terminal, and left to the user's `cq_measure`;
;   * clause (d)'s interval is [this trip's `sitofp`, this trip's discharge], and
;     the body's `cqrt_ry` sits strictly BETWEEN two intervals, never inside one.
;
; The end-to-end witness is `tests/e2e/slice_control_grover_loop_derived.c`, whose
; golden is BYTE-IDENTICAL to its hand-unrolled twin's.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare double @llvm.sqrt.f64(double)
declare i32 @cq_phi_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice(i32 noundef %0, double noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  br label %6
4:                                                ; preds = %15
  %5 = tail call i32 @cq_measure_si32(i32 noundef %17)
  ret i32 %5
6:                                                ; preds = %2, %15
  %7 = phi i32 [ 0, %2 ], [ %18, %15 ]
  %8 = phi i32 [ %3, %2 ], [ %17, %15 ]
  %9 = sitofp i32 %8 to double
  %10 = fadd double %9, 3.000000e+00
  %11 = tail call double @llvm.sqrt.f64(double %10)
  %12 = fcmp ugt double %11, 3.500000e+00
  br i1 %12, label %15, label %13
13:                                               ; preds = %6
  %14 = tail call i32 @cq_phi_si32(i32 noundef %8, double noundef %1)
  br label %15
15:                                               ; preds = %13, %6
  %16 = phi i32 [ %14, %13 ], [ %8, %6 ]
  %17 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef -5.000000e-01)
  %18 = add nuw nsw i32 %7, 1
  %19 = icmp eq i32 %18, 3
  br i1 %19, label %4, label %6
}

; ONE rail, minted outside the loop; the rail phi is collapsed away:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
;
; the exit block is printed BEFORE the loop block (LLVM layout order) — the
; register is the user measurement's to own, never compiler-freed:
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
;
; ONE rolled copy of the whole per-iteration stream, and the surviving header phi
; is the CLASSICAL induction variable only:
; CHECK:     %{{.*}} = phi i32 [ 0, %2 ], [ %{{.*}}, %4 ]
; CHECK-NOT: phi
; CHECK:     %[[C1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %[[H]])
; CHECK:     %[[C2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f64_hl(i32 %[[C1]], double 3.000000e+00)
; CHECK:     %[[C3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sqrt_f64(i32 %[[C2]])
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ugt_f64_hl(i32 %[[C3]], double 3.500000e+00)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; the gate arm is the FALSE successor -> the route is `cqrt_x`-bracketed:
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[R]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R]], double %1)
; CHECK:     call void @cqrt_free(i32 %[[R]])
;
; THE LOAD-BEARING PART — strip, then the WHOLE chain reversed LIFO and freed,
; then the flag free, and only THEN the S-dagger Ry. All in-body, once per trip:
; CHECK:     call void @cq_template_fcmp_ugt_f64_hl_unc(i32 %[[F]], i32 %[[C3]], double 3.500000e+00)
; CHECK:     call void @cq_template_sqrt_f64_unc(i32 %[[C3]], i32 %[[C2]])
; CHECK:     call void @cqrt_free(i32 %[[C3]])
; CHECK:     call void @cq_template_fadd_f64_hl_unc(i32 %[[C2]], i32 %[[C1]], double 3.000000e+00)
; CHECK:     call void @cqrt_free(i32 %[[C2]])
; CHECK:     call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[C1]], i32 %[[H]])
; CHECK:     call void @cqrt_free(i32 %[[C1]])
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
;
; still ROLLED — one back edge into the same block that holds the whole stream:
; CHECK:     br i1 %{{.*}}, label %3, label %4
;
; no leak, no dephasing report, no loop decline:
; CHECK-NOT: control flow inside a loop body
; CHECK-NOT: non-diagonal gate over a live derived record
