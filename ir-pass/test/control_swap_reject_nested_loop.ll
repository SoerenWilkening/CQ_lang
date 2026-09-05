; control_swap_reject_nested_loop.ll — DECLINE: a depth-2 phase nest that sits
; INSIDE a loop (the routed base %q is a loop-carried phi, the merge result feeds
; the backedge). The WI-1 forward-note backedge hazard, made a principled decline
; at WI-3 (§8 review 2026-06-12).
;
; `for (...) { if (q>5) { q=rz(q,b); if (q<9) { q=rz(q,a); } } }`. Detection's
; outer-shape / one-phi / 3-incoming / RAUW-collapse criteria all PASS (the loop
; phi is the routed base; every merge edge bottoms at it), so without a loop check
; the nest would be ACCEPTED — but the swap-route emitter's emitter-driven LIFO
; frees + 3-incoming-phi erase run BEFORE (and bypass) the FreePoint /
; declineClassicalMuxes backedge guards the flat path defers to ("tainted value
; muxed by a classical-condition phi"), so a loop-resident nest has no proven sound
; lowering in 4.3. recoverRegionTree's LOOP GUARD declines it `nested control flow`
; via the textbook backedge test (a region edge whose successor DOMINATES its
; source: %merge -> %loop, and %loop dominates %merge). The flat 4.1 path declines
; the analogous loop diamond too (declineClassicalMuxes), so this is consistent —
; the safe disposition (Prime Directive). A regression that re-accepted + emitted
; this would flip opt to exit 0 and fail the `not` wrapper.
;
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
; CHECK: error{{.*}}nested control flow under quantum control
