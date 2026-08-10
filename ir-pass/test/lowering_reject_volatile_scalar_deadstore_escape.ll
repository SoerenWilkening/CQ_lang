; lowering_reject_volatile_scalar_deadstore_escape.ll — DECLINE PIN (bd k710): the
; whole-alloca user scan IS the escape proof, and this is what it buys.
;
; The fenv ruling (owner 2026-08-10) is scoped to a NON-ESCAPING function-local.
; Here the alloca's address is handed to an opaque callee, so the object may be
; read by anyone — the store is observable and the ruling does not reach it. The
; user scan forfeits on the call (not a store-with-A-as-pointer, not a lifetime
; marker), the volatile store survives, and the tainted value dies on the existing
; escape decline.
;
; This is the gate that keeps the stage honest about WHY it is allowed to delete a
; volatile write at all. Without it, "fenv is out of scope" would be doing work it
; was never granted: fenv being unmodelled says nothing about whether some OTHER
; observer can read the slot.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)
declare void @sink(ptr)

define float @probe(float %u0, float %u1) {
entry:
  %u = alloca float, align 4
  %q = call float @cq_theta_f32(float %u0, double 5.000000e-01)
  %p = call float @cq_theta_f32(float %u1, double 5.000000e-01)
  %uu = fmul float %p, %p
  store volatile float %uu, ptr %u, align 4
  call void @sink(ptr nonnull %u)                  ; the address ESCAPES
  %m = call float @cq_measure_f32(float %q)
  ret float %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
