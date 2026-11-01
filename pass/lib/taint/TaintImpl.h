// Private to module taint (cq-w0-taint). The storage behind TaintInfo (K1) and the analysis state.
//
// Lattice. Every SSA value carries a lane vector (Lanes): an integer leaf of width W has
// max(1, ceil(W/8)) byte lanes, a floating-point leaf one lane, a pointer leaf two lanes (tag, idx:
// rule 21), aggregates and vectors the concatenation of their leaves. A lane is 1 iff that part of the
// value depends on a cq_theta result (rule 3). Byte lanes are what lets an ABI-coerced struct
// (159: { int, int } as i64) keep one taint bit per field through zext/shl/or/lshr/trunc packing.
//
// Pointers carry, besides their two lanes, a PtrInfo: the memory sites they may point into and their
// byte offset from the site's base as the lattice (c, g): offset = c + k*g for unknown k (g = 0: exact).
//
// The whole module is iterated to one fixed point (specializations, memory, provenance); computeTaint
// is a pure function of the module: every piece of state lives in one Impl it builds from scratch.
#pragma once

#include <deque>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <vector>

#include "DeadEnd.h"
#include "cq/Taint.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallBitVector.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"

namespace cq::taintimpl {

using Lanes = llvm::SmallBitVector;

// Offset lattice of a pointer relative to its site's base (bytes).
struct PtrInfo {
  llvm::SmallVector<unsigned, 2> sites; // sorted, unique
  bool init = false;                     // false: no information yet (bottom)
  bool top = false;                      // offset entirely unknown
  int64_t c = 0;
  uint64_t g = 0;
  std::optional<int64_t> exact() const {
    if (!init || top || g != 0)
      return std::nullopt;
    return c;
  }
  std::optional<int64_t> mod(uint64_t stride) const;
  bool join(const PtrInfo &o); // returns true if changed
  bool sameOffset(const PtrInfo &o) const;
};

enum class SiteKind : uint8_t { Alloca, Global, Heap, External, Function };

// A memory site: an alloca, a global, a heap allocation call, an external (unknown) object, or a
// function (function pointers are pointers to function sites).
struct Site {
  SiteKind kind;
  const llvm::Value *v;            // the alloca/global/call/argument/load that names it
  const llvm::Function *owner;     // function of an alloca/heap call/external, else null
  uint64_t stride = 0;             // array-of-struct element size: one object per field column
  llvm::SmallVector<int64_t, 4> columns; // field byte offsets within the stride (when stride != 0)
  llvm::SmallVector<ObjectId, 4> objects; // one object, or one per column
};

struct Range {
  int64_t off;
  uint64_t size;
};

struct Object {
  unsigned site;
  int column = -1;                // index into Site::columns, -1 when the site is not split
  bool anyHandle = false;          // a handle written at an unknown cell
  std::vector<Range> handleCells;  // cells (byte ranges from the site base) written with a handle
  std::vector<Range> ptrCells;     // cells written with a pointer (pointer-kind cells)
  bool anyPtr = false;
  // cq-n58p, cq-0y74, cq-kuuf: cells written by a non-pointer store whose value may carry an address
  // (an integer, a byte of a pointer): a pointer read there has lost its provenance.
  std::vector<Range> intCells;
  bool anyInt = false;
  bool qram = false;
  bool storedTagQ = false, storedIdxQ = false;
  PtrInfo stored;                  // pointers copied in (initializer, memcpy)
  std::map<const llvm::Instruction *, PtrInfo> storedBy; // pointers stored by each store
  bool cellHandle(std::optional<int64_t> off, uint64_t size) const;
  bool mayHoldHandle() const { return qram || anyHandle || !handleCells.empty(); }
};

struct FnInfo {
  std::unique_ptr<llvm::DominatorTree> DT;
  std::unique_ptr<llvm::PostDominatorTree> PDT;
  std::unique_ptr<llvm::LoopInfo> LI;
  // Direct control dependence: block -> the branching blocks it is control dependent on. An edge into
  // a dead end does not restrict its siblings (cq-820w, rule 16): a block that reaches a return is
  // control dependent on A only through A's successors that reach a return too.
  cq::taint_detail::DeadEnds dead;
  llvm::DenseMap<const llvm::BasicBlock *, llvm::SmallVector<const llvm::BasicBlock *, 2>> cdParents;
  std::vector<const llvm::BasicBlock *> rpo;
  // cq-z6q1: per (loop header, exiting block), whether SCEV computes the exit's count (exitCountKnown).
  std::map<std::pair<const llvm::BasicBlock *, const llvm::BasicBlock *>, bool> exitKnown;
  // cq-bxc4: per join J, per predecessor P, the branching blocks the edge P -> J is (transitively)
  // control dependent on within the paths that end in J (Analyzer::joinEdgeCD). Structural only.
  llvm::DenseMap<const llvm::BasicBlock *,
                 llvm::DenseMap<const llvm::BasicBlock *, llvm::SmallVector<const llvm::BasicBlock *, 4>>>
      joinEdgeCD;
};

// Rule 23 environment state (cq-pu8b). Two facts: MODE (the rounding mode is a rail) and FLAGS (the
// exception-flags rail is not empty), each a may-fact joined by OR over predecessors and callers.
// Within a specialization a state is symbolic over its entry state E: one nibble per fact (low nibble
// MODE, high nibble FLAGS), bit 0 "set", bit 1 "if E's MODE", bit 2 "if E's FLAGS". The fact holds
// iff bit 0, or bit 1 and E has MODE, or bit 2 and E has FLAGS. Concrete states are two bits
// (1 MODE, 2 FLAGS). Join is bitwise OR in both encodings.
namespace fenvstate {
constexpr uint8_t kIdentity = 0x42;                 // MODE := E.MODE, FLAGS := E.FLAGS
inline uint8_t nib(uint8_t s, unsigned k) { return (s >> (4 * k)) & 0xF; }
inline uint8_t withNib(uint8_t s, unsigned k, uint8_t n) {
  return uint8_t((s & ~(0xF << (4 * k))) | ((n & 0xF) << (4 * k)));
}
inline uint8_t eval(uint8_t s, uint8_t E) {
  uint8_t r = 0;
  for (unsigned k = 0; k < 2; ++k) {
    uint8_t n = nib(s, k);
    if ((n & 1) || ((n & 2) && (E & 1)) || ((n & 4) && (E & 2)))
      r |= uint8_t(1u << k);
  }
  return r;
}
// The callee's exit state X (symbolic over the callee's entry) after the caller's state Y.
inline uint8_t compose(uint8_t X, uint8_t Y) {
  uint8_t r = 0;
  for (unsigned k = 0; k < 2; ++k) {
    uint8_t n = nib(X, k), o = n & 1;
    if (n & 2)
      o |= nib(Y, 0);
    if (n & 4)
      o |= nib(Y, 1);
    r = withNib(r, k, o);
  }
  return r;
}
} // namespace fenvstate

struct SpecState {
  llvm::Function *F = nullptr;
  bool ctl = false, pure = false, adj = false;
  unsigned depth = 0;
  std::vector<uint64_t> bounds;
  bool declared = false; // rule 27: F has no body
  bool inPlace = false;  // all-classical, no flags: the function rewritten in place
  std::vector<Lanes> formal;     // fixed formals, then the variadic actuals of this arity
  std::vector<llvm::Type *> formalTy;
  std::vector<std::string> cells; // per formal: the pointee-cell digits at the call (pointer formals)
  std::vector<PtrInfo> formalPtr; // pointer formals: union of the callers' actuals
  // T4: per formal, how a pointer formal crosses (buildMask); mixedPointee: objects of several classes.
  std::vector<cq::PtrFormal> ptrFormal;
  std::vector<bool> mixedPointee;
  std::string key;
  unsigned depthCut = 0;          // cutoff min(K, B) of a quantum-depth recursion, 0 = none
  std::optional<uint64_t> depthB; // B of the outermost call (rule 14)
  bool depthBUnknown = false;

