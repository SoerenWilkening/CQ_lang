// Module uncompute (cq-w0-uncompute): the uncompute spine, CR rules 5, 6 and 7.
//
// References (Bennett.jl 824458d, read at these lines):
//  - src/bennett_transform.jl:_bennett_default (lines 337-381): forward, copy-out, then every forward
//    gate replayed in reverse order. Whole-program reverse order is one valid reverse dependency order.
//  - src/pebble/value_eager.jl:_value_eager_bennett_impl (lines 1-174): a value's gates are reversed
//    as a unit only once every consumer's reversal is done (Kahn over consumer counts, lines 141-171).
//    This is rule 5's "an operand rail outlives every _unc that reads it", our readers-first order.
//    Its dead-end cleanup during the forward pass (lines 111-126) is the as-early-as-allowed
//    convention. Lines 31-39 make an in-place overwrite unsafe when an earlier reader replays after
//    it. Here that is the write barrier: the reader's _unc goes before the write, or it is unimplemented.
//    It differs where CR's roles do: Bennett.jl uncomputes every value after copy-out, but a CQ rail
//    with a kept role (user register, measured, result) is never uncomputed, so its sources may go
//    right after their last use (14, 42).
//  - src/bennett_transform.jl:bennett_direct (lines 383-425) is the forward-only path for
//    self-reversing primitives. It does no uncompute and is not a reference for this module.
//  - Kept-entangled (A4) has no counterpart: Bennett.jl and BennettVM.jl are classical reversible,
//    with no non-diagonal gate. It rests on CR §0, rule 5's scheduling invariant and rule 10 alone.
//
// CONTRACT (what the callers of Uncompute.h may rely on; the header is frozen, so it is stated here)
//
// Recording. Nothing is emitted while recording.
//  - recordTemplate(fwd, spec, ops): fwd is the forward cq_template_* call, already in the IR; ops is
//    exactly fwd's argument list (checked operand by operand). The result is a new rail, Role::Garbage.
//  - recordSeed(alloc): a cqrt_alloc_<W> call; a new rail, Role::Seed (rule 7).
//  - recordCore(fwd, spec, ops, out): a reversible core gate, ops = fwd's argument list.
//      in place on the rail `out` (out must be fwd's target operand): copy, xorc, not_i1, and_i1, or_i1,
//        xor_i1 (involutions: undone by the same call, BACKEND_ABI §1.8, §1.9) and qram_store (undone by
//        its _unc, popped last-in-first-out because a rail's records are undone in reverse order);
//      with a fresh result (`out` is ignored, the new rail's id is returned): qram_load (Role::Garbage,
//        undone by its _unc(h, args...)), qram_alloc (Role::Seed, released by cqrt_qram_free), alloc
//        (= recordSeed). Any other core gate is not reversible and is an internal error here.
//  - recordExternal(h, role): a rail with no producer (a formal, a clone's result, a loaded slot cell).
//  - setRole: Garbage and Seed are resolvable; every other role is kept (never _unc'd, never freed).
//    A Seed whose only writes are uncontrolled xorc is freed directly; a Seed with other writes is
//    undone write by write, then freed.
//  - noteUse(r, i): i reads r without being an IR user of r's handle (e.g. a load of a slot cell that
//    holds r). IR users of the handle are uses automatically.
//  - noteNonDiagonal(x, g): g is a non-diagonal gate on x (Ry, a quantum-angle Ry; the caller decides,
//    a computational-basis measurement is not one: 42). It is a barrier for every _unc that needs x.
//  - cleanupBijective(old, inverse, ops): rule 6. Instead of its producer's _unc, `old` is cleaned by
//    t = inverse(ops); copy_<W>(t, old); inverse_unc(t, ops); free t; free old. It overrides old's
//    role. ops are the inverse template's forward operands.
//  - recordMerge(m) (U1, CR rule 9 at a58c3a4): m is a classical select (condition not a rail) or a
//    complete phi (one incoming per predecessor) whose every value operand is a recorded rail or
//    merge, none freed. m's handle becomes a MERGE: idOf(m) answers, and it may be an operand of any
//    record, noteUse and setRole. A merge names one of its arms at run time, so:
//      * it is never resolved itself: no _unc, no cqrt_free, never live at exit as a rail of its own;
//      * a use of m (an IR user of m's handle, a noted use, a record reading m, a rule 6 clean-up
//        reading m) is a use of every arm it may name, transitively through nested merges: every
//        arm's item comes after it, and after the item of every rail whose record reads m;
//      * a barrier on an arm (an in-place write, a noted non-diagonal gate) binds every item that
//        reads m;
//      * its role stays Garbage, or a kept role that changes nothing: setRole(m, kept) is accepted
//        only when every arm it may name is already kept (135's spelling: each arm copied out into a
//        Result rail inside its own arm). Otherwise it is an internal error. Keeping every arm
//        would keep the unchosen arm as garbage (an extra kept rail: §6-different, and CR §0's
//        garbage policy), and keeping only the chosen one is path-dependent, which no static role
//        says. A consumer that needs the merged value kept (measure, escape, result, a rotation,
//        any in-place write) copies it out first: f = cqrt_alloc_<W>(0) (recordSeed),
//        cqrt_copy_<W>(m, f) (recordCore Copy, out f), then uses and keeps f. The copy reads m,
//        so every arm is uncomputed after it (compute-copy-uncompute).
//      * noteNonDiagonal(m) and recordCore with m as the written rail are unimplemented (copy out
//        first); cleanupBijective(m) is an internal error; Role::Seed on m is an internal error.
//      * an arm whose definition does not dominate the return where it would be resolved (a phi
//        over arm-local garbage handles) is unimplemented (cq-ut4k).
//
// Emission. Each resolvable rail g is resolved once, as one ITEM: its records undone in reverse
// (or its rule 6 clean-up, or nothing for a direct seed free), then cqrt_free / cqrt_qram_free.
//  - Order (rule 5): the item of g comes after every use of g and after the item of every rail whose
//    item reads g (an operand outlives every _unc that reads it); a batch is emitted readers first.
//  - Placement: as early as these allow (the corpus convention), i.e. right after the last of them.
//  - Invariant (rule 5): every rail an item reads must still hold the value its record read. A noted
//    non-diagonal gate on such a rail (or on g itself) after the record and before the earliest
//    placement makes g Role::KeptEntangled (amendment A4: never freed, live at exit). An in-place
//    recorded write in the same position is an internal "unimplemented".
//  - flushBefore(P): resolves the pending rails defined in P's block whose every use and record is a
//    call in that block before P. Contract: after it, no further use of such a rail is noted.
//  - flushAtExit(R): resolves every pending rail whose definition dominates R's block. A rail whose
//    every use lies in its defining block is placed there once; otherwise it is placed in R's block
//    (once per return it dominates). A pending rail that reaches R from a block that does not dominate
//    R is an internal error (its arm was not flushed).
//  - emitMirror(scope, B): resolves, at B's insertion point and in reverse dependency order, every
//    pending resolvable rail created by a record of the scope. Its operands are the forward Values;
//    a caller that mirrors outside their dominance region (a reverse loop) remaps the instructions
//    emitted between B's insertion point before and after the call. No barrier check is made.
//  - scopeRecords(s): the records created while s was open (nested scopes included), program order.
//    The ArrayRef is valid until the next record* call. Scopes close last-in-first-out.
//
// Symbols. A _unc is spelled from its forward call: the callee's name + "_unc", arguments
// (out, the forward argument list) for a template or a qram_load, the forward argument list for an
// in-place core gate (CR §1.2, §1.3). Spelling it from the call keeps operand types and literals
// identical to the forward by construction. Rule 6 has no forward call to copy from and declares its
// inverse template and copy through abi::declare.
#include "cq/Uncompute.h"

