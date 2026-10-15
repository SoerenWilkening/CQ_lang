// InPlaceQQ.h — in-place lowering of a QUANTUM-QUANTUM `x ^= y` / `x += y` /
// `x -= y` whose OLD `x` is dead (bd test_C_libtooling-r2j3.33, dm7f.51 step 1;
// owner ruling owner-ruling-dm7f51-inplace-qq-2026-10-14 Q1–Q3).
//
// THE DEFECT. `rewriteBinary` lowered every two-quantum add/sub/xor out of place:
// `cq_template_xor_<W>(h_a, h_t)` minted a fresh rail and left the old `t` rail
// standing. When `t` is a rotated user register that rail is never discharged,
// so after `t ^= a` the pair (old t, new t) jointly records `a`, and a later
// non-diagonal gate on `a` is dephased: `bool a,t; t ^= a; cq_theta(&a,.7)` gave
// P(a=0,t=0) = 0.796 where the program's circuit gives 0.766 (verify-clean, rc 0).
//
// THE LOWERING. `V = x OP y` becomes the void in-place gate
//     i1:        cqrt_cnot(y, x)        (add and sub mod 2 are xor)
//     i8..i64:   cqrt_{xor,add,sub}_<W>(y, x)
// tagged `!cq.inplace.qq`, and `V` is RAUW'd to `x`'s handle (V is a new name of
// x's wire from then on). Per operand `x`, the op is ELIGIBLE iff
//   (E1) `x` is DEAD AFTER the op in the IR as the pass received it, before any
//        emitter ran (`recordDeadQQOperands`, carried onto the QQ template by
//        `rewriteBinary` as `!cq.qq.dead`): every other use provably before it,
//        not a φ, not re-read by a later trip. Bennett.jl's exclusive-reader
//        target (src/lowering/operand.jl:182-221 @824458d) is the order-free
//        special case; the positional question is the owner's ("the OLD x is
//        dead at the op"). An op an emitter created has no record: never here.
//   (E2) `x`'s rail is USER DATA (it carries a non-permutation move, an Ry —
//        `isNonPermutationMove`). A derived rail with no rotation is a
//        temporary the spine returns to |0⟩: out of place is already exact.
//   (E3) the result SURVIVES (measured, rotated, escaped, or continued as the
//        dead operand of a later QQ op whose result survives; after a TAPE WRITE
//        the spine's own `computeFreePoint` decides — `Escaped` in `main` keeps
//        it, an `Insert` elsewhere discharges it) and is not discharged inline or
//        by the M-B plan. A temporary result is better out of place: that is in place
//        followed by its own adjoint at its death, which the dead-record ruling
//        asks for and the in-place form cannot deliver.
// An ELIGIBLE op then (R11 round 1, rulings ruling-dm7f51-step1-departures-
// 2026-10-15 and ruling-dm7f51-both-dead-loud-2026-10-15):
//   * with BOTH operands eligible fails loudly (`kMsgInPlaceQQAmbiguousTarget`):
//     the overwritten register is not recoverable from -O1 SSA and the choice
//     changes the unitary — no tiebreak;
//   * with an eligible SUBTRAHEND (`t = a - t`), or a source that depends on the
//     target's OLD value (`dependsOnTarget`: an alias of `x`, or a compiler
//     temporary whose lineage reads `x`; a user register stops the walk), fails
//     loudly (`kMsgInPlaceQQRefused` / `kMsgInPlaceQQSelfDependent`): no clean
//     in-place form exists;
//   * otherwise converts iff the M-C positional fence holds on `x` for a QUANTUM
//     source (`inPlacePositionHolds(..., QuantumSource=true)`: G5 not in a loop,
//     G6 no later use of `x`, G7 every prior use settled — with arm (c′): a
//     prior void reader is settled only if every rail it writes is user data or
//     released before the gate) and the width has an in-place symbol; else loud.
// Target choice is by these facts, never by operand spelling.
//
// STEP 2 (bd test_C_libtooling-dm7f.77, dm7f.51 step 2) widened the round in four
// places, each pinned by its own fixture:
//   * E1 over the WIRE (design D2(b)): a merge φ whose every incoming is a name
//     on ONE rotation chain (`phi [Ry(%q), %q]`) is a target when every chain
//     member is dead after the op (`singleWirePhiDeadAfter`). Step 1 refused every
//     φ, which silently miscompiled `if (a) cq_theta(&q,·); q ^= x; cq_theta(&x,·)`
//     (lowering_inplace_qq_phi_target_accept.ll) and is what dicke.c's
//     `q2 ^= q1` needs. A second dead operand then makes the op both-dead (loud).
//   * E2′ (design D5): a dead FRESH REGISTER CONDITION rail (RegCondLeaf.h) is an
//     optional target — in place on it equals out of place then its discharge,
//     and a measured terminal's DAG would otherwise leave it standing.
//   * G7 arm (d3) (`priorUseIsSettled`, ArithLowering.cpp, D2(b) "observed counts
//     settled"): a prior producer whose rail is MEASURED is settled.
//   * THE COMMIT IS HONOURED: a template carrying `!cq.regcond` (a control emitter
//     read it as a register on the wire the commit named) converts only onto its
//     tagged target; any other conversion Q1 demands is loud.
//
// Q1 — ELIGIBLE BUT NOT CONVERTED IS LOUD, at the op's `!dbg`, nothing lowered.
// Out of place there would leave the dead user register recording the source
// beside a surviving result — the defect above. An op whose old operand is LIVE
// stays out of place: the fresh rail is an entangling copy, which is the program
// (design D5). Measured loud shapes: a condition network re-reading the old
// register (the Dicke block V5 was one until step 2: its xor is now committed
// as a REGISTER CONDITION before detection, RegCondLeaf.h), a prior record
// still to be uncomputed (G7, incl. a merge copy of `x`), an in-loop op (G5), the
// eligible subtrahend, a self-dependent source, and both operands dead.
//
// WHERE AND WHEN. One round, called from `lowerLateReassignments` (the last slot
// before `uncompute`, reached by both entry points, after the round-2 fixpoint:
// L1), so every prior reader the fence adjudicates is lowered and inline, and the
// M-B plan exists. Sites are decided one at a time in program order on the
// current IR (a conversion re-plans), so a chained `t ^= a; t ^= b` converts both.
// Every pre-`lowerOps` gate-set walk (`staleRailRecordRead`, `collectRailGates`,
// the WireWalk non-diagonal set, `railWireClosure`) therefore sees the op as the
// BinaryOperator it still is and never meets the tagged gate; the conversion's
// G6/G7 refuse any read of `x`'s pre-op value that is still owed, and the
// postcondition below catches one that a prediction let through.
//
// THE SPINE (ruling Q1 accepted this departure from design D7). On its
// DESTINATION the tagged gate is an in-place gate exactly like
// the M-C `cqrt_addc_<W>` (`isInPlaceGateOn` arg 1, `preservesBasisUnderRecord`,
// `EmitInverse` xor self / add <-> sub), with the source a BORROWED parent the way
// a QRAM store's idx/val are: a dead target is reversed by the spine, a measured,
// recorded or rotated one is left as any rotated register is (never freed dirty,
// R5). On its SOURCE it is a forward reader finished with the rail
// (`isInteriorConsumer` (b‴), `preservesBorrowedParent` (2b)), the role of the
// out-of-place template it replaced. It is not merge-stream traffic
// (`streamGateWrites`), and the carried-merge fence admits it as a permutation.
// ⚠ This departs from design D7's "frozen, never freed by the spine": freezing a
// dead target leaks its record, which the dead-record ruling forbids; the spine's
// own reversal is what Bennett's soundness argument assumes (the in-place group is
// reversed before the target's defining group).
#ifndef CQ_IRPASS_IN_PLACE_QQ_H_
#define CQ_IRPASS_IN_PLACE_QQ_H_

