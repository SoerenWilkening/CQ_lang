; lowering_reject_volatile_scalar_deadstore_nonvolatile.ll — DECLINE PIN (bd k710):
; the dead-store stage requires at least one VOLATILE access, and this fixture is
; the gate that keeps it from widening into a general dead-store eliminator.
;
; Identical to lowering_volatile_scalar_deadstore.ll in every respect EXCEPT that
; the store is PLAIN. A plain store-only alloca is ordinary dead code that `clang
; -O1` already removed before the pass ever sees it, so a shape reaching us here
; is off-idiom by construction — claiming it would mean CQ silently performs
; classical DSE that the frontend declined to, on a shape nobody characterised.
; Over-declining is safe; the store rides the existing loud escape decline.
;
; DISCRIMINATION: this fixture is meaningful only because its ACCEPT twin exists
; and passes. The pair differs by the single token `volatile`, so the `SawVolatile`
; gate is the ONLY thing separating them — delete that gate and this fixture goes
; green while its twin stays green, which is exactly the mutation the pairing is
; here to catch (bd predmux-decline-fixture-discrimination).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

define float @probe(float %u0, float %u1) {
entry:
  %u = alloca float, align 4
  %q = call float @cq_theta_f32(float %u0, double 5.000000e-01)
  %p = call float @cq_theta_f32(float %u1, double 5.000000e-01)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %u)
  %uu = fmul float %p, %p
  store float %uu, ptr %u, align 4                 ; PLAIN — not volatile
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %u)
  %m = call float @cq_measure_f32(float %q)
  ret float %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
