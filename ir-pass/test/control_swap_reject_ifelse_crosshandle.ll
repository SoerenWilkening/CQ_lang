; control_swap_reject_ifelse_crosshandle.ll — DECLINE: if/else over TWO handles.
;
; `if (q > 5) { cq_phi(a); r = q; } else { cq_phi(b); r = p; }` — both arms carry
; a branch phase, AND the merge φ muxes two DIFFERENT tainted sources (%q vs %p),
; so neither arm is a pure phase arm: loud decline (`impure phase arm`), nothing
; lowered. (Pre-3qlq the arms were register-form `rz(q, a)` / `rz(p, b)`, declined
; because a swap-route if/else routed ONE shared handle.)
;
; The existing control_swap_reject_crosshandle.ll exercises the DIAMOND path; this
; pins the TWO-ARM if/else path.
;
;
; 3qlq(prep_a2): the asserted diagnostic was RE-SPELLED on the Inc-1 binary.
; The construct this fixture pins is unchanged; the CLAUSE that refuses it
; MOVED — this is a real disposition change, not a widening, and the new
; string does not contain the old one.
; OLD: control flow under quantum control
; NEW: cq controlled lowering: impure phase arm under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  call void @cq_phi(double %a)  ; rotates the routed %q
  br label %merge
else:
  call void @cq_phi(double %b)  ; rotates a DIFFERENT handle %p
  br label %merge
merge:
  %qm = phi i32 [ %q, %then ], [ %p, %else ]     ; muxes phase-of-%q vs phase-of-%p
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: impure phase arm under quantum control
