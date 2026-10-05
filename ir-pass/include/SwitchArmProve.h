// SwitchArmProve.h — the per-class G6 proofs for a tainted `switch`
// (swap-route 4.5 WI-1; PRD Part V §20.7; IMPLEMENTATION-4.5 §3.1).
//
// The `SwitchClassify` driver does the structural recovery (merge block, content
// phi, per-case arms, the G1/G3/G4/G5/G9/G10/G11 gates) and then dispatches to one
// of the three per-content-class proofs declared here. Each proof returns true on
// a clean ACCEPT shape (the driver then pushes a region; under WI-1 it declined
// `switch` transitionally until WI-2/3/4 built the emitters) or fires the precise
// loud decline and returns false. Pure SSA/CFG analysis — NO IR is mutated
// (Rule 9).

#ifndef CQ_IRPASS_SWITCH_ARM_PROVE_H_
#define CQ_IRPASS_SWITCH_ARM_PROVE_H_

#include "ControlPlan.h"  // SwitchClass

#include "llvm/ADT/SmallVector.h"

namespace llvm {
class BasicBlock;
class ConstantInt;
class PHINode;
class SwitchInst;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

// One recovered NON-default case arm of a tainted switch.
struct SwitchCase {
  // The case literal targeting this arm (the value `q == Value` selects it).
  llvm::ConstantInt *Value = nullptr;
  // The arm block: single-pred(switch block), single unconditional successor =
  // the merge block. Null when the case edge goes straight to the merge (an empty
  // case whose phi incoming rides the switch→merge edge).
  llvm::BasicBlock *Block = nullptr;
  // The merge-phi incoming value contributed on this case's edge.
  llvm::Value *Incoming = nullptr;
};

// The structurally-recovered shape of a tainted switch — filled by the
// `SwitchClassify` driver (by SSA/CFG identity, before any mutation) and consumed
// by the per-class proofs.
struct SwitchShape {
  llvm::SwitchInst *SI = nullptr;
  llvm::BasicBlock *SwitchBB = nullptr;  // SI->getParent()
  llvm::BasicBlock *MergeBB = nullptr;   // common successor / merge block
  llvm::PHINode *Merge = nullptr;        // the sole content phi in MergeBB
  // The phi incoming on the SwitchBB→MergeBB (default-direct) edge — the
  // straight-through value (the scrutinee for an empty default). Null when the
  // default is not direct (an explicit default block — declined at C5).
  llvm::Value *StraightThrough = nullptr;
  llvm::SmallVector<SwitchCase, 4> Cases;  // the non-default case arms
  bool DefaultDirect = false;
};

// G5 — per-case content class (the IMPLEMENTATION-4.5 open-Q-8 fallback: a TU-local
// composition of the exported `walkPhaseSpine` + a re-derived `isValueChangingOp`,
// leaving `ArmHomogeneity` untouched). `DataMux` when the incoming is a
// `ConstantInt`; `Value` when its in-arm phase spine bottoms at an in-arm
// value-changing op; `Phase` otherwise.
SwitchClass caseArmClass(llvm::Value *Incoming, llvm::BasicBlock *Block);

// The three per-class G6 proofs. Each fires the precise decline + returns false on
// an off-pattern shape, or returns true on a clean would-be-accept.
bool proveSwitchPhase(const SwitchShape &S, TaintSet &Taint);
bool proveSwitchValue(const SwitchShape &S, TaintSet &Taint);
bool proveSwitchDataMux(const SwitchShape &S, TaintSet &Taint);

}  // namespace cq

#endif  // CQ_IRPASS_SWITCH_ARM_PROVE_H_
