// Module pred (cq-w0-pred), private: the storage behind Pred and PathPredicates (K1) and the pieces of
// the construction that do not need a LoweringContext, so tests/pred/ can drive them directly.
//
// Atoms. A Pred is a BDD over atoms. Three kinds:
//   Cond   Pred::atom(v): an i1 value of the input IR, quantum iff taint says v is quantum.
//   Eq     Pred::eqAtom(s, v) (A3): s == v, a switch case. Quantum iff s is.
//   Entry  the block predicate a _ctl clone receives as its first parameter (a value of the new IR).
// "Quantum-like" = needs a rail: quantum Cond and Eq atoms, every Entry atom. Rule 8 (a46894a, freeze
// cq-6yb): a predicate factors on its Boolean function as C & Q; C (classicalFactor) is a classical
// branch, a classical atom left in Q is a seed rail of the one flag.
#pragma once

#include <functional>
#include <memory>
#include <optional>
#include <type_traits>
#include <map>
#include <utility>
#include <vector>

#include "Bdd.h"
#include "cq/Abi.h"
#include "cq/Predicate.h"
#include "cq/Switch.h"
#include "llvm/ADT/APInt.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

namespace llvm { class LoopInfo; }

namespace cq {

// K1 storage. Pred::Impl and PathPredicates::Impl are private nested types of frozen headers, so the
// module's free functions reach them through the accessors below. They are obtained once, by the
// explicit-instantiation rule (access is not checked in the arguments of an explicit instantiation),
// and used only inside pass/lib/pred/ and tests/pred/.
struct Pred::Impl {
  unsigned n;
};

struct PathPredicates::Impl {
  const llvm::Function *F = nullptr;
  llvm::DenseMap<const llvm::BasicBlock *, Pred> blocks;
  std::map<std::pair<const llvm::BasicBlock *, const llvm::BasicBlock *>, Pred> edges;
  llvm::DenseMap<const llvm::BasicBlock *, unsigned> rpo;   // reachable blocks only
  llvm::DenseSet<const llvm::BasicBlock *> loopHeaders;
  llvm::Value *entryFlag = nullptr;
};

namespace pred_detail {
template <typename Tag, auto M> struct Grant { friend auto member(Tag) { return M; } };
struct PredTag { friend auto member(PredTag); };
struct PathTag { friend auto member(PathTag); };
template struct Grant<PredTag, &Pred::impl>;
template struct Grant<PathTag, &PathPredicates::impl>;

using PredStorage = std::remove_cv_t<typename std::decay_t<decltype(std::declval<Pred &>().*member(PredTag{}))>::element_type>;
using PathStorage = typename std::decay_t<decltype(std::declval<PathPredicates &>().*member(PathTag{}))>::element_type;

unsigned nodeOf(const Pred &p);          // internalError on a Pred never initialised
Pred makePred(unsigned node);
PathStorage &storage(PathPredicates &pp);
} // namespace pred_detail

namespace pred_detail {

enum class AtomKind : uint8_t { Cond, Eq, Entry };
struct Atom { AtomKind kind; const llvm::Value *v; llvm::APInt c; };

unsigned atomVar(AtomKind, const llvm::Value *, const llvm::APInt &c = llvm::APInt());
const Atom &atomOf(unsigned var);
std::string describe(unsigned node);   // the formula with atoms named by their IR values

// What compute() asks of taint. The production oracle forwards to TaintInfo for one Specialization
// and to sw::switchEdges; tests substitute their own.
class Oracle {
public:
  virtual ~Oracle() = default;
  virtual bool isQuantum(const llvm::Value *) = 0;
  virtual bool controlTainted(const llvm::BasicBlock *) = 0;
  // Is the block a dead end (no return reachable from it)? Taint's one definition (taint/DeadEnd.h,
  // cq-820w): an edge into a dead end does not restrict its siblings.
  virtual bool deadEnd(const llvm::BasicBlock *) = 0;
  virtual EdgePreds switchEdges(const llvm::SwitchInst &) = 0;
};
std::unique_ptr<Oracle> taintOracle(const TaintInfo &, const Specialization &);

// Does the variable need a rail?
bool quantumLike(unsigned var, Oracle &);
// The Pred of a branch condition. A classical condition is one atom. A quantum one is expanded
// through and/or/xor/select on i1 into its leaves (each an atom, classical or quantum), so rule 8's
// factoring sees the Boolean function, not -O1's spelling.
unsigned condNode(const llvm::Value *cond, Oracle &);
// Rule 8's factoring: f == classicalFactorNode(f) & quantumPartNode(f). The classical factor is the
// conjunction of every classical literal f implies; the quantum part is f cofactored on them.
unsigned classicalFactorNode(unsigned f, Oracle &);
unsigned quantumPartNode(unsigned f, Oracle &);
bool isClassicalNode(unsigned f, Oracle &);

void computePaths(PathStorage &, llvm::Function &, const llvm::LoopInfo &, Oracle &,
                  llvm::Value *entryFlag);

// Rule 9's chain. Given each arm's predicate (in preference order), the conditions the selects test,
// outermost first: result[i] = (condition relative to the arms not yet taken, arm index). Arms are
// taken greedily: next is the first remaining arm one literal separates in the current context, so
// nested arms nest (158) and an if/else chain is single compares (104). An arm unreachable in its
// context is dropped; the last entry's condition is true (the complement arm, innermost).
std::vector<std::pair<unsigned, unsigned>> chainConditions(llvm::ArrayRef<unsigned> armNodes);

// Flag synthesis (rule 8). The flag for f is a positive rail holding f: an existing rail when f is one
// positive quantum-like atom, otherwise a fresh |0> rail t that receives XOR-into-t gates only
// (xor_i1, and_i1, or_i1 with t as target, not_i1 on t). Such gates commute with one another, so
// replaying them in any order (the uncompute flush) returns t to |0>. A classical sub-function becomes
// one seed rail.
class GateSink {
public:
  virtual ~GateSink() = default;
  virtual llvm::Value *atomRail(unsigned var) = 0;        // a quantum-like atom's positive rail
  virtual llvm::Value *classicalSeed(unsigned node) = 0;  // a seed rail holding a classical node
  virtual llvm::Value *alloc0() = 0;                      // a fresh |0> i1 rail, recorded as a seed
  // target ^= op(controls): XorI1 (1 control), AndI1/OrI1 (2), NotI1 (0); recorded against target.
  virtual void gate(abi::Core op, llvm::ArrayRef<llvm::Value *> controls, llvm::Value *target) = 0;
  // For bracketedFlag, emitted and NOT recorded (the caller undoes them itself, CR §5 balanced where
  // emitted): a fresh |0> i1 rail, an XOR-type gate (not_i1 on an atom rail for a bracket), its free.
  virtual llvm::Value *scratch0() = 0;
  virtual void rawGate(abi::Core op, llvm::ArrayRef<llvm::Value *> controls, llvm::Value *target) = 0;
  virtual void freeScratch(llvm::Value *t) = 0;
};
llvm::Value *materialize(unsigned node, GateSink &, const std::function<bool(unsigned)> &quantumLikeVar);
// Rule 8's X bracket inside a compound flag (cq-rdux, 137). The flag's gates take a negated
// quantum-like atom as a literal control: not_i1 on the atom's rail before the first gate that reads
// it negated, not_i1 again after the last. When some gate of f's decomposition has such a control,
// emits: every control rail (literal atoms; sub-flags through materialize, recorded), a scratch |0>
// rail t, the gates into t (fewest negated controls first, brackets opened as needed), use(t), the
// same gates in reverse, the closing brackets, free(t); and returns true. t and the bracket are not
// recorded. Otherwise emits nothing and returns false (the ordinary flag applies).
bool bracketedFlag(unsigned node, GateSink &, const std::function<bool(unsigned)> &quantumLikeVar,
                   const std::function<void(llvm::Value *)> &use);

// Rule 9 at CQ_spec a58c3a4 (owner ruling on cq-mtt): a select or phi whose condition, or choice of
// incoming edge, is purely classical is a classical select/phi over the handles, with no gate, like a
// classical branch. A classical arm is seeded onto a rail (a phi's on its incoming edge, before that
// edge's branch: 128), the merged handle is recorded with Uncompute::recordMerge (U1) before any
// consumer reads it, and each arm's rails are computed and uncomputed as usual (uncompute's alias).
// What the lowering needs from the spine and uncompute, behind a sink so tests drive it directly.
class MergeSink {
public:
  virtual ~MergeSink() = default;
  virtual Operand operand(const llvm::Value *orig) = 0;   // read with the builder where it is used
  // A fresh rail holding a classical value, recorded as a seed, at the builder's insertion point.
  virtual llvm::Value *seed(llvm::Value *classical, RailType) = 0;
  virtual void merged(llvm::Instruction *m) = 0;            // Uncompute::recordMerge
};
// The select's condition must be classical in the new IR (internal error otherwise).
llvm::Value *classicalSelect(llvm::SelectInst &, llvm::IRBuilder<> &, MergeSink &);
// For a phi at a classically chosen join whose output block is `join`: outOf(u) is the output block
// carrying the original edge u -> phi's block, for each reachable incoming block u (null when u is
// unreachable). The output CFG must already route every such edge into `join` and nothing else.
llvm::Value *classicalPhi(llvm::PHINode &, llvm::BasicBlock *join, llvm::IRBuilder<> &,
                          const std::function<llvm::BasicBlock *(const llvm::BasicBlock *)> &outOf, MergeSink &);

// Rule 8's X bracket: when f is the negation of one positive quantum-like atom, that atom's variable.
std::optional<unsigned> negatedAtom(unsigned f, const std::function<bool(unsigned)> &quantumLikeVar);

} // namespace pred_detail
} // namespace cq
