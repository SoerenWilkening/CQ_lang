; control_swap_reject_post_region_theta_nested.ll — DECLINE: precondition P3 of
; the Inc-4 position-aware accept (bd test_C_libtooling-lom0). The 4.3 depth-2
; NEST keeps the POSITION-FREE reading.
;
; `if (q > 5) { if (q > 7) { q = cq_phi(q, a); } }` followed by a chained
; `cq_theta` on the wire — structurally the same "the gate runs after the
; region" situation the FLAT phase path now accepts, on the nested path.
;
; WHO OWNS THIS DECLINE, and it is NOT `classifyArms`. `handleBranchRegion`
; recovers this as `RegionShape::Nested` and hands it to
; `RegionTreeDetect::recoverRegionTree`, which BYPASSES `classifyArms` entirely
; and runs its own PER-LEVEL `staleCond` walk (RegionTreeDetect.cpp, the bd tayx
; p16 guard) — a position-free `findNonDiagonalWireGate` plus the bounded
; positional compare→branch scan, mirrored from the flat guard. Increment 4
; touched only `ArmClassify`, so both levels here still decline on ANY theta
; anywhere on their wire.
;
; MEASURED IDENTICAL at HEAD (b4e329b) and in this tree:
;     cq controlled lowering: condition predates a non-diagonal gate
;
; WHY THE NEST WAS NOT WIDENED WITH THE FLAT PATH. The Inc-4 proof is stated
; over ONE emission point: `emitRegion` inserts its entire stream — mint, route,
; Rz, route-back, rail free, strip, flag free — before `R.Pred`'s terminator, so
; `provablyBefore(BI, T)` is a complete statement about the whole stream.
; `NestedRouteEmit::lowerNestedRegion` emits at TWO levels with an inner mint
; that follows the outer route, so "after the region" would need a per-level
; obligation and a proof about the outer flag's lifetime across the inner
; stream. That is a separate increment with its own Rule-13 round; until then
; the nest over-declines, which is the safe direction (Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge

mid:
  %c2 = icmp sgt i32 %q, 7
  br i1 %c2, label %inner, label %merge

inner:
  %g1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge

merge:
  %p = phi i32 [ %q, %entry ], [ %q, %mid ], [ %g1, %inner ]
  %w = call i32 @cq_theta_si32(i32 %p, double 2.500000e-01)   ; POST-region Ry
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
