// CloneRailSelect.h — bd p3kd.7.2: classical control over quantum data inside a
// Bennett clone, lowered as a select of rail HANDLES (owner ruling 2026-10-06,
// bd memory owner-ruling-clone-classical-control-2026-10-06).
//
// In a lifted clone, PredMux (clone mode) if-converts classical branches and
// switches like tainted ones, so a classical merge becomes a select whose
// condition is classical and whose arms may be quantum. The choice is classical:
// whichever rail the condition picks holds the value, and every rail both arms
// minted is reversed and freed by the Bennett wrap after the copy-out, because the
// wrap reverses each forward op on its own operands. Where a forward op read the
// select (a template operand, a copy source), its adjoint reads the SAME select
// value, which is classical and fixed for the whole execution (its condition is
// classical, and frozen when it may be poison), so forward and reverse name the
// same rail. The select is not a gate
// and its result is never freed (it is no minted rail).
// So the select itself stays a classical `select`, retyped to choose between i32
// handles, with each classical arm materialized to a |v> rail first
// (`materializeCopySource`, left allocated as separable classical data).
//
// The rewrite runs AFTER `lowerOps`, when every quantum arm is the i32 handle of
// its lowered producer; building it earlier would mix still-fp quantum operands
// with i32 handles (measured on the prototype: a verifier abort on pow/powf QC).
// `recordCloneRailSelects` RECORDS the selects (with the per-arm taint it read) and
// leaves them in place; the clone's "no tainted select survives" backstop skips
// recorded ones.

#ifndef CQ_IRPASS_CLONE_RAIL_SELECT_H_
#define CQ_IRPASS_CLONE_RAIL_SELECT_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/IR/ValueHandle.h"

namespace llvm {
class SelectInst;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// A classical-condition select over at least one quantum arm, with the arm taint
// read at record time (before `lowerOps` RAUWs the quantum producers).
struct RailSelectRecord {
  llvm::WeakVH Sel;
  bool TrueQuantum = false;
  bool FalseQuantum = false;
};

// Is `SI` a recorded rail select (the clone backstop's exemption)?
bool isRecordedRailSelect(llvm::ArrayRef<RailSelectRecord> Recs,
                          const llvm::SelectInst *SI);

// Rewrite every recorded select into `select i1 %c, i32 %hT, i32 %hF` over rail
// handles, materializing each classical arm. Returns false after a loud decline
// (a quantum arm that is not an i32 handle by now, or a width with no
// allocator); the caller treats it as a failed clone.
bool rewriteRailSelects(llvm::ArrayRef<RailSelectRecord> Recs, TaintSet &ct,
                        WidthDispatch &wd);

}  // namespace cq

#endif  // CQ_IRPASS_CLONE_RAIL_SELECT_H_
