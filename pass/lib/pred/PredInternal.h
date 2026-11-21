// Module pred (cq-w0-pred), private: the storage behind Pred and PathPredicates (K1) and the pieces of
// the construction that do not need a LoweringContext, so tests/pred/ can drive them directly.
//
// Atoms. A Pred is a BDD over atoms. Three kinds:
//   Cond   Pred::atom(v): an i1 value of the input IR, quantum iff taint says v is quantum.
//   Eq     Pred::eqAtom(s, v) (A3): s == v, a switch case. Quantum iff s is.
//   Entry  the block predicate a _ctl clone receives as its first parameter (a value of the new IR).
//   Addr   a computed goto's case (rule 13, b137e75): address v == blockaddress(bb). Quantum iff v is.
// "Quantum-like" = needs a rail: quantum Cond, Eq and Addr atoms, every Entry atom. Rule 8 (a46894a, freeze
// cq-6yb): a predicate factors on its Boolean function as C & Q; C (classicalFactor) is a classical
// branch, a classical atom left in Q is a seed rail of the one flag.
#pragma once

#include <functional>
#include <memory>
#include <optional>
#include <type_traits>
#include <map>
#include <tuple>
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
  std::optional<Pred> assumed;   // PathPredicates::assume
  Pred assumedClassical = Pred::top();
  unsigned assumedId = 0;
  std::map<std::tuple<unsigned, const llvm::BasicBlock *, const llvm::BasicBlock *>, Pred> underAssumed;
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

enum class AtomKind : uint8_t { Cond, Eq, Entry, Addr };
struct Atom { AtomKind kind; const llvm::Value *v; llvm::APInt c; const llvm::BasicBlock *bb = nullptr; };

unsigned atomVar(AtomKind, const llvm::Value *, const llvm::APInt &c = llvm::APInt());
// Rule 13: the Addr atom `address == blockaddress(dest)`.
unsigned addrVar(const llvm::Value *address, const llvm::BasicBlock *dest);
const Atom &atomOf(unsigned var);
// Two case atoms of one switch (computed goto) on different cases: never both true.
bool exclusiveAtoms(const Atom &, const Atom &);
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

