; lowering_reject_volatile_scalar_deadstore_typepun.ll — DECLINE PIN (bd k710): an
; OFF-TYPE store forfeits. The store's value type must equal the alloca's type.
;
; Here an `i32` bit pattern is written through a `float` slot. The slot is still
; never read, so a naive "zero loads, at least one volatile access" gate would
; happily erase it — but a type-punned view is not the one-line scalar local this
; stage characterised, and the exact-type requirement is what keeps "scalar" from
; quietly meaning "any slot somebody wrote bytes into". The narrower reading is the
; safe one and costs nothing: the idiom in the wild
; (`volatile float u = x*x;`) is always exact-type.
;
; This mirrors the exact-type/exact-address posture the etiq local fold already
; takes (`lowering_reject_volatile_local_typepun.ll`) — same family, same rule, so
; the two stages cannot drift into disagreeing about what a scalar slot is.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)

define float @probe(float %u0, float %u1) {
entry:
  %u = alloca float, align 4
  %q = call float @cq_theta_f32(float %u0, double 5.000000e-01)
  %p = call float @cq_theta_f32(float %u1, double 5.000000e-01)
  %uu = fmul float %p, %p
  %bits = bitcast float %uu to i32
  store volatile i32 %bits, ptr %u, align 4        ; i32 through a float slot
  %m = call float @cq_measure_f32(float %q)
  ret float %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
