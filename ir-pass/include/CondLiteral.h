// CondLiteral.h — bd `test_C_libtooling-xdu2.13`: a CLASSICAL operand of a
// mixed `and`/`or` node in a 4.4 data-select condition tree, lowered as the
// LITERAL of the existing `cq_template_{and,or}_i1_hl` (the §5.2 mixed-operand
// convention — the classical operand is NEVER promoted to a qubit).
//
// THE SHAPE. `clang -O1` fuses `if (q && m == n)` into
// `and i1 (icmp eq m, n), (icmp ne q, 0)` — one tainted leaf, one classical
// leaf — and a 4.4 data select on it used to decline at `SelectClassify`'s
// per-leaf taint check (`control flow`). The node is now minted exactly like
// every other mixed Q+C op the pass lowers: `gl = cq_template_and_i1_hl(f, c)`
// with `f` the tainted child's network flag and `c` the classical i1 value in
// the `_hl` literal slot; the select's copies are controlled on `gl`; the strip
// is the void `cq_template_and_i1_hl_unc(gl, f, c)` — the SAME SSA literal —
// then `cqrt_free(gl)`, a proven-|0> free (Rule 6: `gl ^= f∧c` twice is 0).
// No classical-guard path, no rewrite of clang's IR, no new frozen symbol.
//
// WHAT IS A LITERAL (`condLiteralAdmissible`), each conjunct load-bearing:
//   (a) a non-`Constant` `i1` `Instruction`/`Argument` — a `Constant` child has
//       no flag and `undef`/`poison` is read as two values by the forward and
//       its `_unc` (`LiteralIntegrity.cpp`); a constant child keeps its decline;
//   (b) UNTAINTED at the classifier's (round-1) taint — re-asked at FINAL taint
//       by `declineQuantumCondLiterals` (CLAUDE.md L1: a leaf derived from a
//       6.5/4.5 merge `%out` is classical at round 1 and quantum after the
//       fixpoint, and a quantum value in a literal slot is a Rule-3 crossing);
//   (c) NOT PREDICTED-TAINTED by PredMux E6 rule (B) (bd q2wk, PRD §4.4b): E6
//       admits an untainted branch condition on the proof that the flatten
//       taints it. Where that prediction fails the value survives untainted, and
//       it must keep declining rather than silently become a literal — so the
//       flatten RECORDS it (instruction metadata `!cq.predmux.predicted` on the
//       whole i1 cone of the condition and of each edge literal built from it,
//       committed at the CLAIM), and this predicate refuses any literal whose
//       i1 cone meets a mark. Metadata rather than a `TaintSet` field because
//       the PredMux fixpoints REBUILD the taint set after every claim and the
//       unroll pre-pass CLONES instructions (metadata travels with a clone).
//       ⚠ Defence in depth: no residue could be CONSTRUCTED — the prediction
//       was exact on every probe (see the E6 block in `PredMuxFlatten.cpp` for
//       the constructions and the retirement trigger).
//   (d) (Rule-13 round 2 F-1) its operand cone reaches no call to a DEFINED
//       function whose RETURN cone carries a tainted value (recursively), and no
//       indirect call: taint does not cross a call return (bd
//       test_C_libtooling-3jru), so `g()` returning a `cq_theta` register is an
//       untainted HANDLE ID in the caller and must never be a literal.
// The literal slot carries `zeroext` on the forward and the `_unc` (round 2
// F-2: the runtime's `bool` parameter; without it C at -O1 delivered 2/254/253).
// Dominance needs no conjunct: the literal is an operand of a tree node, the
// node dominates the select (non-φ SSA use), and the network, the copies and
// the strip are all emitted immediately before the select.
//
// SCOPE. The 4.4 DATA select only. The register-free branch phase (`if (q &&
// m == n) cq_phi(θ)`) reaches `ArmClassify` with the same tree and keeps its
// `control flow` decline (pinned by `condtree_classical_leaf_reject_phase.ll`).
// An `xor` node with a classical child, a node whose tainted sibling is a bare
// RAIL (`_Bool` register or region-merge φ), and a node with two classical
// children also keep declining.

#ifndef CQ_IRPASS_COND_LITERAL_H_
#define CQ_IRPASS_COND_LITERAL_H_

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"

namespace llvm {
class CallInst;
class DebugLoc;
class Instruction;
class Module;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// The metadata kind PredMux attaches to a rule-(B) predicted-tainted value's
// i1 cone, and the FUNCTION metadata it attaches if a cone overflowed the walk
// budget (then no literal in that function is admitted — the safe direction).
constexpr const char *kPredMuxPredictedMD = "cq.predmux.predicted";
constexpr const char *kPredMuxPredictedOverflowMD =
    "cq.predmux.predicted.overflow";

// PredMux, at the claim: mark `Root`'s i1 cone (itself plus every `i1`
// Instruction reachable backwards through operands) as predicted-tainted.
void markPredictedTaintCone(llvm::Value *Root);

// The classifier's literal predicate — conjuncts (a)–(c) above.
bool condLiteralAdmissible(llvm::Value *V, const TaintSet &taint);

// Forward: `gl = cq_template_<and|or>_i1_hl(Flag, Lit)` before `B`'s insertion
// point, recorded in `taint.CondLiteralGates` for the round-2 re-ask. Null if the
// symbol cannot be resolved (the caller treats it as malformed and declines).
llvm::CallInst *emitCondLiteralNode(llvm::IRBuilder<> &B,
                                    llvm::Instruction::BinaryOps Opc,
                                    llvm::Value *Flag, llvm::Value *Lit,
                                    WidthDispatch &wd, TaintSet &taint,
                                    const llvm::DebugLoc &DL);

// Strip: the forward's void `_unc` (via `emitInverseCall`, Rule 14 — the SAME
// operands, literal included) then `cqrt_free` of its rail.
void stripCondLiteralNode(llvm::IRBuilder<> &B, llvm::CallInst *Tpl,
                          WidthDispatch &wd, TaintSet &taint);

// THE L1 RE-ASK, after the round-2 fixpoint in BOTH entry points: every emitted
// literal gate whose literal is tainted at FINAL taint declines loudly
// ("classical condition literal became quantum-derived"). Returns true iff it
// declined.
bool declineQuantumCondLiterals(llvm::Module &M, TaintSet &taint);

// Drop every `!cq.predmux.predicted` mark (instruction and function) once no
// classifier can ask again — immediately after the re-ask — so the lowered
// module is byte-identical to one the marks were never attached to.
void stripPredMuxPredictedMarks(llvm::Module &M);

}  // namespace cq

#endif  // CQ_IRPASS_COND_LITERAL_H_
