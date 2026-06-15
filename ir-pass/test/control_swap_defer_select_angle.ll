; control_swap_defer_select_angle.ll — tainted ANGLE select declines `rotation
; angle` (4.4 WI-1 §3.2 detector; RE-PINNED from the old `select` string).
;
; The exact shape clang -O1 SimplifyCFG produces from a SYMMETRIC one-gate-per-arm
; phase if/else over a derived base:
;     q = rz(q, 0.9); if (q > 5) { rz(q, a); } else { rz(q, b); }
; folds to ONE hoisted cq_phi whose ANGLE is a tainted-condition select
; (`select i1 c, double a, double b`) — the branch CFG is gone before the pass
; runs (Rule 9). This is a rotation angle under quantum control (Family B2 /
; AngleSelectRegion vocabulary), NOT a data mux: it must keep DECLINING loudly,
; never lower the select, never let the angle-position taint leak into a handle
; (the f64/angle miscompile family). 4.4 catches it at DETECTION via the new
; transitive arg-1 walk `selReachesRotationArg1` (gate 3, the BLOCKER): `%ang`
; feeds `cq_phi(%qd, %ang)` at arg-1 → `rotation angle`. There is NO downstream
; backstop — `declineTaintedAngle` runs after an accepted select's product is
; RAUW'd to an untainted handle, so the angle MUST be caught pre-mutation.
;
; control_swap_defer_select.ll pins the select-over-HANDLE variant (which ACCEPTS,
; transitional `control flow`); this pins the select-over-ANGLE variant (double
; operands feeding a cq_phi arg-1, which DECLINES). The e2e
; slice_control_phase_ifelse_derived.c documents the same trap from the C side
; (its arms are asymmetric precisely to dodge this fold). (Rule 12 deliberate
; baseline: the old "select" CHECK is replaced, not retained.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; The §3.2 detector must lower NOTHING for an angle select (no merge stream).
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cqrt_alloc
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd  = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)
  %c   = icmp sgt i32 %qd, 5
  %ang = select i1 %c, double 2.500000e-01, double 7.500000e-01
  %q2  = call i32 @cq_phi_si32(i32 %qd, double %ang)
  %m   = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}
