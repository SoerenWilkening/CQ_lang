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
//   (E3) `y` does not depend on `x`'s old value (`dependsOnTarget`; covers every
//        alias, `x ^= x` included). If it does, `y` cannot be uncomputed once `x`
//        is relabelled, so in place only trades one record for another and blocks
//        `y`'s own discharge; that stays out of place (a self-dependent permutation
//        such as `x ^= x >> 1` needs a dedicated circuit — a follow-up).
//   (E4) the result SURVIVES (measured, taped, rotated, escaped, or continued as
//        the dead operand of a later QQ op whose result survives) and is not
//        discharged inline or by the M-B plan. A temporary result is better out of
//        place: that is in place followed by its own adjoint at its death, which
//        the dead-record ruling asks for and the in-place form cannot deliver.
// An eligible op is converted iff the M-C positional fence holds on `x`
// (`inPlacePositionHolds`: G5 not in a loop, G6 no later use of `x`, G7 every
// prior use settled, with the M-B plan) and the width has an in-place symbol.
// `sub` is directional: only the MINUEND can be the target. Target choice is by
// these facts, never by operand spelling; when both qualify, the lower
// BirthOrder rail (design D2(c)).
//
// Q1 — ELIGIBLE BUT NOT CONVERTED IS LOUD (`kMsgInPlaceQQRefused`, at the op's
// `!dbg`, nothing lowered). Out of place there would leave the dead user register
// recording the source beside a surviving result — the defect above. An op whose
// old operand is LIVE stays out of place: the fresh rail is an entangling copy,
// which is the program (design D5). Measured loud shapes: the condition of a
// later region re-reading the old register (the Dicke block, V5 — design D3,
// step 2), a prior record still to be uncomputed (G7), an in-loop op (G5), and
// the eligible subtrahend `t = a - t`.
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
// THE SPINE. On its DESTINATION the tagged gate is an in-place gate exactly like
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
class CallInst;
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

// `cqrt_{xor,add,sub}_{i8,i16,i32,i64}` — the in-place quantum-source symbols.
bool isInPlaceQQSymbol(llvm::StringRef N);

// A TAGGED in-place quantum-source gate: `!cq.inplace.qq`, void, two distinct
// i32 operands, callee `cqrt_cnot` or an `isInPlaceQQSymbol`. Slot 0 is the
// source (read), slot 1 the destination (written). Membership, never the name
// alone: an untagged `cqrt_cnot` is a condition-network gate.
bool isInPlaceQQGate(const llvm::CallInst *G);

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
// `!cq.qq.dead` record before returning.
bool lowerInPlaceQQ(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

// THE POSTCONDITION (L1 / bd memory fix-that-predicts-a-later-stage-must-
// reverify-there), asked after `uncompute` in both entry points. The round's
// fence trusts a prediction about what `uncompute` will do (the M-B plan, G7 arm
// (d2)). If it was wrong, an adjoint of a rail minted BEFORE the gate reads the
// relabelled destination after it, without the gate having been undone first: a
// wrong unitary. Fails loudly (`kMsgInPlaceQQStaleAdjoint`) and returns true.
extern const char kMsgInPlaceQQStaleAdjoint[];
bool declineStaleInPlaceQQReads(llvm::Module &M);

}  // namespace cq

#endif  // CQ_IRPASS_IN_PLACE_QQ_H_