#include <algorithm>
#include <functional>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq {

namespace {

constexpr unsigned kNone = ~0u;

enum class RecKind : uint8_t {
  Template,  // fresh out, undone by name_unc(out, args...)
  Seed,      // cqrt_alloc: nothing to undo, released by cqrt_free
  QramAlloc, // nothing to undo, released by cqrt_qram_free
  QramLoad,  // fresh out, undone by name_unc(out, args...)
  Involution,// in place on out, undone by the same call
  QramStore, // in place on the object, undone by name_unc(args...)
};

bool isCreator(RecKind k) { return k != RecKind::Involution && k != RecKind::QramStore; }

std::string describe(const Value *v) {
  std::string s;
  raw_string_ostream os(s);
  v->printAsOperand(os, false);
  return os.str();
}

// Rail type of a cqrt_alloc literal (the abi module owns railTypeOf; the seed's spec only records it).
RailType literalRailType(Type *t) {
  if (auto *it = dyn_cast<IntegerType>(t))
    return {Kind::Int, it->getBitWidth()};
  if (t->isHalfTy())
    return {Kind::Fp, 16};
  if (t->isFloatTy())
    return {Kind::Fp, 32};
  if (t->isDoubleTy())
    return {Kind::Fp, 64};
  if (t->isX86_FP80Ty())
    return {Kind::Fp, 80};
  return {Kind::Int, 0};
}

// Result rail type of a template (rule 6's t has it; the copy into old is at that width).
RailType templateResultType(const abi::TemplateSpec &s) {
  StringRef op = s.op;
  if (op == "icmp" || op == "fcmp" || op == "fcmps" || op == "is_fpclass" || op.ends_with("_overflow"))
    return {Kind::Int, 1};
  return s.to ? *s.to : s.w;
}

// Instruction-level "a executes after b" for acyclic regions: same block by order, else reachability.
} // namespace

struct Uncompute::Impl {
  struct RecInfo {
    RecKind kind;
    SmallVector<RailId, 3> reads; // handle operands other than the record's own rail
    bool preserving = false;      // an uncontrolled xorc: a seed stays in a known basis state
  };
  struct Cleanup {
    abi::TemplateSpec inverse;
    SmallVector<Operand, 3> ops;
    SmallVector<RailId, 3> reads;
  };
  struct Rail {
    Value *handle = nullptr;
    Role role = Role::Garbage;
    bool released = false; // resolved for good (placed in its defining block, or mirrored)
    bool qram = false;
    unsigned creator = kNone;
    SmallVector<unsigned, 2> writes;
    SmallVector<Instruction *, 2> uses; // noted, beyond the IR users of handle
    SmallVector<Instruction *, 2> hits; // noted non-diagonal gates
    SmallVector<unsigned, 4> readerRecs; // records with this rail among their reads
    SmallVector<RailId, 2> cleanupReaders; // rails whose rule 6 clean-up reads this rail
    std::optional<Cleanup> cleanup;
    SmallPtrSet<const BasicBlock *, 2> exitsDone; // returns this rail was placed for
    SmallVector<RailId, 2> arms;       // U1: non-empty iff this rail is a merge (its handle aliases one arm)
    SmallVector<RailId, 2> mergedInto; // U1: the merges that name this rail as an arm
  };
  struct Scope {
    unsigned begin, end;
    bool open;
  };

  std::vector<Record> records;
  std::vector<RecInfo> info;
  std::vector<Rail> rails;
  DenseMap<const Value *, RailId> byHandle;
  std::vector<Scope> scopes;
  SmallVector<unsigned, 4> openStack;
  DenseSet<const Instruction *> emitted;
  DenseMap<std::pair<RailId, const BasicBlock *>, Instruction *> itemEnd;

  // ---- recording -------------------------------------------------------------------------------

  Rail &rail(RailId r, const char *who) {
    if (r >= rails.size())
      internalError(std::string("uncompute: ") + who + ": no rail #" + std::to_string(r));
    return rails[r];
  }

  RailId lookup(const Value *h, const char *who, const Value *at) const {
    auto it = byHandle.find(h);
    if (it == byHandle.end())
      internalError(std::string("uncompute: ") + who + ": " + describe(h) + " is not a recorded rail", at);
    return it->second;
  }

