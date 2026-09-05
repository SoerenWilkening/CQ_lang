; control_inplace_rz_ifelse.ll — the §6a Rz peephole on a TWO-ARM if/else
; (bd test_C_libtooling-drbq Inc 2a).
;
; Both arms rotate the SAME register; the true arm fires on the flag and the else
; arm on ¬flag via the `cqrt_x` bracket. Under the swap route this shape cost TWO
; work rails, FOUR `cqrt_cswap`s, FOUR `cqrt_x` and THREE frees; it now costs two
; controlled gates, two `cqrt_x` and ONE free (the flag).
;
; ARM ORDER IS THE CONTRACT and is why this fixture is not redundant with the
; diamond: the emitter walks `Arms` in SUCCESSOR order (R.Arm then R.ArmFalse),
; so the true arm's gate must precede the bracketed else arm's — the same order
; the route emitted its two bodies in. A swap here would apply the two phases
; under the wrong branch of the flag.
;
; Hand-constructed IR: `clang -O1` merges a symmetric two-gate if/else into ONE
; call with a `select` on the ANGLE (which declines today and is Inc 2b's shape),
; so the two-block form has to be written directly.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; The ROUTE'S ABSENCE, on its own prefix anchored at the function header. A
; trailing CHECK-NOT scans only past the LAST positive of its own prefix, and every
; route line lands BEFORE that, so it could never fire (bd memory
; filecheck-check-not-window-trap). The window reaches the declares too, hence the
; `call void @` anchors.
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; Exact free count: ONE (the flag) — two work rails and their frees are gone.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %armt, label %armf
armt:
  call void @cq_phi(double %a)
  br label %merge
armf:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %m1 = call i32 @cq_measure_si32(i32 %r)
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %o = add i32 %m1, %m2
  ret i32 %o
}

; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; TRUE arm first, unbracketed
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[R:[a-zA-Z0-9_.]+]], double %a)
; ELSE arm second, on the SAME register, bracketed on ¬flag
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[R]], double %b)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NOT:  call void @cqrt_free

; NOROUTE: define i32 @example
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: call void @cqrt_copy
; NOROUTE-NOT: phi i32

; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
