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
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: rotation angle under quantum control
; NEW: cq controlled lowering: rotation angle under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: rotation angle under quantum control
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cqrt_alloc
; 3qlq: migrated from register cq_phi (mixed sites: see the migration report)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c   = icmp sgt i32 %q, 5
  %sel = select i1 %c, float 2.500000e-01, float 7.500000e-01   ; float-operand select
  %w   = fpext float %sel to double                              ; value-preserving carrier
  call void @cq_phi(double %w)  ; %w lands in arg-1 (angle)
  %m   = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
