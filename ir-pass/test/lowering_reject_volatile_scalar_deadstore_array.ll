; lowering_reject_volatile_scalar_deadstore_array.ll — DECLINE PIN (bd k710): the
; `isArrayAllocation()` clause, ISOLATED.
;
; `alloca float, i32 4` allocates FOUR floats but its allocated TYPE is a plain
; `float`, so the int/fp type clause passes; the store is direct at the base
; pointer, exact-type, volatile, with no loads and no other user, so the user scan
; passes too. Every gate except `isArrayAllocation()` is satisfied — which is the
; point. Erasing this would drop three slots the scan never looked at.
;
; *** THIS FIXTURE WAS REWRITTEN BECAUSE ITS FIRST DRAFT PINNED NOTHING. *** The
; draft used `alloca [4 x float]` written through a gep, and the ARM-KILL caught
; it: removing the scalar/array gate left the fixture RED anyway, because the gep
; already forfeits at the user scan. It tested defence-in-depth and reported it as
; a gate test. A fixture that survives the removal of the arm it is named after is
; not a decline pin (bd predmux-decline-fixture-discrimination). The vector sibling
; `..._vector.ll` isolates the other clause of the same gate.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)

define float @probe(float %u0, float %u1) {
entry:
  %u = alloca float, i32 4, align 16               ; ARRAY ALLOCATION, scalar type
  %q = call float @cq_theta_f32(float %u0, double 5.000000e-01)
  %p = call float @cq_theta_f32(float %u1, double 5.000000e-01)
  %uu = fmul float %p, %p
  store volatile float %uu, ptr %u, align 4        ; direct, exact-type, no gep
  %m = call float @cq_measure_f32(float %q)
  ret float %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