  // ---- merges (U1) ------------------------------------------------------------------------------

  bool isMerge(RailId g) const { return !rails[g].arms.empty(); }

  bool isMergeHandle(const Value *v) const {
    auto it = byHandle.find(v);
    return it != byHandle.end() && isMerge(it->second);
  }

  static bool keptRole(Role r) { return r != Role::Garbage && r != Role::Seed; }

  // g and every merge that may name it (transitively), g first.
  SmallVector<RailId, 4> names(RailId g) const {
    SmallVector<RailId, 4> out{g};
    for (unsigned i = 0; i < out.size(); ++i)
      for (RailId m : rails[out[i]].mergedInto)
        if (!is_contained(out, m))
          out.push_back(m);
    return out;
  }

  // The rails a handle may name at run time: g itself, or a merge's arms down to non-merge rails.
  SmallVector<RailId, 4> leaves(RailId g) const {
    SmallVector<RailId, 4> out, work{g}, seen;
    while (!work.empty()) {
      RailId x = work.pop_back_val();
      if (is_contained(seen, x))
        continue;
      seen.push_back(x);
      if (isMerge(x))
        work.append(rails[x].arms.begin(), rails[x].arms.end());
      else
        out.push_back(x);
    }
    return out;
  }

  bool anyReleased(RailId g) const {
    for (RailId x : leaves(g))
      if (rails[x].released)
        return true;
    return false;
  }

  RailId newRail(Value *h, Role role, const char *who) {
    if (!h->getType()->isIntegerTy(32))
      internalError(std::string("uncompute: ") + who + ": a rail handle is an i32", h);
    if (byHandle.count(h))
      internalError(std::string("uncompute: ") + who + ": handle recorded twice", h);
    RailId id = rails.size();
    rails.emplace_back();
    rails.back().handle = h;
    rails.back().role = role;
    byHandle[h] = id;
    return id;
  }

  void checkOps(CallInst *fwd, ArrayRef<Operand> ops, const char *who) {
    if (!fwd || !fwd->getCalledFunction())
      internalError(std::string("uncompute: ") + who + ": the forward must be a direct call", fwd);
    if (ops.size() != fwd->arg_size())
      internalError(std::string("uncompute: ") + who + ": operand list differs from the forward call", fwd);
    for (unsigned i = 0; i < ops.size(); ++i) {
      if (ops[i].v != fwd->getArgOperand(i))
        internalError(std::string("uncompute: ") + who + ": operand " + std::to_string(i) +
                          " differs from the forward call",
                      fwd);
      if (ops[i].handle) {
        RailId r = lookup(ops[i].v, who, fwd);
        if (anyReleased(r))
          internalError(std::string("uncompute: ") + who + ": operand " + describe(ops[i].v) +
                            " was already uncomputed and freed",
                        fwd);
      }
    }
  }

  unsigned addRecord(CallInst *fwd, std::variant<abi::TemplateSpec, abi::CoreSpec> spec, ArrayRef<Operand> ops,
                     RailId out, RecKind kind, bool preserving) {
    unsigned idx = records.size();
    Record rec{fwd, std::move(spec), SmallVector<Operand, 3>(ops.begin(), ops.end()), out};
    RecInfo ri{kind, {}, preserving};
    for (const Operand &o : ops) {
      if (!o.handle)
        continue;
      RailId r = byHandle.lookup(o.v);
      if (r == out || is_contained(ri.reads, r))
        continue;
      ri.reads.push_back(r);
      rails[r].readerRecs.push_back(idx);
    }
    records.push_back(std::move(rec));
    info.push_back(std::move(ri));
    Rail &o = rails[out];
    if (isCreator(kind))
      o.creator = idx;
    else
      o.writes.push_back(idx);
    return idx;
  }

  // ---- CFG helpers -----------------------------------------------------------------------------

  static bool reaches(const BasicBlock *from, const BasicBlock *to) {
    if (from == to)
      return true;
    SmallPtrSet<const BasicBlock *, 16> seen;
    SmallVector<const BasicBlock *, 16> work{from};
    seen.insert(from);
    while (!work.empty()) {
      const BasicBlock *b = work.pop_back_val();
      const Instruction *t = b->getTerminator();
      if (!t)
        continue;
      for (const BasicBlock *s : successors(t)) {
        if (s == to)
          return true;
        if (seen.insert(s).second)
          work.push_back(s);
      }
    }
    return false;
  }

  // Does d dominate b? (b unreachable from the entry while avoiding d.)
  static bool dominates(const BasicBlock *d, const BasicBlock *b) {
    if (d == b)
      return true;
    const BasicBlock *entry = &b->getParent()->getEntryBlock();
    if (entry == d)
      return true;
    SmallPtrSet<const BasicBlock *, 16> seen;
    SmallVector<const BasicBlock *, 16> work{entry};
    seen.insert(entry);
    while (!work.empty()) {
      const BasicBlock *x = work.pop_back_val();
      if (x == b)
        return false;
      const Instruction *t = x->getTerminator();
      if (!t)
        continue;
      for (const BasicBlock *s : successors(t))
        if (s != d && seen.insert(s).second)
          work.push_back(s);
    }
    return true;
  }

  // a executes after b on some path (acyclic reading).
  static bool after(const Instruction *a, const Instruction *b) {
    if (a->getParent() == b->getParent())
      return b->comesBefore(a);
    return reaches(b->getParent(), a->getParent());
  }

  // ---- items -----------------------------------------------------------------------------------

  bool resolvable(RailId g) const {
    const Rail &r = rails[g];
    return !r.released && r.arms.empty() && (r.cleanup || r.role == Role::Garbage || r.role == Role::Seed);
  }

  bool directRelease(RailId g) const {
    const Rail &r = rails[g];
    if (r.cleanup || r.role != Role::Seed)
      return false;
    for (unsigned w : r.writes)
      if (!info[w].preserving)
        return false;
    return true;
  }

