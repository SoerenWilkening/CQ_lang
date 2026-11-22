// Frozen interface (cq-arch, with owner amendment A3 of 2026-10-27 and freeze beads cq-k1w and cq-6yb).
// Changes only under cq-arch's freeze rule.
#pragma once

#include <functional>
#include <memory>
#include <optional>
#include <vector>
#include <utility>

#include "cq/Common.h"
#include "cq/Lowering.h"
#include "cq/Taint.h"
#include "llvm/ADT/APInt.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

namespace llvm { class LoopInfo; }

// Predicate.h  (rules 8, 9, 12)
namespace cq {
struct Pred {   // canonical Boolean function over condition atoms
  static Pred top(); static Pred bottom(); static Pred atom(const llvm::Value *cond);
  // A3: a switch case atom `scrutinee == v` (rule 13), no i1 Value in the input IR.
  static Pred eqAtom(const llvm::Value *scrutinee, const llvm::APInt &v);
  Pred operator&(const Pred &) const; Pred operator|(const Pred &) const; Pred operator!() const;
  bool isTop() const; bool isBottom() const;
  Pred quantumPart(const TaintInfo &, const Specialization &) const;
  bool isClassical(const TaintInfo &, const Specialization &) const;
  // P1 (freeze bead cq-6yb, rule 8 at CQ_spec a46894a): p == p.classicalFactor(T,S) & p.quantumPart(T,S)
  // for every p. classicalFactor is the conjunction of every classical term that is a conjunct of p,
  // taken on the Boolean function, never on the syntax; it stays a classical branch. quantumPart is
  // exactly the unfactorable rest: one flag, a classical term left inside it a seed rail (c || q).
  Pred classicalFactor(const TaintInfo &, const Specialization &) const;
  // cq-gujb (rules 8, 9): p with every quantum atom quantified away (exists): the classical condition under
  // which some quantum path satisfies p, i.e. under which the walker runs a block of predicate p (its
  // quantum part is a flag, its classical part classical control flow).
  Pred classicalProjection(const TaintInfo &, const Specialization &) const;
  // K1: storage owned by module pred; immutable and shared, so Pred copies as a value.
private:
  struct Impl; std::shared_ptr<const Impl> impl;
};
// cq-pfpy: can a and b hold together on some execution? a & b is satisfiable once the switch case atoms of
// one scrutinee with distinct values are taken as mutually exclusive (a value equals one case at most).
// Does p read every atom of lit (lit's support within p's)?
bool predReads(const Pred &p, const Pred &lit);
bool predsMeet(const Pred &a, const Pred &b);
// No two of ps meet (predsMeet), tested pairwise; a pair whose parts imply distinct cases of one switch is settled
// without predsMeet's conjunction per pair of case atoms (cq-m16f6).
bool predsExclusive(llvm::ArrayRef<Pred> ps);
struct EdgePreds { llvm::SmallVector<std::pair<const llvm::BasicBlock *, Pred>, 4> succ; };
class PathPredicates {
public:
  PathPredicates();
  void compute(llvm::Function &, const llvm::LoopInfo &, const TaintInfo &, const Specialization &,
               llvm::Value *entryFlag /* _ctl clones */);
  const Pred &block(const llvm::BasicBlock *) const;
  const Pred &edge(const llvm::BasicBlock *from, const llvm::BasicBlock *to) const;
  llvm::Value *flag(LoweringContext &, const Pred &);
  // CR rule 14 with rule 9 (a block lowered for some of its paths only: an exit arm's tail on the paths from outside the
  // unit, an arm on a loop's classical exit): until restored, block() and edge() answer under `p`, the condition of those
  // paths. Returns the assumption it replaces, to restore. The results stay valid across later calls.
  std::optional<Pred> assume(std::optional<Pred> p, const TaintInfo &, const Specialization &);
  // Rule 8: the rail of the atom when the predicate is exactly its negation (the false edge is an X bracket on it), a
  // flag that controls a kept store being kept with it (rule 5). nullptr otherwise.
  llvm::Value *negatedAtomRail(LoweringContext &, const Pred &);
  // K1: storage owned by module pred.
private:
  struct Impl; std::shared_ptr<Impl> impl;
};
// CR rule 13 (b137e75): a computed goto (indirectbr) is a switch whose scrutinee is the ADDRESS itself, an
// integer of pointer width, whatever produced it; the case value of destination d is caseAddress(d). The
// default is unreachable, so the last distinct destination is the complement of the others. The predicate
// under which ib transfers control to `to` (bottom when `to` is no destination).
Pred computedGotoEdge(const llvm::IndirectBrInst &ib, const llvm::BasicBlock *to);
// ptrtoint(blockaddress(@f, %d)) as i64: a run-time constant naming d (the lowered function keeps d under
// its identity, CR rule 13).
llvm::Constant *caseAddress(const llvm::BasicBlock *d);
// The distinct destinations of ib in its destination list's order, and, at the builder, the i32 position of a
// classical address among them (the last where it equals none of the others): a classical computed goto is a
// switch on that position.
llvm::SmallVector<llvm::BasicBlock *, 4> computedGotoDestinations(const llvm::IndirectBrInst &ib);
llvm::Value *computedGotoPosition(llvm::IRBuilder<> &B, llvm::Value *address, const llvm::IndirectBrInst &ib);
void lowerBranch(LoweringContext &, llvm::BranchInst &);
llvm::Value *lowerMerge(LoweringContext &, llvm::PHINode &);
// cq-oa67 (rules 9, 25, 26): a quantum phi of a vector, struct or array, merged field by field; binds its
// fields (aggr). The spine routes such phis here.
// rebind (cq-pfpy): the phi is bound already (a trip of a cutoff loop rebinds it), its fields replace it.
void lowerMergeFields(LoweringContext &, llvm::PHINode &, bool rebind = false);
// cq-u9oy (rules 9, 21): a quantum phi's fields merged over its edge predicates, each field k of rail type
// rails[k] and classical type tys[k]; read(v) gives an incoming value's fields at the builder (at the edge's
// end when the choice is classical, at the merge otherwise). A field equal on every arm stays as it is; a
// classical choice of classical fields is a classical phi. Binds nothing.
llvm::SmallVector<Operand, 4> mergeFieldsOf(LoweringContext &, llvm::PHINode &, llvm::ArrayRef<RailType> rails,
                                            llvm::ArrayRef<llvm::Type *> tys,
                                            const std::function<llvm::SmallVector<Operand, 4>(const llvm::Value *)> &read);
// Whether every reachable incoming edge of phi is chosen by a classical predicate (rule 9 at a58c3a4).
bool classicalChoice(LoweringContext &, const llvm::PHINode &);
llvm::Value *lowerSelect(LoweringContext &, llvm::SelectInst &);
llvm::Value *selectChain(LoweringContext &, llvm::ArrayRef<std::pair<Pred, Operand>> arms, RailType);
// cq-pfpy: the same select chain read only where `care` holds (the classical facts of the output edge it
// is emitted on): an arm or condition minted in a classical arm is carried to the point under those facts.
llvm::Value *selectChain(LoweringContext &, llvm::ArrayRef<std::pair<Pred, Operand>> arms, RailType, const Pred &care);
// cq-pfpy (rule 9): op read at the builder, where a merge reads it as the arm of predicate `arm` under the
// classical facts `care`. A value minted in a block that does not dominate the point (an arm the walk ran
// on a classical path that joins the point's path above it) is carried to the point by the classical
// joins above it: a don't-care (a |0> seed, or the null value) on a join edge whose facts exclude the
// arm. Otherwise op itself.
Operand reachingOperand(LoweringContext &, const Operand &op, RailType, const Pred &arm, const Pred &care);
// Rule 9: has every condition atom p reads a value in the new IR yet? An edge of a block still to be lowered has not:
// a unit lowered before it leaves that incoming to the walker's join (LoweringContext::addJoinArm).
bool predReadable(LoweringContext &, const Pred &);
// cq-jws5r (rule 8: a purely classical condition is a classical branch): the i1 of a predicate with no quantum atom,
// at the builder, its atoms read through their current bindings.
llvm::Value *classicalValue(LoweringContext &, const Pred &);
void lowerPhase(LoweringContext &, llvm::CallInst &cqPhi);
}
