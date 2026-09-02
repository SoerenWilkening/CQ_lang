; control_inplace_ry_dead_base_late_use_frozen.ll — ACCEPT + FREEZE, and THE
; REGRESSION PIN for a defect this increment MEASURED and fixed (bd
; test_C_libtooling-drbq Inc 1).
;
;     int q=cq_theta(0,.5); int r=cq_theta(0,.3);
;     if (q > 5) r = cq_theta(r, .9);
;     int s = r + 1;                     // reads the MERGE (post-region) name
;     return cq_measure(q);              // r and s dead
;
; THE DEFECT, as emitted before the freeze (verbatim, `opt` exit 0, `opt -verify`
; clean):
;
;     cq_template_icmp_sgt_i32_hl_unc(%f, %h, 5)
;     cqrt_free(%f)                      <-- the flag is reclaimed here
;     cqrt_addc_i32(%h1, 1)
;     cqrt_addc_i32(%h1, -1)
;     cqrt_ry_i32_controlled(%f, %h1, -0.9)   <-- USE AFTER FREE
;     cqrt_ry_i32(%h1, -0.3)
;     cqrt_free(%h1)                     <-- and then a DIRTY free
;
; The spine reverses after a rail's LAST USER, and the M-C in-place `addc` for
; `s = r + 1` is a post-region user, so the reversal landed past the flag free.
; A `cqrt_free` is a hardware reset, so the adjoint's control is |0> and the
; adjoint never fires: `%h1` is still carrying `Ry(.9)` entangled with `q` when
; the spine frees it — a hidden measurement that collapses `q` (Rules 6/8).
;
; Stage 2b DOES see it (`VIOLATION F2-use-after-free`, then `A-not-reducible`),
; which is how it was found — but a second gate catching the pass's mistake is
; not the pass being right. The register is FROZEN at BOTH spine sites; this
; module goes through the DagTraversal CLOSURE site (the register is reached as a
; DAG ancestor via its in-place `addc`), which is why subtracting only at terminal
; selection would not have been enough.
;
; ⚠ THE FREEZE IS ASKED STRUCTURALLY OF THE EMITTED GATE
; (`ChainWalk::railCarriesControlledRotation`), not from a recorded `Value *`.
; Inc 1 shipped a `TaintSet::ControlledRotationRails` keyed on the theta's arg-0
; at `lowerRotations` time; for a DERIVED base that is an instruction `lowerOps`
; erases one stage later, so the set dangled and the defect above returned
; verbatim. This fixture uses a SOURCE base and therefore never saw it — see
; `control_inplace_ry_derived_base_{mul,add,f64}_late_use_frozen.ll`, the
; round-1 Rule-13 review's pins for that half.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Independent scan: the ONLY cqrt_free in the module is the flag's.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %s  = add i32 %rm, 1
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl
; CHECK:     call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]],
; CHECK:     call void @cqrt_free(i32 %[[F]])
; the post-region `r + 1` still lowers (in place, M-C) — the freeze is about the
; REVERSAL, not about the forward program
; CHECK:     call void @cqrt_addc_i32(i32 %[[R]], i32 1)
; and NOTHING reverses it: no negated `addc`, no controlled-Ry adjoint, no free
; CHECK-NOT: @cqrt_addc_i32(i32 %[[R]], i32 -1)
; CHECK-NOT: double -9.000000e-01
; CHECK-NOT: call void @cqrt_free(i32 %[[R]])

; EXACTLY one free in the whole module: the flag's.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