  // Records the item of g undoes, in program order.
  SmallVector<unsigned, 4> undone(RailId g) const {
    SmallVector<unsigned, 4> out;
    const Rail &r = rails[g];
    if (r.cleanup || directRelease(g))
      return out;
    if (r.creator != kNone)
      out.push_back(r.creator);
    out.append(r.writes.begin(), r.writes.end());
    return out;
  }

  SmallVector<RailId, 4> itemReads(RailId g) const {
    const Rail &r = rails[g];
    if (r.cleanup)
      return SmallVector<RailId, 4>(r.cleanup->reads.begin(), r.cleanup->reads.end());
    SmallVector<RailId, 4> out;
    for (unsigned rec : undone(g))
      for (RailId x : info[rec].reads)
        if (x != g && !is_contained(out, x))
          out.push_back(x);
    return out;
  }

  // CR rule 6 ("when the old value is still needed to uncompute other rails, those are uncomputed
  // first"): a clean-up whose inverse reads a garbage rail whose own uncompute reads the cleaned
  // rail cannot run. That garbage is uncomputed first, which leaves no y' to recompute the old
  // value from, so the old rail keeps its role (42: s = y + x is garbage, y stays a register).
  bool garbageReads(RailId x, RailId g, unsigned depth = 0) const {
    if (depth > 64 || rails[x].cleanup || rails[x].role != Role::Garbage || rails[x].released)
      return false;
    for (RailId y : itemReads(x))
      if (y == g || garbageReads(y, g, depth + 1))
        return true;
    return false;
  }
  void pruneCleanups() {
    for (RailId g = 0; g < rails.size(); ++g) {
      Rail &r = rails[g];
      if (!r.cleanup || r.released)
        continue;
      bool drop = false;
      for (RailId x : r.cleanup->reads)
        if (garbageReads(x, g)) {
          drop = true;
          break;
        }
      if (!drop)
        continue;
      for (RailId x : r.cleanup->reads)
        llvm::erase(rails[x].cleanupReaders, g);
      r.cleanup.reset();
    }
  }

  // Rails whose item reads g, directly or through a merge that may name g (U1).
  SmallVector<RailId, 4> readersOf(RailId g) const {
    SmallVector<RailId, 4> ns = names(g);
    SmallVector<RailId, 4> cand;
    for (RailId n : ns) {
      for (unsigned rec : rails[n].readerRecs)
        if (!is_contained(cand, records[rec].out))
          cand.push_back(records[rec].out);
      for (RailId o : rails[n].cleanupReaders)
        if (!is_contained(cand, o))
          cand.push_back(o);
    }
    SmallVector<RailId, 4> out;
    for (RailId o : cand) {
      if (o == g)
        continue;
      SmallVector<RailId, 4> rd = itemReads(o);
      if (any_of(ns, [&](RailId n) { return is_contained(rd, n); }))
        out.push_back(o);
    }
    return out;
  }

  const BasicBlock *defBlock(RailId g) const {
    const Rail &r = rails[g];
    if (r.creator != kNone)
      return records[r.creator].forward->getParent();
    if (auto *i = dyn_cast<Instruction>(r.handle))
      return i->getParent();
    if (auto *a = dyn_cast<Argument>(r.handle))
      return &a->getParent()->getEntryBlock();
    internalError("uncompute: rail handle is neither an instruction nor a formal", r.handle);
  }

  // Every instruction g's item must follow (except the items of readers, added at placement).
  SmallVector<Instruction *, 8> anchors(RailId g) const {
    const Rail &r = rails[g];
    SmallVector<Instruction *, 8> out;
    if (r.creator != kNone)
      out.push_back(records[r.creator].forward);
    for (unsigned w : r.writes)
      out.push_back(records[w].forward);
    // U1: a use of a merge that may name g is a use of g.
    for (RailId n : names(g)) {
      const Rail &rn = rails[n];
      for (User *u : rn.handle->users())
        if (auto *i = dyn_cast<Instruction>(u))
          out.push_back(i);
      out.append(rn.uses.begin(), rn.uses.end());
    }
    return out;
  }

  struct Pos {
    BasicBlock *bb = nullptr;
    Instruction *before = nullptr;
  };

  Pos afterLatest(BasicBlock *bb, ArrayRef<Instruction *> as, RailId g) {
    Instruction *latest = nullptr;
    for (Instruction *a : as)
      if (a->getParent() == bb && (!latest || latest->comesBefore(a)))
        latest = a;
    Instruction *before;
    if (!latest) {
      before = &*bb->getFirstInsertionPt();
    } else if (latest->isTerminator()) {
      internalError("uncompute: a resolvable rail is used by a terminator: " + describe(rails[g].handle), latest);
    } else if (isa<PHINode>(latest)) {
      before = &*bb->getFirstInsertionPt();
    } else {
      before = latest->getNextNode();
    }
    // Items placed at one point keep the order they were emitted in.
    while (before && emitted.count(before) && !before->isTerminator())
      before = before->getNextNode();
    return {bb, before};
  }

