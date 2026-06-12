// NestedRouteEmit.h — The recursive swap-route emitter for the depth-2
// homogeneous-phase nest (Phase 4.3, IMPLEMENTATION-4.3 §4). The mutating twin of
// the flat `SwapRouteEmit::emitRegion`, lowering the proven §0 accept shape
//
//     if (q>5) { rz(q,b); if (q<9) { rz(q,a); } }
//
// to the coherent, ZERO-controlled-gate two-level routed stream emitted into the
// outer pred block before the outer `br`, in this EXACT order (the §5g contract;
// symbol order IS the contract):
//
//   1 outer mint + route-in   icmp_hl(q,·) ; alloc rail1 ; cswap(f1, q, rail1)
//   2 intervening replay       cqrt_rz_<W>(rail1, ·)   per `Mid` gate (g on rail1)
//   3 inner (FROM rail1)       icmp_hl(rail1,·) [the mint-from-rail primitive] ;
//                              alloc rail2 ; cswap(f2, rail1, rail2) ;
//                              cqrt_rz_<W>(rail2, ·) per inner-arm gate ;
//                              cswap(f2, rail1, rail2)              [route-back]
//   4 inner clean-up (LIFO)    free rail2 ; icmp_hl_inv(rail1,·) STRIP f2 ; free f2
//   5 outer route-back         cswap(f1, q, rail1) ; free rail1 ;
//                              icmp_hl_inv(q,·) STRIP f1 ; free f1
//   6 rewire + flatten         RAUW merge phi → q ; erase merge phi + both arm
//                              gate chains + both compares + both branches ;
//                              splice the SINGLE shared merge into pred once.
//
// The load-bearing temporal invariant (§12.3, verify-clean-invisible): the inner
// STRIP (step 4) comes AFTER the inner route-back (which restores rail1's mint
// value) and BEFORE the outer route-back (rail1 not yet emptied to |0⟩). A
// misordered emitter produces the IDENTICAL symbol multiset yet dirty-frees `%f2`
// = a hidden measurement collapsing `q` — caught only by the ordered FileCheck +
// the §8 four-row trace, never by `opt -verify`.
//
// Each per-level negation is independent (Rule 9 — clang -O1 may make either gate
// arm the FALSE successor); the ¬flag `cqrt_x` bracket rides `ArmNegated` per
// region exactly as the flat path. The inner flag is minted FROM rail1 (where the
// parent-routed value's amplitude physically lives post-route-in), via
// `lowerCompareToFlagRail` — a plain mint off the now-stale SSA register would
// compute the wrong predicate (§12.2).
//
// Dispatched from `SwapRouteEmit::lowerControlRegions` for a depth-0 region that
// has a coordinated depth-1 child (same shared merge, `Outer.Arm == Inner.Pred`).
// Runs BEFORE `lowerRotations` (references the still-present `@cq_theta`/`@cq_phi`
// results) and BEFORE `declineClassicalMuxes` (it is the SOLE owner of the
// 3-incoming merge phi — it must RAUW + erase it here, else the live tainted phi
// false-declines `classical phi`, §6.1).

#ifndef CQ_IRPASS_NESTED_ROUTE_EMIT_H_
#define CQ_IRPASS_NESTED_ROUTE_EMIT_H_

namespace cq {

class ControlledSymbols;
class WidthDispatch;
struct ControlRegion;
struct TaintSet;

// Lower one accepted depth-2 homogeneous-phase nest. `Outer` is the depth-0
// one-content-arm diamond whose arm block (`Outer.Arm` = the `Mid` block) holds
// the intervening gate(s) + the inner condition/branch; `Inner` is the depth-1
// diamond (`Inner.Pred == Outer.Arm`, `Inner.MergeBB == Outer.MergeBB`, the SAME
// 3-incoming `Outer.Merge` phi). Both polarities ride their region's `ArmNegated`.
// Mutates the module IR and `taint` (scrubs every erased instruction via
// `flattenRegionTree`).
void lowerNestedRegion(const ControlRegion &Outer, const ControlRegion &Inner,
                       WidthDispatch &wd, ControlledSymbols &csyms,
                       TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_NESTED_ROUTE_EMIT_H_
