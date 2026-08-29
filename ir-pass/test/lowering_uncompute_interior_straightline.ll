; lowering_uncompute_interior_straightline.ll — ACCEPT (Phase 5 + M-B Increment
; 5a, bd test_C_libtooling-6uqc). THE FLAGSHIP INTERIOR-RAIL FIXTURE: bd 6uqc's
; P1, verbatim, as the pass receives it.
;
;     int f = sqrt(a + 3.0) <= 5.0;      /* a = cq_theta(a, 0.5) */
;     return cq_measure(f);
;
; THE DEFECT IT PINS. `clang -O1` DCEs only chains that are dead BEFORE the pass;
; this one is live into a `zext` whose result is measured, so all four
; intermediate rails survive. They are NOT terminals either — every one has a
; forward consumer — so `ChainWalk::isTerminalHandle` is false for each and
; `recoverDataDag` was never seeded anywhere in the chain. HEAD (c36934a) emitted
;     alloc; ry; sitofp -> h1; fadd -> h2; sqrt -> h3; fcmp -> h4; zext -> h5;
;     measure(h5)
; with `opt` rc=0, `opt -verify` clean and `free_pairing_check.py` silent (it does
; not track template-minted rails — bd 1739). FOUR entangled basis records of the
; wire, minted and never discharged. Under any later interference on `a` that is
; a dephasing, not a leak (bd 6uqc's P4 is the same chain with a chained
; `cq_theta` after it, and it DECLINES at the M-A guard).
;
; THE ANALYTIC ARGUMENT, per rail, because "verify-clean" proves none of it:
;   * h1..h4 are each minted by an UNCONTROLLED `cq_template_*`, i.e. a BASIS
;     PERMUTATION of its parents (`preservesBasisUnderRecord`). Writing W_R for
;     that permutation and C for the record the surviving `zext`/`measure` chain
;     holds of it, W_R† C W_R (|0>_R ⊗ |ψ>) = |0>_R ⊗ (C relabelled) — the bd
;     261j(a) invariant, whose clause (d) ("every register the adjoint reads
;     holds its forward value") is delivered here by reverse program order for
;     the OWNED parents and by the clause-(d1) no-mutation scan for the BORROWED
;     one. So each rail is provably |0> at its `cqrt_free` (Rule 6).
;   * h0 — the `cqrt_alloc`-minted source wire — is a BORROWED parent and is
;     LEFT ALLOCATED. Its gate is `cqrt_ry`, which is NOT a basis permutation:
;     it is the gate that MINTS the superposition, so once the surviving record
;     exists Ry† does not return it to |0> and a `cqrt_free` on it would be a
;     hidden measurement. That is the "decisive corollary" in
;     ChainWalk::preservesBasisUnderRecord, and it is why M-B can never lift a
;     SOURCE rail — only interior ones.
;   * The discharge is placed BEFORE `cqrt_measure_i32(h5)`, which reads only h5.
;     Nothing the reversal touches is read by the measurement.
;
; ORDER IS THE ASSERTION. The `CHECK` lines below are `CHECK-NEXT`-tight through
; the whole reversal so that a re-ordering — an `_unc` before the `_unc` of a rail
; it reads, or a `cqrt_free` before the last reverse-read of the rail — fails
; here rather than in a golden nobody re-derives.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @llvm.sqrt.f64(double)

define i32 @interior_p1(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = sitofp i32 %q to double
  %a = fadd double %c, 3.000000e+00
  %s = call double @llvm.sqrt.f64(double %a)
  %f = fcmp ole double %s, 5.000000e+00
  %z = zext i1 %f to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}

; CHECK-LABEL: define i32 @interior_p1(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[C:.*]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %[[H]])
; CHECK-NEXT: %[[A:.*]] = call i32 @cq_template_fadd_f64_hl(i32 %[[C]], double 3.000000e+00)
; CHECK-NEXT: %[[S:.*]] = call i32 @cq_template_sqrt_f64(i32 %[[A]])
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_fcmp_ole_f64_hl(i32 %[[S]], double 5.000000e+00)
; CHECK-NEXT: %[[Z:.*]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[F]])
; The whole-DAG LIFO reversal, innermost-last, each rail freed after its last
; reverse-read:
; CHECK-NEXT: call void @cq_template_fcmp_ole_f64_hl_unc(i32 %[[F]], i32 %[[S]], double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_sqrt_f64_unc(i32 %[[S]], i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[S]])
; CHECK-NEXT: call void @cq_template_fadd_f64_hl_unc(i32 %[[A]], i32 %[[C]], double 3.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[C]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: %[[M:.*]] = call i32 @cqrt_measure_i32(i32 %[[Z]])
; CHECK-NEXT: ret i32 %[[M]]

; The BORROWED source wire is never adjointed and never freed — a Rule-6 safe
; leak, and the ONE thing this increment must not "improve".
; CHECK-NOT: cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