  // The barrier events of g's item: (event, isHit) that must not precede the item.
  SmallVector<std::pair<Instruction *, bool>, 4> barriers(RailId g) const {
    SmallVector<std::pair<Instruction *, bool>, 4> out;
    auto eventsOf = [&](RailId x, auto &&isAfterBase) {
      const Rail &rx = rails[x];
      for (Instruction *h : rx.hits)
        if (isAfterBase(h))
          out.push_back({h, true});
      if (x == g)
        return; // g's own writes are undone by its item
      for (unsigned w : rx.writes)
        if (isAfterBase(records[w].forward))
          out.push_back({records[w].forward, false});
    };
    const Rail &r = rails[g];
    if (r.cleanup) {
      // Base: the latest definition among the inverse's operand rails and old's records.
      SmallVector<const Instruction *, 4> bases;
      for (RailId x : r.cleanup->reads)
        if (auto *i = dyn_cast<Instruction>(rails[x].handle))
          bases.push_back(i);
      if (r.creator != kNone)
        bases.push_back(records[r.creator].forward);
      for (unsigned w : r.writes)
        bases.push_back(records[w].forward);
      auto afterAll = [&](const Instruction *e) {
        for (const Instruction *b : bases)
          if (b != e && !after(e, b))
            return false;
        return true;
      };
      for (RailId x0 : r.cleanup->reads)
        for (RailId x : leaves(x0))
          eventsOf(x, afterAll);
      eventsOf(g, afterAll);
      return out;
    }
    for (unsigned rec : undone(g)) {
      const Instruction *f = records[rec].forward;
      auto afterRec = [&](const Instruction *e) { return e != f && after(e, f); };
      for (RailId x0 : info[rec].reads)
        for (RailId x : leaves(x0)) // U1: a read of a merge reads one of its arms
          eventsOf(x, afterRec);
    }
    // Hits on g itself after it was minted (a rotated seed or result is never freed).
    if (r.creator != kNone) {
      const Instruction *f = records[r.creator].forward;
      auto afterRec = [&](const Instruction *e) { return e != f && after(e, f); };
      eventsOf(g, afterRec);
    } else if (auto *i = dyn_cast<Instruction>(r.handle)) {
      auto afterDef = [&](const Instruction *e) { return e != i && after(e, i); };
      eventsOf(g, afterDef);
    } else {
      for (Instruction *h : r.hits)
        out.push_back({h, true});
    }
    // De-duplicate (an event may be reachable through several records).
    SmallVector<std::pair<Instruction *, bool>, 4> uniq;
    for (auto &e : out)
      if (!is_contained(uniq, e))
        uniq.push_back(e);
    return uniq;
  }

  // ---- emission --------------------------------------------------------------------------------

  CallInst *track(CallInst *c) {
    emitted.insert(c);
    return c;
  }

  static FunctionCallee declareFn(Module &M, StringRef name, FunctionType *FT, const Value *at) {
    if (Function *ex = M.getFunction(name)) {
      if (ex->getFunctionType() != FT)
        internalError("uncompute: " + name.str() + " is declared with another type", at);
      return {FT, ex};
    }
    return M.getOrInsertFunction(name, FT);
  }

  // name_unc spelled from the forward call (CR §1.2, §1.3): (out, args...) or (args...).
  static FunctionCallee uncOf(CallInst *fwd, bool outFirst) {
    Function *callee = fwd->getCalledFunction();
    SmallVector<Type *, 6> ps;
    if (outFirst)
      ps.push_back(Type::getInt32Ty(fwd->getContext()));
    for (Type *t : callee->getFunctionType()->params())
      ps.push_back(t);
    FunctionType *FT = FunctionType::get(Type::getVoidTy(fwd->getContext()), ps, false);
    return declareFn(*fwd->getModule(), (callee->getName() + "_unc").str(), FT, fwd);
  }

  static SmallVector<Value *, 6> argsOf(CallInst *fwd, Value *outFirst) {
    SmallVector<Value *, 6> a;
    if (outFirst)
      a.push_back(outFirst);
    for (Value *v : fwd->args())
      a.push_back(v);
    return a;
  }

  CallInst *emitRelease(RailId g, IRBuilder<> &B) {
    Rail &r = rails[g];
    Module &M = *B.GetInsertBlock()->getModule();
    LLVMContext &C = M.getContext();
    FunctionType *FT = FunctionType::get(Type::getVoidTy(C), {Type::getInt32Ty(C)}, false);
    return track(B.CreateCall(declareFn(M, r.qram ? "cqrt_qram_free" : "cqrt_free", FT, r.handle), {r.handle}));
  }

  Instruction *emitItem(RailId g, IRBuilder<> &B) {
    Rail &r = rails[g];
    if (r.cleanup) {
      // Rule 6: t = f^-1(ops); copy(t, old); f^-1_unc(t, ops); free t; free old.
      Module &M = *B.GetInsertBlock()->getModule();
      SmallVector<Value *, 4> args;
      for (const Operand &o : r.cleanup->ops)
        args.push_back(o.v);
      CallInst *t = track(B.CreateCall(abi::declare(M, r.cleanup->inverse, false), args));
      abi::CoreSpec cp{abi::Core::Copy, templateResultType(r.cleanup->inverse)};
      track(B.CreateCall(abi::declare(M, cp), {t, r.handle}));
      SmallVector<Value *, 5> uargs{t};
      uargs.append(args.begin(), args.end());
      track(B.CreateCall(abi::declare(M, r.cleanup->inverse, true), uargs));
      LLVMContext &C = M.getContext();
      FunctionType *FT = FunctionType::get(Type::getVoidTy(C), {Type::getInt32Ty(C)}, false);
      track(B.CreateCall(declareFn(M, "cqrt_free", FT, t), {t}));
      return emitRelease(g, B);
    }
    if (!directRelease(g)) {
      if (r.role == Role::Seed && r.creator != kNone && info[r.creator].kind != RecKind::Seed &&
          info[r.creator].kind != RecKind::QramAlloc)
        internalError("uncompute: Role::Seed on a rail not minted by alloc", r.handle);
      SmallVector<unsigned, 4> recs = undone(g);
      if (r.creator == kNone)
        internalError("uncompute: a garbage rail has no producer to uncompute it", r.handle);
      for (auto it = recs.rbegin(); it != recs.rend(); ++it) {
        CallInst *fwd = records[*it].forward;
        switch (info[*it].kind) {
        case RecKind::Template:
        case RecKind::QramLoad:
          track(B.CreateCall(uncOf(fwd, true), argsOf(fwd, fwd)));
          break;
        case RecKind::Involution:
          track(B.CreateCall(fwd->getFunctionType(), fwd->getCalledOperand(), argsOf(fwd, nullptr)));
          break;
        case RecKind::QramStore:
          track(B.CreateCall(uncOf(fwd, false), argsOf(fwd, nullptr)));
          break;
        case RecKind::Seed:
        case RecKind::QramAlloc:
          break;
        }
      }
    }
    return emitRelease(g, B);
  }

