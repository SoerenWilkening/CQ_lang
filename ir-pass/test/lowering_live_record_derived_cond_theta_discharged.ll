; lowering_live_record_derived_cond_theta_discharged.ll — ACCEPT (M-B Increment
; 5b, bd test_C_libtooling-6uqc). bd 6uqc's P4, and the DELIBERATE
; RE-DISPOSITION of the fixture that used to pin its decline.
;
;     a = cq_theta(a, 0.5);
;     int f = sqrt(a + 3.0) <= 5.0;
;     m = cq_measure(f);
;     a = cq_theta(a, 0.5);            <-- the chained, in-place Ry
;     cq_measure(a);
;
; WHAT THIS FILE USED TO BE, and why the change is a fix rather than a
; relaxation. As `lowering_reject_live_record_derived_cond_theta.ll` it asserted
; the M-A guard's loud "cq rotation lowering: non-diagonal gate over a live
; derived record". That decline was CORRECT for the compiler that emitted it: the
; four condition-provenance rails (`sitofp`/`fadd`/`sqrt`/`fcmp`) were minted,
; never uncomputed and never freed, so at the second `cqrt_ry` the wire carried
; four dead basis records of itself and the gate was physically dephased. The
; guard was the only thing standing between that program and a verify-clean
; silent miscompile (at the increment before M-A it ACCEPTED, `opt` rc=0).
;
; WHAT CHANGED IS THE PHYSICS, NOT THE PREDICATE. Increment 5's interior
; partition now discharges all four rails — LIFO `_unc` + `cqrt_free` — BEFORE the
; chained Ry, so nothing is standing at the gate. The M-A guard then exempts each
; of them on clause 2 (`isDischargeOf` matches the out-first `_unc` and the
; `cqrt_free`, and `provablyBefore(discharge, T)` holds) and on clause 4 for the
; measured `zext` copy. NOT ONE CLAUSE OF THE GUARD WAS TOUCHED. That division of
; labour is the design: M-B moves the rails, M-A re-reads the settled module.
;
; THE 5b HALF OF CLAUSE (d) IS WHAT MAKES IT LAND HERE. The chained `cq_theta` is
; an in-place `cqrt_ry` on the BORROWED source wire `%h` — a mutation of a
; borrowed parent, which Increment 5a refused outright (it could only prove
; mutations that ran BEFORE the interval). 5b adds the RIGHT disjunct,
; `provablyBefore(At, M)`: the Ry runs only after the discharge point, so every
; `_unc` reads the PRE-Ry basis, which is the basis its forward gate read. Note
; what this does NOT do — it never schedules a discharge after a non-diagonal
; wire gate, which owner ruling 2026-08-27 forbids outright; it proves the gate is
; after the discharge. The shape where the Ry sits strictly INSIDE the interval
; satisfies neither disjunct and still leaks
; (lowering_uncompute_interior_leak_parent_ry_between.ll).
;
; DECLINE TWINS THAT REMAIN, so the guard's derived-condition coverage is not
; emptied by this re-disposition:
;   * lowering_uncompute_interior_leak_parent_ry_between.ll — a chained Ry inside
;     the discharge interval. No anchor can move a discharge past a non-diagonal
;     write on the wire it reads, so this one is permanent.
;   * lowering_uncompute_interior_leak_region_wire_measured.ll — the same shape
;     with a COLLAPSE instead of a rotation, in a region program.
;   * lowering_uncompute_interior_leak_select_cond_chain.ll — a 4.4 select's
;     condition chain: its strip is not one an emitter recorded, so it leaks.
;   (The REGION spelling of THIS file, once
;   control_swap_reject_post_region_theta_derived_cond.ll, is no longer among
;   them: M-B Increment 6 gave its chain an anchor after the recorded flag strip
;   and it is now control_swap_accept_post_region_theta_derived_cond.ll.)
;   * lowering_reject_live_record_two_hop.ll and its three siblings keep the
;     guard's walk mechanisms pinned on records M-B cannot reach.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @llvm.sqrt.f64(double)

define i32 @slice(i32 %u0) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
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

; CHECK-LABEL: define i32 @slice(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[C:.*]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %[[H]])
; CHECK-NEXT: %[[A:.*]] = call i32 @cq_template_fadd_f64_hl(i32 %[[C]], double 3.000000e+00)
; CHECK-NEXT: %[[S:.*]] = call i32 @cq_template_sqrt_f64(i32 %[[A]])
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_fcmp_ole_f64_hl(i32 %[[S]], double 5.000000e+00)
; CHECK-NEXT: %[[Z:.*]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[F]])
; the whole LIFO reversal, and every line of it BEFORE the chained Ry:
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

; The BORROWED source wire is still never adjointed and never freed.
; CHECK-NOT: cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NOT: call void @cqrt_free(i32 %[[H]])

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
