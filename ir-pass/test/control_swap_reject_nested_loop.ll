; control_swap_reject_nested_loop.ll — DECLINE: a depth-2 phase nest that sits
; INSIDE a loop (the condition register %q is a loop-carried phi, the merge feeds
; the backedge). The WI-1 forward-note backedge hazard, made a principled decline
; at WI-3 (§8 review 2026-06-12).
;
; `for (...) { if (q>5) { cq_phi(b); if (q<9) cq_phi(a); } }`. recoverRegionTree's
; LOOP GUARD declines it `nested control flow` via the textbook backedge test (a
; region edge whose successor DOMINATES its source: %merge -> %loop, and %loop
; dominates %merge). At WI-3 the swap-route nest emitter's own LIFO frees bypassed
; the FreePoint / declineClassicalMuxes backedge guards, so a loop-resident nest
; had no proven sound lowering. A regression that re-accepted + emitted this would
; flip opt to exit 0 and fail the `not` wrapper.
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: nested control flow under quantum control
; NEW: cq controlled lowering: nested control flow under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %q, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
