; control_phase_nest_reject_merge_phi.ll — DECLINE. A depth-2 register-free phase
; nest whose merge block carries a φ.
;
; P4 requires the merge to have NO φ at all. A register-free phase region
; produces no value, so a φ there belongs to somebody else — and a φ left
; standing in a block `flattenRegionTree` splices away is a BROKEN MODULE
; (`PHI nodes not grouped at top of basic block!`), which part A measured on the
; FLAT path before its own merge-φ rule existed. ⚠ NOT "at `opt` exit 0": this
; header was written on a parallel branch that never saw round-1 finding F-L3-5,
; which MEASURED that `cq-opt`'s `VerifierPass` (default `FatalErrors=true`)
; makes a broken module a `report_fatal_error` — **exit 134 (SIGABRT)**, no
; module written. Round-2 finding F-R2-3 caught the false claim propagating here.
; The point of the fixture is unchanged and stronger: a broken module is LOUD but
; it is not a DECLINE, and Rule 1 wants a decline. The flat
; kickback can claim ONE 2-incoming `phi double` as a merge-tail ANGLE
; (`phaseAngleTail`); a nest merge has THREE incomings, which that predicate
; refuses outright, so there is no φ this emitter knows how to account for.
;
; Refusing is what keeps the failure a DECLINE rather than a broken module — the
; distinction Rule 1 exists for.
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double 2.500000e-01)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %inner, label %merge
inner:
  call void @cq_phi(double 7.500000e-01)
  br label %merge
merge:
  %k = phi i32 [ 1, %entry ], [ 2, %mid ], [ 3, %inner ]
  %m = call i32 @cq_measure_si32(i32 %q)
  %t = add i32 %m, %k
  ret i32 %t
}

; CHECK: cq controlled lowering: impure phase arm under quantum control