  llvm::DenseMap<const llvm::Value *, Lanes> lanes;
  llvm::DenseMap<const llvm::Value *, PtrInfo> ptr;
  llvm::DenseMap<const llvm::BasicBlock *, llvm::SmallVector<const llvm::BasicBlock *, 2>> cdt;
  llvm::DenseSet<const llvm::BasicBlock *> taintedTerm;
  // Loops whose next trip is decided by a tainted terminator (rule 14; grows monotonically).
  llvm::SmallPtrSet<const llvm::Loop *, 4> exitQ;
  Lanes ret;
  PtrInfo retPtr;
  bool analyzedOnce = false;

  bool hasTheta = false, hasPhi = false, hasEffect = false, writesOuter = false, hasMeasure = false;
  bool anyQuantum = false;
  // Rule 23 (cq-pu8b): the floating-point environment as point-wise state (see FenvState below).
  // fenvIn is concrete (the join of every caller's state at its call; 0 for a root), every other
  // state symbolic over it.
  uint8_t fenvIn = 0;
  llvm::DenseMap<const llvm::BasicBlock *, uint8_t> fenvOut; // state at the end of each block
  uint8_t fenvExit = 0;    // join of the states at the returns
  uint8_t fenvWrites = 0;  // facts this specialization (with its callees) may change: 1 mode, 2 flags
  // State before and after each instruction that reads or changes the environment (the dump).
  llvm::DenseMap<const llvm::Instruction *, std::pair<uint8_t, uint8_t>> fenvAt;
  llvm::DenseMap<const llvm::CallBase *, llvm::SmallVector<SpecState *, 2>> callees;
  llvm::DenseSet<const llvm::CallBase *> cutCalls; // depth-recursion calls replaced by |0>

