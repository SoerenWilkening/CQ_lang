; control_swap_accept_post_region_theta_shared_rail.ll — ACCEPT (bd
; test_C_libtooling-lom0 Increment 4, precondition (c) of the Rule-13 round):
; the ROUTED BASE and the POST-REGION theta are the SAME PHYSICAL RAIL.
;
; WHY THIS FIXTURE EXISTS SEPARATELY. The Inc-4 accept is proven over IR
; POSITIONS — `provablyBefore(R.Pred->getTerminator(), T, DT)`. It is very
; tempting to reach instead for the easier-sounding argument "the theta sits on
; a different SSA value than the routed base, so it is a different rail". THAT
; ARGUMENT IS FALSE HERE, and has been since M-C (bd test_C_libtooling-6uqc
; Inc 2a/2b): a tainted `add` with one classical operand lowers IN PLACE to
; `cqrt_addc_i32`, minting NO new rail, so `%d` and `%q` are one register. The
; source below is exactly that shape — the routed base `%d` is the addc result,
; and the post-region `cq_theta` lands on the identical handle.
;
; SOURCE:
;     volatile int off = 3;
;     int q = cq_theta(u0, 0.5);
;     q += off;                              /* IN PLACE — no new rail */
;     if (q == 5) { q = cq_phi(q, PI); }     /* phase arm over that rail */
;     q = cq_theta(q, 0.25);                 /* the post-region Ry */
;     return cq_measure(q);
;
; THE CHECKS BIND ONE CAPTURE `%[[H]]` ACROSS ALL THREE ROLES — the `cqrt_addc`
; destination, the `cqrt_cswap` routed operand, and the post-strip `cqrt_ry`
; target. If the routed base and the re-prep Ry ever stopped being the same
; rail, FileCheck's capture would not match twice and this fixture goes red;
; that is the point of writing it with captures rather than literal names.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
@off = global i32 3, align 4

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %o = load volatile i32, ptr @off, align 4
  %d = add nsw i32 %q, %o                       ; the ROUTED BASE — in-place addc
  %c = icmp eq i32 %d, 5
  br i1 %c, label %arm, label %merge

arm:
  %g = call i32 @cq_phi_si32(i32 %d, double 0x400921FB54442D18)
  br label %merge

merge:
  %p = phi i32 [ %g, %arm ], [ %d, %entry ]
  %w = call i32 @cq_theta_si32(i32 %p, double 2.500000e-01)   ; POST-REGION Ry
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}

; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; The reassignment is IN PLACE: same handle in, no new handle out.
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; The routed operand IS %[[H]] — the same rail the addc wrote.
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[R]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R]], double 0x400921FB54442D18)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[R]])
; CHECK:     call void @cqrt_free(i32 %[[R]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; ...and the post-region Ry lands on that SAME rail, after the strip and free.
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT: phi
; CHECK-NOT: br i1
;
; Two allocations only: the wire and the one work rail. No ancestor rail is
; minted for the `+= off`, which is exactly why the wire and the Ry target
; coincide.
; CNT-COUNT-2: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
