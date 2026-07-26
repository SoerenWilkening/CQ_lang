; control_predmux_reject_classical_br_in_region.ll — DECLINE (3c6m.14 L6 Inc 5,
; bd q2wk, PRD §4.4b sub-rule (B) — the CONTAINMENT FENCE).
;
; Inc 5 widened E6 so that a branch condition which is currently UNTAINTED but
; which the flatten ITSELF will taint (region-internal and transitively derived
; from a region-internal phi — `valueWillTaintAfterFlatten`) no longer reads as
; "classical control inside a tainted region". This fixture pins the other side
; of that line: a GENUINELY classical condition must still leave at
; gate=E6-classicalbr and fall through to the loud decline. It is the proof that
; the widening did not simply DELETE the E6 classical-branch check.
;
; `%cc = icmp sgt i32 %n, 3` is defined INSIDE the region (block %mid), so the
; taint-after-flatten walk really does run — it descends through the icmp's
; operands and finds only a function ARGUMENT (defined outside the region,
; derived from no region phi) and a literal, so the predicate is false and the
; branch stays classical. The condition is deliberately an on-grammar compare
; leaf (non-i1 operands), so `isSupportedCondTree` would ADMIT it: E6-classicalbr
; is therefore the sole blocker, not E6-condtree. The rest of the region is
; claimable — replacing `%n` with the tainted `%q` makes the identical CFG
; flatten cleanly — so a regression here shows up as an ACCEPT (a classical mux
; over quantum control, i.e. a silent miscompile), not as a different decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0, i32 %n) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %v1 = add i32 %q, 1
  %cc = icmp sgt i32 %n, 3
  br i1 %cc, label %arm, label %merge
arm:
  %v2 = xor i32 %q, 3
  br label %merge
merge:
  %rm = phi i32 [ %q, %entry ], [ %v1, %mid ], [ %v2, %arm ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