  // Post-fixpoint.
  bool reachable = false;
  bool needsTwin = false;
  bool effectful = false; // transitively: phase, tape, abort (what a twin must not replay)
  bool nonPure = false;   // transitively: rotation, phase, outer store, tape (rule 19 _ctl test)
  std::string mask;
  std::string name;
};

struct LookupKey; // fwd

struct ImplState {
  llvm::Module *M = nullptr;
  const llvm::DataLayout *DL = nullptr;
  TaintOptions opts;
  std::unique_ptr<llvm::TargetLibraryInfoImpl> TLII;
  std::unique_ptr<llvm::TargetLibraryInfo> TLI;

  std::vector<Site> sites;
  llvm::DenseMap<const llvm::Value *, unsigned> siteOf;
  std::vector<Object> objects;

  std::vector<std::unique_ptr<SpecState>> specs;
  std::map<std::string, SpecState *> byKey;
  std::map<const llvm::Function *, std::unique_ptr<FnInfo>> fns;
  llvm::DenseMap<llvm::Type *, unsigned> laneCount;
  bool changed = false;
  bool longjmpUnderQuantum = false;
  // Rule 23: the concrete environment facts saved into each fenv_t / fexcept_t object (fegetenv,
  // feholdexcept, fegetexceptflag), joined over every save; an object never saved holds none.
  std::map<ObjectId, uint8_t> fenvSaved;
  // cq-n58p: every site whose address escaped into memory or into an integer (a pointer stored, a
  // ptrtoint, a pointer in a global initializer). A pointer whose provenance is lost (inttoptr of an
  // integer not derived from one ptrtoint, a pointer read from a cell written as an integer) may point
  // into any of them (offset unknown).
  PtrInfo escaped;

  // Published result.
  std::vector<Specialization> published;
  std::vector<SpecState *> publishedState;
  llvm::DenseSet<const llvm::Function *> tainted;
  std::deque<std::vector<ObjectId>> provCache; // stable storage behind provenance()
};

} // namespace cq::taintimpl
