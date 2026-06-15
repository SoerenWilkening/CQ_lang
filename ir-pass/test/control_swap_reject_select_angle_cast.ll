; control_swap_reject_select_angle_cast.ll — DECLINE: a TRANSITIVE-cast angle
; select (4.4 WI-1 §3.2 gate 3, the BLOCKER). Proves the forward walk follows
; value-preserving carriers, not just direct users.
;
; `%sel` is a float-operand select whose result is `fpext`'d to double and fed to
; a `cq_phi` arg-1 (the angle slot): `%w = fpext %sel; cq_phi(%qd, %w)`. The
; angle never appears as a DIRECT user of the select — it sits one `fpext` hop
; behind it. `selReachesRotationArg1` crosses the fpext carrier
; (`WireWalk.cpp:105-113` pattern) and lands on the arg-1 reach
; (`TaintPropagation.cpp:300-303` predicate), declining `rotation angle`. Lowering
; this as a data merge would route quantum-derived data into a rotation angle
; (the f64/angle miscompile family); the only sound disposition is a loud decline
; (Rule 3). There is NO downstream backstop — the angle MUST be caught here,
; pre-mutation (an accepted select's product is RAUW'd to an untainted handle
; before `declineTaintedAngle` ever runs).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
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
  %sel = select i1 %c, float 2.500000e-01, float 7.500000e-01   ; float-operand select
  %w   = fpext float %sel to double                              ; value-preserving carrier
  %q2  = call i32 @cq_phi_si32(i32 %qd, double %w)               ; %w lands in arg-1 (angle)
  %m   = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}