  // ---- batches ---------------------------------------------------------------------------------

  enum class Mode { Local, Exit, Mirror };
  struct Ctx {
    Mode mode;
    Instruction *point = nullptr; // P or R
    IRBuilder<> *mirror = nullptr;
  };

  bool done(RailId g, const Ctx &c) const {
    return rails[g].released || (c.mode == Mode::Exit && rails[g].exitsDone.count(c.point->getParent()));
  }

  // Readers first; ties by most recent rail first.
  SmallVector<RailId, 16> order(ArrayRef<RailId> cands) const {
    DenseSet<RailId> in(cands.begin(), cands.end());
    DenseMap<RailId, int> state; // 1 visiting, 2 done
    SmallVector<RailId, 16> out;
    SmallVector<RailId, 16> roots(cands.begin(), cands.end());
    llvm::sort(roots, [](RailId a, RailId b) { return a > b; });
    std::function<void(RailId)> visit = [&](RailId g) {
      int &s = state[g];
      if (s == 2)
        return;
      if (s == 1)
        internalError("uncompute: cyclic uncompute dependency through rule 6", rails[g].handle);
      s = 1;
      SmallVector<RailId, 4> rd = readersOf(g);
      llvm::sort(rd, [](RailId a, RailId b) { return a > b; });
      for (RailId o : rd)
        if (in.count(o))
          visit(o);
      state[g] = 2;
      out.push_back(g);
    };
    for (RailId g : roots)
      visit(g);
    return out;
  }

  // Drop every candidate a pending resolvable non-candidate reader still needs.
  void dropBlocked(SmallVectorImpl<RailId> &cands, const Ctx &c, bool fatal) const {
    bool changed = true;
    while (changed) {
      changed = false;
      DenseSet<RailId> in(cands.begin(), cands.end());
      for (unsigned i = 0; i < cands.size(); ++i) {
        RailId g = cands[i];
        for (RailId o : readersOf(g)) {
          if (in.count(o) || !resolvable(o) || done(o, c))
            continue;
          if (fatal)
            internalError("uncompute: mirror would free " + describe(rails[g].handle) +
                              " while a rail outside the scope still reads it",
                          rails[o].handle);
          cands.erase(cands.begin() + i);
          changed = true;
          break;
        }
        if (changed)
          break;
      }
    }
  }

  void place(RailId g, const Ctx &c) {
    Rail &r = rails[g];
    if (c.mode == Mode::Mirror) {
      Instruction *end = emitItem(g, *c.mirror);
      r.released = true;
      itemEnd[{g, end->getParent()}] = end;
      return;
    }
    BasicBlock *D = const_cast<BasicBlock *>(defBlock(g));
    SmallVector<Instruction *, 12> as = anchors(g);
    for (RailId o : readersOf(g))
      for (auto &kv : itemEnd)
        if (kv.first.first == o)
          as.push_back(kv.second);
    bool local = all_of(as, [&](Instruction *a) { return a->getParent() == D; });
    Pos pos;
    if (local) {
      pos = afterLatest(D, as, g);
    } else {
      if (c.mode != Mode::Exit)
        internalError("uncompute: local flush of a rail used outside its block", r.handle);
      BasicBlock *Rb = c.point->getParent();
      SmallVector<Instruction *, 12> rel;
      for (Instruction *a : as)
        if (reaches(a->getParent(), Rb))
          rel.push_back(a);
      pos = afterLatest(Rb, rel, g);
    }
    if (!pos.before)
      internalError("uncompute: no insertion point for " + describe(r.handle));
    // Rule 5's invariant.
    bool kept = false;
    for (auto [e, isHit] : barriers(g)) {
      bool violated;
      if (e->getParent() == pos.bb)
        violated = !(pos.before == e || pos.before->comesBefore(e));
      else if (reaches(e->getParent(), pos.bb))
        unimplemented("uncompute: a barrier in another block lies between a rail and its uncompute", e);
      else
        violated = false;
      if (!violated)
        continue;
      if (!isHit)
        unimplemented("uncompute: an in-place write on an operand rail precedes the earliest uncompute of " +
                          describe(r.handle),
                      e);
      kept = true;
    }
    if (kept) {
      r.role = Role::KeptEntangled;
      r.cleanup.reset();
      return;
    }
    IRBuilder<> B(pos.before);
    Instruction *end = emitItem(g, B);
    itemEnd[{g, pos.bb}] = end;
    if (local)
      r.released = true;
    else
      r.exitsDone.insert(pos.bb);
  }

  void resolve(SmallVectorImpl<RailId> &cands, const Ctx &c) {
    dropBlocked(cands, c, c.mode == Mode::Mirror);
    for (RailId g : order(cands))
      place(g, c);
  }
};

// ---- public interface ----------------------------------------------------------------------------

Uncompute::Uncompute() : impl(std::make_shared<Impl>()) {}

RailId Uncompute::recordTemplate(CallInst *fwd, const abi::TemplateSpec &spec, ArrayRef<Operand> ops) {
  impl->checkOps(fwd, ops, "recordTemplate");
  RailId out = impl->newRail(fwd, Role::Garbage, "recordTemplate");
  impl->addRecord(fwd, spec, ops, out, RecKind::Template, false);
  return out;
}

