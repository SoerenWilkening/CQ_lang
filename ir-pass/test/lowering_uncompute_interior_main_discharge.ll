; lowering_uncompute_interior_main_discharge.ll — ACCEPT (M-B Increment 5, bd
; test_C_libtooling-4p7j Rule-13 round, finding F4f). THE INTERIOR PARTITION DOES
; NOT SKIP `main`, and this is the pin for that decision (owner question 1,
; answered by the Rule-13 reviewer: keep discharging in `main`).
;
; bd 6uqc's P4, written inside `main` instead of a called slice:
;     int a = 1; cq_theta(&a, 0.5);
;     int f = sqrt(a + 3.0) <= 5.0;   int m = cq_measure(f);
;     cq_theta(&a, 0.5);           return m + cq_measure(a);
;
; WHY `FreePoint`'S `main` SKIP DOES NOT APPLY HERE, stated as the difference it
; is: that skip is about RECLAMATION — process exit releases every register, so a
; dead terminal in `main` need not be freed. M-B is not about reclamation. It is
; about DISENTANGLING a record before a later non-diagonal gate, and the physics
; does not care which function the gate is in. Skipping `main` would leave every
; `main`-resident P4/Grover program declined at the M-A guard (which does not
; skip `main` either), for no benefit.
;
; MEASURED BOTH WAYS: this module DECLINES at c36934a ("cq rotation lowering:
; non-diagonal gate over a live derived record" — the four derived rails are
; still standing when the chained `cq_theta` fires) and LOWERS here, with the
; whole reversal placed before that `cqrt_ry`. The M-A guard is byte-identical;
; M-B moved the physics and the guard only re-read it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEH < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @llvm.sqrt.f64(double)

define i32 @main() {
entry:
  %q    = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %cast = sitofp i32 %q to double
  %add  = fadd double %cast, 3.000000e+00
  %rt   = call double @llvm.sqrt.f64(double %add)
  %cmp  = fcmp ole double %rt, 5.000000e+00
  %f    = zext i1 %cmp to i32
  %m    = call i32 @cq_measure_si32(i32 %f)
  %q2   = call i32 @cq_theta_si32(i32 %q, double 5.000000e-01)  ; chained, in-place Ry
  %m2   = call i32 @cq_measure_si32(i32 %q2)
  %r    = add nsw i32 %m2, %m
  ret i32 %r
}

; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %[[H]])
; CHECK-NEXT: %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f64_hl(i32 %[[C]], double 3.000000e+00)
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sqrt_f64(i32 %[[A]])
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ole_f64_hl(i32 %[[S]], double 5.000000e+00)
; CHECK-NEXT: %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[F]])
; the whole LIFO reversal, every line of it BEFORE the chained Ry:
; CHECK-NEXT: call void @cq_template_fcmp_ole_f64_hl_unc(i32 %[[F]], i32 %[[S]], double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_sqrt_f64_unc(i32 %[[S]], i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[S]])
; CHECK-NEXT: call void @cq_template_fadd_f64_hl_unc(i32 %[[A]], i32 %[[C]], double 3.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[C]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Z]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; The BORROWED source wire is never adjointed and never freed — `main` changes
; nothing about that (one anchor, one prefix ⇒ window anchor -> EOF; bd memory
; [filecheck-check-not-window-trap]):
; NOFREEH:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; NOFREEH-NOT: call void @cqrt_ry_i32(i32 %[[H2]], double -5.000000e-01)
; NOFREEH-NOT: call void @cqrt_free(i32 %[[H2]])

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
