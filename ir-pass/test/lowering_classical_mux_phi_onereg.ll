; lowering_classical_mux_phi_onereg.ll — ACCEPT: the ONE-REGISTER merge phi
; (test_C_libtooling-5j5, the headline lift). The natural classical-if-around-
; a-quantum-gate program
;     if (classical_c) q = cq_phi(q, theta);  measure(q);
; (pre-3qlq register form) survived `clang -O1` as exactly this branch+phi shape
; (verified 2026-06-10 on BOTH the `if` and the ternary form), with two DISTINCT
; SSA incomings denoting the SAME register. The 3qlq migration deleted the phase
; (a global phase under a classical condition), so the arm is now EMPTY and the
; merge is `phi [q, arm], [q, entry]`: a pure SSA renaming that touches no register.
;
; THE LIFT (TaintPropagation::liftOneRegisterMergePhi): both incomings
; tainted; both resolve through the in-place cq_theta arg-0 wire to
; the ONE base %q; the gate chain lives entirely in its edge's incoming
; block; no path can fire the arm gate and then enter the merge through the
; straight edge (no back edges). The phi is RAUW'd to %q and ERASED before
; rotation lowering; the module reduces to the phi-less form the pipeline
; already accepted.
;
; Rule-13 trace clearance: the condition is CLASSICAL — each shot runs one
; path; the lift adds/moves/removes NO gate, only an SSA name disappears.
;
; DECLINE complements (Rule 12): select_onereg (speculated gate), phi_tworeg
; (distinct registers), phi_derived_add (fresh template rail),
; phi_crossblock_chain (pre-branch gate), phi_loop (back-edge staleness),
; and the pinned wi5 mixed-incoming fixtures (phi_measured et al.).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; Mint + Ry in entry:
; CHECK:      call i32 @cqrt_alloc_i32(i32 7)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 5.000000e-01)
; The arm block survives (empty since 3qlq):
; CHECK:      arm:
; The merge measures the ONE handle; the renaming phi is GONE:
; CHECK:      merge:
; CHECK-NEXT:   call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT:  phi i32
; CHECK-NOT:  cq_phi_si32
; CHECK-NOT:  cq_theta_si32
; main-resident handle: process exit reclaims registers (pinned domain) —
; no free is emitted:
; CHECK-NOT:  cqrt_free
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 7, double 5.000000e-01)
  br i1 %c, label %arm, label %merge            ; CLASSICAL condition
arm:
  br label %merge
merge:
  %p = phi i32 [ %q, %arm ], [ %q, %entry ]    ; one register, two SSA names
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}