#include "llvm/ADT/StringRef.h"

namespace llvm {
class BinaryOperator;
class Value;
class CallInst;
class DominatorTree;
class LoopInfo;
class Module;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// The tag every emitted in-place quantum-source gate carries (and its adjoint).
inline constexpr const char kInPlaceQQTag[] = "cq.inplace.qq";
// The pre-emission dead-operand record: `!{i32 mask}`, bit i = operand i.
inline constexpr const char kDeadOperandTag[] = "cq.qq.dead";

extern const char kMsgInPlaceQQRefused[];
// Both operands are eligible dead targets (ruling-dm7f51-both-dead-loud-2026-10-15).
extern const char kMsgInPlaceQQAmbiguousTarget[];
// The source depends on the dead target's OLD value (ruling Q2; R11 round 2 F4
// gave it its own message so the fixture pins `dependsOnTarget`, not G7).
extern const char kMsgInPlaceQQSelfDependent[];

// `cqrt_{xor,add,sub}_{i8,i16,i32,i64}` — the in-place quantum-source symbols.
bool isInPlaceQQSymbol(llvm::StringRef N);

// A TAGGED in-place quantum-source gate: `!cq.inplace.qq`, void, two distinct
// i32 operands, callee `cqrt_cnot` or an `isInPlaceQQSymbol`. Slot 0 is the
// source (read), slot 1 the destination (written). Membership, never the name
// alone: an untagged `cqrt_cnot` is a condition-network gate.
bool isInPlaceQQGate(const llvm::CallInst *G);

// Is `P`'s rail USER DATA the spine never discharges: does it carry a
// non-permutation move (an Ry or a controlled Ry — `isNonPermutationMove`)?
bool railIsUserData(const llvm::Value *P);

// THE ONE SPELLING of "operand `V` is dead after `BO` on the current IR" that
// `recordDeadQQOperands` records (every other user provably before `BO`, not a
// φ, not re-read by a later trip). Exposed for the pre-detection register
// condition commit (bd dm7f.77, RegCondLeaf.h), which asks it of IR the record
// never saw (the `_Bool` narrowing's xors).
bool qqOperandDeadAfter(llvm::Value *V, llvm::BinaryOperator *BO,
                        const llvm::DominatorTree &DT, const llvm::LoopInfo &LI);

// Record `!cq.qq.dead` on every integer add/sub/xor with a tainted operand.
// Called once per entry point, before `lowerLoops`, the peel and control
// detection (the IR the user wrote, after the pre-passes that only fold).
void recordDeadQQOperands(llvm::Module &M, const TaintSet &taint);

// Carry `BO`'s record onto its QQ template `T`, remapped when `rewriteBinary`
// swapped the operands for BirthOrder.
void transferDeadOperandMask(const llvm::BinaryOperator *BO, llvm::CallInst *T,
                             bool Swapped);

// The record `transferDeadOperandMask` wrote on a template (0 when none).
unsigned deadOperandMask(const llvm::CallInst *T);

// The round. Returns true if any site was converted. Strips every remaining
// `!cq.qq.dead` record and `!cq.regcond` tag (bd dm7f.77) before returning.
bool lowerInPlaceQQ(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

// THE POSTCONDITION (L1 / bd memory fix-that-predicts-a-later-stage-must-
// reverify-there), asked after `uncompute` in both entry points. The round's
// fence trusts predictions about what `uncompute` will do (the M-B plan, G7 arm
// (d2); a taped prior producer is never reversed, arm (d4)). Asked as a GATE SET
// (R11 round 1): any call after the gate that reads its target, or an alias of
// it, and writes a non-user compiler record minted BEFORE the gate — an adjoint,
// a strip, a merge replay — with no adjoint of the gate in between, is a read
// of the relabelled register expecting its old value: a wrong unitary. R11 round
// 2/2b: every `_unc`/`_inv` counts (a superset of the b12d4452 scan) and is stale
// iff its FORWARD (located by EmitInverse's `forwardOfAdjoint`) predates the gate,
// a reader it cannot classify FAILS CLOSED, and so does an alias set
// `handleAliases` cannot enumerate. Fails loudly (`kMsgInPlaceQQStaleAdjoint`) and returns true.
extern const char kMsgInPlaceQQStaleAdjoint[];
// R11 round 2b (finding N2): one message per cause, so each fixture pins its
// branch — a gate writing a record of the old value, an unclassifiable reader,
// and an alias set `handleAliases` cannot enumerate.
extern const char kMsgInPlaceQQStaleRecord[];
extern const char kMsgInPlaceQQReaderUnknown[];
extern const char kMsgInPlaceQQAliasUnknown[];
bool declineStaleInPlaceQQReads(llvm::Module &M, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_IN_PLACE_QQ_H_