RailId Uncompute::recordCore(CallInst *fwd, const abi::CoreSpec &spec, ArrayRef<Operand> ops, RailId out) {
  using abi::Core;
  impl->checkOps(fwd, ops, "recordCore");
  if (spec.unc)
    internalError("uncompute: recordCore of an _unc call", fwd);
  auto target = [&](unsigned i) -> RailId {
    if (i >= ops.size() || !ops[i].handle)
      internalError("uncompute: recordCore: the target operand is not a rail", fwd);
    RailId t = impl->lookup(ops[i].v, "recordCore", fwd);
    if (impl->isMerge(t))
      unimplemented("uncompute: recordCore: an in-place write through a merged handle (U1: copy it out first)", fwd);
    if (t != out)
      internalError("uncompute: recordCore: `out` is not the gate's target rail", fwd);
    return t;
  };
  unsigned c = spec.ctl ? 1 : 0;
  switch (spec.op) {
  case Core::Alloc:
    return recordSeed(fwd);
  case Core::QramAlloc: {
    RailId r = impl->newRail(fwd, Role::Seed, "recordCore");
    impl->rails[r].qram = true;
    impl->addRecord(fwd, spec, ops, r, RecKind::QramAlloc, false);
    return r;
  }
  case Core::QramLoad: {
    RailId r = impl->newRail(fwd, Role::Garbage, "recordCore");
    impl->addRecord(fwd, spec, ops, r, RecKind::QramLoad, false);
    return r;
  }
  case Core::Copy:
    impl->addRecord(fwd, spec, ops, target(c + 1), RecKind::Involution, false);
    return out;
  case Core::Xorc:
    impl->addRecord(fwd, spec, ops, target(c), RecKind::Involution, !spec.ctl);
    return out;
  case Core::NotI1:
    impl->addRecord(fwd, spec, ops, target(0), RecKind::Involution, false);
    return out;
  case Core::AndI1:
  case Core::OrI1:
    impl->addRecord(fwd, spec, ops, target(2), RecKind::Involution, false);
    return out;
  case Core::XorI1:
    impl->addRecord(fwd, spec, ops, target(1), RecKind::Involution, false);
    return out;
  case Core::QramStore:
    impl->addRecord(fwd, spec, ops, target(c), RecKind::QramStore, false);
    return out;
  case Core::QramRealloc:
    unimplemented("uncompute: recordCore of qram_realloc", fwd);
  default:
    internalError("uncompute: recordCore: core gate " + fwd->getCalledFunction()->getName().str() +
                      " is not a reversible record",
                  fwd);
  }
}

RailId Uncompute::recordSeed(CallInst *alloc) {
  if (!alloc || !alloc->getCalledFunction() || alloc->arg_size() != 1)
    internalError("uncompute: recordSeed expects a cqrt_alloc_<W>(lit) call", alloc);
  RailId r = impl->newRail(alloc, Role::Seed, "recordSeed");
  abi::CoreSpec spec{abi::Core::Alloc, literalRailType(alloc->getArgOperand(0)->getType())};
  Operand lit{alloc->getArgOperand(0), false};
  impl->addRecord(alloc, spec, ArrayRef<Operand>(lit), r, RecKind::Seed, false);
  return r;
}

RailId Uncompute::recordExternal(Value *handle, Role role) {
  return impl->newRail(handle, role, "recordExternal");
}

RailId Uncompute::recordMerge(Instruction *merged) {
  Impl &I = *impl;
  if (!merged || !merged->getParent())
    internalError("uncompute: recordMerge needs an instruction in a block");
  SmallVector<Value *, 4> vals;
  if (auto *sel = dyn_cast<SelectInst>(merged)) {
    if (I.byHandle.count(sel->getCondition()))
      internalError("uncompute: recordMerge: the select condition is a rail (a quantum select is a template)", merged);
    vals = {sel->getTrueValue(), sel->getFalseValue()};
  } else if (auto *phi = dyn_cast<PHINode>(merged)) {
    if (phi->getNumIncomingValues() != pred_size(phi->getParent()))
      internalError("uncompute: recordMerge: the phi is not complete (an incoming per predecessor)", merged);
    for (Value *v : phi->incoming_values())
      vals.push_back(v);
  } else {
    internalError("uncompute: recordMerge: a merge is a select or a phi", merged);
  }
  SmallVector<RailId, 2> arms;
  for (Value *v : vals) {
    RailId a = I.lookup(v, "recordMerge", merged);
    if (I.anyReleased(a))
      internalError("uncompute: recordMerge: arm " + describe(v) + " was already uncomputed and freed", merged);
    if (!is_contained(arms, a))
      arms.push_back(a);
  }
  RailId m = I.newRail(merged, Role::Garbage, "recordMerge");
  I.rails[m].arms = arms;
  for (RailId a : arms)
    I.rails[a].mergedInto.push_back(m);
  return m;
}

RailId Uncompute::idOf(Value *handle) const { return impl->lookup(handle, "idOf", handle); }

void Uncompute::setRole(RailId r, Role role) {
  Impl &I = *impl;
  Impl::Rail &x = I.rail(r, "setRole");
  if (x.released || !x.exitsDone.empty())
    internalError("uncompute: setRole on a rail that was already uncomputed", x.handle);
  if (I.isMerge(r)) {
    // U1: a merge is never resolved itself; a kept role on it would have to keep whichever arm the
    // classical condition chose and clean the others, which no static role can say. It is accepted
    // only where it changes nothing: every arm it may name is already kept.
    if (role == Role::Seed)
      internalError("uncompute: setRole: Role::Seed on a merged handle", x.handle);
    if (Impl::keptRole(role))
      for (RailId a : I.leaves(r))
        if (I.resolvable(a))
          internalError("uncompute: setRole: a kept role on a merged handle whose arm " + describe(I.rails[a].handle) +
                            " is still resolvable (U1: copy the merged handle out into a fresh rail and keep that)",
                        x.handle);
    x.role = role;
    return;
  }
  if (!Impl::keptRole(role) && !x.cleanup)
    for (RailId m : I.names(r))
      if (m != r && Impl::keptRole(I.rails[m].role))
        internalError("uncompute: setRole: a resolvable role on an arm of a kept merged handle", x.handle);
  x.role = role;
}

void Uncompute::noteUse(RailId r, Instruction *consumer) {
  Impl::Rail &x = impl->rail(r, "noteUse");
  if (!consumer)
    internalError("uncompute: noteUse without a consumer", x.handle);
  if (impl->anyReleased(r))
    internalError("uncompute: use of " + describe(x.handle) + " after it was uncomputed and freed", consumer);
  x.uses.push_back(consumer);
}

