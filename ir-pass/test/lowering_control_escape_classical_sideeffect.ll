; lowering_control_escape_classical_sideeffect.ll — Phase 4.x (test_C_libtooling-
; npu.3), NEGATIVE. A reconverging quantum-controlled arm that holds a `cq_phi`
; gate body ALONGSIDE a CLASSICAL side effect (the `sink(42)` call — an
; untainted-operand call, not a gate / terminator / measure) is rejected
; PERMANENTLY. `armEscapesOrCollect` used to COLLECT the `cq_phi` into the shadow
; and silently SKIP every other instruction, so `CFGLinearization` spliced the
; whole arm body — including `sink()` — UNCONDITIONALLY into the predecessor: the
; effect the source guarded on `p > 0` then fired on EVERY path (verify-clean,
; exit 0, ZERO diagnostic — a silent miscompile). A classical effect conditioned
; on a quantum predicate is non-physical (you cannot run a classical side effect
; "in superposition"); it joins the measure/return/break/goto escape family, so
; the verdict is a LOUD DECLINE, the terminal state — no correct lowering exists.
;
; The fix gives `armEscapesOrCollect` a gate-bodies-only guard: any in-arm
; instruction with an observable side effect (`I.mayHaveSideEffects()`) that is
; not a `cq_phi` gate / the fall-through terminator is diagnosed. Pure SSA values
; (icmp/add feeding an angle) still splice through. A TAINTED memory op is caught
; earlier by `diagnoseTaintedMemoryEscape`; this closes the classical-operand
; sibling. See [[angle-reducer-single-block-invariant]] / the npu epic.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}classical side effect under quantum control
; The gate must NOT have been lowered to a controlled rotation (region declined)…
; CHECK-NOT: cqrt_rz_i32_controlled
; …and the classical effect must NOT have been hoisted to run unconditionally.
; CHECK-NOT: call void @sink
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @sink(i32)

; int r = q; if (p > 0) { r = cq_phi(q, 0.1); sink(42); } return cq_measure(r);
define i32 @example(i32 %x, i32 %cnd) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %cnd, double 3.000000e-01)
  %c = icmp sgt i32 %p, 0
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @cq_phi_si32(i32 %q, double 1.000000e-01)   ; gate body (would lower)
  call void @sink(i32 42)                                   ; classical side effect
  br label %merge
merge:
  %res = phi i32 [ %r, %arm ], [ %q, %entry ]               ; tainted-handle merge φ
  %m = call i32 @cq_measure_si32(i32 %res)
  ret i32 %m
}
