; lowering_reject_volatile_scalar_deadstore_measured.ll — DECLINE PIN (bd k710):
; the stage FIRES here and the module still declines, downstream, for a reason
; that is not the stage's to overrule. Pinning that is the point.
;
; Same idiom as the accept twin, except the dead product is rooted at the rail the
; program MEASURES (`%q * %q`, and `%q` is measured) rather than at a rail of its
; own. Erasing the store leaves a dead chain whose uncompute would have to run the
; adjoint back through a measured register — and the whole-DAG spine refuses:
; `cq uncompute: dead chain would free a measured register`. That is a pre-existing
; Rule-6 guard (the measurement owns its rail; freeing it is a second, hidden
; measurement) and it is exactly right.
;
; WHY THIS FIXTURE EXISTS RATHER THAN A CODE CHANGE: it is tempting to read the
; decline as "the k710 stage broke something" and add a gate refusing to erase a
; store whose value derives from a measured rail. That would be wrong twice over —
; it would duplicate a check the spine already performs correctly (Rule 14), and it
; would move a Rule-6 decision out of the one place that owns it. The stage's job
; ends at the store; whether the exposed dead chain is recoverable is the spine's
; call, and here the answer is a loud no.
;
; This shape was found by writing the accept fixture, not by review — the first
; draft of the twin used one theta for both roles and hit this. Recorded so the
; next person does not re-discover it as a regression.
;
; ⚠⚠ bd vsfp ROUND 2 (bd test_C_libtooling-qjoc; bd vsfp Rule-13 r1B) — THIS FILE IS
; NOW AN ACCEPT, AND THAT IS A FIX, NOT A LOST FENCE. Its name is kept deliberately
; (bd gahu / CLAUDE.md L8: a `git mv` can be resurrected by a merge). The decline
; above was the spine refusing to uncompute a dead chain through a measured
; register — correct, but the chain only existed because the fenv stage erased the
; STORE and left the dead `fmul` behind. The stage now deletes the stored value's
; DEAD cone with the pass's ONE liveness predicate (`DeadValueLiveness.h`), so there
; is no chain: the module is exactly the fenv-intended program without the volatile
; line — `alloc; Ry; measure` — which is what its hand-inlined twin compiles to.
; The Rule-6 guard the old pin exercised is unchanged and is still reached by any
; LIVE chain through a measured register; this module simply has none now. What the
; paragraph above calls "the stage's job ends at the store" is RETIRED by the same
; change (L7, corrected in QramLowering.h).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

define float @probe(float %u0) {
entry:
  %u = alloca float, align 4
  %q = call float @cq_theta_f32(float %u0, double 5.000000e-01)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %u)
  %uu = fmul float %q, %q                          ; rooted at the MEASURED rail
  store volatile float %uu, ptr %u, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %u)
  %m = call float @cq_measure_f32(float %q)
  ret float %m
}

; CHECK-LABEL: define float @probe(float %u0)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f32(float %u0)
; CHECK-NEXT:  call void @cqrt_ry_f32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT:  %{{[a-zA-Z0-9_.]+}} = call float @cqrt_measure_f32(i32 %[[H]])
; CHECK-NEXT:  ret float
