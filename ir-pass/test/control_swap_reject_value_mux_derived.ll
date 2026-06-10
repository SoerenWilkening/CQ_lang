; control_swap_reject_value_mux_derived.ll — the DEFECT-2 fix: derived
; straight-through + independently-derived arm value is a data MUX, not a §3c
; clobber and not a routable value arm (4.2 WI-3; PRD Part II §8.3 + bd memory
; swap-route-detect-known-limits item 2, superseded by this disposition).
;
; `t = q + 7; if (q > 5) { t = q + 3; }` — the merge muxes TWO independently
; q-derived values (%t on the straight-through edge, %t2 from the arm). The arm
; chain bottoms at %q, NOT at the routed slot %t (`ChainBase != Routed`), so the
; region is NOT routable: routing %t and replaying the arm chain on a rail would
; compute add(t,3), not the source's add(q,3) — a verify-clean wrong unitary.
; The condition register q is never overwritten here (it stays live; the flag is
; strippable), so this is NOT a §3c clobber either — it is the 4.4 select-family
; data mux, declined with the generic string until a mux-capable increment.
; Defect-2 was the old 'value-arm swap-route' label on this shape: with 4.2
; un-deferring value arms, that label would have become an over-accept hazard.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: arm rewrites a condition operand
; CHECK-NOT: value-arm swap-route
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t = add i32 %q, 7         ; straight-through incoming: DERIVED from %q pre-region
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %t2 = add i32 %q, 3        ; arm chain bottoms at %q != routed slot %t -> mux
  br label %merge
merge:
  %tm = phi i32 [ %t2, %arm ], [ %t, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %tm)
  ret i32 %m
}
