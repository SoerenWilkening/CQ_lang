; lowering_uncompute_interior_region_partial.ll — ACCEPT + THE INCREMENT-6 SEAM
; (M-B Increment 5b, bd test_C_libtooling-6uqc). bd 6uqc's P0, and exactly how far
; Increment 5 gets on it.
;
;     a = cq_theta(a, 0.5);
;     if (sqrt(a + 3.0) <= 5.0) { a = cq_phi(a, 3.0); }
;     return cq_measure(a);
;
; AT HEAD (c36934a) the region stripped only the FLAG: `fcmp_ugt_f64_hl_unc` +
; `cqrt_free` on the compare rail, while `sitofp`, `fadd` and `sqrt` stayed
; allocated and entangled with the wire forever. Three leaked basis records,
; verify-clean, stage-2b silent.
;
; INCREMENT 5 DISCHARGES TWO OF THE THREE, and the placement is the interesting
; part. The interior partition's anchor is the point after the LAST consumer of
; each owned rail: the `sitofp` rail is consumed by the `fadd`, the `fadd` rail by
; the `sqrt`, so `At` lands right after the `sqrt` — i.e. BEFORE the compare and
; before the whole swap-route region. Both are uncomputed and freed there, LIFO,
; reading a source wire that the region's `cqrt_cswap` routing has not touched
; yet. (That routing IS a mutation of the borrowed parent; it is admitted by the
; 5b RIGHT disjunct, `provablyBefore(At, M)` — the cswaps run only after the
; discharge — which is the same clause that makes P4 lower.)
;
; THE THIRD RAIL — the `sqrt` result — STAYS, and this is the seam Increment 6
; has to work on rather than a gap to paper over. Its users are the compare AND
; the compare's own `_unc`, the region's flag strip. An `_unc` is not an interior
; consumer (`isTemplateProducer` excludes every adjoint twin), so the rail is
; refused, and refusing it is CORRECT: discharging it at the anchor its forward
; consumers imply would put its `_unc` and `cqrt_free` BEFORE the strip that
; recomputes the flag from it — a use-after-free. The fix is clause (d2): the
; emitter records the point right after its strip-and-free as a DISCHARGE ANCHOR,
; and the interior partition places the condition chain's reversal there.
;
; So this fixture is the before-picture for Increment 6 and the after-picture for
; Increment 5, in one file. When Inc 6 lands, the two remaining CHECK-NOTs at the
; bottom become CHECKs.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @llvm.sqrt.f64(double)

define i32 @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c  = sitofp i32 %q to double
  %a  = fadd double %c, 3.000000e+00
  %s  = call double @llvm.sqrt.f64(double %a)
  %gt = fcmp ugt double %s, 5.000000e+00
  br i1 %gt, label %merge, label %arm

arm:
  %qz = call i32 @cq_phi_si32(i32 %q, double 3.000000e+00)
  br label %merge

merge:
  %p = phi i32 [ %qz, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; CHECK-LABEL: define i32 @slice(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[C:.*]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %[[H]])
; CHECK-NEXT: %[[A:.*]] = call i32 @cq_template_fadd_f64_hl(i32 %[[C]], double 3.000000e+00)
; CHECK-NEXT: %[[S:.*]] = call i32 @cq_template_sqrt_f64(i32 %[[A]])
; the two ownable rails are discharged HERE, before the compare and the region:
; CHECK-NEXT: call void @cq_template_fadd_f64_hl_unc(i32 %[[A]], i32 %[[C]], double 3.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[C]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_fcmp_ugt_f64_hl(i32 %[[S]], double 5.000000e+00)
; the region: work rail, X-bracketed cswap route, arm Rz, route back, free, strip
; CHECK:      call void @cqrt_cswap(i32 %[[F]], i32 %[[H]]
; CHECK:      call void @cq_template_fcmp_ugt_f64_hl_unc(i32 %[[F]], i32 %[[S]], double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; INCREMENT 6's customer: the `sqrt` rail is still standing, and so is the source
; wire (which is a BORROWED parent and correctly stays).
; CHECK-NOT: cq_template_sqrt_f64_unc
; CHECK-NOT: call void @cqrt_free(i32 %[[S]])