void Uncompute::noteNonDiagonal(RailId target, Instruction *gate) {
  Impl::Rail &x = impl->rail(target, "noteNonDiagonal");
  if (!gate)
    internalError("uncompute: noteNonDiagonal without a gate", x.handle);
  if (impl->isMerge(target))
    unimplemented("uncompute: a non-diagonal gate on a merged handle (U1: copy it out first)", gate);
  if (x.released)
    internalError("uncompute: gate on " + describe(x.handle) + " after it was uncomputed and freed", gate);
  x.hits.push_back(gate);
}

void Uncompute::cleanupBijective(RailId oldRail, const abi::TemplateSpec &inverse, ArrayRef<Operand> ops) {
  Impl::Rail &x = impl->rail(oldRail, "cleanupBijective");
  if (x.released || !x.exitsDone.empty())
    internalError("uncompute: cleanupBijective of a rail already uncomputed", x.handle);
  if (x.cleanup)
    internalError("uncompute: cleanupBijective requested twice", x.handle);
  if (impl->isMerge(oldRail))
    internalError("uncompute: cleanupBijective of a merged handle", x.handle);
  Impl::Cleanup cl{inverse, SmallVector<Operand, 3>(ops.begin(), ops.end()), {}};
  for (const Operand &o : ops) {
    if (!o.handle)
      continue;
    RailId r = impl->lookup(o.v, "cleanupBijective", x.handle);
    if (r == oldRail)
      internalError("uncompute: rule 6 inverse reads the rail it cleans", x.handle);
    if (impl->rails[r].released)
      internalError("uncompute: rule 6 operand already uncomputed", o.v);
    if (!is_contained(cl.reads, r)) {
      cl.reads.push_back(r);
      impl->rails[r].cleanupReaders.push_back(oldRail);
    }
  }
  impl->rails[oldRail].cleanup = std::move(cl);
}

void Uncompute::flushBefore(Instruction *point) {
  impl->pruneCleanups();
  if (!point || !point->getParent())
    internalError("uncompute: flushBefore needs an instruction in a block");
  Impl &I = *impl;
  Impl::Ctx c{Impl::Mode::Local, point, nullptr};
  BasicBlock *P = point->getParent();
  SmallVector<RailId, 16> cands;
  for (RailId g = 0; g < I.rails.size(); ++g) {
    if (!I.resolvable(g) || !I.rails[g].exitsDone.empty() || I.defBlock(g) != P)
      continue;
    bool ok = true;
    for (Instruction *a : I.anchors(g))
      if (a->getParent() != P || !a->comesBefore(point) ||
          (!isa<CallBase>(a) && !I.emitted.count(a) && !I.isMergeHandle(a))) {
        ok = false;
        break;
      }
    if (ok)
      cands.push_back(g);
  }
  I.resolve(cands, c);
}

void Uncompute::flushAtExit(ReturnInst *ret) {
  impl->pruneCleanups();
  if (!ret || !ret->getParent())
    internalError("uncompute: flushAtExit needs a return in a block");
  Impl &I = *impl;
  Impl::Ctx c{Impl::Mode::Exit, ret, nullptr};
  BasicBlock *Rb = ret->getParent();
  SmallVector<RailId, 16> cands;
  for (RailId g = 0; g < I.rails.size(); ++g) {
    if (!I.resolvable(g) || I.done(g, c))
      continue;
    const BasicBlock *D = I.defBlock(g);
    if (!Impl::reaches(D, Rb))
      continue;
    if (!Impl::dominates(D, Rb) && !I.rails[g].mergedInto.empty())
      unimplemented("uncompute: an arm of a merged handle, " + describe(I.rails[g].handle) +
                        ", is pending at a return its definition does not dominate (a phi over arm-local "
                        "handles: cq-ut4k)",
                    ret);
    if (!Impl::dominates(D, Rb))
      internalError("uncompute: " + describe(I.rails[g].handle) +
                        " is still pending at a return its definition does not dominate (an arm was not flushed)",
                    ret);
    cands.push_back(g);
  }
  I.resolve(cands, c);
}

unsigned Uncompute::openScope() {
  unsigned id = impl->scopes.size();
  impl->scopes.push_back({static_cast<unsigned>(impl->records.size()), kNone, true});
  impl->openStack.push_back(id);
  return id;
}

void Uncompute::closeScope(unsigned s) {
  if (impl->openStack.empty() || impl->openStack.back() != s)
    internalError("uncompute: scopes close last-in-first-out; scope " + std::to_string(s) + " is not innermost");
  impl->openStack.pop_back();
  impl->scopes[s].end = impl->records.size();
  impl->scopes[s].open = false;
}

ArrayRef<Record> Uncompute::scopeRecords(unsigned s) const {
  if (s >= impl->scopes.size())
    internalError("uncompute: no scope " + std::to_string(s));
  const Impl::Scope &sc = impl->scopes[s];
  unsigned end = sc.open ? impl->records.size() : sc.end;
  return ArrayRef<Record>(impl->records).slice(sc.begin, end - sc.begin);
}

void Uncompute::emitMirror(unsigned s, IRBuilder<> &B) {
  impl->pruneCleanups();
  if (s >= impl->scopes.size())
    internalError("uncompute: no scope " + std::to_string(s));
  Impl &I = *impl;
  const Impl::Scope &sc = I.scopes[s];
  unsigned end = sc.open ? I.records.size() : sc.end;
  Impl::Ctx c{Impl::Mode::Mirror, nullptr, &B};
  SmallVector<RailId, 16> cands;
  for (RailId g = 0; g < I.rails.size(); ++g) {
    unsigned cr = I.rails[g].creator;
    if (cr != kNone && cr >= sc.begin && cr < end && I.resolvable(g))
      cands.push_back(g);
  }
  I.resolve(cands, c);
}

} // namespace cq
