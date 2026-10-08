// PoisonFlow.h — bd bwfp / dm7f.21: where may a classical call under quantum
// control run once the 6.5 arm hoists it onto every basis state?
//
// The 6.5 hoist executes the call on basis states the source's guard excluded.
// Owner ruling 2026-10-08 (bd memory owner-ruling-hoist-callee-ub-sound-2026-10-08):
// the hoist stays SOUND, and a callee whose own `noundef` sinks may see poison
// there is not declined but hoisted as its SPECULATION-SAFE TWIN: an internal
// clone in which every operand whose poison is immediate UB and which a `freeze`
// discharges is frozen. On a basis state where the source ran the call without UB
// every such operand was already defined, so each `freeze` is the identity and the
// twin computes the source's value; on any other state the result is never merged
// (the controlled copy is the identity where the flag is 0).
//
// ONE DATAFLOW serves both questions, so the claim and the twin builder cannot
// drift: `classicalCallHoistRoute` (claim and emitter, before any mutation) and
// `TwinPlanner` (the builder, on the original body and again on each built twin
// until it plans nothing) run the same walk.
#ifndef CQ_POISON_FLOW_H
#define CQ_POISON_FLOW_H

#include "llvm/ADT/SmallVector.h"

#include <memory>
#include <optional>
#include <utility>

namespace llvm {
class CallInst;
class Function;
class Instruction;
}  // namespace llvm

namespace cq {

// How the 6.5 arm may hoist `Call`: as written (`Direct`, no poison reaches a
// sink once the bd 9hea root freezes run), as its callee's speculation-safe twin
// (`Twin`), or not at all (`Unsafe`: a contract no freeze discharges — a calling
// convention mismatch, a value-constraining parameter attribute, a cycle, a
// bodyless callee whose sink sees poison, a non-freezable sink such as a divisor).
// Purity and totality of the body (memory, division, CFG) are the strict walk's
// question (`isSpeculatableTotalCallee`), asked by the claim before this.
enum class HoistRoute { Unsafe, Direct, Twin };
HoistRoute classicalCallHoistRoute(const llvm::CallInst *Call);

// The edits that make one body speculation-safe, keyed by its own instructions
// (the builder maps them onto its clone). Valid for ANY caller: every parameter
// is assumed possibly poison.
struct TwinEdits {
  // Operand `second` of instruction `first` is replaced by its `freeze`.
  llvm::SmallVector<std::pair<const llvm::Instruction *, unsigned>, 8> Freeze;
  // An intrinsic call site whose value-constraining return attributes and
  // `noundef` are dropped (its result is tracked as possibly poison instead).
  llvm::SmallVector<const llvm::CallInst *, 4> StripRet;
  // An inner call pointed at its own callee's twin.
  llvm::SmallVector<const llvm::CallInst *, 4> Redirect;
};
// The twin-mode dataflow with ONE memo for a whole twin build (a chain may be
// 60000 deep; a fresh memo per twin made the build quadratic). `edits(F)` is
// `F`'s own edits (its redirect targets are separate bodies); nullopt when no
// twin exists (see `HoistRoute`). The builder runs it on the original body and
// then on the built twin itself until it plans nothing (R11 round 1, F1/F2), and
// calls `forget(T)` whenever it edits twin `T`.
class TwinPlanner {
public:
  TwinPlanner();
  ~TwinPlanner();
  std::optional<TwinEdits> edits(const llvm::Function &F);
  void forget(const llvm::Function &F);

private:
  struct State;
  std::unique_ptr<State> S;
};

}  // namespace cq

#endif  // CQ_POISON_FLOW_H
