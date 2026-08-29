; control_swap_accept_post_region_theta_derived_cond.ll — ACCEPT, and the
; INTERLOCK bd test_C_libtooling-6uqc opened is now CLOSED from the other side
; (M-B Increment 6, clause (d2); renamed from
; control_swap_reject_post_region_theta_derived_cond.ll, which pinned the
; decline).
;
;     a = cq_theta(a, 0.5);
;     if (sqrt(a + 3.0) <= 5.0) { a = cq_phi(a, PI); }
;     a = cq_theta(a, 0.25);            /* <-- the post-region Ry */
;     return cq_measure(a);
;
; WHAT THIS FILE HAS ALWAYS BEEN ABOUT. bd lom0's Increment-4 accept claim is
; "once the strip has run, the region holds no live record of the wire". That is
; TRUE for a DIRECT condition — the flag is the sole record and the `_unc` strip
; discharges it — and it was FALSE here, because `cq_template_sitofp_i32_to_f64`,
; `cq_template_fadd_f64_hl` and `cq_template_sqrt_f64` mint rails the flag strip
; never touches. Accepting the program then would have been a verify-clean
; dephasing miscompile, so Increment 4 deliberately did NOT re-prove the point
; inside `ArmClassify` and let the LATE M-A record guard own the decline:
;     HEAD b4e329b  cq controlled lowering: condition predates a non-diagonal gate
;     Inc 3/4       cq rotation lowering: non-diagonal gate over a live derived record
;
; WHAT CHANGED IS THE PHYSICS, NOT THE GUARD. Increment 6 does not relax one
; clause of `warnLiveRecordRotations`. It makes the three chain rails
; genuinely DISCHARGED before the second `cqrt_ry` — the emitter records its flag
; strip, the interior partition anchors the chain's reversal right after it, and
; the guard's clause 2 (`isDischargeOf` + `provablyBefore`) then reads that as the
; FACT it is. The claim lom0 could not make for a derived condition is now true
; of the emitted stream.
;
; IF THIS FILE EVER DECLINES AGAIN, the M-B discharge stopped landing before the
; Ry — that is the regression to look for, not a guard change.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @llvm.sqrt.f64(double)

define i32 @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %cast = sitofp i32 %q to double
  %add = fadd double %cast, 3.000000e+00
  %rt = call double @llvm.sqrt.f64(double %add)
  %c = fcmp ole double %rt, 5.000000e+00
  br i1 %c, label %arm, label %merge

arm:
  %g = call i32 @cq_phi_si32(i32 %q, double 0x400921FB54442D18)
  br label %merge

merge:
  %p = phi i32 [ %g, %arm ], [ %q, %entry ]
  %w = call i32 @cq_theta_si32(i32 %p, double 2.500000e-01)
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}

; CHECK-LABEL: define i32 @slice(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[C:.*]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %[[H]])
; CHECK-NEXT: %[[A:.*]] = call i32 @cq_template_fadd_f64_hl(i32 %[[C]], double 3.000000e+00)
; CHECK-NEXT: %[[S:.*]] = call i32 @cq_template_sqrt_f64(i32 %[[A]])
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_fcmp_ole_f64_hl(i32 %[[S]], double 5.000000e+00)
; CHECK:      call void @cq_template_fcmp_ole_f64_hl_unc(i32 %[[F]], i32 %[[S]], double 5.000000e+00)
; every chain rail is uncomputed and freed HERE — before the post-region Ry:
; CHECK-NEXT: call void @cq_template_sqrt_f64_unc(i32 %[[S]], i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[S]])
; CHECK-NEXT: call void @cq_template_fadd_f64_hl_unc(i32 %[[A]], i32 %[[C]], double 3.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[C]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; …and only then does the chained theta fire, with nothing but the register live:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