// Rule 9's select tree. Given each arm's predicate (in preference order), the selects to emit, root at
// index 0. A node with arm >= 0 is that arm's value; otherwise it selects on cond (relative to the
// context of the node) between thenIdx and elseIdx. Built greedily: a chain step takes the first arm
// one literal separates in the current context, so nested arms nest (158) and an if/else chain is
// single compares (104); when no arm is separable, a literal that splits the arms into two groups is
// selected on with a tree per group (two-sided nested arms, cq-95k8), so each select tests one
// literal and there is one select per distinct arm less one. Only when neither exists does a node
// test a compound condition. An arm unreachable in its context is dropped; the complement arm of
// each context is innermost.
struct SelectNode {
  unsigned cond;
  int arm;
  int thenIdx, elseIdx;
};
std::vector<SelectNode> selectTree(llvm::ArrayRef<unsigned> armNodes);

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
  // The free is the last thing a bracketed flag emits, after every bracket closed; it is noted as a
  // use of every rail in `held` (each recorded control rail of the flag's gates), so the uncompute
  // spine places no item of theirs, nor any item ordered after one, inside a bracket (cq-nogu).
  virtual llvm::Value *scratch0() = 0;
  virtual void rawGate(abi::Core op, llvm::ArrayRef<llvm::Value *> controls, llvm::Value *target) = 0;
  virtual void freeScratch(llvm::Value *t, llvm::ArrayRef<llvm::Value *> held) = 0;
  // Decision (1) on cq-su3p (NORTHSTAR p2, CR rule 3; 113): the flag for NOT v, v a quantum-like
  // atom, is an existing live i1 rail holding that Boolean function when there is one (the rail of
  // xor v, true / icmp eq v, false), so no fresh rail is minted. nullptr: mint as usual.
  virtual llvm::Value *liveNegation(unsigned var) { return nullptr; }
};
llvm::Value *materialize(unsigned node, GateSink &, const std::function<bool(unsigned)> &quantumLikeVar);
// Rule 8's X bracket inside a compound flag (cq-rdux, 137). The flag's gates take a negated
// quantum-like atom as a literal control: not_i1 on the atom's rail before the first gate that reads
// it negated, not_i1 again after the last. When some gate of f's decomposition has such a control,
// emits: every control rail (literal atoms; sub-flags through materialize, recorded), a scratch |0>
// rail t, the gates into t (fewest negated controls first, brackets opened as needed), use(t), the
// same gates in reverse, the closing brackets, free(t) holding every control rail until it (so no
// uncompute item lands inside a bracket); and returns true. t and the bracket are not recorded. Otherwise emits nothing and returns false (the ordinary flag applies).
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
  // cq-88vg: a fresh rail holding a basis copy of the rail h (cqrt_alloc_<W>(0), copy_<W>(h, f)),
  // recorded as a seed with its copy, at the builder's insertion point.
  virtual llvm::Value *copy(llvm::Value *h, RailType) = 0;
  // cq-pfpy: op, the value of phi's incoming edge from u read at the builder (where that edge's output
  // block ends), carried there when it is minted where it does not reach (an arm the walk ran on a
  // classical path that joins the edge's path above it). Identity by default.
  virtual Operand reaching(const Operand &op, RailType, const llvm::PHINode &, const llvm::BasicBlock *u) { return op; }
  // cq-pfpy: the value of phi on the output edge P -> join when the output CFG does not reach the join
  // through exactly its incoming edges' blocks: the incoming the edge's classical facts choose (several:
  // a classical select on their edge predicates), read at the builder (P's end).
  virtual Operand edgeChoice(llvm::PHINode &phi, llvm::BasicBlock *P, llvm::BasicBlock *join, RailType,
                             llvm::Type *fieldTy, const std::function<Operand(const llvm::Value *)> &read) {
    internalError("pred: a merge sink with no output CFG to choose an edge's incoming in", &phi);
  }
};
// The select's condition must be classical in the new IR (internal error otherwise).
llvm::Value *classicalSelect(llvm::SelectInst &, llvm::IRBuilder<> &, MergeSink &);
// For a phi at a classically chosen join whose output block is `join`: outOf(u) is the output block
// carrying the original edge u -> phi's block, for each reachable incoming block u (null when u is
// unreachable). The output CFG must already route every such edge into `join` and nothing else.
llvm::Value *classicalPhi(llvm::PHINode &, llvm::BasicBlock *join, llvm::IRBuilder<> &,
                          const std::function<llvm::BasicBlock *(const llvm::BasicBlock *)> &outOf, MergeSink &);
// classicalPhi over one field of a composite phi (rule 26): `read` gives an incoming value's field at the
// builder, w its rail type (used only to seed a classical field beside a rail) and fieldTy its type.
// seedClassical false: a field classical on every edge stays classical (the result's handle bit says).
Operand classicalPhiOf(llvm::PHINode &, llvm::BasicBlock *join, llvm::IRBuilder<> &,
                       const std::function<llvm::BasicBlock *(const llvm::BasicBlock *)> &outOf, MergeSink &,
                       RailType w, llvm::Type *fieldTy, const std::function<Operand(const llvm::Value *)> &read,
                       bool seedClassical);

// The output-IR half of GateSink::liveNegation. An existing rail of the output function that holds
// NOT a (a the value of the i1 rail `atom`) at the insertion point (bb, pt): the result of a forward
// template xor_i1(atom, true), icmp_eq_i1(atom, false) or icmp_ne_i1(atom, true) that
//   - lies in bb before pt, or in a block from which bb is reached through a chain of blocks each with
//     a single predecessor (so it runs, once, before pt on every path to pt);
//   - is not resolved: no cqrt_free of it and no _unc whose result operand it is, anywhere;
//   - still holds its value at pt: between it and pt no call writes it or the atom (a target of Ry,
//     copy, xorc, and/or/xor_i1, a measurement, a free, a clone or any call pred does not know), except
//     an even number of not_i1 on the atom (rule 8's X brackets, closed). Templates and diagonal gates
//     (rz) only read.
// nullptr when there is none.
llvm::Value *liveNegationAt(llvm::Value *atom, llvm::BasicBlock *bb, llvm::BasicBlock::iterator pt);

// Rule 8's X bracket: when f is the negation of one positive quantum-like atom, that atom's variable.
std::optional<unsigned> negatedAtom(unsigned f, const std::function<bool(unsigned)> &quantumLikeVar);

} // namespace pred_detail
} // namespace cq
