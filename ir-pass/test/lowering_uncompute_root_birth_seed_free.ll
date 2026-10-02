; lowering_uncompute_root_birth_seed_free.ll — clause (a) of the record-freeze
; invariant, "R starts at |0⟩", asked of a dead `cq_theta` root (bd
; test_C_libtooling-5c5b, libcqops bead vmz9; BirthFreeze.h).
;
; `cqrt_alloc_<W>(seed)` prepares the classical basis state |seed⟩. The spine
; reverse-plays the root's `Ry`, which returns it to |seed⟩ — not |0⟩ — so a
; `cqrt_free` after the adjoint resets a nonzero (or, for a runtime seed, an
; unproven) basis state: a dirty free, convicted by libcqops' free certificate.
; Before bd 5c5b each single-root function below ended `ry(h, -0.5); cqrt_free(h)`
; (measured with the pre-fix cq-opt on main aec4a6ce). The rule:
;   * a runtime i32 seed, a runtime f64 seed, a nonzero literal, and the f64
;     literal -0.0 (sign bit set — bitwise NONZERO) are NOT proven |0⟩: the
;     adjoint stays, the free goes, the root is LEFT ALLOCATED (Rule 6);
;   * an i32 literal 0 and the f64 literal +0.0 are born |0⟩: the free stays,
;     CHECK-NEXT-adjacent to the adjoint that proves it;
;   * per RAIL, not per DAG (`@mixed_qq`): in one dead Q+Q DAG the template
;     rail and the zero-seeded root are freed while the runtime-seeded root is
;     reverse-played and kept.
; Each body is sealed by an unbroken CHECK-NEXT chain from `entry:` to `ret`, so
; a free (or any other stray call) slipped into a kept root's tail fails the
; positive chain itself — no CHECK-NOT window to get wrong.
;
; Mutants this fixture kills (bd 5c5b mutation record): `railBornZero` true for
; every `cqrt_alloc` (the pre-fix behaviour); -0.0 read as zero
; (`APFloat::isZero`); and the freeze applied to every rail (template and
; zero-seed frees vanish).
;
; RETIREMENT TRIGGER: a reversal that un-seeds a root (`cqrt_xorc`/`cqrt_addc`
; of the classical seed before the free) changes the kept-root tails below into
; un-seed + free; update this fixture with that emitter, never by deleting the
; runtime/literal cases.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare double @cq_theta_f64(double, double)

define void @runtime_i32(i32 %seed) {
entry:
  %q = call i32 @cq_theta_si32(i32 %seed, double 5.000000e-01)
  ret void
}

; CHECK-LABEL: define void @runtime_i32(
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[RI:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %seed)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[RI]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[RI]], double -5.000000e-01)
; CHECK-NEXT:  ret void

define void @runtime_f64(double %seed) {
entry:
  %q = call double @cq_theta_f64(double %seed, double 5.000000e-01)
  ret void
}

; CHECK-LABEL: define void @runtime_f64(
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[RF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %seed)
; CHECK-NEXT:  call void @cqrt_ry_f64(i32 %[[RF]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_f64(i32 %[[RF]], double -5.000000e-01)
; CHECK-NEXT:  ret void

define void @literal_nonzero_i32() {
entry:
  %q = call i32 @cq_theta_si32(i32 5, double 5.000000e-01)
  ret void
}

; CHECK-LABEL: define void @literal_nonzero_i32(
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[LI:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[LI]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[LI]], double -5.000000e-01)
; CHECK-NEXT:  ret void

define void @literal_negzero_f64() {
entry:
  %q = call double @cq_theta_f64(double -0.000000e+00, double 5.000000e-01)
  ret void
}

; CHECK-LABEL: define void @literal_negzero_f64(
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[NF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double -0.000000e+00)
; CHECK-NEXT:  call void @cqrt_ry_f64(i32 %[[NF]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_f64(i32 %[[NF]], double -5.000000e-01)
; CHECK-NEXT:  ret void

define void @literal_zero_i32() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  ret void
}

; CHECK-LABEL: define void @literal_zero_i32(
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[ZI:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[ZI]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[ZI]], double -5.000000e-01)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[ZI]])
; CHECK-NEXT:  ret void

define void @literal_poszero_f64() {
entry:
  %q = call double @cq_theta_f64(double 0.000000e+00, double 5.000000e-01)
  ret void
}

; CHECK-LABEL: define void @literal_poszero_f64(
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[PF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT:  call void @cqrt_ry_f64(i32 %[[PF]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_f64(i32 %[[PF]], double -5.000000e-01)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[PF]])
; CHECK-NEXT:  ret void

define void @mixed_qq(i32 %seed) {
entry:
  %a = call i32 @cq_theta_si32(i32 %seed, double 2.500000e-01)
  %b = call i32 @cq_theta_si32(i32 0, double 3.500000e-01)
  %p = mul i32 %a, %b
  ret void
}

; CHECK-LABEL: define void @mixed_qq(
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[MA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %seed)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[MA]], double 2.500000e-01)
; CHECK-NEXT:  %[[MB:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[MB]], double 3.500000e-01)
; CHECK-NEXT:  %[[MP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %[[MA]], i32 %[[MB]])
; CHECK-NEXT:  call void @cq_template_mul_i32_unc(i32 %[[MP]], i32 %[[MA]], i32 %[[MB]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[MP]])
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[MB]], double -3.500000e-01)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[MB]])
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[MA]], double -2.500000e-01)
; CHECK-NEXT:  ret void

; The module frees exactly the four rails proven |0⟩ — the two zero-literal
; roots, the zero-seeded Q+Q parent and the template rail.
; CNT-COUNT-4: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
