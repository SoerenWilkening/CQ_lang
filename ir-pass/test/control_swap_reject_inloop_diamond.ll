; control_swap_reject_inloop_diamond.ll — DECLINE: a FLAT (depth-1) tainted-
; condition phase diamond that lives wholly inside a loop body, with a
; loop-CARRIED routed base (the merge feeds the backedge; the routed `%q` is a
; loop-header phi). Source shape:
;
;     for (...) { if (q > 5) { q = cq_phi(q, b); } }   // q loop-carried
;
; test_C_libtooling-d8jl. BEFORE this guard the flat path ACCEPTED the diamond
; (`recoverRegion` → Diamond, `classifyArms` → Accept), EMITTED the swap-route
; stream, and relied on the surviving loop-header phi tripping
; `declineClassicalMuxes` — whose `tainted value muxed by a classical-condition
; phi` string MISLABELS the QUANTUM condition `%c1 = icmp sgt %q, 5` as classical.
; The d8jl `flatControlInLoop` guard in `detectControlRegions` (LI.getLoopFor(BB)
; + every successor in the same loop) declines it HERE, before any mutation
; (Rule 9), with the accurate `control flow inside a loop body` message. The
; depth-2 in-loop NEST keeps its distinct `nested control flow` disposition
; (recoverRegionTree backedge guard) — see control_swap_reject_nested_loop.ll.
; Over-declining is always safe (Prime Directive): an in-loop control region has
; no sound swap-route lowering (the flatten would cross the backedge).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control
; The OLD misleading message must be gone, and nothing may be emitted.
; CHECK-NOT: classical-condition phi
; CHECK-NOT: cqrt_cswap

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %qm, %merge ]       ; loop-carried routed base
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]      ; classical induction
  %c1 = icmp sgt i32 %q, 5                             ; TAINTED (quantum) condition
  br i1 %c1, label %mid, label %merge
mid:
  %g = call i32 @cq_phi_si32(i32 %q, double %b)        ; phase arm (Rz)
  br label %merge
merge:
  %qm = phi i32 [ %g, %mid ], [ %q, %loop ]           ; merge feeds the backedge
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n                      ; classical loop bound
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
