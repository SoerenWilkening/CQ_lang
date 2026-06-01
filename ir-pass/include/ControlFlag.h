// ControlFlag.h — Control-wire lowering for a recovered region (PRD §2.3/§2.4,
// IMPLEMENTATION §5.2). Reopens the Phase-3 compare seam: a tainted `icmp`
// feeding a `br i1` lowers as the control FLAG (not as data), reusing the
// extracted `CompareLowering::lowerCompareToFlag`. The original `icmp` is left
// standing — it is erased by `CFGLinearization` — so the `br i1` stays
// well-typed at the WP boundary (§1.3).

#ifndef CQ_IRPASS_CONTROL_FLAG_H_
#define CQ_IRPASS_CONTROL_FLAG_H_

#include "llvm/ADT/StringRef.h"

namespace llvm {
class CmpInst;
}  // namespace llvm

namespace cq {

class ControlledSymbols;
class WidthDispatch;
struct TaintSet;
struct ControlRegion;

// Recover the QQ compare width for a tainted-tainted (`if (q1 < q2)`) control
// condition from the `taint.HandleWidth` side-table (PRD §2.4, §5.6). Shared by
// the forward control-flag compute (`lowerControlFlag`) and its uncompute
// counterpart (`ControlledLowering::emitUncompute`) so both spell the same QQ
// width. Risk R3: a missing/mismatched entry is staleness — a real bug — so it
// `report_fatal_error`s rather than silently emitting a wrong-width symbol.
// Precondition: both `Cmp` operands are in `taint.Tainted`.
llvm::StringRef qqControlWidth(llvm::CmpInst *Cmp, TaintSet &taint);

// Mint `region.Flag` from `region.Condition`.
//   * Plain compare (`region.Conj == ConjNone`, WP3): the HL path (`qqWidth`
//     empty); the Q+Q path (reading `taint.HandleWidth`) is the forward seam
//     for WP6.
//   * Compound `&&`/`||` (`region.Conj != ConjNone`, WP5): lower `region.CondA`
//     and `region.CondB` each to its own flag via the same HL path, then
//     `FlagConjunction::combineFlags` ANDs/ORs them into the single
//     `region.Flag` (§1.2, PRD §2.5). `csyms` mints `cqrt_alloc_i1` /
//     `cqrt_toffoli` / `cqrt_x` for the combination.
// Returns true on success (flag stored); false if any compare/symbol was
// unsupported (diagnosed) — the caller then skips the region.
bool lowerControlFlag(ControlRegion &region, WidthDispatch &wd,
                      ControlledSymbols &csyms, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_CONTROL_FLAG_H_
