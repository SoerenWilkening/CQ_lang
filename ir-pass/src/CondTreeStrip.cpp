// CondTreeStrip.cpp — `stripCondNetwork`, the exact-LIFO strip of the condition
// network `CondTreeEmit.cpp` mints. MOVED VERBATIM out of `CondTreeEmit.cpp` by
// bd `test_C_libtooling-xdu2.13` (file line budget, AGENTS.md); the only change
// is that increment's mixed-node branch. Contract: `CondTreeEmit.h`. Every rail
// here was minted at |0> by `emitCondNetwork` and is returned to |0> by its own
// adjoint on the line above its free (Rule 6).

#include "CondTreeEmit.h"

#include "CompareLowering.h"     // lowerCompareToFlag / qqSelectLeafWidth
#include "CondLiteral.h"         // stripCondLiteralNode (bd xdu2.13)
#include "ControlledSymbols.h"   // cnotFn / toffoliFn / xFn
#include "TaintPropagation.h"    // TaintSet
#include "WidthDispatch.h"       // freeFn

#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

void stripCondNetwork(const CondNetwork &Net, WidthDispatch &wd,
                      const ControlledSymbols &csyms, TaintSet &taint,
                      Instruction *Before, const DebugLoc &DL,
                      bool AllowQQLeaves,
                      SmallVectorImpl<CallInst *> *StripsOut) {
  IRBuilder<> B(Before);
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };
  // bd test_C_libtooling-r9e5 (1b-B.1) — THE RAIL-ROOT COPY FLAG FIRST, because
  // it was minted LAST (exact LIFO). `cqrt_cnot` is an involution, so re-emitting
  // it returns `f` to `x ⊕ x = 0` on EVERY basis branch — a proven-|0> free
  // (Rule 6), and the register it reads is left exactly as the forward found it
  // (the merge's controlled copies write `%out`, never the condition rail; the
  // `cqrt_x` brackets act on `f`). Vacuous for every other caller: `RailRootFlag`
  // is null unless `CopyRailRoot` was asked for and the root was a rail.
  if (Net.RailRootFlag) {
    stamp(B.CreateCall(csyms.cnotFn(), {Net.RailRoot, Net.RailRootFlag}));
    stamp(B.CreateCall(wd.freeFn(), {Net.RailRootFlag}));
  }
  // NODES first, in REVERSE post-order — a parent un-computes while its
  // children's rails are STILL ALLOCATED, which is the whole reason the order is
  // load-bearing: the inverse network READS L and R, so freeing a child before
  // its parent's undo would be a use-after-free of a rail whose value the undo
  // needs (§5 of the pre-lift SelectMergeEmit; the 4.3 nest's §12.3 in
  // miniature).
  //
  // bd urlv audit — NO KEPT-CARRIER RECORD REACHES ANYTHING FREED HERE. Every
  // rail is minted BY `emitCondNetwork` at |0> and returned to |0> on the line
  // above its free; none is an operand of a gate writing a carrier the reversal
  // does not touch, and this TU mints NO `cqrt_tape_write_*`.
  for (const CondNetwork::Node &N : llvm::reverse(Net.Nodes)) {
    if (N.Tpl) {  // bd xdu2.13 — a mixed node: its `_unc` (same literal) + free.
      stripCondLiteralNode(B, N.Tpl, wd, taint);
      continue;
    }
    emitCondNode(N, csyms, B, DL, /*Inverse=*/true);
    stamp(B.CreateCall(wd.freeFn(), {N.G}));
  }
  // LEAVES second, in reverse MINT order: the `_unc` strip recomputes the
  // predicate on the leaf's ORIGINAL operands and XORs it back onto that leaf's
  // own rail (so it MUST run before the caller erases the tree), then the rail
  // is freed at a proven |0>.
  for (const auto &LF : llvm::reverse(Net.Leaves)) {
    auto *Strip = dyn_cast_or_null<CallInst>(lowerCompareToFlag(
        LF.first, wd, taint,
        /*qqWidth=*/AllowQQLeaves ? qqSelectLeafWidth(LF.first, taint)
                                  : StringRef(),
        /*inverse=*/true, /*before=*/Before, /*negate=*/false,
        /*railToStrip=*/LF.second));
    if (StripsOut && Strip)
      StripsOut->push_back(Strip);
    stamp(B.CreateCall(wd.freeFn(), {LF.second}));
  }
}

}  // namespace cq
