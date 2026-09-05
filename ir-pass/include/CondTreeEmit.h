// CondTreeEmit.h — THE condition-tree flag NETWORK: one forward emitter, one
// exact-LIFO strip, three callers (Rule 14).
//
// bd test_C_libtooling-3qlq Inc 1 part B (PRD `retire-swap-route-PRD.md` §6.2
// row P3). Before this TU the network lived ONLY inside `SelectMergeEmit.cpp`
// (steps 1 and 5) with a second, partial copy in `Specialization.cpp`
// (`mintCondNetwork`, forward-only). P3 needs the SAME network for a `br`
// condition, so it is lifted here rather than copied a third time — the
// duplicated-lowering prohibition, and the reason the 4.4 select goldens are the
// witness that the lift is a REFACTOR: with `AllowQQLeaves = true` the emitted
// stream is byte-identical to the pre-lift `SelectMergeEmit`, instruction for
// instruction and NAME for name (the ancillas are still called `g`).
//
// THE NETWORK (unchanged from 3c6m.12 / bd 3c6m.67 — see `SelectMergeEmit.cpp`'s
// step 1 for the full derivation). Post-order over the tree; each `CmpInst` leaf
// mints its flag via `lowerCompareToFlag` at FIRST visit (a SHARED leaf mints
// ONCE), each interior node computes onto a fresh |0> i1 ancilla:
//
//   AND: toffoli(l, r, g)                         g = l ∧ r
//   OR : cnot(l, g); cnot(r, g); toffoli(l, r, g) g = l ⊕ r ⊕ lr = l ∨ r
//   XOR: cnot(l, g); cnot(r, g)                   g = l ⊕ r
//
// Controls are READ-ONLY, so sharing a rail between two node slots is safe by
// construction. The strip is the EXACT LIFO mirror: nodes in reverse post-order
// (a parent un-computes while its children's rails are still allocated), each
// node's own inverse network then its free; then leaves in reverse mint order,
// each `_unc`-stripped against its own rail then freed. Every rail is minted at
// |0> by this emitter and returned to |0> by its own inverse, so every
// `cqrt_free` here is a proven-|0> free (Rule 6) and no `cqrt_cswap`, no
// `_controlled` gate and no reverse-play is involved.
//
// POLARITY (`NegL`/`NegR`, P4 only). The `br`-nest caller (PRD §6.2 row P4)
// has no `and i1` instruction to read — its conjunction is a CFG, and either
// level's content arm may be the FALSE successor (Rule 9). A negated operand is
// expressed with the project's standing self-inverse `cqrt_x` bracket around the
// node's gates, NOT by a second flag mint: `x(l); toffoli(l,r,g); x(l)` computes
// `g = ¬l ∧ r` and leaves `l` exactly as it found it. With both flags false —
// the `and`/`or`/`xor` tree case — NOTHING is emitted for the bracket, which is
// what keeps the 4.4 stream byte-identical.
//
// WHAT THIS FILE DELIBERATELY DOES NOT DO: it never classifies. Every accept
// precondition (leaf taint, predicate scope, mintable width, Q+Q policy, the
// stale-condition wire guard, tree size) belongs to the CALLER's classifier and
// must be proven BEFORE the first emission — with one flag per leaf the mint is
// no longer atomic, so a mid-stream bail would leave earlier flags and ancillas
// dangling (the ziov.4 mutate-then-decline class). `emitCondNetwork` returns
// false ONLY on a resource failure it cannot foresee (no i1 allocator, a mint
// that diagnosed) and the caller must then decline loudly.

#ifndef CQ_IRPASS_COND_TREE_EMIT_H_
#define CQ_IRPASS_COND_TREE_EMIT_H_

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"

#include <utility>

namespace llvm {
class CmpInst;
class DebugLoc;
class Instruction;
class Value;
}  // namespace llvm

namespace cq {

class ControlledSymbols;
class WidthDispatch;
struct CondTree;
struct TaintSet;

// One emitted network. `Leaves` is in MINT order and `Nodes` in POST-ORDER (=
// emission order); `stripCondNetwork` walks both in reverse. `Root` is the rail
// that carries the whole predicate — the gate control the caller wants.
struct CondNetwork {
  struct Node {
    llvm::Instruction::BinaryOps Opc;  // And / Or / Xor (the LOGICAL op).
    llvm::Value *L = nullptr;
    llvm::Value *R = nullptr;
    llvm::Value *G = nullptr;  // the fresh |0> i1 ancilla this node writes.
    bool NegL = false;         // `cqrt_x` bracket on the left control (P4).
    bool NegR = false;         // …on the right control.
  };
  llvm::SmallVector<std::pair<llvm::CmpInst *, llvm::Value *>, 4> Leaves;
  llvm::SmallVector<Node, 4> Nodes;
  llvm::Value *Root = nullptr;
};

// Emit ONE interior node's gates onto `N.G`, forward (`Inverse=false`) or as its
// exact adjoint (`Inverse=true` — the same gates in reverse order; every gate is
// self-inverse). `Neg*` bracket the corresponding control with `cqrt_x`.
void emitCondNode(const CondNetwork::Node &N, ControlledSymbols &csyms,
                  llvm::IRBuilder<> &B, const llvm::DebugLoc &DL, bool Inverse);

// Emit the forward network for the already-collected `Tree` (whose root is
// `Root`) immediately before `Before`, recording it in `Out`. `AllowQQLeaves`
// selects the leaf-mint width policy: TRUE passes `qqSelectLeafWidth` (the 4.4
// select's shipped behaviour, bd adia), FALSE passes an empty width so a Q+Q
// leaf has no mint — the caller must then have declined it already. Returns
// false (having emitted nothing, or having stopped at a leaf whose mint already
// diagnosed loudly) if the network cannot be built.
bool emitCondNetwork(llvm::Value *Root, const CondTree &Tree, WidthDispatch &wd,
                     ControlledSymbols &csyms, TaintSet &taint,
                     llvm::Instruction *Before, const llvm::DebugLoc &DL,
                     bool AllowQQLeaves, CondNetwork &Out);

// The exact LIFO strip of a network emitted above, before `Before`: every node
// in reverse post-order (inverse network, then `cqrt_free` of its ancilla), then
// every leaf in reverse mint order (`_unc` strip against its own rail, then
// `cqrt_free`). Leaves the tree's IR untouched — erasing it is the caller's
// (the strip READS each leaf's original operands, so it must precede any erase).
void stripCondNetwork(const CondNetwork &Net, WidthDispatch &wd,
                      ControlledSymbols &csyms, TaintSet &taint,
                      llvm::Instruction *Before, const llvm::DebugLoc &DL,
                      bool AllowQQLeaves);

}  // namespace cq

#endif  // CQ_IRPASS_COND_TREE_EMIT_H_
