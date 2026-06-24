; lowering_reject_intrinsic_fma_vector.ll — DECLINE: a VECTOR ternary fma
; (`@llvm.fma.v2f64`) over a tainted operand (PRD-iw81.4 §6 decline-matrix D8 /
; §7 hazard 1). wd2p admits fma ONLY at the SCALAR widths {f16,f32,f64} — a vector
; width is categorically out (the per-ID fp admit is NOT a blanket fp open). Two
; defenses prove it stays declined:
;   (1) `abiWidthFromType(<2 x double>)` is empty (it recognizes only scalar iN /
;       half/float/double), so `widthInTableSet(fma, "")` is false and
;       `isCuratedReversibleIntrinsic` returns false.
;   (2) Independently, a tainted scalar can only be assembled into a vector via an
;       `insertelement`, itself a tainted-value escape into an unsupported
;       instruction — the decline fires there FIRST.
; Either way: loud decline, zero templates. NEVER a `cq_template_fma_v2f64` mint.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare <2 x double> @llvm.fma.v2f64(<2 x double>, <2 x double>, <2 x double>)

define <2 x double> @example(double %u) {
entry:
  %q  = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %v0 = insertelement <2 x double> undef, double %q, i32 0
  %v1 = insertelement <2 x double> %v0, double %q, i32 1
  %r  = call <2 x double> @llvm.fma.v2f64(<2 x double> %v1, <2 x double> %v1, <2 x double> %v1)
  ret <2 x double> %r
}

; CHECK: error{{.*}}cq taint escape: tainted value reaches an unsupported instruction
; CHECK-NOT: cq_template_fma
