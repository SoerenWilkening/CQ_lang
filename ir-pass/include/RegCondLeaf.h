// RegCondLeaf.h — bd test_C_libtooling-dm7f.77 (dm7f.51 step 2, design D3):
// the REGISTER CONDITION, a tainted `i1` value that a control consumer reads as
// its own register instead of decomposing it into a condition network.
//
// ── WHY ──────────────────────────────────────────────────────────────────────
//
// `t ^= a; if (t) cq_theta(&a, θ); t ^= a;` reaches the pass as
//     %c = xor i1 %a, %t        ; t is DEAD after %c (the user overwrote it)
//     br i1 %c, …               ; the arm rotates %a
//     %t2 = xor i1 %c, %a.new
// The owner's register ruling (owner-ruling-dm7f51-inplace-qq-2026-10-14 Q1) says
// `%c` lowers IN PLACE: `cqrt_cnot(a, t)` and `%c` names t's rail from then on
// (step 1, `InPlaceQQ.h`, in `lowerLateReassignments`). A condition consumer that
// DECOMPOSES `%c` into an xor node over the leaves `%a` and `%t` re-reads the OLD
// `t` after that gate: the network's `cqrt_cnot(h_t, g)` names a register that
// now holds `t ^ a`. That is the measured V5 / Dicke block failure (step 1 made it
// loud: `lowering_inplace_qq_decline_dicke_block.ll`). The circuit the program
// means reads t's rail, which IS the condition: no network, no ancilla, no strip.
//
// ── THE COMMIT ───────────────────────────────────────────────────────────────
//
// `commitRegisterConditions` runs before EVERY `detectControlRegions` (after the
// merge-φ peel, both rounds: CLAUDE.md L1) and tags `!cq.regcond !{i32 k}` on the
// CONDITION of a tainted conditional `br` or `select` when it is a QQ `xor i1`
// whose operand `k` is the step-1 in-place target: dead after the xor
// (`qqOperandDeadAfter`, the record's own spelling), a register carrying a
// rotation (a `cq_theta` result, possibly through φ/select/freeze routers), the
// OTHER operand not also such a target (the both-dead ruling keeps that loud in
// the late round), and the result surviving the xor's own region (read past the
// branch — measured, rotated, returned, stored, or the dead operand of a later
// QQ xor that survives). Exactly the sites the late round converts, asked on the
// IR detection sees, BEFORE any emitter adds a read.
//
// THREE MORE TAGS, THE SAME CONCEPT. A condition with NO dead target is tagged
// FRESH (`kRegCondFresh`: its out-of-place rail is the register) when it survives
// past its control (design D5: the entangling copy `t' = a ^ t` with the old `t`
// live) or when its tree holds a logical NOT (`xor X, true`), which no network
// decomposes (`-O1`'s `a & (a ^ b)` → `a & !b`, the reporter's t7.c); its i1
// and/or/xor is then lowered out of place by `lowerOps` and the spine discharges
// it after its last control read (ChainWalk `isInteriorConsumer` row (c′)). And
// DESIGN D4 CASE 2 (`substituteNegatedGuard`): `br i1 %c` whose arm rotates `%c`
// itself, with `%g = xor %c, true` dominating it, becomes `br i1 %g` with the
// successors swapped and `%g` tagged fresh (dicke.c's `q3 = !q2`). A committed
// target-tagged condition is SUNK to just before its branch, across non-call
// instructions only (`sinkCommittedCondition`), so independent pure readers
// (`q3 ^= q1` in dicke.c) run before the in-place gate.
//
// THE TAG IS HONOURED DOWNSTREAM: the late QQ round converts a target-tagged
// op only onto its target (any other conversion Q1 demands is loud), and
// `RegionFlatten` never erases a tagged condition (a state prep holds it only
// through a `WeakTrackingVH`). ChainWalk's row (c′) reads the tag on the
// template; the tags are stripped after `uncompute` (`declineStaleInPlaceQQReads`).
//
// A TAGGED VALUE is read as a register by the consumers that opt in: the flat
// in-place rotation / state-prep region (`classifyArms` + `emitInPlaceRotation-
// Region`, beside the bare `_Bool` rail and the claimed merge φ) and, as a tree
// ROOT, the 4.4 data select (`collectCondTree`'s `AllowRegRoot`). Wire questions
// reach it through `condProvenance` / `railWireClosure`, which stop at a tagged
// value and continue only into its target. The post-fixpoint re-ask
// (`reverifyRailCondReads`) re-asks both rungs over that wire (L1). Its wire is
// `{V} ∪ wire(target)`: the in-place gate leaves `V` on the target's rail, the
// SOURCE operand is only read (Bennett's in-place xor, Bennett.jl @824458d
// src/lowering/arith.jl:378 and the exclusive-reader target rule
// src/lowering/operand.jl:182-221; BennettVM.jl @23d28e6
// src/ir/arithmetic_assignment.jl:1-17), so a later gate on the source does not
// touch the condition. Every other consumer still decomposes it — and a tagged
// value read that way is refused by the late round's own fence (G6/G7), loudly.
//
// ── WHY READING THE REGISTER IS SOUND EITHER WAY THE LATE ROUND DECIDES ──────
//
// The control read sees `V`'s VALUE whether `V` is lowered out of place (a fresh
// rail holding `x ^ y`) or in place (x's rail holding `x ^ y`), because the
// read is by SSA identity and the in-place gate is placed at `V`'s own position,
// before the branch. The union wire covers both. The late round is unchanged: it
// converts iff eligible and surviving, else the template stands.
#ifndef CQ_IRPASS_REG_COND_LEAF_H_
#define CQ_IRPASS_REG_COND_LEAF_H_

#include "llvm/ADT/SmallPtrSet.h"

namespace llvm {
class Instruction;
class Module;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

inline constexpr const char kRegCondTag[] = "cq.regcond";
// The tag's operand for a register condition with NO in-place target (design
// D5: no operand is a dead rotated register, so the xor stays out of place and
// its fresh rail is the condition register).
inline constexpr unsigned kRegCondFresh = 7;

// Is `V` a tagged register condition (an `i1` instruction carrying the tag)?
bool isRegCondLeaf(const llvm::Value *V);

// The committed in-place TARGET operand of a register condition, or null (no
// target: the condition's wire is its own fresh rail).
llvm::Value *regCondTarget(const llvm::Value *V);

// The provenance seed set of a register condition: `V` itself plus the tainted
// provenance of its target (`condProvenance` of the target). NOT the source.
void regCondProvenance(llvm::Value *V, TaintSet &Taint,
                       llvm::SmallPtrSetImpl<llvm::Value *> &Out);

// Copy the tag from `From` (the IR op) to `To` (its template), the operand
// index remapped when the template swapped the operands. A no-op without a tag.
void transferRegCondTag(const llvm::Instruction *From, llvm::Instruction *To,
                        bool Swapped);

// The tag's raw operand on any instruction (a template too): -1 without a tag,
// `kRegCondFresh` for no target, else the target operand's index.
int regCondTagIndex(const llvm::Instruction *I);

// The commit stage (see the header). Idempotent; only ever adds tags.
void commitRegisterConditions(llvm::Module &M, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_REG_COND_LEAF_H_
