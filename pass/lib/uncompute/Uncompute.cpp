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
//  - setRole: Garbage and Seed are resolvable; every other role is kept (never _unc'd, never freed).
//    A Seed whose only writes are uncontrolled xorc is freed directly; a Seed with other writes is
//    undone write by write, then freed.
//  - noteNonDiagonal(x, g): g is a non-diagonal gate on x (Ry, a quantum-angle Ry; the caller decides,
//    a computational-basis measurement is not one: 42). It is a barrier for every _unc that needs x.
//    cq-igqp: when x's handle is a phi or select over handles that is not a merge (a classically
//    bounded loop's header phi, recordExternal), g is also a gate on every rail it may name (through
//    nested phis, selects and merges; re-read before every placement, since the back edge is filled
//    after the gate): those rails are never uncomputed through it. An unchosen arm of a kept merge so
//    hit on every path to its edge stays allocated there (A4); on some paths only: unimplemented. A
//    rail already uncomputed and freed that such a gate reaches: unimplemented.
//  - recordBusLoad(load, ops) (rule 5 sentence 1): load is a new-IR cqrt_qram_load_<W>[_hl][_controlled]; a new rail,
//    Role::Garbage, whose item is the same call's _unc(h, ops...) then cqrt_free(h). The item is placed like a
//    template's (after the last reader and its _unc; its address rail and control outlive it). At the placement the
//    version changes noted so far decide: one on a path from the load to the point leaves the rail allocated,
//    Role::Overtaken. A kept role (Measured, UserRegister, Frozen, Kept) means no item at all.
//  - noteVersionChange(at): at is the first new-IR instruction of a memory version change (rule 5 Memory).
//  - noteKeptStore(store, value, ctl) (rule 5 sentence 3): the value and control rails stay, Role::Kept unless they
//    already hold a kept role; a pending rule 6 clean-up of either is dropped. A rail a classical branch can bypass the
//    store of is kept only where the store ran: one instance under a run flag, a rule-14 trip's instance through a copy the
//    store reads (the reverse loop undoes the rail itself), as a carried phi and an exit rail stored only after its loop
//    always (cq-ii0vf, cq-mmdf3, cq-qayew).
//  - cleanupBijective(old, inverse, ops): rule 6. Instead of its producer's _unc, `old` is cleaned by
//    t = inverse(ops); copy_<W>(t, old); inverse_unc(t, ops); free t; free old. It overrides old's
//    role. ops are the inverse template's forward operands.
//  - recordMerge(m) (U1, CR rule 9 at a58c3a4): m is a classical select (condition not a rail) or a
//    complete phi (one incoming per predecessor) whose every value operand is a recorded rail or
//    merge, none freed, or m itself (a loop's back edge carrying m unchanged, cq-b9w7: no arm). m's handle becomes a MERGE: idOf(m) answers, and it may be an operand of any
//    record, noteUse and setRole. A merge names one of its arms at run time, so:
//      * it is never resolved itself: no _unc, no cqrt_free, never live at exit as a rail of its own;
//      * a use of m (an IR user of m's handle, a noted use, a record reading m, a rule 6 clean-up
//        reading m) is a use of every arm it may name, transitively through nested merges: every
//        arm's item comes after it, and after the item of every rail whose record reads m;
//      * a barrier on an arm (an in-place write, a noted non-diagonal gate) binds every item that
//        reads m;
//      * its role stays Garbage, or becomes kept (cq-bv91, superseding U1's copy-out on the review of
//        cq-hs4k: a copy-out keeps a second rail beside an arm that is already kept, 128). A kept role
//        on a phi merge keeps the chosen arm itself on each path: every arm takes the role, and an
//        arm that also reaches the join along an edge that does not choose it is resolved at the end
//        of that edge's block (a block whose only successor is the join), so exactly one arm of the
//        merge is live on each path through the join (128: arm-local arms, nothing to resolve; 25:
//        the zero-trip seed, defined before the loop, is freed on the loop's exit edge). Arms already
//        kept stay as they are; a nested phi merge arm is kept the same way. An edge chooses an arm
//        when its incoming value may name it, through nested merges too (cq-sodl). After the edge
//        the arm is gone on that path: a later record, noted use, gate, role, merge or IR use that
//        reads it other than through m, at a point some path leaving that edge reaches without
//        defining it again, is unimplemented (a role or rule 6 clean-up has no point: always).
//        Unimplemented: the unchosen arm may still be read after that edge (directly or through
//        another merge), is
//        read by a pending rail, has a barrier before the edge, may not exist where the edge leaves,
//        or leaves by a block that also branches elsewhere; an arm that may reach a return without
//        passing the join; a kept role on a classical select with a resolvable arm (keeping only
//        the chosen arm needs a branch on the condition). Arms that are all kept already: nothing
//        changes (135's spelling). The kept-select check reads every select the merge may name
//        before any role changes, so the order of the arms changes nothing.
//      * noteNonDiagonal(m) hits every arm m may name; each must be kept already (the consumer sets
//        the role first), otherwise unimplemented. recordCore with m as the written rail is
//        unimplemented; cleanupBijective(m) is an internal error; Role::Seed on m is an internal error.
//      * an arm whose definition does not dominate the return where it would be resolved (a phi
//        over arm-local garbage handles) is unimplemented (cq-ut4k).
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
//  - Deferred items (F1, freeze bead cq-fx3s; CR rule 14: the reverse loop runs after the readers of the
//    loop's exit values, 153, 178, 187, 188). recordDeferred(scopes, exits, emit, reads): the rails created
//    by records of the (closed) scopes are OWNED by the item: no flush resolves them, emit's mirrors do.
//    exits (owned, pending) are read after the loop; reads (not owned) are the rails the item reads. The
//    item is a pseudo rail g: it reads `reads` (their items follow it), and every rail outside it whose
//    item reads an exit rail (through merges too) precedes it; a reader owned by another pending item is
//    that item. Placement:
//      * flushBefore(P): last in the batch, when every use of the exit rails after the loop (IR users and
//        noted uses of every handle that may name one, outside the blocks that reach the loop) lies in
//        P's block before P, there is at least one, every reader is resolved, and no block holding a
//        pending record of another scope reaches P (never inside a later loop's trip or an open region);
//      * flushAtExit(R): when the loop reaches R, in the batch's reverse dependency order, else
//        unimplemented if it cannot be placed. Placed once: a return reached from the loop by a path that
//        avoids the placement is unimplemented.
//    At the placement the block is split: its head (phis included) and its predecessors move to a fresh
//    block H, emit runs from the end of H (it may branch around itself where the loop did not run) and
//    the original block keeps the tail and its terminator. Rule 5: a non-diagonal gate or an in-place
//    write after the loop on a rail the item reads (or on an exit rail) that the placement does not
//    precede moves the item to where the loop exits (cq-dyef, 116: the immediate placement), which
//    needs every exit rail kept (each is copied there, below); otherwise it is unimplemented. An exit rail that became kept (a measurement, a kept merge's arm, an
//    escape) is copied in the loop's exit block before its first use after the loop, every such use reads
//    the copy (which takes the role), and the item undoes the rail itself; one a trip rotated is read in place, never undone.
//    An exit rail with no IR use outside the region (it reaches later code only through memory: cell-load
//    merges, M3) that became kept is not copied and not undone: every trip's instance keeps its role
//    (rule 5, rule 14 case 1; 179). An owned record reading it is still undone.
//  - resolveAt(P, rails) (U5, cq-arch 2026-11-01; CR rule 5): emits right before P, readers first, the
//    items of the listed pending rails (kept or resolved ones are skipped), with rule 5's barrier check.
//    Precondition, else an internal error: each rail's definition dominates P, none of its uses comes
//    at or after P, every pending reader of it is in the list, and every path from its definition to
//    a return passes P (it is resolved for good there, CR §0). A merge or a deferred item's rail is an
//    internal error.
//  - scopeRecords(s): the records created while s was open (nested scopes included), program order.
//    The ArrayRef is valid until the next record* call. Scopes close last-in-first-out.
//
// Symbols. A _unc is spelled from its forward call: the callee's name + "_unc", arguments
// (out, the forward argument list) for a template or a qram_load, the forward argument list for an
// in-place core gate (CR §1.2, §1.3). Spelling it from the call keeps operand types and literals
// identical to the forward by construction. Rule 6 has no forward call to copy from and declares its
// inverse template and copy through abi::declare.
#include "cq/Uncompute.h"
#include "cq/Order.h"

#include <algorithm>
#include <functional>
#include <map>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SCCIterator.h"
#include "llvm/IR/Dominators.h"
#include "llvm/Analysis/CaptureTracking.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/SSAUpdater.h"

using namespace llvm;

namespace cq {

namespace {

constexpr unsigned kNone = ~0u;

enum class RecKind : uint8_t {
  Template,  // fresh out, undone by name_unc(out, args...)
  Seed,      // cqrt_alloc: nothing to undo, released by cqrt_free
  Involution,// in place on out, undone by the same call
  Call,      // U2: a clone call's results, undone together by name_unc(outs..., extra..., args...)
  BusLoad,   // rule 5 sentence 1: fresh out, un-copied by name_unc(out, args...), freed iff no version change between
};

bool isCreator(RecKind k) { return k != RecKind::Involution; }

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
    RailId item = kNone;          // the item that undoes it: out
  };
  struct Cleanup {
    abi::TemplateSpec inverse;
    SmallVector<Operand, 3> ops;
    SmallVector<RailId, 3> reads;
    // cq-mgkr (cleanupBijectiveUnder): the guarded form. Each alternative cleans the rail where its classical
    // guard holds; elsewhere the item is the rail's plain one. inverse/ops above are unused; reads is the
    // union of the alternatives' reads.
    struct Alt { Value *guard; abi::TemplateSpec inverse; SmallVector<Operand, 3> ops; SmallVector<RailId, 3> reads; };
    SmallVector<Alt, 2> alts;
    bool everyPath = false;   // the alternatives' guards cover every path: no plain part
  };
  struct Rail {
    Value *handle = nullptr;
    Role role = Role::Garbage;
    bool released = false; // resolved for good (placed in its defining block, or mirrored)
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
    unsigned group = kNone;            // U2: the call group this rail is a member of
    bool explicitKept = false;         // U2: setRole gave this rail a kept role itself
    bool storeKept = false;            // rule 5 sentence 3: the value or control rail of a kept store
    bool carried = false;              // noteCarried: a rule-14 header phi over handles, no rule 6 register
    // cq-guzg3 (rule 5 sentence 3, §6 item 1): a rail stored only on some classical paths from its definition: kept
    // where a store in here ran, a rail like any other on the paths that bypass them (placeAt's run flag).
    SmallVector<Instruction *, 1> condStores;
    bool loadCall = false;             // rule 18: the result of a clone call that loads from the bus (noteLoadsBus)
    // cq-lshe (CR rule 9, §0): the kept merges that keep this rail where they choose it. It stays
    // resolvable: its item runs under the classical predicate "no keeper chose it" (a re-branch on the
    // conditions that chose the arm), placed after its own uses (not those through a keeper).
    SmallVector<RailId, 1> keepers;
    // cq-lshe (CR §0, rules 5, 10): non-diagonal gates on a merge that names this rail where the merge
    // chooses it (gate, merge): a barrier on the paths where it chose it, nothing elsewhere.
    SmallVector<std::pair<Instruction *, RailId>, 1> condHits;
    // F1 (cq-fx3s): on the pseudo rail of a deferred item, its index in defs; on a rail created by a
    // record of a deferred item's scopes, that item (no flush resolves it; the item's emit mirrors it).
    unsigned deferred = kNone;
    unsigned ownedBy = kNone;
  };
  // F1 (cq-fx3s): a deferred item (the rule-14 reverse loop), see recordDeferred.
  struct Deferred {
    SmallVector<RailId, 4> exits;
    std::function<void(IRBuilder<> &)> emit;
    SmallVector<RailId, 8> reads;
    SmallPtrSet<const BasicBlock *, 8> region; // the blocks of the owned records
    SmallVector<unsigned, 8> hostScopes;       // F2: an enclosing region's scopes (its trip hosts the item)
    SmallVector<unsigned, 4> scopes;           // the scopes whose records it owns (recordDeferred)
    RailId pseudo = kNone;
    BasicBlock *placedAt = nullptr;            // the block the program continues in after the item
  };
  struct Scope {
    unsigned begin, end;
    bool open;
    DenseSet<RailId> left = {};   // leaveScope: rails the scope's time span holds and its region does not
  };

  std::vector<Record> records;
  std::vector<RecInfo> info;
  std::vector<Rail> rails;
  DenseMap<const Value *, RailId> byHandle;
  std::vector<Scope> scopes;
  std::vector<Deferred> defs;
  struct CallGroup {
    CallInst *fwd;
    SmallVector<RailId, 4> outs, members;
    SmallVector<Value *, 4> extra;
    bool table = false;   // rules 19, 27: a table clone's twin frees the results itself
    // Rules 19, 27 (cq-j2r0j): a table call's result widths, parallel to outs, from the C result type.
    SmallVector<RailType, 4> widths;
  };
  std::vector<CallGroup> groups;
  DenseMap<const CallInst *, std::string> twinNames;
  // Rule 5 Memory: the memory version changes of the new IR (noteVersionChange), in the order noted.
  SmallVector<Instruction *, 16> versions;
  // Rule 18: the original block a version change or a call was lowered from (noteSourceBlock). The arms of a quantum branch
  // lie one after the other in the new IR; which of them can follow a call only the original CFG says.
  const BasicBlock *srcBlock = nullptr;
  DenseMap<const Instruction *, const BasicBlock *> srcOf;
  SmallVector<unsigned, 4> openStack;
  std::vector<SmallVector<unsigned, 8>> tripFlush;   // beginTripFlush: the segment scopes of the trip being flushed
  DenseSet<const Instruction *> emitted;
  MapVector<std::pair<RailId, const BasicBlock *>, Instruction *> itemEnd;   // insertion order: keyed by a pointer
  // cq-g3h1i: per rail, the positions of its itemEnd entries (in insertion order; no entry is ever removed), so
  // "the item ends of rail o" is no scan of every item placed so far.
  DenseMap<RailId, SmallVector<unsigned, 2>> itemEndOf;
  void setItemEnd(RailId g, const BasicBlock *bb, Instruction *end) {
    auto [it, fresh] = itemEnd.insert({{g, bb}, end});
    if (fresh)
      itemEndOf[g].push_back(unsigned(itemEnd.size() - 1));
    else
      it->second = end;
  }
  // as += the item ends of o, in itemEnd's order.
  void itemEndsOf(RailId o, SmallVectorImpl<Instruction *> &as) const {
    if (auto it = itemEndOf.find(o); it != itemEndOf.end())
      for (unsigned k : it->second)
        as.push_back((itemEnd.begin() + k)->second);
  }
  // cq-ut4k: rails pending at the return being flushed whose definition does not dominate it (an arm
  // of a classical branch, often of a merge: a phi over arm-local handles), and the items placed for
  // them there, each run under its own selector (wrapArmItems).
  DenseSet<RailId> armLocal;
  DenseSet<RailId> cycleArm;   // cq-lshe: arms on a cycle pending at a return (cyclePoint)
  // cq-lshe: an item emitted under a classical condition (its run flag, flagAt), wrapped into a block of
  // its own: at a return after the batch (armItems), elsewhere at the end of the flush (localWraps).
  struct ArmItem { RailId g; Instruction *first, *last; Value *cond; };
  std::vector<ArmItem> armItems, localWraps;

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

  // D lies on a built cycle that does not pass S: D's rail has instances a store in S never reads, a store after the loop
  // keeping the last trip's only. A store in the trip is lowered before its back edge exists, so it never answers yes.
  static bool repeatsWithout(const BasicBlock *D, const BasicBlock *S) {
    if (D == S)
      return false;
    SmallPtrSet<const BasicBlock *, 16> seen;
    SmallVector<const BasicBlock *, 16> work{D};
    while (!work.empty()) {
      const Instruction *t = work.pop_back_val()->getTerminator();
      if (!t)
        continue;
      for (const BasicBlock *n : successors(t)) {
        if (n == D)
          return true;
        if (n != S && seen.insert(n).second)
          work.push_back(n);
      }
    }
    return false;
  }

  // A classical branch on the way from D to S has an edge from which S cannot be reached (the output CFG is built up
  // to S when S is being lowered): some path from D does not pass S.
  // cq-jws5r: join block -> the empty block of its skip edge, for each classical arm a loop module noted (flagAt).
  DenseMap<const BasicBlock *, const BasicBlock *> armJoins;
  DenseMap<RailId, BasicBlock *> flushAt;   // cq-bqbty (flushIn): a rail a local flush in this block takes
  // The block whose conditional branch enters the noted arm that ends at join b, and the arm's first block; nullptr
  // where b is no such join (any more: an item wrapped since may have split it).
  BasicBlock *armBranch(BasicBlock *b, BasicBlock *&first) const {
    auto it = armJoins.find(b);
    if (it == armJoins.end())
      return nullptr;
    BasicBlock *S = const_cast<BasicBlock *>(it->second);
    if (pred_size(b) != 2 || !is_contained(predecessors(b), S) || S->size() != 1 || S->getSingleSuccessor() != b)
      return nullptr;
    BasicBlock *pre = S->getSinglePredecessor();
    auto *br = pre ? dyn_cast_or_null<BranchInst>(pre->getTerminator()) : nullptr;
    if (!br || !br->isConditional())
      return nullptr;
    first = br->getSuccessor(0) == S ? br->getSuccessor(1) : br->getSuccessor(0);
    if (first == S || first == b)
      return nullptr;
    return pre;
  }
  static bool bypassed(const BasicBlock *D, const BasicBlock *S) {
    SmallPtrSet<const BasicBlock *, 16> toS{S};
    SmallVector<const BasicBlock *, 16> work{S};
    while (!work.empty())
      for (const BasicBlock *p : predecessors(work.pop_back_val()))
        if (toS.insert(p).second)
          work.push_back(p);
    if (D == S || !toS.count(D))
      return false;
    SmallPtrSet<const BasicBlock *, 16> seen{D};
    work.push_back(D);
    while (!work.empty()) {
      const BasicBlock *b = work.pop_back_val();
      if (b == S)
        continue;
      const Instruction *t = b->getTerminator();
      if (!t)
        continue;
      for (const BasicBlock *n : successors(t)) {
        if (!toS.count(n))
          return true;
        if (seen.insert(n).second)
          work.push_back(n);
      }
    }
    return false;
  }

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

  // cq-igqp (CR §0, rules 5, 10): a phi or select over handles that is not a merge (a classically
  // bounded loop's header phi, recordExternal) names at run time one of its incoming rails: the seed or
  // the initial rail on entry, the previous trip's next value on the back edge. A non-diagonal gate on
  // it is a gate on every rail it may name, so the hit goes to each of them (through nested phis,
  // selects and merges): a rotated rail is never uncomputed through (a garbage one stays allocated,
  // KeptEntangled) and is a barrier for every item that reads it. The phi may not be complete when the
  // gate is noted (its back-edge incoming is added at the latch), so this runs again before every
  // placement, to a fixed point. A rail already uncomputed and freed that such a gate reaches is
  // unimplemented (its _unc ran against a rail the gate may have rotated).
  SmallVector<RailId, 4> phiAliasLeaves(RailId g) const {
    SmallVector<RailId, 4> out;
    SmallVector<const Value *, 8> work;
    SmallPtrSet<const Value *, 8> seen;
    auto push = [&](const Value *v) {
      if (auto *p = dyn_cast<PHINode>(v))
        for (const Value *in : p->incoming_values())
          work.push_back(in);
      else if (auto *sl = dyn_cast<SelectInst>(v)) {
        work.push_back(sl->getTrueValue());
        work.push_back(sl->getFalseValue());
      }
    };
    seen.insert(rails[g].handle);
    push(rails[g].handle);
    while (!work.empty()) {
      const Value *v = work.pop_back_val();
      if (!seen.insert(v).second || isa<Constant>(v))
        continue;
      auto it = byHandle.find(v);
      if (it == byHandle.end()) {
        push(v);   // an unrecorded phi or select over handles: look through it
        continue;
      }
      for (RailId x : leaves(it->second))
        if (x != g && !is_contained(out, x))
          out.push_back(x);
    }
    return out;
  }
  void syncPhiHits() {
    for (bool again = true; again;) {
      again = false;
      for (RailId g = 0; g < rails.size(); ++g) {
        if (rails[g].hits.empty() || isMerge(g) ||
            !(isa<PHINode>(rails[g].handle) || isa<SelectInst>(rails[g].handle)))
          continue;
        for (RailId x : phiAliasLeaves(g))
          for (unsigned k = 0; k < rails[g].hits.size(); ++k) {
            Instruction *gate = rails[g].hits[k];
            if (is_contained(rails[x].hits, gate))
              continue;
            if (rails[x].released)
              internalError("uncompute: a non-diagonal gate on " + describe(rails[g].handle) +
                                " may rotate " + describe(rails[x].handle) +
                                ", which it names at run time and which was already uncomputed and freed (its "
                                "item preceded a read of it: the phi's incoming value)",
                            gate);
            rails[x].hits.push_back(gate);
            again = true;
          }
      }
    }
  }

  // A read of g reads a freed rail: a leaf already resolved for good, unless the read reaches it only
  // through a merge that keeps it where it chooses it (cq-lshe: freed only where no keeper chose it).
  bool anyReleased(RailId g) const {
    for (RailId x : leaves(g))
      if (rails[x].released && (rails[x].keepers.empty() || readsAvoiding(g, x)))
        return true;
    return false;
  }
  // Does reading r read x other than through one of x's keepers (r == x, or a merge naming x by an arm
  // path that passes no keeper)?
  bool readsAvoiding(RailId r, RailId x) const {
    SmallVector<RailId, 8> seen;
    std::function<bool(RailId)> go = [&](RailId n) {
      if (is_contained(rails[x].keepers, n) || is_contained(seen, n))
        return false;
      if (n == x)
        return true;
      seen.push_back(n);
      for (RailId a : rails[n].arms)
        if (go(a))
          return true;
      return false;
    };
    return go(r);
  }
  // names(g) without the merges that name g only through one of its keepers: their uses read g only
  // where a keeper chose it, where g is kept (cq-lshe).
  SmallVector<RailId, 4> ownNames(RailId g) const {
    SmallVector<RailId, 4> ns = names(g);
    if (rails[g].keepers.empty())
      return ns;
    SmallVector<RailId, 4> out;
    for (RailId n : ns)
      if (readsAvoiding(n, g))
        out.push_back(n);
    return out;
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
    // An own symbol's call has its lowered return type before the callee is rewritten (a pointer result, a handle): direct all the same.
    if (!fwd || !isa<Function>(fwd->getCalledOperand()))
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
    RecInfo ri{kind, {}, preserving, out};
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

  // cq-4tkb4: reachability and dominance in one function while its CFG does not change (a return's flush: its
  // candidates and resolve, a deferred item's placement excepted, ReachScope), read from the strongly connected
  // components' order, each target's set of blocks with a path to it (made on first use) and one dominator tree.
  // The answers are those of the walks below: the successors are the terminators' (a block without one has none).
  struct ReachCache {
    static constexpr unsigned kNo = ~0u;
    const Function *F = nullptr;
    bool dirty = true;
    DenseMap<const BasicBlock *, unsigned> idx;
    std::vector<unsigned> ord;                      // the component's position (kNo: not reachable from the entry)
    std::vector<SmallVector<unsigned, 2>> rev;      // the blocks with an edge to each block
    DenseMap<unsigned, BitVector> to;               // per target: the blocks with a path of length >= 1 to it
    std::unique_ptr<DominatorTree> DT;
    // cq-a24ig: flagAt's answers while the CFG stands, by the at block and the events per block (see flagAt).
    // cq-aeroi: the key holds the conditions' addresses, so an entry carries handles to them and counts only while they
    // all live: a condition erased since (sweepChooses) frees its address for an unrelated value, which would match.
    struct FlagMemo {
      WeakVH r;
      std::vector<WeakVH> conds;
    };
    std::map<std::vector<uintptr_t>, FlagMemo> flagMemo;
    void build() {
      dirty = false;
      flagMemo.clear();
      idx.clear();
      ord.clear();
      rev.clear();
      to.clear();
      DT.reset();
      Function &Fn = const_cast<Function &>(*F);
      for (const BasicBlock &b : Fn)
        idx.try_emplace(&b, unsigned(idx.size()));
      ord.assign(idx.size(), kNo);
      rev.resize(idx.size());
      for (const BasicBlock &b : Fn)
        if (const Instruction *t = b.getTerminator())
          for (const BasicBlock *n : successors(t))
            if (auto it = idx.find(n); it != idx.end())
              rev[it->second].push_back(idx[&b]);
      unsigned k = 0;
      for (scc_iterator<Function *> it = scc_begin(&Fn); !it.isAtEnd(); ++it, ++k)
        for (BasicBlock *b : *it)
          ord[idx[b]] = k;
    }
    // nullopt: a block it does not know (the walk answers).
    std::optional<bool> reaches(const BasicBlock *from, const BasicBlock *t) {
      if (dirty)
        build();
      auto fi = idx.find(from), ti = idx.find(t);
      if (fi == idx.end() || ti == idx.end())
        return std::nullopt;
      unsigned i = fi->second, j = ti->second;
      if (ord[i] != kNo && ord[j] != kNo) {
        if (ord[i] < ord[j])
          return false;
        if (ord[i] == ord[j])
          return true;   // one component of two or more blocks (from != t)
      }
      auto [it, fresh] = to.try_emplace(j);
      BitVector &bv = it->second;
      if (fresh) {
        bv.resize(unsigned(idx.size()));
        SmallVector<unsigned, 32> w{j};
        while (!w.empty())
          for (unsigned p : rev[w.pop_back_val()])
            if (!bv.test(p)) {
              bv.set(p);
              w.push_back(p);
            }
      }
      return bv.test(i);
    }
    bool dominates(const BasicBlock *d, const BasicBlock *b) {
      if (dirty)
        build();
      if (!DT)
        DT = std::make_unique<DominatorTree>(const_cast<Function &>(*F));
      return DT->dominates(d, b);
    }
  };
  static ReachCache *&activeReach() {
    static ReachCache *active = nullptr;
    return active;
  }
  // The cache answers for F's blocks while it lives; Suspend (a CFG change) turns it off and has it rebuilt after.
  struct ReachScope {
    ReachCache rc, *prev;
    explicit ReachScope(const Function &F) : prev(activeReach()) {
      rc.F = &F;
      activeReach() = &rc;
    }
    ~ReachScope() { activeReach() = prev; }
  };
  struct ReachSuspend {
    ReachCache *rc;
    ReachSuspend() : rc(activeReach()) { activeReach() = nullptr; }
    ~ReachSuspend() {
      if (rc)
        rc->dirty = true;
      activeReach() = rc;
    }
  };

  static bool reaches(const BasicBlock *from, const BasicBlock *to) {
    if (from == to)
      return true;
    if (ReachCache *rc = activeReach(); rc && from->getParent() == rc->F && to->getParent() == rc->F)
      if (std::optional<bool> r = rc->reaches(from, to))
        return *r;
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

  // Does the classical i1 `guard` reading true imply that block D ran before it? A guard D dominates does; a phi does when
  // each incoming edge that may carry true leaves a block D dominates, or carries a guard that implies it in turn.
  static bool guardImpliesRan(const Value *guard, const BasicBlock *D, unsigned depth) {
    if (auto *k = dyn_cast<ConstantInt>(guard))
      return k->isZero();
    auto *gi = dyn_cast<Instruction>(guard);
    if (!gi || !gi->getParent() || depth > 64)
      return false;
    if (gi->getParent() != D && dominates(D, gi->getParent()))
      return true;
    auto *ph = dyn_cast<PHINode>(gi);
    if (!ph)
      return false;
    for (unsigned i = 0; i < ph->getNumIncomingValues(); ++i) {
      const Value *v = ph->getIncomingValue(i);
      if (auto *k = dyn_cast<ConstantInt>(v); k && k->isZero())
        continue;
      if (!dominates(D, ph->getIncomingBlock(i)) && !guardImpliesRan(v, D, depth + 1))
        return false;
    }
    return true;
  }

  // Does d dominate b? (b unreachable from the entry while avoiding d.)
  static bool dominates(const BasicBlock *d, const BasicBlock *b) {
    if (d == b)
      return true;
    const BasicBlock *entry = &b->getParent()->getEntryBlock();
    if (entry == d)
      return true;
    if (ReachCache *rc = activeReach(); rc && d->getParent() == rc->F && b->getParent() == rc->F)
      return rc->dominates(d, b);
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
      return cq::comesBefore(b, a);
    return reaches(b->getParent(), a->getParent());
  }

  // ---- items -----------------------------------------------------------------------------------




  // cq-4593 (CR rule 17): the rails pending at each open cq_invert region's begin (openInvert), innermost
  // last. No flush places their items while the region is open.
  // Per rail, its anchors at the begin: a rail with no anchor added inside the region is placed after its
  // last earlier anchor, before the begin.
  SmallVector<DenseMap<RailId, SmallPtrSet<Instruction *, 8>>, 2> invertFrozen;
  // cq-5n3n: the number of rails at each open region's begin (parallel to invertFrozen), and that of the
  // region closeInvert closed last (resolveRegionMade reads it).
  SmallVector<RailId, 2> invertStart;
  RailId lastRegionStart = kNone;
  bool frozen(RailId g) const {
    return any_of(invertFrozen, [&](const DenseMap<RailId, SmallPtrSet<Instruction *, 8>> &s) { return s.count(g) != 0; });
  }

  // g's item may be placed now: it is still to come.
  bool resolvable(RailId g) const { return pending(g); }
  // cq-sdqu (CR rule 5: an operand rail outlives every _unc that reads it): g's item is still to come. As a reader
  // it holds back the items of the rails its item reads exactly as a resolvable one does (a clone cell's select(p, v, old) is uncomputed after the cell's last
  // access, so v outlives it: musl __rem_pio2_large's y[0] = ih ? -fw : fw under a quantum predicate).
  bool pending(RailId g) const {
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
    for (unsigned w : r.writes)
      out.push_back(w);
    return out;
  }

  SmallVector<RailId, 4> itemReads(RailId g) const {
    SmallVector<RailId, 4> out = ownReads(g);
    // cq-lshe: the rails the sandwich of the item reads (the operands of in-place writes it may undo and
    // redo around itself) outlive it too.
    if (rails[g].deferred == kNone) {
      SmallVector<unsigned, 4> ws = sandwichCands(g);
      if (!ws.empty()) {
        SmallDenseSet<RailId, 16> seen(out.begin(), out.end());   // cq-g3h1i: a sandwich may read many rails
        for (unsigned w : ws)
          for (RailId x : info[w].reads)
            if (x != g && seen.insert(x).second)
              out.push_back(x);
      }
    }
    return out;
  }
  // cq-g3h1i: itemReads(g) holds one of ns, answered without building the list: g's own reads first, the
  // sandwich only when they hold none.
  bool itemReadsAny(RailId g, ArrayRef<RailId> ns) const {
    SmallVector<RailId, 4> own = ownReads(g);
    if (any_of(ns, [&](RailId n) { return is_contained(own, n); }))
      return true;
    if (rails[g].deferred != kNone)
      return false;
    for (unsigned w : sandwichCands(g))
      for (RailId x : info[w].reads)
        if (x != g && is_contained(ns, x))
          return true;
    return false;
  }
  SmallVector<RailId, 4> ownReads(RailId g) const {
    const Rail &r = rails[g];
    if (r.deferred != kNone)
      return SmallVector<RailId, 4>(defs[r.deferred].reads.begin(), defs[r.deferred].reads.end());
    SmallVector<RailId, 4> out;
    if (r.cleanup) {
      if (r.cleanup->alts.empty())
        return SmallVector<RailId, 4>(r.cleanup->reads.begin(), r.cleanup->reads.end());
      // cq-mgkr: an image a keeper keeps (the classical merge that chose it, kept) is alive on its alternative's
      // path whatever its own item does elsewhere: no order between the two items.
      for (RailId x : r.cleanup->reads)
        if (rails[x].keepers.empty())
          out.push_back(x);
      if (r.role != Role::Garbage || r.cleanup->everyPath)
        return out;   // a guarded clean-up's plain part undoes the rail's records (below)
      // cq-dw87k: undone() answers nothing for a rail with a clean-up, so the plain part's reads go in by hand.
      if (!directRelease(g)) {
        SmallVector<unsigned, 4> recs;
        if (r.creator != kNone)
          recs.push_back(r.creator);
        recs.append(r.writes.begin(), r.writes.end());
        for (unsigned rec : recs)
          for (RailId x : info[rec].reads)
            if (x != g && !is_contained(out, x))
              out.push_back(x);
      }
      return out;
    }
    for (unsigned rec : undone(g))
      for (RailId x : info[rec].reads)
        if (x != g && !is_contained(out, x))
          out.push_back(x);
    return out;
  }
  SmallVector<unsigned, 4> sandwichCands(RailId g) const {
    SmallVector<unsigned, 4> out;
    const Rail &r = rails[g];
    if (r.deferred != kNone)
      return out;
    struct Rd { RailId x; const Instruction *at; };
    SmallVector<Rd, 8> R;
    auto addReads = [&](ArrayRef<RailId> xs, const Instruction *at) {
      for (RailId x0 : xs)
        for (RailId x : leaves(x0))
          if (x != g)
            R.push_back({x, at});
    };
    if (r.cleanup) {
      addReads(r.cleanup->reads, r.creator != kNone ? records[r.creator].forward : nullptr);
    } else {
      for (unsigned rec : undone(g))
        addReads(info[rec].reads, records[rec].forward);
    }
    SmallDenseSet<unsigned, 16> taken;   // cq-g3h1i: out's members
    for (unsigned i = 0; i < R.size(); ++i) {
      Rd rd = R[i];
      for (unsigned w : rails[rd.x].writes) {
        const Instruction *f = records[w].forward;
        if (taken.count(w) || !f->getParent() || (rd.at && (f == rd.at || !after(f, rd.at))))
          continue;
        taken.insert(w);
        out.push_back(w);
        for (RailId y0 : info[w].reads)
          for (RailId y : leaves(y0))
            if (y != g)
              R.push_back({y, f});
      }
    }
    return out;
  }

  // CR rule 6 ("when the old value is still needed to uncompute other rails, those are uncomputed
  // first"): a clean-up whose inverse reads a garbage rail whose own uncompute reads the cleaned
  // rail cannot run. That garbage is uncomputed first, which leaves no y' to recompute the old
  // value from, so the old rail keeps its role (42: s = y + x is garbage, y stays a register).
  // cq-hfj9: `failed` keeps, per rail, the least depth at which the walk from it found no path to g (the
  // item graph shares its rails, so without it the walk is exponential: asinhl). The answer only weakens
  // as the depth grows, so a rail that failed at depth d fails at every depth >= d.
  bool garbageReads(RailId x, RailId g) const {
    DenseMap<RailId, unsigned> failed;
    return garbageReadsAt(x, g, 0, failed);
  }
  bool garbageReadsAt(RailId x, RailId g, unsigned depth, DenseMap<RailId, unsigned> &failed) const {
    // cq-dw87k: a clean-up under a guard that does not cover every path leaves x's plain item, which reads what it reads, on the
    // other paths: x is still a garbage reader of g.
    bool cleaned = rails[x].cleanup && (rails[x].cleanup->alts.empty() || rails[x].cleanup->everyPath);
    // cq-jt90l (CR rule 6, "when the old value is still needed to uncompute other rails"): a seed whose writes are
    // not all preserving (a trip flag, a flag's and_i1) is undone through those records like garbage, and they read
    // what they read: g = x, y' = c ? x + 1 : x with c's _unc reading a classical loop's trip flags that tested x.
    bool undoes = rails[x].role == Role::Garbage || (rails[x].role == Role::Seed && !directRelease(x));
    // cq-8qs3j (CR rules 6, 14): a rail of a deferred item's scopes (a loop's exit rail) is undone by that item's reverse
    // loop, which reads what the item reads: a classical loop's trips that tested g (nob2: b's clean-up through s + b
    // reads the loop's exit s, the loop's reverse reads b).
    if (unsigned di = rails[x].ownedBy; depth <= 64 && di != kNone && !rails[x].released && !rails[defs[di].pseudo].released) {
      if (auto f = failed.find(x); f != failed.end() && f->second <= depth)
        return false;
      for (RailId y : defs[di].reads)
        if (y == g || garbageReadsAt(y, g, depth + 1, failed))
          return true;
    }
    if (depth > 64 || (cleaned && !viaCleanups) || !undoes || rails[x].released)
      return false;
    if (auto f = failed.find(x); f != failed.end() && f->second <= depth)
      return false;
    // viaCleanups (cq-4wbdf): x cleaned by rule 6 itself is freed by its clean-up, which reads the image and the
    // inverse's operands: they outlive x's uncompute in turn. A clean-up the plain rule drops once x is resolved (a
    // garbage operand reading x) is x's plain item instead.
    if (cleaned) {
      viaCleanups = false;
      if (any_of(rails[x].cleanup->reads, [&](RailId z) { return garbageReads(z, x); }))
        cleaned = false;
      viaCleanups = true;
    }
    // cq-jt90l: a read of a merge reads every rail it may name (readersOf's names, order()'s edges): the select's
    // condition above reads the loop's exit merge, whose arms read the trip flags.
    for (RailId y0 : cleaned ? rails[x].cleanup->reads : itemReads(x))
      for (RailId y : leaves(y0))
        if (y == g || y0 == g || garbageReadsAt(y, g, depth + 1, failed))
          return true;
    auto [f, ins] = failed.try_emplace(x, depth);
    if (!ins && depth < f->second)
      f->second = depth;
    return false;
  }
  // `only`: prune the clean-ups of these rails alone (a local flush, cq-1jxg). A pending clean-up whose
  // operand is garbage now may find it kept later (a measurement after a later reader of the old value
  // in another block), so the decision waits until the old rail itself is resolved.
  void pruneCleanups(const SmallVectorImpl<RailId> *only = nullptr) {
    syncPhiHits();   // cq-igqp: before any placement
    // cq-ewzri: the rails visited, in rail order: `only` sorted (the same visits as filtering every rail by
    // membership in it, without a scan of `only` per rail of the function).
    std::vector<RailId> picked;
    if (only) {
      picked.assign(only->begin(), only->end());
      llvm::sort(picked);
      picked.erase(std::unique(picked.begin(), picked.end()), picked.end());
    }
    auto visit = [&](auto &&f) {
      if (!only) {
        for (RailId g = 0; g < rails.size(); ++g)
          if (f(g))
            return;
        return;
      }
      for (RailId g : picked)
        if (g < rails.size() && f(g))
          return;
    };
    for (;;) {
      // To a fixed point: dropping one clean-up makes its rail plain garbage again, which may now be a
      // garbage reader of an earlier clean-up's operand (164's clone: %6 = %7 - %3 kept while %7's own
      // clean-up through the result was still there, then %7's dropped: a cycle).
      for (bool again = true; again;) {
        again = false;
        visit([&](RailId g) {
          if (pruneOne(g))
            again = true;
          return false;
        });
      }
      // cq-4wbdf (CR rule 6: "when the old value is still needed to uncompute other rails, those are uncomputed
      // first"; "the old value is kept only when no such point exists"): a cycle that runs through another rail's
      // clean-up. g = sext q cleaned against s = g + a, s cleaned against s + m, m a garbage select whose item reads
      // g through its condition: g's clean-up needs s, s's needs m, m's uncompute needs g. No order places all three.
      // Once nothing else drops, the first such clean-up (rail order) gives way to g's plain item, one at a time, the
      // plain fixed point again after each: the others may hold then.
      viaCleanups = true;
      bool dropped = false;
      visit([&](RailId g) { return dropped = pruneOne(g); });
      viaCleanups = false;
      if (!dropped)
        return;
    }
  }
  mutable bool viaCleanups = false;   // garbageReads walks through a cleaned rail's clean-up (pruneCleanups' second phase)
  bool pruneOne(RailId g) {
    Rail &r = rails[g];
    if (!r.cleanup || r.released)
      return false;
    if (!r.cleanup->alts.empty()) {
      // cq-mgkr: an alternative whose image is garbage reading g (rule 5 undoes the image through g) is
      // dropped; g's plain item runs on its path instead.
      auto &alts = r.cleanup->alts;
      size_t before = alts.size();
      alts.erase(std::remove_if(alts.begin(), alts.end(),
                                [&](const Cleanup::Alt &a) {
                                  return any_of(a.reads, [&](RailId x) {
                                    return rails[x].keepers.empty() && garbageReads(x, g);
                                  });
                                }),
                 alts.end());
      if (alts.size() == before)
        return false;
      r.cleanup->everyPath = false;   // the dropped alternative's path takes the plain item
      for (RailId x : r.cleanup->reads)
        llvm::erase(rails[x].cleanupReaders, g);
      if (alts.empty()) {
        r.cleanup.reset();
        keepIfNoProducer(g);
        return true;
      }
      r.cleanup->reads.clear();
      for (const Cleanup::Alt &a : alts)
        for (RailId x : a.reads)
          if (!is_contained(r.cleanup->reads, x)) {
            r.cleanup->reads.push_back(x);
            rails[x].cleanupReaders.push_back(g);
          }
      return true;
    }
    bool drop = false;
    for (RailId x : r.cleanup->reads)
      if (garbageReads(x, g)) {
        drop = true;
        break;
      }
    if (!drop)
      return false;
    for (RailId x : r.cleanup->reads)
      llvm::erase(rails[x].cleanupReaders, g);
    r.cleanup.reset();
    keepIfNoProducer(g);
    return true;
  }
  // cq-rb96s (CR rule 6: "the old value is kept only when no such point exists"; GMP toom6h_mul): a rail with no producer
  // (a merge of kept arms that rule 6 took over, spine clean/keptMerge) has no plain item to fall back on once its
  // clean-up gives way: it is kept, as the merge of kept arms was.
  void keepIfNoProducer(RailId g) {
    if (rails[g].creator == kNone && rails[g].role == Role::Garbage)
      rails[g].role = Role::Kept;
  }

  // cq-g3h1i: itemReads per rail, kept while resolve only reads the rails (dropBlocked and order: no record,
  // rail or instruction changes between their calls); null outside.
  mutable DenseMap<RailId, SmallVector<RailId, 4>> *readsMemo = nullptr;

  // Rails whose item reads g, directly or through a merge that may name g (U1).
  SmallVector<RailId, 4> readersOf(RailId g) const {
    if (rails[g].deferred != kNone) {
      // F1: the item frees its exit rails, so every rail outside it whose item reads one goes first.
      const Deferred &d = defs[rails[g].deferred];
      // cq-03rdt (CR rules 5, 14): a rail a record of the item's own scopes made is the item's, undone by its reverse,
      // also once an enclosing loop's recordDeferred took it over (ownedBy names the outer item then).
      auto own = [&](RailId o) {
        unsigned c = rails[o].creator;
        return rails[o].ownedBy == rails[g].deferred ||
               (c != kNone && any_of(d.scopes, [&](unsigned s) {
                  return c >= scopes[s].begin && c < scopes[s].end && !scopes[s].left.count(o);
                }));
      };
      SmallVector<RailId, 4> out;
      for (RailId x : d.exits)
        for (RailId o : readersOf(x))
          if (o != g && !own(o) && !is_contained(out, o))
            out.push_back(o);
      return out;
    }
    SmallVector<RailId, 4> ns = ownNames(g); // cq-lshe: not the readers through a keeper
    SmallVector<RailId, 4> cand;
    // cq-lshe: an in-place write reading g is in the sandwich of the items that read its target (or, in
    // turn, a rail another such write reads): those items read g too (itemReads), so they are candidates.
    SmallVector<RailId, 4> targets;
    // cq-g3h1i: membership through a set beside each list (a rail many records read has many candidates).
    SmallDenseSet<RailId, 16> candSet, targetSet;
    auto addCands = [&](RailId n) {
      for (unsigned rec : rails[n].readerRecs) {
        if (candSet.insert(info[rec].item).second)
          cand.push_back(info[rec].item);
        if (!isCreator(info[rec].kind))
          if (RailId t = records[rec].out; t < rails.size() && targetSet.insert(t).second)
            targets.push_back(t);
      }
      for (RailId o : rails[n].cleanupReaders)
        if (candSet.insert(o).second)
          cand.push_back(o);
    };
    for (RailId n : ns)
      addCands(n);
    for (unsigned i = 0; i < targets.size(); ++i)
      for (RailId n : names(targets[i]))
        addCands(n);
    SmallVector<RailId, 4> out;
    for (RailId o : cand) {
      if (o == g)
        continue;
      if (readsMemo) {
        auto [it, fresh] = readsMemo->try_emplace(o);
        if (fresh)
          it->second = itemReads(o);
        const SmallVector<RailId, 4> &rd = it->second;
        if (!any_of(ns, [&](RailId n) { return is_contained(rd, n); }))
          continue;
      } else if (!itemReadsAny(o, ns)) {
        continue;
      }
      // F1: a reader owned by a deferred item not yet placed is undone by that item.
      if (unsigned di = rails[o].ownedBy; di != kNone && rails[g].ownedBy != di && !rails[defs[di].pseudo].released)
        o = defs[di].pseudo;
      // Rule 14: an exit rail of a deferred loop is undone by that loop's reverse: that item is the reader.
      for (const Deferred &d : defs)
        if (d.pseudo != g && !rails[d.pseudo].released && is_contained(d.exits, o) && !is_contained(d.exits, g)) {
          o = d.pseudo;
          break;
        }
      if (o != g && !is_contained(out, o))
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
    if (r.group != kNone && r.creator != kNone && info[r.creator].kind == RecKind::Call) {
      const CallGroup &cg = groups[r.group];
      for (RailId m : cg.members)
        if (auto *i = dyn_cast<Instruction>(rails[m].handle))
          out.push_back(i);
      for (Value *e : cg.extra)
        if (auto *i = dyn_cast<Instruction>(e); i && i->getParent() && !(i->getParent() == cg.fwd->getParent() && cq::comesBefore(i, cg.fwd)))
          out.push_back(i);
    }
    for (unsigned w : r.writes)
      out.push_back(records[w].forward);
    // U1: a use of a merge that may name g is a use of g (cq-lshe: not through a keeper of g, where g is kept).
    for (RailId n : ownNames(g)) {
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
      if (a->getParent() == bb && (!latest || cq::comesBefore(latest, a)))
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

  enum class Bar { Hit, Write };
  // The barrier events of g's item: (event, kind) that must not precede the item.
  SmallVector<std::pair<Instruction *, Bar>, 4> barriers(RailId g) const {
    SmallVector<std::pair<Instruction *, Bar>, 4> out;
    auto eventsOf = [&](RailId x, auto &&isAfterBase) {
      const Rail &rx = rails[x];
      for (Instruction *h : rx.hits)
        if (isAfterBase(h))
          out.push_back({h, Bar::Hit});
      if (x == g)
        return; // g's own writes are undone by its item
      for (unsigned w : rx.writes)
        if (isAfterBase(records[w].forward))
          out.push_back({records[w].forward, Bar::Write});
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
        out.push_back({h, Bar::Hit});
    }
    // De-duplicate (an event may be reachable through several records).
    SmallVector<std::pair<Instruction *, Bar>, 4> uniq;
    for (auto &e : out)
      if (!is_contained(uniq, e))
        uniq.push_back(e);
    return uniq;
  }


  // m and every rail it may name, merges included (m first).
  SmallVector<RailId, 4> closure(RailId m) const {
    SmallVector<RailId, 4> out{m};
    for (unsigned i = 0; i < out.size(); ++i)
      for (RailId a : rails[out[i]].arms)
        if (!is_contained(out, a))
          out.push_back(a);
    return out;
  }

  // Does n name a on every path (statically): n is a, a cell load naming a directly or through a merge
  // that always names it, or a phi or select every incoming of which always names a.
  bool alwaysChosen(RailId n, RailId a, unsigned depth = 0) const {
    if (n == a)
      return true;
    if (!isMerge(n) || depth > 32)
      return false;
    if (rails[n].group != kNone) {
      for (RailId x : rails[n].arms)
        if (alwaysChosen(x, a, depth + 1))
          return true;
      return false;
    }
    SmallVector<Value *, 4> ins;
    if (auto *phi = dyn_cast<PHINode>(rails[n].handle))
      ins.append(phi->incoming_values().begin(), phi->incoming_values().end());
    else if (auto *sel = dyn_cast<SelectInst>(rails[n].handle))
      ins = {sel->getTrueValue(), sel->getFalseValue()};
    for (Value *v : ins) {
      auto it = byHandle.find(v);
      if (it == byHandle.end() || !alwaysChosen(it->second, a, depth + 1))
        return false;
    }
    return !ins.empty();
  }

  void keepMerge(RailId m, Role role) {
    // The rails m may name that are resolvable before the role is set: the decisions below read this
    // snapshot, so the order of m's arms changes nothing; rails kept already stay as they are.
    DenseSet<RailId> live;
    for (RailId x : closure(m))
      if (pending(x))
        live.insert(x);
    for (RailId x : closure(m)) {
      if (x == m)
        continue;
      if (isMerge(x)) {
        rails[x].role = role;
        continue;
      }
      if (!live.count(x))
        continue;
      if (rails[x].ownedBy != kNone || alwaysChosen(m, x))
        rails[x].role = role;
      else if (!is_contained(rails[x].keepers, m))
        rails[x].keepers.push_back(m);
    }
  }

  // cq-lshe (CR rule 9): the classical i1 "n names a" at n's definition. A rail names itself; a phi
  // merge chooses by its incoming edge (an i1 phi beside it), a select merge by its classical condition
  // (an i1 select beside it); a cell load may name each of its arms (true for a direct arm, else the
  // disjunction over its merge arms). Nested merges compose.
  DenseMap<std::pair<RailId, RailId>, Value *> chooseMemo;
  Value *chooses(RailId n, RailId a) {
    LLVMContext &C = rails[a].handle->getContext();
    Type *I1 = Type::getInt1Ty(C);
    if (n == a)
      return ConstantInt::getTrue(C);
    if (!isMerge(n) || !is_contained(closure(n), a))
      return ConstantInt::getFalse(C);
    if (auto it = chooseMemo.find({n, a}); it != chooseMemo.end())
      return it->second;
    auto *nh = cast<Instruction>(rails[n].handle);
    if (rails[n].group != kNone) {
      if (is_contained(rails[n].arms, a))
        return chooseMemo[{n, a}] = ConstantInt::getTrue(C);
      Value *v = ConstantInt::getFalse(C);
      Instruction *ip = nh->getNextNode();
      for (RailId x : rails[n].arms) {
        Value *c = chooses(x, a);
        if (auto *k = dyn_cast<ConstantInt>(c)) {
          if (k->isOne())
            return chooseMemo[{n, a}] = c;
          continue;
        }
        if (auto *k = dyn_cast<ConstantInt>(v); k && k->isZero())
          v = c;
        else
          v = track(BinaryOperator::CreateOr(v, c, "cq.ch", ip));
      }
      return chooseMemo[{n, a}] = v;
    }
    if (auto *phi = dyn_cast<PHINode>(nh)) {
      PHINode *p = PHINode::Create(I1, phi->getNumIncomingValues(), "cq.ch");
      p->insertAfter(phi);
      emitted.insert(p);
      chooseMemo[{n, a}] = p;
      for (unsigned i = 0; i < phi->getNumIncomingValues(); ++i)
        p->addIncoming(chooses(lookup(phi->getIncomingValue(i), "chooses", phi), a), phi->getIncomingBlock(i));
      Value *same = nullptr;
      bool uniform = true;
      for (Value *v : p->incoming_values())
        if (v != p) {
          uniform = uniform && (!same || same == v);
          same = same ? same : v;
        }
      if (uniform && same && isa<Constant>(same)) {
        p->replaceAllUsesWith(same);
        p->eraseFromParent();
        emitted.erase(p);
        return chooseMemo[{n, a}] = same;
      }
      return p;
    }
    auto *sel = cast<SelectInst>(nh);
    Value *t = chooses(lookup(sel->getTrueValue(), "chooses", sel), a);
    Value *f = chooses(lookup(sel->getFalseValue(), "chooses", sel), a);
    if (t == f)
      return chooseMemo[{n, a}] = t;
    auto *kt = dyn_cast<ConstantInt>(t), *kf = dyn_cast<ConstantInt>(f);
    if (kt && kf && kt->isOne())   // (c ? true : false) is c itself
      return chooseMemo[{n, a}] = sel->getCondition();
    auto *s = SelectInst::Create(sel->getCondition(), t, f, "cq.ch");
    s->insertAfter(sel);
    emitted.insert(s);
    return chooseMemo[{n, a}] = s;
  }
  Instruction *track(Instruction *i) {
    emitted.insert(i);
    return i;
  }

  // ---- run flags (cq-lshe, CR §0, rules 5, 9) ---------------------------------------------------
  //
  // A classical i1 path variable: dflt at the entry; at each event, in program order, set (true) or
  // cleared where its condition holds (flag &= !cond). Its value at an instruction is built as SSA:
  // phis at the joins (over the output CFG's real predecessors, as carryTo), and/xor before the
  // terminators of the blocks with events; a block with a set event starts from it. Trivial phis are
  // folded, a clear by an i1 phi beside a merge is applied per incoming edge (so a choice made on every
  // path folds to a constant).
  struct FlagEv {
    Instruction *at;               // a phi: the top of its block
    bool set;                      // set: true; else clear by cond
    RailId merge = kNone, arm = kNone; // the clear's cond: chooses(merge, arm); merge kNone: true
    Value *cond = nullptr;             // cq-4lqy: a clear by this run-time i1 instead (merge unused)
  };
  Value *flagAt(Instruction *at, ArrayRef<FlagEv> evs, bool dflt) {
    LLVMContext &C = at->getContext();
    Type *I1 = Type::getInt1Ty(C);
    Constant *T = ConstantInt::getTrue(C), *F = ConstantInt::getFalse(C);
    // The conditions first: they may add phis and selects beside merges.
    SmallVector<Value *, 8> conds;
    for (const FlagEv &e : evs)
      conds.push_back(e.set ? T : e.cond ? e.cond : e.merge == kNone ? static_cast<Value *>(T) : chooses(e.merge, e.arm));
    // Insertion order (cq-aeroi): the loops over byBlock mint run flags and seed worklists, and a DenseMap keyed by block
    // address walks in an order that changes from run to run.
    MapVector<const BasicBlock *, SmallVector<unsigned, 2>> byBlock;
    for (unsigned i = 0; i < evs.size(); ++i)
      if (evs[i].at && evs[i].at->getParent())
        byBlock[evs[i].at->getParent()].push_back(i);
    for (auto &kv : byBlock)
      llvm::stable_sort(kv.second, [&](unsigned x, unsigned y) {
        return evs[x].at != evs[y].at && cq::comesBefore(evs[x].at, evs[y].at);
      });
    // cq-a24ig: the flag is a function of the path alone, decided by dflt, the events of each block in their order with
    // their conditions, and the CFG. While the CFG stands (an active ReachCache that is not dirty), a query at a block
    // holding no event asks what an earlier query with the same events at the same block asked: its answer is reused
    // where it still dominates `at` (a function with many K-loops has thousands of items placed at a return, each of
    // which would mint its own chain of run phis over every classical arm).
    std::vector<uintptr_t> memoKey;
    std::vector<WeakVH> memoConds;
    ReachCache *rc = activeReach();
    if (rc && rc->F != at->getFunction())
      rc = nullptr;
    if (rc && !byBlock.count(at->getParent())) {
      if (rc->dirty)
        rc->build();
      SmallVector<const BasicBlock *, 8> bs;
      for (auto &kv : byBlock)
        bs.push_back(kv.first);
      llvm::sort(bs, [&](const BasicBlock *x, const BasicBlock *y) { return std::less<const BasicBlock *>()(x, y); });
      memoKey.push_back(reinterpret_cast<uintptr_t>(at->getParent()));
      memoKey.push_back(dflt);
      for (const BasicBlock *b : bs) {
        const SmallVector<unsigned, 2> &is = byBlock.find(b)->second;
        memoKey.push_back(reinterpret_cast<uintptr_t>(b));
        memoKey.push_back(is.size());
        for (unsigned i : is) {
          memoKey.push_back(evs[i].set);
          memoKey.push_back(reinterpret_cast<uintptr_t>(conds[i]));
          memoConds.emplace_back(conds[i]);
        }
      }
      if (auto it = rc->flagMemo.find(memoKey);
          it != rc->flagMemo.end() && all_of(it->second.conds, [](const WeakVH &c) { return c != nullptr; })) {
        Value *v = it->second.r;
        if (v && isa<ConstantInt>(v))
          return v;
        if (auto *vi = dyn_cast_or_null<Instruction>(v); vi && vi->getParent() && vi->getFunction() == at->getFunction() &&
                                                          (vi->getParent() == at->getParent()
                                                               ? vi != at && cq::comesBefore(vi, at)
                                                               : dominates(vi->getParent(), at->getParent())))
          return v;
      }
    }
    std::vector<PHINode *> made;
    std::vector<Instruction *> ops;   // and/xor made here
    DenseMap<BasicBlock *, Value *> startOf, endOf;
    SmallPtrSet<BasicBlock *, 8> busy;
    // cq-jws5r (CR rules 8, 14): a function whose K-loop trips branch on classical conditions has one join per branch, and
    // the walk below visits every one of them for every flag. Two facts cut it short there, each giving
    // the value the walk would fold its phis to: a block no event block reaches starts at dflt; and the join of a
    // noted classical arm (noteClassicalArm) whose arm reaches no event block starts with the value its branch ends
    // with (every path into the join leaves that branch, and none passes an event).
    const bool arms = !armJoins.empty();
    SmallPtrSet<const BasicBlock *, 32> reachEvent, afterEvent;
    if (arms) {
      SmallVector<const BasicBlock *, 32> w;
      for (auto &kv : byBlock) {
        reachEvent.insert(kv.first);
        w.push_back(kv.first);
      }
      while (!w.empty())
        for (const BasicBlock *p : predecessors(w.pop_back_val()))
          if (reachEvent.insert(p).second)
            w.push_back(p);
      for (auto &kv : byBlock)
        w.push_back(kv.first);
      while (!w.empty())
        if (const Instruction *t = w.pop_back_val()->getTerminator())
          for (const BasicBlock *n : successors(t))
            if (afterEvent.insert(n).second)
              w.push_back(n);
    }
    auto armEntry = [&](BasicBlock *b) -> BasicBlock * {
      BasicBlock *first = nullptr;
      BasicBlock *pre = arms ? armBranch(b, first) : nullptr;
      return pre && !reachEvent.count(first) ? pre : nullptr;
    };
    std::function<Value *(Value *, Value *, Instruction *, BasicBlock *)> clearWith =
        [&](Value *v, Value *c, Instruction *ip, BasicBlock *b) -> Value * {
      if (auto *k = dyn_cast<ConstantInt>(c))
        return k->isZero() ? v : F;
      if (auto *k = dyn_cast<ConstantInt>(v); k && k->isZero())
        return F;
      // A choice phi of this block: apply it per incoming edge (v is a start phi of the block or a constant).
      auto *cp = dyn_cast<PHINode>(c);
      auto *vp = dyn_cast<PHINode>(v);
      // (Only over a complete start phi: one still being filled lies on a cycle being built.)
      auto complete = [&](PHINode *q) {
        return all_of(cp->blocks(), [&](BasicBlock *p) { return q->getBasicBlockIndex(p) >= 0; });
      };
      if (cp && cp->getParent() == b &&
          (isa<Constant>(v) || (vp && vp->getParent() == b && is_contained(made, vp) && complete(vp)))) {
        PHINode *np = PHINode::Create(I1, cp->getNumIncomingValues(), "cq.run");
        np->insertInto(b, b->begin());
        emitted.insert(np);
        made.push_back(np);
        for (unsigned i = 0; i < cp->getNumIncomingValues(); ++i) {
          BasicBlock *p = cp->getIncomingBlock(i);
          if (int seen = np->getBasicBlockIndex(p); seen >= 0) {   // both edges of one branch into b: one value
            np->addIncoming(np->getIncomingValue(seen), p);
            continue;
          }
          Value *vi = vp ? vp->getIncomingValueForBlock(p) : v;
          np->addIncoming(clearWith(vi, cp->getIncomingValue(i), p->getTerminator(), p), p);
        }
        return np;
      }
      Instruction *n = track(BinaryOperator::CreateXor(c, T, "cq.not", ip));
      ops.push_back(n);
      if (isa<ConstantInt>(v))   // true here
        return n;
      Instruction *a = track(BinaryOperator::CreateAnd(v, n, "cq.run", ip));
      ops.push_back(a);
      return a;
    };
    std::function<Value *(BasicBlock *)> startV, endV;
    auto applyIn = [&](BasicBlock *b, Instruction *limit, Instruction *ip) -> Value * {
      SmallVector<unsigned, 4> es;
      if (auto it = byBlock.find(b); it != byBlock.end())
        for (unsigned i : it->second)
          if (!limit || (evs[i].at != limit && cq::comesBefore(evs[i].at, limit)))
            es.push_back(i);
      int lastSet = -1;
      for (unsigned k = 0; k < es.size(); ++k)
        if (evs[es[k]].set)
          lastSet = static_cast<int>(k);
      Value *v = lastSet >= 0 ? static_cast<Value *>(T) : startV(b);
      for (unsigned k = lastSet + 1; k < es.size(); ++k)
        v = clearWith(v, conds[es[k]], ip, b);
      return v;
    };
    endV = [&](BasicBlock *b) -> Value * {
      if (auto it = endOf.find(b); it != endOf.end())
        return it->second;
      if (!b->getTerminator())
        internalError("uncompute: a run flag through a block that is not terminated yet", at);
      Value *v = applyIn(b, nullptr, b->getTerminator());
      return endOf[b] = v;
    };
    startV = [&](BasicBlock *b) -> Value * {
      if (auto it = startOf.find(b); it != startOf.end())
        return it->second;
      SmallVector<BasicBlock *, 4> ps(predecessors(b));
      if (b->isEntryBlock() || ps.empty())
        return startOf[b] = dflt ? T : F;
      if (arms && !afterEvent.count(b))
        return startOf[b] = dflt ? T : F;
      if (BasicBlock *pre = armEntry(b)) {
        // The joins straight above it that are such joins too and hold no event: one value for all of them.
        SmallVector<BasicBlock *, 16> js{b};
        while (!byBlock.count(pre) && !startOf.count(pre) && !endOf.count(pre)) {
          BasicBlock *up = armEntry(pre);
          if (!up)
            break;
          js.push_back(pre);
          pre = up;
        }
        Value *v = endV(pre);
        for (size_t k = 0; k < js.size(); ++k) {
          startOf[js[k]] = v;
          if (k)
            endOf[js[k]] = v;
        }
        return v;
      }
      if (ps.size() == 1) {
        if (!busy.insert(b).second) {
          // Re-entered while its own start is in progress. Only a cycle of single-predecessor blocks is unreachable
          // (F). Otherwise the walk entered the cycle here and went round it through a block with several
          // predecessors, whose start phi is made already (cq-j9bvd: a loop's back edge entered through its latch
          // segment read F, so the header's run flag dropped the trip path): the value is b's predecessor's end,
          // recomputed without caching up the chain of blocks in progress, which stops at that phi.
          BasicBlock *q = ps[0];
          while (q != b && !startOf.count(q) && busy.count(q) && q->getSinglePredecessor())
            q = q->getSinglePredecessor();
          return q != b && startOf.count(q) ? endV(ps[0]) : static_cast<Value *>(F);
        }
        Value *v = endV(ps[0]);
        busy.erase(b);
        return startOf[b] = v;
      }
      PHINode *phi = PHINode::Create(I1, ps.size(), "cq.run");
      phi->insertInto(b, b->begin());
      emitted.insert(phi);
      made.push_back(phi);
      startOf[b] = phi;
      for (BasicBlock *p : ps)
        phi->addIncoming(endV(p), p);
      return phi;
    };
    Value *r = applyIn(at->getParent(), at, at);
    // Fold trivial phis and drop unused ones, to a fixed point.
    for (bool changed = true; changed;) {
      changed = false;
      for (PHINode *&phi : made) {
        if (!phi)
          continue;
        bool dead = phi != r && all_of(phi->users(), [&](User *u) { return u == phi; });
        if (dead) {
          phi->replaceAllUsesWith(PoisonValue::get(I1));
          emitted.erase(phi);
          phi->eraseFromParent();
          phi = nullptr;
          changed = true;
          continue;
        }
        // Trivial through cycles of made phis: every value reached through them is one value.
        Value *same = nullptr;
        bool trivial = true;
        SmallPtrSet<PHINode *, 8> seen;
        SmallVector<PHINode *, 8> work{phi};
        while (!work.empty() && trivial) {
          PHINode *q = work.pop_back_val();
          if (!seen.insert(q).second)
            continue;
          for (Value *in : q->incoming_values()) {
            if (auto *qp = dyn_cast<PHINode>(in); qp && is_contained(made, qp)) {
              work.push_back(qp);
              continue;
            }
            if (in == same)
              continue;
            if (same) {
              trivial = false;
              break;
            }
            same = in;
          }
        }
        if (!trivial || !same)
          continue;
        phi->replaceAllUsesWith(same);
        if (r == phi)
          r = same;
        emitted.erase(phi);
        phi->eraseFromParent();
        phi = nullptr;
        changed = true;
      }
    }
    // Instructions made here that nothing reads (a block's end value computed twice on a cycle).
    for (bool changed = true; changed;) {
      changed = false;
      for (Instruction *&i : ops)
        if (i && i != r && i->use_empty()) {
          emitted.erase(i);
          i->eraseFromParent();
          i = nullptr;
          changed = true;
        }
      for (PHINode *&phi : made)
        if (phi && phi != r && all_of(phi->users(), [&](User *u) { return u == phi; })) {
          phi->replaceAllUsesWith(PoisonValue::get(I1));
          emitted.erase(phi);
          phi->eraseFromParent();
          phi = nullptr;
          changed = true;
        }
    }
    sweepChooses(r);
    if (!memoKey.empty() && activeReach() == rc && !rc->dirty)
      rc->flagMemo[memoKey] = {r, std::move(memoConds)};
    return r;
  }
  // Choice values nothing reads (a flag that folded to a constant): erased, to a fixed point.
  void sweepChooses(Value *keep) {
    for (bool changed = true; changed;) {
      changed = false;
      for (auto it = chooseMemo.begin(); it != chooseMemo.end(); ++it) {
        auto *i = dyn_cast<Instruction>(it->second);
        if (!i || i == keep || !emitted.count(i) || !all_of(i->users(), [&](User *u) { return u == i; }))
          continue;
        i->replaceAllUsesWith(PoisonValue::get(i->getType()));
        emitted.erase(i);
        i->eraseFromParent();
        chooseMemo.erase(it);
        changed = true;
        break;
      }
    }
  }

  // cq-1dgy: is there a path of at least one edge from P to B (B == P: a cycle through P) that
  // enters none of the blocks in avoid?
  static bool reachesAgain(const BasicBlock *P, const BasicBlock *B, ArrayRef<const BasicBlock *> avoid) {
    SmallPtrSet<const BasicBlock *, 16> seen;
    SmallVector<const BasicBlock *, 16> work{P};
    while (!work.empty()) {
      const BasicBlock *b = work.pop_back_val();
      const Instruction *t = b->getTerminator();
      if (!t)
        continue;
      for (const BasicBlock *s : successors(t)) {
        if (is_contained(avoid, s))
          continue;
        if (s == B)
          return true;
        if (seen.insert(s).second)
          work.push_back(s);
      }
    }
    return false;
  }

  // ---- emission --------------------------------------------------------------------------------

  CallInst *track(CallInst *c) {
    emitted.insert(c);
    return c;
  }

  // CR §1.4: a clone keeps the original's calling convention and its calls keep it (`internal fastcc` stays, and its
  // calls stay `fastcc`); a twin is defined with its forward's (calls::finalize). A reverse call of `fwd`, or of
  // its twin, is spelled with the forward call's convention (cq-5yuk9).
  CallInst *trackLike(CallInst *c, const CallInst *fwd) {
    c->setCallingConv(fwd->getCallingConv());
    return track(c);
  }

  static FunctionCallee declareFn(Module &M, StringRef name, FunctionType *FT, const Value *at) {
    if (Function *ex = M.getFunction(name)) {
      if (ex->getFunctionType() != FT)
        internalError("uncompute: " + name.str() + " is declared with another type", at);
      return {FT, ex};
    }
    return M.getOrInsertFunction(name, FT);
  }

  // CR §1.4: a _ctl clone's twin takes the predicate first: _ctl_unc(pred, outs..., args...).
  static bool ctlTwin(const CallInst *fwd) {
    const Function *F = fwd->getCalledFunction();
    std::optional<abi::CloneSpec> s = F ? abi::parseClone(F->getName()) : std::nullopt;
    return s && s->ctl && !s->unc;
  }

  // name_unc spelled from the forward call (CR §1.2, §1.3): (out, args...) or (args...).
  FunctionCallee uncOf(CallInst *fwd, bool outFirst, IRBuilder<> &B) {
    SmallVector<Type *, 6> ps;
    ArrayRef<Type *> params = fwd->getFunctionType()->params();
    if (outFirst && ctlTwin(fwd)) {
      ps.push_back(params.front());
      params = params.drop_front();
    }
    if (outFirst)
      ps.push_back(Type::getInt32Ty(fwd->getContext()));
    for (Type *t : params)
      ps.push_back(t);
    FunctionType *FT = FunctionType::get(Type::getVoidTy(fwd->getContext()), ps, false);
    return twinOf(fwd, FT, B);
  }
  // The twin <callee>_unc of FT.
  FunctionCallee twinOf(CallInst *fwd, FunctionType *FT, IRBuilder<> &) {
    if (auto it = twinNames.find(fwd); it != twinNames.end())
      return declareFn(*fwd->getModule(), it->second, FT, fwd);
    return declareFn(*fwd->getModule(), (fwd->getCalledFunction()->getName() + "_unc").str(), FT, fwd);
  }

  static SmallVector<Value *, 6> argsOf(CallInst *fwd, Value *outFirst) {
    SmallVector<Value *, 6> a;
    bool first = true, ctl = outFirst && ctlTwin(fwd);
    if (outFirst && !ctl)
      a.push_back(outFirst);
    for (Value *v : fwd->args()) {
      a.push_back(v);
      if (first && ctl)
        a.push_back(outFirst);
      first = false;
    }
    return a;
  }

  // CR §1.3 (cq-lshe, 2026-11-02): a realloc of a bus with a leaf the function did not allocate (a formal's,
  // a loaded one) reads the old logical size by cqrt_qram_size(a) right before the realloc; keyed by the
  // realloc's record, used by its release qram_realloc_<W>_unc(a', n_old).


  CallInst *emitRelease(RailId g, IRBuilder<> &B) {
    Rail &r = rails[g];
    Module &M = *B.GetInsertBlock()->getModule();
    LLVMContext &C = M.getContext();
    FunctionType *FT = FunctionType::get(Type::getVoidTy(C), {Type::getInt32Ty(C)}, false);
    return track(B.CreateCall(declareFn(M, "cqrt_free", FT, r.handle), {r.handle}));
  }

  // cq-mgkr (CR rule 6, dead on one classical path only): each alternative's clean-up under its guard, then
  // the plain item under none of them, each a segment segOut wraps (placeAt) into a block of its own.
  struct Seg { Instruction *first, *last; Value *cond; };
  SmallVector<Seg, 4> *segOut = nullptr;
  Instruction *emitGuardedCleanup(RailId g, IRBuilder<> &B) {
    Rail &r = rails[g];
    if (!segOut)
      internalError("uncompute: a rule 6 clean-up under a classical guard in a mirror (a merge on a cycle)", r.handle);
    Module &M = *B.GetInsertBlock()->getModule();
    LLVMContext &C = M.getContext();
    FunctionType *FT = FunctionType::get(Type::getVoidTy(C), {Type::getInt32Ty(C)}, false);
    // An image a keeper keeps (an arm of a kept merge) is alive at the clean-up point only where a keeper
    // chose it; elsewhere its own item undid it already: the alternative runs where its guard holds and its
    // image is so kept.
    Instruction *at = &*B.GetInsertPoint();
    SmallVector<Value *, 2> eff;
    for (const Cleanup::Alt &a : r.cleanup->alts) {
      Value *gd = a.guard;
      for (RailId x : a.reads) {
        if (rails[x].keepers.empty())
          continue;
        SmallVector<FlagEv, 4> evs;
        Instruction *def = rails[x].creator != kNone ? records[rails[x].creator].forward
                                                     : dyn_cast<Instruction>(rails[x].handle);
        if (def)
          evs.push_back({def, true});
        for (RailId m : rails[x].keepers)
          if (auto *mi = dyn_cast<Instruction>(rails[m].handle); mi && mi->getParent())
            evs.push_back({mi, false, m, x});
        Value *runs = flagAt(at, evs, !def);   // x's own item would run here: not chosen by a keeper
        B.SetInsertPoint(at);
        gd = B.CreateAnd(gd, B.CreateNot(runs));
      }
      eff.push_back(gd);
    }
    Value *none = nullptr;
    for (Value *gd : eff)
      none = none ? B.CreateOr(none, gd) : gd;
    none = B.CreateNot(none, "cq.r6.plain");
    Instruction *last = dyn_cast<Instruction>(none);
    if (!last)
      last = track(BinaryOperator::CreateOr(none, none, "cq.r6.mark", at));
    for (size_t ai = 0; ai < r.cleanup->alts.size(); ++ai) {
      const Cleanup::Alt &a = r.cleanup->alts[ai];
      SmallVector<Value *, 4> args;
      for (const Operand &o : a.ops)
        args.push_back(o.v);
      CallInst *t = track(B.CreateCall(abi::declare(M, a.inverse, false), args));
      abi::CoreSpec cp{abi::Core::Copy, templateResultType(a.inverse)};
      track(B.CreateCall(abi::declare(M, cp), {t, r.handle}));
      SmallVector<Value *, 5> uargs{t};
      uargs.append(args.begin(), args.end());
      track(B.CreateCall(abi::declare(M, a.inverse, true), uargs));
      track(B.CreateCall(declareFn(M, "cqrt_free", FT, t), {t}));
      last = emitRelease(g, B);
      segOut->push_back({t, last, eff[ai]});
    }
    if ((r.role != Role::Garbage && r.role != Role::Seed) || r.cleanup->everyPath)
      return last;   // kept where no alternative holds (the rail is the live value there), or no such path
    std::optional<Cleanup> saved = std::move(r.cleanup);
    r.cleanup.reset();
    Instruction *first = nullptr;
    {
      Instruction *mark = last;
      last = emitItem(g, B);
      first = mark->getNextNode();
    }
    r.cleanup = std::move(saved);
    if (first)
      segOut->push_back({first, last, none});
    return last;
  }

  Instruction *emitItem(RailId g, IRBuilder<> &B) {
    Rail &r = rails[g];
    bool soleCellCleaned = r.cleanup && r.group != kNone && groups[r.group].outs.empty() &&
                           groups[r.group].members.size() == 1;
    if (r.group != kNone && r.creator != kNone && info[r.creator].kind == RecKind::Call && !soleCellCleaned) {
      const CallGroup &cg = groups[r.group];
      CallInst *fwd = cg.fwd;
      Module &M = *B.GetInsertBlock()->getModule();
      LLVMContext &C = M.getContext();
      SmallVector<Type *, 8> ps;
      SmallVector<Value *, 8> args;
      bool ctl = ctlTwin(fwd);
      if (ctl) {
        ps.push_back(fwd->getArgOperand(0)->getType());
        args.push_back(fwd->getArgOperand(0));
      }
      for (RailId o : cg.outs) {
        ps.push_back(Type::getInt32Ty(C));
        args.push_back(rails[o].handle);
      }
      // Rule 19: the registers' handles after the results and before the arguments.
      for (size_t k = 0; k < cg.extra.size(); ++k) {
        ps.push_back(cg.extra[k]->getType());
        args.push_back(cg.extra[k]);
      }
      for (unsigned k = ctl ? 1 : 0; k < fwd->arg_size(); ++k) {
        ps.push_back(fwd->getArgOperand(k)->getType());
        args.push_back(fwd->getArgOperand(k));
      }
      FunctionType *TT = FunctionType::get(Type::getVoidTy(C), ps, false);
      trackLike(B.CreateCall(twinOf(fwd, TT, B), args), fwd);
      FunctionType *FT = FunctionType::get(Type::getVoidTy(C), {Type::getInt32Ty(C)}, false);
      Instruction *last = &*std::prev(B.GetInsertPoint());
      if (!cg.table)
      for (RailId o : cg.members)
        last = o == g ? emitRelease(g, B) : track(B.CreateCall(declareFn(M, "cqrt_free", FT, rails[o].handle),
                                                               {rails[o].handle}));
      return last;
    }
    if (r.cleanup && !r.cleanup->alts.empty())
      return emitGuardedCleanup(g, B);
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
      if (r.role == Role::Seed && r.creator != kNone && info[r.creator].kind != RecKind::Seed)
        internalError("uncompute: Role::Seed on a rail not minted by alloc", r.handle);
      SmallVector<unsigned, 4> recs = undone(g);
      if (r.creator == kNone)
        internalError("uncompute: a garbage rail has no producer to uncompute it", r.handle);
      for (auto it = recs.rbegin(); it != recs.rend(); ++it) {
        CallInst *fwd = records[*it].forward;
        switch (info[*it].kind) {
        case RecKind::Template:
        case RecKind::BusLoad:
          trackLike(B.CreateCall(uncOf(fwd, true, B), argsOf(fwd, fwd)), fwd);
          break;
        case RecKind::Involution:
          trackLike(B.CreateCall(fwd->getFunctionType(), fwd->getCalledOperand(), argsOf(fwd, nullptr)), fwd);
          break;
        case RecKind::Call:
          internalError("uncompute: a call group's record outside its leader's item", fwd);
        case RecKind::Seed:
          break;
        }
      }
    }
    // Rule 5 sentence 1: a load copy a memory version change overtook is un-copied all the same and not freed.
    if (r.creator != kNone && info[r.creator].kind == RecKind::BusLoad &&
        overtakenAt(records[r.creator].forward, B.GetInsertBlock(), B.GetInsertPoint())) {
      r.role = Role::Overtaken;
      return &*std::prev(B.GetInsertPoint());
    }
    return emitRelease(g, B);
  }

  bool inMirror = false;   // emitMirror is resolving: the builder is in a reverse block, not linked to the forward code
  // Rule 18's "on every path" is a path of the program: a change in an arm no path from the call enters (the other arm of a
  // quantum branch: emitted between the call and its twin, its gates under the other arm's flag) does not come first.
  bool offThePath(const Instruction *call, const Instruction *v) const {
    auto from = srcOf.find(call), to = srcOf.find(v);
    return from != srcOf.end() && to != srcOf.end() && !reaches(from->second, to->second);
  }

  // Rule 5 Memory: does a memory version change lie on a path from `load` to the point (bb, at), the load not run
  // again in between? `at` may be bb's end (a mirror's builder). twin: `load` is a clone call and the question rule 18's.
  bool overtakenAt(const Instruction *load, const BasicBlock *bb, BasicBlock::const_iterator at, bool twin = false) const {
    const BasicBlock *LB = load->getParent();
    auto versions = [&] {
      SmallVector<const Instruction *, 16> vs;
      for (const Instruction *v : this->versions)
        if (!twin || !offThePath(load, v))
          vs.push_back(v);
      return vs;
    }();
    // A reverse loop's block (emitMirror, not linked yet): the copy of every trip waits for it, so a version change
    // anywhere the forward region can go after the load overtakes it, a later trip's included (rules 5, 14).
    if (inMirror) {
      SmallPtrSet<const BasicBlock *, 16> reach;
      SmallVector<const BasicBlock *, 16> work{LB};
      while (!work.empty())
        if (const Instruction *t = work.pop_back_val()->getTerminator())
          for (const BasicBlock *s : successors(t))
            if (reach.insert(s).second)
              work.push_back(s);
      return any_of(versions, [&](const Instruction *v) {
        return reach.count(v->getParent()) || (v->getParent() == LB && cq::comesBefore(load, v));
      });
    }
    // v is one of bb's instructions before `at` (cq-g3h1i: by order, not by a scan of the block up to `at`).
    auto before = [&](const Instruction *v) {
      return v->getParent() == bb && (at == bb->end() || (v != &*at && cq::comesBefore(v, &*at)));
    };
    bool linear = LB == bb && (at == bb->end() || cq::comesBefore(load, &*at));
    if (linear) {
      for (const Instruction *v : versions)
        if (v->getParent() == LB && cq::comesBefore(load, v) && before(v))
          return true;
      return false;
    }
    SmallPtrSet<const BasicBlock *, 16> fwd, back;
    SmallVector<const BasicBlock *, 16> work;
    auto succs = [&](const BasicBlock *b) {
      if (const Instruction *t = b->getTerminator())
        for (const BasicBlock *s : successors(t))
          if (s != LB && fwd.insert(s).second)
            work.push_back(s);
    };
    succs(LB);
    while (!work.empty())
      succs(work.pop_back_val());
    work.push_back(bb);
    back.insert(bb);
    while (!work.empty())
      for (const BasicBlock *p : predecessors(work.pop_back_val()))
        if (p != LB && back.insert(p).second)
          work.push_back(p);
    for (const Instruction *v : versions) {
      const BasicBlock *VB = v->getParent();
      if (VB == LB) {
        if (cq::comesBefore(load, v))
          return true;
      } else if (VB == bb) {
        if (fwd.count(bb) && before(v))
          return true;
      } else if (fwd.count(VB) && back.count(VB)) {
        return true;
      }
    }
    return false;
  }

  // ---- batches ---------------------------------------------------------------------------------

  enum class Mode { Local, Exit, Mirror };
  struct Ctx {
    Mode mode;
    Instruction *point = nullptr; // P or R
    IRBuilder<> *mirror = nullptr;
  };

  // F1b: while a deferred item placed at a return emits its mirror, the items placed for that return
  // before it (a later POP on a bus the item writes) are done.
  const BasicBlock *mirrorExit = nullptr;
  bool done(RailId g, const Ctx &c) const {
    return rails[g].released || (c.mode == Mode::Exit && rails[g].exitsDone.count(c.point->getParent())) ||
           (c.mode == Mode::Mirror && mirrorExit && rails[g].exitsDone.count(mirrorExit));
  }

  // Readers first; ties by most recent rail first.
  SmallVector<RailId, 16> order(ArrayRef<RailId> cands, const DenseMap<RailId, SmallVector<RailId, 4>> *readers = nullptr) const {
    DenseSet<RailId> in(cands.begin(), cands.end());
    DenseMap<RailId, int> state; // 1 visiting, 2 done
    SmallVector<RailId, 16> out;
    SmallVector<RailId, 16> roots(cands.begin(), cands.end());
    llvm::sort(roots, [](RailId a, RailId b) { return a > b; });
    std::function<void(RailId)> visit = [&](RailId g) {
      int &s = state[g];
      if (s == 2)
        return;
      if (s == 1) {
        internalError("uncompute: cyclic uncompute dependency through rule 6", rails[g].handle);
      }
      s = 1;
      SmallVector<RailId, 4> rd;
      auto known = readers ? readers->find(g) : decltype(readers->find(g))();
      if (readers && known != readers->end())
        rd = known->second;
      else
        rd = readersOf(g);
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
  // cq-g3h1i: a candidate is dropped when a reader outside the set is pending, and dropping only shrinks the set,
  // so the survivors are one fixed point whatever the order of the drops. The readers of each candidate are
  // read once (nothing here changes them) and the passes repeat over them until none drops; the first drop found
  // is the one a scan restarted after every drop finds first (the fatal message names it).
  // `readers` (when given) receives readersOf of every candidate, for order().
  void dropBlocked(SmallVectorImpl<RailId> &cands, const Ctx &c, bool fatal,
                   DenseMap<RailId, SmallVector<RailId, 4>> *readers = nullptr) const {
    DenseSet<RailId> in(cands.begin(), cands.end());
    DenseMap<RailId, unsigned> copies;   // a rail listed twice stays in the set until its last copy drops
    for (RailId g : cands)
      ++copies[g];
    std::vector<SmallVector<RailId, 4>> blockers(cands.size());
    for (unsigned i = 0; i < cands.size(); ++i) {
      SmallVector<RailId, 4> rd = readersOf(cands[i]);
      for (RailId o : rd)
        if (pending(o) && !done(o, c))
          blockers[i].push_back(o);
      if (readers)
        readers->try_emplace(cands[i], std::move(rd));
    }
    std::vector<char> dropped(cands.size(), 0);
    for (bool changed = true; changed;) {
      changed = false;
      for (unsigned i = 0; i < cands.size(); ++i) {
        if (dropped[i])
          continue;
        RailId g = cands[i];
        for (RailId o : blockers[i]) {
          if (in.count(o))
            continue;
          if (fatal)
            internalError("uncompute: mirror would free " + describe(rails[g].handle) +
                              " while a rail outside the scope still reads it",
                          rails[o].handle);
          dropped[i] = 1;
          if (--copies[g] == 0)
            in.erase(g);
          changed = true;
          break;
        }
      }
    }
    unsigned n = 0;
    for (unsigned i = 0; i < cands.size(); ++i)
      if (!dropped[i])
        cands[n++] = cands[i];
    cands.truncate(n);
  }

  void place(RailId g, const Ctx &c) {
    Rail &r = rails[g];
    if (!resolvable(g))
      return; // kept by a POP placed earlier in this batch (keepBelow)
    if (r.deferred != kNone)
      return placeDeferred(g, c);
    if (c.mode == Mode::Mirror) {
      // cq-lshe (CR §0, rule 10; A4): a rail a non-diagonal gate hit after its record (directly, or through a
      // carried phi that names it, syncPhiHits) is entangled: the reverse loop never undoes it.
      const Instruction *f = r.creator != kNone ? records[r.creator].forward : nullptr;
      if (any_of(r.hits, [&](Instruction *h) { return !f || (h != f && after(h, f)); })) {
        r.role = Role::KeptEntangled;
        r.cleanup.reset();
        return;
      }
      Instruction *end = emitItem(g, *c.mirror);
      r.released = true;
      setItemEnd(g, end->getParent(), end);
      return;
    }
    BasicBlock *D = const_cast<BasicBlock *>(defBlock(g));
    if (BasicBlock *at = flushAt.lookup(g); at && c.mode == Mode::Local && c.point->getParent() == at)
      D = at;   // cq-bqbty: flushIn
    SmallVector<Instruction *, 12> as = anchors(g);
    for (RailId o : readersOf(g))
      itemEndsOf(o, as);
    bool local = all_of(as, [&](Instruction *a) { return a->getParent() == D; });
    if (!local && cycleArm.count(g)) {
      // cq-lshe: an arm defined on a cycle, pending at a return its definition does not dominate. Each
      // instance is resolved in the pass that defined it, at a block every path from the definition
      // passes before it runs again or returns, after every use of the instance, under its run flag
      // (cleared by the item itself, so a later pass through the block before a redefinition is no
      // second free).
      BasicBlock *Bp = cyclePoint(g, as);
      if (!Bp)
        internalError("uncompute: no block resolves each instance of " + describe(r.handle) +
                          " (an arm on a cycle read where no block every path from it passes before it runs again or "
                          "returns lies after its uses: cyclePoint)",
                      r.handle);
      placeAt(g, {Bp, Bp->getTerminator()}, true, /*exists=*/true, /*selfClear=*/true);
      return;
    }
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
    placeAt(g, pos, local, !local && armLocal.count(g));
  }

  // Emits g's item at pos after rule 5's barrier check (local: resolved for good). exists: the item runs
  // only where g's definition ran (an arm-local rail at a span point or a return).
  //
  // cq-lshe (CR §0, rules 5, 9, 10): the item runs under its run flag, a classical i1 (flagAt) that holds
  // where g exists and none of these happened since its definition: a non-diagonal gate on g or on a
  // rail its item reads (after the record that read it; on the paths through the gate the rail stays
  // allocated, entangled), a keeper of g choosing g (it is kept there), a gate on a merge choosing g or
  // a rail the item reads. A flag that is constant false keeps g (KeptEntangled when a gate decides it,
  // A4); constant true emits the item plainly; otherwise the item is wrapped in a block of its own.
  void placeAt(RailId g, Pos pos, bool local, bool exists = false, bool selfClear = false) {
    Rail &r = rails[g];
    // Rule 18: a memory version change before the twin's place: the results are KEPT and no twin is called.
    if (r.loadCall && !r.cleanup && r.creator != kNone &&
        overtakenAt(records[r.creator].forward, pos.bb, pos.before->getIterator(), true)) {
      r.role = Role::Kept;
      return;
    }
    // cq-lshe (CR rule 6): a clean-up reads its inverse's operands, which must exist wherever the item runs; one
    // whose operand is defined on some paths to pos only (an arm) gives way to g's own uncompute.
    auto notThere = [&](RailId x) {
      auto *h = dyn_cast<Instruction>(rails[x].handle);
      return h && (!dominates(h->getParent(), pos.bb) || (h->getParent() == pos.bb && !cq::comesBefore(h, pos.before)));
    };
    // A guarded clean-up whose guard implies that the arm defining such an operand ran (a K-loop's rule 6 clean-up
    // behind a classical exit test, CR rule 14 with owner ruling Q10) reads it only where it exists.
    auto guardedThere = [&]() {
      return !r.cleanup->alts.empty() && all_of(r.cleanup->alts, [&](const Cleanup::Alt &a) {
               return all_of(a.reads, [&](RailId x) {
                 return !notThere(x) || guardImpliesRan(a.guard, cast<Instruction>(rails[x].handle)->getParent(), 0);
               });
             });
    };
    if (r.cleanup && r.creator != kNone && any_of(r.cleanup->reads, notThere) && !guardedThere()) {
      for (RailId x : r.cleanup->reads)
        llvm::erase(rails[x].cleanupReaders, g);
      r.cleanup.reset();
    }
    SmallVector<FlagEv, 8> evs;
    if (selfClear)
      evs.push_back({pos.before, false});
    bool gated = false;
    auto beforePos = [&](const Instruction *e) {
      return e->getParent() == pos.bb ? (e != pos.before && cq::comesBefore(e, pos.before)) : reaches(e->getParent(), pos.bb);
    };
    bool written = false;
    for (auto [e, kind] : barriers(g)) {
      if (!beforePos(e))
        continue;
      if (kind == Bar::Hit) {
        evs.push_back({e, false});
        gated = true;
        continue;
      }
      written = true;
    }
    // The record that defines g's value (the gates and choices before it concern an older instance).
    Instruction *def = r.creator != kNone ? records[r.creator].forward : dyn_cast<Instruction>(r.handle);
    // cq-lshe (CR rule 5; Bennett.jl value_eager lines 31-39): the in-place writes on rails the item reads
    // that run between g's record and pos are undone before the item and redone after it (sandwich).
    SmallVector<unsigned, 4> sandwich;
    if (written)
      sandwichOf(g, def, beforePos, sandwich, evs, gated);
    for (RailId m : r.keepers)
      if (auto *mi = dyn_cast<Instruction>(rails[m].handle); mi && mi->getParent())
        evs.push_back({mi, false, m, g});
    for (Instruction *st : r.condStores)
      if (beforePos(st))
        evs.push_back({st, false});
    SmallVector<RailId, 8> xs{g};
    for (RailId x0 : itemReads(g))
      for (RailId x : leaves(x0))
        if (!is_contained(xs, x))
          xs.push_back(x);
    for (RailId x : xs)
      for (auto [gate, n] : rails[x].condHits)
        if (gate->getParent() && (!def || after(gate, def)) && beforePos(gate)) {
          evs.push_back({gate, false, n, x});
          gated = true;
        }
    bool guard = exists || !evs.empty();
    Value *cond = nullptr;
    if (guard) {
      if (def)
        evs.push_back({def, true});
      cond = flagAt(pos.before, evs, !def);
      if (auto *k = dyn_cast<ConstantInt>(cond)) {
        if (k->isZero()) {
          // cq-guzg3: a store ran on every path to this point: kept here; another return may be reached without one.
          if (!r.condStores.empty() && !gated && r.keepers.empty()) {
            if (local)
              r.role = Role::Kept;
            else
              r.exitsDone.insert(pos.bb);
            return;
          }
          // Kept on every path to pos: entangled (A4), or chosen by a keeper on each of them.
          if (gated || r.keepers.empty()) {
            r.role = Role::KeptEntangled;
            r.cleanup.reset();
          } else {
            r.role = rails[r.keepers.front()].role;
          }
          return;
        }
        guard = false;
      }
    }
    auto &wraps = local ? localWraps : armItems;
    // Each sandwich write that does not run on every path from g's definition to pos is undone and redone
    // under its own flag "it ran since the definition".
    SmallVector<Value *, 4> wcond;
    for (unsigned w : sandwich) {
      SmallVector<FlagEv, 2> we;
      if (def)
        we.push_back({def, false});
      we.push_back({records[w].forward, true});
      wcond.push_back(flagAt(pos.before, we, false));
    }
    IRBuilder<> B(pos.before);
    auto guarded = [&](Value *c, function_ref<Instruction *()> emit) {
      Instruction *i = emit();
      if (auto *k = dyn_cast<ConstantInt>(c); !(k && k->isOne()))
        wraps.push_back({g, i, i, c});
      return i;
    };
    for (unsigned k = sandwich.size(); k-- > 0;)
      guarded(wcond[k], [&] { return emitWrite(sandwich[k], B, /*undo=*/true); });
    Instruction *prev = pos.before->getPrevNode();
    SmallVector<Seg, 4> segs;
    segOut = &segs;
    Instruction *end = emitItem(g, B);
    segOut = nullptr;
    Instruction *first = prev ? prev->getNextNode() : &pos.bb->front();
    if (!segs.empty()) {
      // cq-mgkr: a guarded rule 6 clean-up: each segment under its own condition (and the run flag).
      if (!sandwich.empty())
        internalError("uncompute: a rule 6 clean-up under a classical guard with in-place writes around it",
                      r.handle);
      for (Seg &sg : segs) {
        Value *c = sg.cond;
        if (guard) {
          IRBuilder<> GB(sg.first);
          c = GB.CreateAnd(cond, c);
        }
        wraps.push_back({g, sg.first, sg.last, c});
      }
      setItemEnd(g, pos.bb, end);
      if (local)
        r.released = true;
      else
        r.exitsDone.insert(pos.bb);
      return;
    }
    Instruction *last = end;
    for (unsigned k = 0; k < sandwich.size(); ++k)
      last = guarded(wcond[k], [&] { return emitWrite(sandwich[k], B, /*undo=*/false); });
    setItemEnd(g, pos.bb, last);
    if (local)
      r.released = true;
    else
      r.exitsDone.insert(pos.bb);
    if (guard && first != pos.before)
      wraps.push_back({g, first, end, cond});
  }

  // Is this record in a scope some reverse (emitMirror) undoes: a rule-14 trip or a loop's seeds?
  bool inScope(unsigned rec) const {
    return any_of(scopes, [&](const Scope &sc) { return rec >= sc.begin && (sc.open || rec < sc.end); });
  }

  // cq-ii0vf: a kept store reads a fresh copy of h instead (alloc + copy right before it, outside its X bracket when h is
  // the bracketed control): the copy is the rail rule 5 keeps, h stays a rail like any other.
  void keepCopyForStore(RailId r, CallInst *store, Value *h) {
    Instruction *open = store->getPrevNode(), *close = store->getNextNode();
    auto bracket = [&](Instruction *i) {
      auto *c = dyn_cast_or_null<CallInst>(i);
      auto k = c && c->getCalledFunction() ? abi::parseCore(c->getCalledFunction()->getName()) : std::nullopt;
      return k && k->op == abi::Core::NotI1 && c->getArgOperand(0) == h;
    };
    bool bracketed = bracket(open) && bracket(close);
    Module &M = *store->getModule();
    std::optional<RailType> w;
    if (auto *cf = store->getCalledFunction())
      if (auto k = abi::parseCore(cf->getName()); k && h == store->getArgOperand(store->arg_size() - 1))
        w = k->w;
    if (!w)
      w = h == store->getArgOperand(0) ? std::optional<RailType>(RailType{Kind::Int, 1}) : handleWidth(h);
    if (!w)
      internalError("uncompute: a kept store's rail whose width no runtime call names", h);
    IRBuilder<> B(bracketed ? open : store);
    CallInst *f = track(B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Alloc, *w}),
                                     {Constant::getNullValue(irTypeOf(M.getContext(), *w))}));
    CallInst *cp = track(B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Copy, *w}), {h, f}));
    store->replaceUsesOfWith(h, f);
    if (bracketed) {
      open->replaceUsesOfWith(h, f);
      close->replaceUsesOfWith(h, f);
    }
    RailId fid = newRail(f, Role::Kept, "noteKeptStore");
    rails[fid].storeKept = true;
    rails[r].uses.push_back(cp);
  }

  // The logical width of the rail behind handle h, read off a runtime call that takes it (CR §1.2, §1.3:
  // the operand's width is spelled in the callee's name), through phis, selects and freezes of handles.
  static std::optional<RailType> handleWidth(Value *h) {
    SmallVector<Value *, 8> work{h};
    SmallPtrSet<Value *, 8> seen{h};
    while (!work.empty()) {
      Value *v = work.pop_back_val();
      for (Use &u : v->uses()) {
        User *U = u.getUser();
        if (isa<PHINode>(U) || isa<FreezeInst>(U) || (isa<SelectInst>(U) && u.getOperandNo() != 0)) {
          if (seen.insert(U).second)
            work.push_back(U);
          continue;
        }
        auto *c = dyn_cast<CallInst>(U);
        if (!c || !c->getCalledFunction() || !c->isArgOperand(&u))
          continue;
        StringRef n = c->getCalledFunction()->getName();
        unsigned i = c->getArgOperandNo(&u);
        bool unc = false;
        if (std::optional<abi::TemplateSpec> t = abi::parseTemplate(n, &unc)) {
          if (unc) {
            if (i == 0)
              return templateResultType(*t);
            --i;
          }
          if ((t->rm == abi::TemplateSpec::RmRail && i + 1 == c->arg_size()))
            continue;
          if (t->op == "select" && i == 0)
            return RailType{Kind::Int, 1};
          return t->w;
        }
        if (std::optional<abi::CoreSpec> k = abi::parseCore(n)) {
          unsigned j = i - (k->ctl ? 1 : 0);
          if (k->ctl && i == 0)
            return RailType{Kind::Int, 1};
          switch (k->op) {
          case abi::Core::Measure: case abi::Core::Copy: case abi::Core::Xorc: case abi::Core::Ry:
          case abi::Core::TapeWrite:
            if (k->op != abi::Core::TapeWrite || j == 1)
              return k->w;
            break;
          case abi::Core::RyQAngle:
            return j == 0 ? k->w : RailType{Kind::Fp, 64};
          case abi::Core::RzQAngle:
            return RailType{Kind::Fp, 64};
          case abi::Core::NotI1: case abi::Core::AndI1: case abi::Core::OrI1: case abi::Core::XorI1:
          case abi::Core::RzI1: case abi::Core::AbortI1:
            return RailType{Kind::Int, 1};
          case abi::Core::QramStore:
            if (j == 2)
              return k->w;
            break;
          default:
            break;
          }
        }
      }
    }
    return std::nullopt;
  }

  // cq-4lqy (CR rule 18 twin point): the kept member m of fwd's call group is copied right after its
  // definition into a fresh rail c, and c continues as the value: every IR use of m's handle other than the
  // copy, every record operand, read, in-place write, noted use and gate on m move to c, which takes m's
  // role; m is garbage again (its twin zeroes it, then it is freed).
  void copyOutResult(RailId m, CallInst *fwd, std::optional<RailType> known = std::nullopt) {
    Value *h = rails[m].handle;
    auto *hI = dyn_cast<Instruction>(h);
    if (!hI || !hI->getNextNode())
      internalError("uncompute: a kept clone result that is not an instruction in a block", fwd);
    Module &M = *fwd->getModule();
    std::optional<RailType> wo = known ? known : handleWidth(h);
    if (!wo)
      internalError("uncompute: a kept clone result whose width no gate, template or copy reading it names", fwd);
    RailType w = *wo;
    IRBuilder<> B(hI->getNextNode());
    CallInst *c = track(B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Alloc, w}),
                                     {Constant::getNullValue(irTypeOf(M.getContext(), w))}));
    CallInst *cp = track(B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Copy, w}), {h, c}));
    h->replaceUsesWithIf(c, [&](Use &u) { return u.getUser() != cp; });
    Role role = rails[m].role;
    RailId cid = newRail(c, role, "copyOutResult"); // may move rails: indices only from here
    Rail &rm = rails[m], &rc = rails[cid];
    for (unsigned k = 0; k < records.size(); ++k) {
      for (Operand &o : records[k].ops)
        if (o.v == h)
          o.v = c;
      for (RailId &x : info[k].reads)
        if (x == m) {
          x = cid;
          rc.readerRecs.push_back(k);
        }
      if (records[k].out == m && k != rm.creator) {
        records[k].out = cid;
        if (info[k].item == m)
          info[k].item = cid;
      }
    }
    llvm::erase_if(rm.readerRecs, [&](unsigned k) { return is_contained(info[k].reads, cid); });
    rc.writes = std::move(rm.writes);
    rm.writes.clear();
    rc.uses = std::move(rm.uses);
    rm.uses.clear();
    rc.hits = std::move(rm.hits);
    rm.hits.clear();
    rc.condHits = std::move(rm.condHits);
    rm.condHits.clear();
    rc.cleanupReaders = std::move(rm.cleanupReaders);
    rm.cleanupReaders.clear();
    for (RailId o = 0; o < rails.size(); ++o)
      if (rails[o].cleanup)
        for (RailId &x : rails[o].cleanup->reads)
          if (x == m)
            x = cid;
    for (RailId mg : SmallVector<RailId, 2>(rm.mergedInto)) {
      if (rails[mg].group == rm.group && rails[mg].group != kNone)
        continue;   // a sibling member's alias of the leader stays on the call's rail
      for (RailId &a : rails[mg].arms)
        if (a == m)
          a = cid;
      rc.mergedInto.push_back(mg);
      llvm::erase(rm.mergedInto, mg);
    }
    for (Deferred &d : defs) {
      for (RailId &x : d.reads)
        if (x == m)
          x = cid;
      for (RailId &x : d.exits)
        if (x == m)
          x = cid;
    }
    rm.role = Role::Garbage;
    rm.explicitKept = false;
    rc.explicitKept = true;
  }


  // The sandwich of g's item: every in-place write record on a rail the item reads, or on a rail such a
  // write reads, that runs after g's definition and before the placement (beforePos), in program order.
  // A non-diagonal gate on a rail a write reads, after the write, makes its undo impossible there: a run
  // flag event of g (it stays allocated on those paths, CR §0). A write that may run more than once per
  // instance of g (a cycle through it that avoids g's definition) is unimplemented.
  template <typename BeforeFn>
  void sandwichOf(RailId g, Instruction *def, BeforeFn &&beforePos, SmallVectorImpl<unsigned> &out,
                  SmallVectorImpl<FlagEv> &evs, bool &gated) {
    for (unsigned w : sandwichCands(g)) {
      Instruction *f = records[w].forward;
      if ((def && !after(f, def)) || !beforePos(f))
        continue;
      if (info[w].kind != RecKind::Involution)
        internalError("uncompute: an in-place write record that is not an involution", f);
      out.push_back(w);
      // A non-diagonal gate on a rail the write reads, after it: its undo cannot run there.
      for (RailId y0 : info[w].reads)
        for (RailId y : leaves(y0))
          for (Instruction *h : rails[y].hits)
            if (h->getParent() && h != f && after(h, f) && beforePos(h)) {
              evs.push_back({h, false});
              gated = true;
            }
    }
    // Program order (the writes lie on paths from def to pos, an acyclic reading).
    llvm::stable_sort(out, [&](unsigned a, unsigned b) {
      const Instruction *x = records[a].forward, *y = records[b].forward;
      if (x->getParent() == y->getParent())
        return cq::comesBefore(x, y);
      return reaches(x->getParent(), y->getParent()) && !reaches(y->getParent(), x->getParent());
    });
  }

  CallInst *emitWrite(unsigned w, IRBuilder<> &B, bool undo) {
    CallInst *fwd = records[w].forward;
    if (fwd->getCalledFunction() && !fwd->getCalledFunction()->getName().starts_with("cqrt_")) {
      // U6/U3: a store a clone made, spelled from its record over the caller's operands.
      abi::CoreSpec spec = std::get<abi::CoreSpec>(records[w].spec);
      spec.unc = undo;
      SmallVector<Value *, 3> args;
      for (const Operand &o : records[w].ops)
        args.push_back(o.v);
      return track(B.CreateCall(abi::declare(*B.GetInsertBlock()->getModule(), spec), args));
    }
    return trackLike(B.CreateCall(fwd->getFunctionType(), fwd->getCalledOperand(), argsOf(fwd, nullptr)), fwd);
  }


  // cq-lshe: the block where each instance of g (defined on a cycle) is resolved: one that every path from
  // g's definition passes before reaching the definition again or a return, after which no anchor of
  // the instance can run (an anchor in it precedes its terminator). Null: none.
  BasicBlock *cyclePoint(RailId g, ArrayRef<Instruction *> as) const {
    const BasicBlock *D = defBlock(g);
    auto escapes = [&](const BasicBlock *B) {
      SmallPtrSet<const BasicBlock *, 16> seen;
      SmallVector<const BasicBlock *, 16> work{D};
      while (!work.empty()) {
        const BasicBlock *b = work.pop_back_val();
        const Instruction *t = b->getTerminator();
        if (!t || isa<ReturnInst>(t) || isa<UnreachableInst>(t))
          return true;
        for (const BasicBlock *s : successors(t)) {
          if (s == B)
            continue;
          if (s == D)
            return true;
          if (seen.insert(s).second)
            work.push_back(s);
        }
      }
      return false;
    };
    // Can B reach A again without passing D (A after B in the same pass)?
    auto reachesWithin = [&](const BasicBlock *B, const BasicBlock *A) { return reachesAgain(B, A, {D}); };
    SmallVector<const BasicBlock *, 16> order{D};
    SmallPtrSet<const BasicBlock *, 16> seen{D};
    for (unsigned i = 0; i < order.size(); ++i)
      if (const Instruction *t = order[i]->getTerminator())
        for (const BasicBlock *s : successors(t))
          if (seen.insert(s).second)
            order.push_back(s);
    for (const BasicBlock *B : order) {
      const Instruction *t = B->getTerminator();
      if (!t || B == D || escapes(B))
        continue;
      bool ok = true;
      for (Instruction *a : as) {
        const BasicBlock *A = a->getParent();
        if (A == B ? a->isTerminator() : reachesWithin(B, A)) {
          ok = false;
          break;
        }
      }
      if (ok)
        return const_cast<BasicBlock *>(B);
    }
    return nullptr;
  }

  // Is b on a cycle of the output CFG?
  static bool onCycle(const BasicBlock *b) {
    const Instruction *t = b->getTerminator();
    if (!t)
      return false;
    for (const BasicBlock *s : successors(t))
      if (reaches(s, b))
        return true;
    return false;
  }

  // cq-ut4k, cq-lshe (CR rules 5, 8, 9, §0): an item placed at a return under a run flag (placeAt) runs
  // only where the flag holds. Each such item [first, last] is split into a block of its own, entered
  // when its flag holds; every operand of the item that does not dominate that block (an arm's own
  // rails, a merged handle's arm) is carried to it as SSA (carryTo), poison on the paths that skip its
  // definition (the flag is false there). A classical re-branch on the conditions that decide it.
  void wrapArmItems(Function &F) {
    if (armItems.empty())
      return;
    // cq-a24ig: items placed one after another in one block under the same flag are one item (one block entered when
    // the flag holds).
    std::vector<ArmItem> joined;
    for (ArmItem &a : armItems) {
      if (!joined.empty()) {
        ArmItem &p = joined.back();
        if (p.cond == a.cond && p.last->getParent() == a.first->getParent() && p.last->getNextNode() == a.first &&
            p.first->getParent() == p.last->getParent()) {
          p.last = a.last;
          continue;
        }
      }
      joined.push_back(a);
    }
    armItems.swap(joined);
    std::vector<BasicBlock *> made;
    for (auto it = armItems.rbegin(); it != armItems.rend(); ++it) {
      BasicBlock *X = it->first->getParent();
      if (it->last->getParent() != X || !it->last->getNextNode())
        internalError("uncompute: an arm item that does not lie in one block before its terminator",
                      rails[it->g].handle);
      BasicBlock *C = X->splitBasicBlock(it->last->getNextNode(), X->getName() + ".cq.after");
      BasicBlock *U = X->splitBasicBlock(it->first, X->getName() + ".cq.arm");
      Instruction *t = X->getTerminator();
      emitted.insert(BranchInst::Create(U, C, it->cond, t));
      t->eraseFromParent();
      made.push_back(U);
    }
    armItems.clear();
    // cq-jws5r: every item block is split off by now and the carries below add phis only, so one dominator tree and one
    // order of the blocks serve them all (a function with noted classical arms has an item block per arm-local rail).
    CfgFacts facts;
    if (!armJoins.empty() && !made.empty()) {
      facts.DT = std::make_unique<DominatorTree>(F);
      unsigned k = 0;
      for (scc_iterator<Function *> it = scc_begin(&F); !it.isAtEnd(); ++it, ++k)
        for (BasicBlock *b : *it)
          facts.order[b] = k;
    }
    for (BasicBlock *U : made)
      carryOperands(U, facts.DT ? &facts : nullptr);
  }

  // Every operand of an item block U that does not dominate it, carried to it (poison where it is not
  // defined; the run flag is false there).
  // The CFG as it stands while nothing but phis is added: its dominator tree, and each reachable block's position in
  // the reverse topological order of the strongly connected components (x reaches y only if order[x] >= order[y]).
  // cq-4tkb4: and the blocks carryTo has met, numbered, with their predecessors and noted arms read once (none of them
  // changes while only phis are added).
  struct CarryView {
    static constexpr unsigned kNo = ~0u;
    DenseMap<const BasicBlock *, unsigned> id;
    std::vector<BasicBlock *> bb;
    std::vector<unsigned> predOff, predCnt, predIds;   // predOff kNo: not read yet
    std::vector<unsigned> armPre;                      // the arm's branch block; kNo none, kNo - 1 not read yet
    std::vector<BasicBlock *> armFirst;
    std::vector<unsigned> ord;                         // order of the block (kNo: none)
    std::vector<unsigned> dia, diaU;                   // the diamond's head and middle block; kNo none, kNo - 1 not read
    std::vector<unsigned> diaRoot, diaDepth, midOf;    // the end of a run of diamonds and the distance to it; the
                                                       // diamond a block is the middle of (kNo none)
    std::vector<unsigned> memoVal, memoStamp;
    unsigned stamp = 0;
  };
  struct CfgFacts {
    std::unique_ptr<DominatorTree> DT;
    DenseMap<const BasicBlock *, unsigned> order;
    mutable CarryView view;
  };
  void carryOperands(BasicBlock *U, const CfgFacts *facts = nullptr) {
    Function &F = *U->getParent();
    BasicBlock *entry = &F.getEntryBlock();
    DenseMap<Value *, Value *> carried;
    // cq-g3h1i: one dominance walk per defining block, not per operand (carryTo adds phis, no block or edge).
    DenseMap<const BasicBlock *, bool> doms;
    auto dominatesU = [&](const BasicBlock *D) {
      auto [it, fresh] = doms.try_emplace(D, false);
      if (fresh)
        it->second = dominates(D, U);
      return it->second;
    };
    for (Instruction &I : *U)
      for (Use &u : I.operands()) {
        auto *op = dyn_cast<Instruction>(u.get());
        if (!op || op->getParent() == U ||
            (facts ? facts->DT->dominates(op->getParent(), U) : dominatesU(op->getParent())))
          continue;
        Value *&c = carried[op];
        if (!c) {
          if (op->getParent() == entry)
            internalError("uncompute: an arm item operand in the entry that does not dominate the item", op);
          c = carryTo(U, false, op->getParent(), op, PoisonValue::get(op->getType()), op->getName(), facts);
        }
        u.set(c);
      }
  }

  // cq-lshe: the run-flag items placed by a flush (localWraps), each moved into a block of its own entered
  // when its flag holds. The block P an item lies in keeps its tail and terminator (a caller's references
  // to P as an edge source stay valid); P's head moves to a fresh block H before it. In program order, so
  // a later item of the same block is found in P's tail.
  void wrapLocal() {
    std::vector<ArmItem> ws;
    ws.swap(localWraps);
    for (ArmItem &w : ws) {
      BasicBlock *P = w.first->getParent();
      if (w.last->getParent() != P || w.last->isTerminator() || !w.last->getNextNode())
        internalError("uncompute: a run-flag item that does not lie in one block before its terminator",
                      rails[w.g].handle);
      Function *F = P->getParent();
      LLVMContext &Cx = F->getContext();
      BasicBlock *H = BasicBlock::Create(Cx, "", F, P);
      H->splice(H->end(), P, P->begin(), w.first->getIterator());
      for (BasicBlock *pr : SmallVector<BasicBlock *, 4>(predecessors(P)))
        if (pr != H)
          pr->getTerminator()->replaceSuccessorWith(P, H);
      BasicBlock *U = BasicBlock::Create(Cx, P->getName() + ".cq.arm", F, P);
      U->splice(U->end(), P, w.first->getIterator(), std::next(w.last->getIterator()));
      emitted.insert(BranchInst::Create(U, P, w.cond, H));
      emitted.insert(BranchInst::Create(P, U));
      carryOperands(U);
    }
  }

  // The SSA value, at the end of `at` (atEnd) or at its start, of a variable that is `v` at the end of
  // block D and `dflt` at the entry: phis at the joins (over the real predecessors: a spine phi still
  // waiting for its incomings must not hide a block's predecessors, as SSAUpdater's lookup through a
  // leading phi would), trivial ones folded.
  //
  // cq-4tkb4: the walk runs on block numbers with an explicit stack (its depth is the length of a path, unbounded), and
  // its phis are built symbolically first: the trivial ones are folded there, and only the phis that survive are made,
  // in the order the walk made them, each inserted at the top of its block. A folded phi still takes its name's unique
  // number when the walk reaches it, as the phi the walk used to make and erase did, so every name stays the same.
  Value *carryTo(BasicBlock *at, bool atEnd, BasicBlock *D, Value *v, Value *dflt, const Twine &name,
                 const CfgFacts *facts = nullptr) {
    constexpr unsigned kNo = CarryView::kNo;
    const bool arms = !armJoins.empty();
    // cq-jws5r: as flagAt, with D the one event: a block D does not reach ends with dflt, and a noted classical arm
    // that does not reach D is passed at its branch.
    SmallPtrSet<const BasicBlock *, 32> reachD, afterD;
    // With the CFG's facts at hand the two questions are read from the order instead of two walks per carry.
    unsigned orderD = 0;
    if (facts) {
      auto it = facts->order.find(D);
      if (it == facts->order.end())
        facts = nullptr;
      else
        orderD = it->second;
    }
    CarryView local;
    CarryView &V = facts ? facts->view : local;
    auto orderOf = [&](const BasicBlock *x) {
      auto it = facts->order.find(x);
      return it == facts->order.end() ? kNo : it->second;
    };
    auto cannotReachD = [&](const BasicBlock *x) {
      if (!facts)
        return !reachD.count(x);
      unsigned o = orderOf(x);
      return o != kNo && o < orderD;
    };
    if (arms && !facts) {
      SmallVector<const BasicBlock *, 32> w{D};
      reachD.insert(D);
      while (!w.empty())
        for (const BasicBlock *p : predecessors(w.pop_back_val()))
          if (reachD.insert(p).second)
            w.push_back(p);
      w.push_back(D);
      while (!w.empty())
        if (const Instruction *t = w.pop_back_val()->getTerminator())
          for (const BasicBlock *n : successors(t))
            if (afterD.insert(n).second)
              w.push_back(n);
    }
    auto idOf = [&](BasicBlock *x) -> unsigned {
      auto [it, fresh] = V.id.try_emplace(x, unsigned(V.bb.size()));
      if (fresh) {
        V.bb.push_back(x);
        V.predOff.push_back(kNo);
        V.predCnt.push_back(0);
        V.armPre.push_back(kNo - 1);
        V.armFirst.push_back(nullptr);
        V.ord.push_back(facts ? orderOf(x) : kNo);
        V.dia.push_back(kNo - 1);
        V.diaU.push_back(kNo);
        V.diaRoot.push_back(kNo - 1);
        V.diaDepth.push_back(0);
        V.midOf.push_back(kNo);
        V.memoVal.push_back(0);
        V.memoStamp.push_back(0);
      }
      return it->second;
    };
    auto predsOf = [&](unsigned x) -> std::pair<unsigned, unsigned> {
      if (V.predOff[x] == kNo) {
        SmallVector<BasicBlock *, 4> ps(predecessors(V.bb[x]));
        SmallVector<unsigned, 4> ids;
        for (BasicBlock *p : ps)
          ids.push_back(idOf(p));
        V.predOff[x] = unsigned(V.predIds.size());
        V.predCnt[x] = unsigned(ids.size());
        V.predIds.insert(V.predIds.end(), ids.begin(), ids.end());
      }
      return {V.predOff[x], V.predCnt[x]};
    };
    auto armOf = [&](unsigned x) -> unsigned {
      if (V.armPre[x] == kNo - 1) {
        BasicBlock *first = nullptr;
        BasicBlock *pre = armBranch(V.bb[x], first);
        V.armPre[x] = pre ? idOf(pre) : kNo;
        V.armFirst[x] = first;
      }
      return V.armPre[x];
    };
    // A join x whose two predecessors are a block h on an earlier strongly connected component and a block u whose only
    // predecessor is h (an item block wrapArmItems split off, X -> U -> C): both incomings of its phi are h's value
    // unless u is D, so the phi folds to it. The walk goes on at h as through a single predecessor (a stand-in keeps the
    // folded phi's place for its name). Only with the CFG's facts (the order tells x apart from h's component).
    auto diamondOf = [&](unsigned x) -> unsigned {
      if (V.dia[x] == kNo - 1) {
        V.dia[x] = kNo;
        auto [off, n] = predsOf(x);
        if (n == 2 && armOf(x) == kNo) {
          unsigned p0 = V.predIds[off], p1 = V.predIds[off + 1];
          for (auto [h, u] : {std::pair<unsigned, unsigned>{p0, p1}, {p1, p0}}) {
            if (h == u)
              break;
            auto [uo, un] = predsOf(u);
            if (un == 1 && V.predIds[uo] == h && V.ord[x] != kNo && V.ord[h] != kNo && V.ord[h] > V.ord[x]) {
              V.dia[x] = h;
              V.diaU[x] = u;
              V.midOf[u] = x;
              break;
            }
          }
        }
      }
      return V.dia[x];
    };
    // A run of diamonds (each head the join of the next, a simple path: a head has one join below it) is passed in one
    // step to its first head that is no diamond's join, unless D lies inside it (as a head or a middle block).
    auto rootOf = [&](unsigned x) {
      SmallVector<unsigned, 16> path;
      unsigned y = x;
      while (V.diaRoot[y] == kNo - 1) {
        unsigned h = diamondOf(y);
        if (h == kNo) {
          V.diaRoot[y] = y;
          V.diaDepth[y] = 0;
          break;
        }
        path.push_back(y);
        y = h;
      }
      for (auto it = path.rbegin(); it != path.rend(); ++it) {
        V.diaRoot[*it] = V.diaRoot[V.dia[*it]];
        V.diaDepth[*it] = V.diaDepth[V.dia[*it]] + 1;
      }
      return V.diaRoot[x];
    };
    auto notAfterD = [&](unsigned x) {
      if (!facts)
        return !afterD.count(V.bb[x]);
      return V.ord[x] != kNo && V.ord[x] > orderD;
    };
    // Symbolic values: 0 dflt, 1 v, 2 + k the k-th phi made.
    if (++V.stamp == 0) {
      std::fill(V.memoStamp.begin(), V.memoStamp.end(), 0);
      V.stamp = 1;
    }
    const unsigned st = V.stamp;
    auto hasMemo = [&](unsigned x) { return V.memoStamp[x] == st; };
    auto setMemo = [&](unsigned x, unsigned val) {
      V.memoStamp[x] = st;
      V.memoVal[x] = val;
    };
    struct Phi { unsigned b; std::vector<unsigned> in; bool ghost = false; };
    const bool named = !name.isTriviallyEmpty();
    SmallVector<char, 64> nameBuf;
    StringRef nameRef = named ? name.toStringRef(nameBuf) : StringRef();
    std::vector<Phi> phis;
    enum : unsigned { Chain, Single, Join };
    struct Frame { unsigned b, kind, i, sym, jsBeg; };
    std::vector<Frame> stack;
    std::vector<unsigned> js;
    unsigned cur;
    if (atEnd) {
      cur = idOf(at);
    } else {
      SmallVector<BasicBlock *, 4> ps(predecessors(at));
      if (ps.size() != 1)
        internalError("uncompute: an arm item block with other than one predecessor", at->getTerminator());
      cur = idOf(ps[0]);
    }
    unsigned ret = 0;
    for (;;) {
      // Enter cur: either its value is known (ret) or a frame is pushed and the walk goes on at a predecessor.
      bool known = true;
      if (V.bb[cur] == D) {
        ret = 1;
      } else if (hasMemo(cur)) {
        ret = V.memoVal[cur];
      } else {
        auto [off, n] = predsOf(cur);
        if (n == 0) {
          setMemo(cur, 0);
          ret = 0;
        } else if (arms && notAfterD(cur)) {
          setMemo(cur, 0);
          ret = 0;
        } else {
          known = false;
          unsigned x = cur, jb = unsigned(js.size());
          if (arms)
            while (V.bb[x] != D && !hasMemo(x)) {
              unsigned pre = armOf(x);
              if (pre != kNo && cannotReachD(V.armFirst[x])) {
                js.push_back(x);
                x = pre;
              } else {
                break;
              }
            }
          if (js.size() > jb) {
            stack.push_back({cur, Chain, 0, 0, jb});
            cur = x;
          } else if (n == 1) {
            stack.push_back({cur, Single, 0, 0, 0});
            cur = V.predIds[off];
          } else if (unsigned h = facts ? diamondOf(cur) : kNo; h != kNo && V.bb[V.diaU[cur]] != D) {
            if (!nameRef.empty()) {
              phis.push_back({cur, {}, true});
            } else {
              unsigned r = rootOf(cur), dep = V.diaDepth[cur];
              bool inside = false;
              if (auto it = V.id.find(D); it != V.id.end()) {
                unsigned d = it->second, m = V.midOf[d];
                inside = (V.diaRoot[d] == r && V.diaDepth[d] > 0 && V.diaDepth[d] < dep) ||
                         (m != kNo && V.diaRoot[m] == r && V.diaDepth[m] <= dep);
              }
              if (!inside)
                h = r;
            }
            stack.push_back({cur, Single, 0, 0, 0});
            cur = h;
          } else {
            unsigned k = unsigned(phis.size());
            phis.push_back({cur, {}});
            phis.back().in.reserve(n);
            setMemo(cur, 2 + k);
            stack.push_back({cur, Join, 0, k, 0});
            cur = V.predIds[off];
          }
        }
      }
      if (!known)
        continue;
      // Return ret to the frames waiting for it.
      bool more = false;
      while (!stack.empty()) {
        Frame &f = stack.back();
        if (f.kind == Chain) {
          for (unsigned i = f.jsBeg; i < js.size(); ++i)
            setMemo(js[i], ret);
          js.resize(f.jsBeg);
        } else if (f.kind == Single) {
          setMemo(f.b, ret);
        } else {
          phis[f.sym].in.push_back(ret);
          auto [off, n] = predsOf(f.b);
          if (++f.i < n) {
            cur = V.predIds[off + f.i];
            more = true;
            break;
          }
          ret = 2 + f.sym;
        }
        stack.pop_back();
      }
      if (!more)
        break;
    }
    // Fold the trivial phis, as the made phis were folded: in order, again until nothing changes.
    const unsigned np = unsigned(phis.size());
    std::vector<unsigned> rep(np, kNo);
    for (unsigned k = 0; k < np; ++k)
      if (phis[k].ghost)
        rep[k] = 0;
    auto res = [&](unsigned s) {
      unsigned r = s;
      while (r >= 2 && rep[r - 2] != kNo)
        r = rep[r - 2];
      while (s >= 2 && rep[s - 2] != kNo) {
        unsigned n = rep[s - 2];
        rep[s - 2] = r;
        s = n;
      }
      return r;
    };
    bool changed = true;
    while (changed) {
      changed = false;
      for (unsigned k = 0; k < np; ++k) {
        if (rep[k] != kNo)
          continue;
        unsigned same = kNo;
        bool trivial = true;
        for (unsigned in : phis[k].in) {
          unsigned x = res(in);
          if (x == 2 + k || x == same)
            continue;
          if (same != kNo) {
            trivial = false;
            break;
          }
          same = x;
        }
        if (!trivial || same == kNo)
          continue;
        rep[k] = same;
        changed = true;
      }
    }
    // Make the survivors in the walk's order; a folded phi takes its name's unique number on a stand-in.
    std::vector<PHINode *> made(np, nullptr);
    PHINode *standIn = nullptr;
    for (unsigned k = 0; k < np; ++k) {
      if (rep[k] == kNo) {
        PHINode *phi = PHINode::Create(v->getType(), unsigned(phis[k].in.size()), nameRef);
        BasicBlock *b = V.bb[phis[k].b];
        phi->insertInto(b, b->begin());
        made[k] = phi;
      } else if (!nameRef.empty()) {
        if (!standIn) {
          standIn = PHINode::Create(v->getType(), 0);
          standIn->insertInto(at, at->begin());
        }
        standIn->setName(nameRef);
      }
    }
    if (standIn)
      standIn->eraseFromParent();
    auto value = [&](unsigned s) -> Value * {
      s = res(s);
      return s == 0 ? dflt : s == 1 ? v : made[s - 2];
    };
    for (unsigned k = 0; k < np; ++k)
      if (PHINode *phi = made[k]) {
        auto [off, n] = predsOf(phis[k].b);
        for (unsigned i = 0; i < n; ++i)
          phi->addIncoming(value(phis[k].in[i]), V.bb[V.predIds[off + i]]);
      }
    return value(ret);
  }

  // ---- deferred items (F1, cq-fx3s) --------------------------------------------------------------

  // A block in the item's region or before it (it reaches a block of an owned record).
  bool beforeOrIn(const Deferred &d, const BasicBlock *b) const {
    for (const BasicBlock *rb : d.region)
      if (reaches(b, rb))
        return true;
    return false;
  }
  bool afterRegion(const Deferred &d, const BasicBlock *b) const {
    if (beforeOrIn(d, b))
      return false;
    for (const BasicBlock *rb : d.region)
      if (reaches(rb, b))
        return true;
    return false;
  }

  // The uses of the item's exit rails after the loop: IR users and noted uses of every handle that may
  // name one (merges included), outside the region.
  SmallVector<Instruction *, 8> deferredAnchors(const Deferred &d) const {
    SmallVector<Instruction *, 8> as;
    for (RailId x : d.exits)
      for (RailId n : names(x)) {
        for (User *u : rails[n].handle->users())
          if (auto *i = dyn_cast<Instruction>(u); i && i->getParent() && !beforeOrIn(d, i->getParent()))
            as.push_back(i);
        for (Instruction *i : rails[n].uses)
          if (i->getParent() && !beforeOrIn(d, i->getParent()))
            as.push_back(i);
      }
    return as;
  }

  bool spanReady(RailId g, Instruction *point, const DenseSet<RailId> &live) const {
    const Rail &r = rails[g];
    if (r.ownedBy != kNone || r.deferred != kNone || !resolvable(g) || !r.exitsDone.empty() || r.group != kNone || r.cleanup)
      return false;
    BasicBlock *P = point->getParent();
    const BasicBlock *D = defBlock(g);
    if (D == P || dominates(D, P) || onCycle(D) || onCycle(P) || !reaches(D, P))
      return false;
    for (RailId n : ownNames(g)) {   // cq-lshe: a keeper's later reads read g only where it is kept
      if (live.count(n))
        return false;
      for (User *u : rails[n].handle->users()) {
        if (isa<PHINode>(u) || isa<SelectInst>(u))
          continue;   // a merge: names(g) covers it
        auto *ci = dyn_cast<CallInst>(u);
        const Function *G = ci ? ci->getCalledFunction() : nullptr;
        if (!G || !(G->getName().starts_with("cqrt_") || G->getName().starts_with("cq_template_")) ||
            G->getName().starts_with("cqrt_qram") || G->getName().starts_with("cqrt_push") ||
            G->getName().starts_with("cqrt_tape"))
          return false;
      }
    }
    SmallVector<Instruction *, 12> as = anchors(g);
    for (RailId o : readersOf(g))
      itemEndsOf(o, as);
    for (Instruction *a : as) {
      const BasicBlock *A = a->getParent();
      if (!A)
        return false;
      if (A == P) {
        if (!cq::comesBefore(a, point))
          return false;
        continue;
      }
      if (!reaches(A, P) || reaches(P, A))
        return false;
    }
    // Every path from D reaches P: the blocks D reaches without passing P are built and none returns.
    SmallPtrSet<const BasicBlock *, 16> seen{D};
    SmallVector<const BasicBlock *, 16> work{D};
    while (!work.empty()) {
      const BasicBlock *b = work.pop_back_val();
      const Instruction *t = b->getTerminator();
      if (!t || isa<ReturnInst>(t) || isa<UnreachableInst>(t))
        return false;
      for (const BasicBlock *sb : successors(t))
        if (sb != P && seen.insert(sb).second)
          work.push_back(sb);
    }
    return true;
  }

  // Places an arm-local rail's item before P's terminator `point`, under its run flag (placeAt: true on
  // the paths through its definition and not past a keeper's choice or a gate), in a block of its own
  // (wrapLocal: P keeps its tail and terminator, its head moves to a fresh block H before it).
  void placeSpan(RailId g, Instruction *point) {
    placeAt(g, {point->getParent(), point}, true, /*exists=*/true);
    wrapLocal();
  }

  // flushBefore(P) may place the item only where every use of its exit rails after the loop lies in
  // P's block before P (and there is at least one: before the exit values' readers are lowered there
  // is none). Uses still to be lowered are the caller's contract, as for any rail flushBefore resolves.
  bool deferredLocalReady(RailId g, Instruction *point, bool span = false) const {
    const Deferred &d = defs[rails[g].deferred];
    SmallVector<Instruction *, 8> as = deferredAnchors(d);
    if (as.empty())
      return false;
    // cq-lqz3: a use in an earlier block (a merge of the exit value at a classical join before P: 177's
    // f_eval result phi, read by the phase in P) is before P when its block reaches P's and P's does not
    // reach it, P is on no cycle, and every path leaving the loop reaches P: the blocks the region reaches
    // without passing P are all built and none returns (the item runs once, guarded by whether the loop
    // ran).
    bool earlier = false;
    for (Instruction *a : as) {
      if (a->getParent() == point->getParent()) {
        if (!cq::comesBefore(a, point))
          return false;
        continue;
      }
      if (!reaches(a->getParent(), point->getParent()) || reaches(point->getParent(), a->getParent()))
        return false;
      earlier = true;
    }
    if (earlier && (onCycle(point->getParent()) || !funnelsTo(d, point->getParent())))
      return false;
    // Never inside another region whose own records are still pending (a later rule-14 loop's trip, its
    // back edges cut while it flushes per trip, or a cq_invert region): the item would run per trip.
    const BasicBlock *P = point->getParent();
    // cq-rb96s (CR rule 14; GLPK spx_update_d): a later rule-14 loop's trip flushed with its back edges cut looks acyclic
    // and, before its own first record, holds no pending record before P; only its sub-units' items belong in it.
    if (!tripFlush.empty() && none_of(tripFlush.back(), [&](unsigned s) { return is_contained(d.hostScopes, s); }))
      return false;
    for (unsigned si = 0; si < scopes.size(); ++si) {
      const Scope &sc = scopes[si];
      if (sc.open)
        return false;
      if (is_contained(d.hostScopes, si))
        continue;   // F2: the hosting region's own records (its reverse undoes them)
      for (unsigned rec = sc.begin; rec < sc.end; ++rec) {
        RailId it = info[rec].item;
        if (it == kNone || rails[it].ownedBy == rails[g].deferred || !pending(it))
          continue;
        // cq-nqa6 (span mode): only a pending record P lies inside (on one cycle with it) is such a region;
        // one before P on no cycle with it is an earlier item still to come (a reader, or a rail the item
        // reads: ordered by readersOf).
        if (reaches(records[rec].forward->getParent(), P) &&
            (!span || reaches(P, records[rec].forward->getParent())))
          return false;
      }
    }
    return true;
  }

  // Every path leaving d's region reaches P: the blocks the region reaches without passing P are built
  // (terminated) and none of them returns, and the region reaches P.
  bool funnelsTo(const Deferred &d, const BasicBlock *P) const {
    SmallPtrSet<const BasicBlock *, 16> seen;
    SmallVector<const BasicBlock *, 16> work(d.region.begin(), d.region.end());
    for (const BasicBlock *b : work)
      seen.insert(b);
    bool hitsP = false;
    while (!work.empty()) {
      const BasicBlock *b = work.pop_back_val();
      const Instruction *t = b->getTerminator();
      if (!t || isa<ReturnInst>(t))
        return false;
      for (const BasicBlock *sb : successors(t)) {
        if (sb == P) {
          hitsP = true;
          continue;
        }
        if (seen.insert(sb).second)
          work.push_back(sb);
      }
    }
    return hitsP;
  }

  static RailType createdType(const Record &rec) {
    if (auto *t = std::get_if<abi::TemplateSpec>(&rec.spec))
      return templateResultType(*t);
    return std::get<abi::CoreSpec>(rec.spec).w;
  }

  // Place the item: after every use of its exit rails after the loop and the items of their readers,
  // before any barrier on a rail it reads. The block is split there: its head (and its predecessors)
  // move to a fresh block H, the item is emitted from the end of H, and the program continues in the
  // original block, which keeps the tail and the terminator (so a caller's references to it as an
  // edge's source stay valid).
  void placeDeferred(RailId g, const Ctx &c) {
    ReachSuspend cfgChanges;   // cq-4tkb4: its split, and the reverse loop its emitter builds
    Rail &r = rails[g];
    Deferred &d = defs[r.deferred];
    SmallVector<Instruction *, 12> as = deferredAnchors(d);
    for (RailId o : readersOf(g))
      itemEndsOf(o, as);
    Pos pos;
    if (c.mode == Mode::Local) {
      pos = afterLatest(c.point->getParent(), as, g);
    } else if (c.mode == Mode::Exit) {
      BasicBlock *Rb = c.point->getParent();
      SmallVector<Instruction *, 12> rel;
      for (Instruction *a : as)
        if (reaches(a->getParent(), Rb))
          rel.push_back(a);
      pos = afterLatest(Rb, rel, g);
    } else {
      // Rule 14: a loop in a scope being mirrored (a loop of a classical exit's arm): its reverse runs here, after the
      // scope's readers of its exit rails and before the rails its seed reads.
      r.released = true;
      d.emit(*c.mirror);
      for (RailId x : d.exits)
        if (!rails[x].released && !keptRole(rails[x].role))
          internalError("uncompute: the deferred reverse loop did not undo its exit rail", rails[x].handle);
      return;
    }
    if (!pos.before)
      internalError("uncompute: no insertion point for a deferred item", r.handle);
    SmallVector<std::pair<RailId, const Value *>, 8> xs;
    for (RailId x0 : d.reads)
      for (RailId x : leaves(x0))
        if (!is_contained(xs, std::make_pair(x, (const Value *)rails[x0].handle)))
          xs.push_back({x, rails[x0].handle});
    for (RailId x : d.exits)
      if (!is_contained(xs, std::make_pair(x, (const Value *)nullptr)))
        xs.push_back({x, nullptr});
    Instruction *barrier = nullptr;
    for (auto [x, via] : xs) {
      SmallVector<Instruction *, 8> evs(rails[x].hits.begin(), rails[x].hits.end());
      for (unsigned w : rails[x].writes)
        if (rails[x].ownedBy == kNone)
          evs.push_back(records[w].forward);
      for (Instruction *e : evs) {
        if (!e->getParent() || !afterRegion(d, e->getParent()))
          continue;
        bool violated = e->getParent() == pos.bb ? !(pos.before == e || cq::comesBefore(pos.before, e))
                                                 : reaches(e->getParent(), pos.bb);
        if (violated && !barrier) {
          barrier = e;
        }
      }
    }
    // Rule 5 sentence 1 with rule 14 (116): the reverse un-copies the trips' load copies; a memory version change after
    // the loop that the placement does not precede overtakes them, and when every exit rail is kept nothing holds the
    // reverse back: it runs where the loop exits (below), its copies clean. An exit rail still read by templates after
    // the change keeps the placement, and the copies are overtaken there (185).
    if (!barrier && all_of(d.exits, [&](RailId x) { return keptRole(rails[x].role); })) {
      bool loads = false;
      for (unsigned i = 0; i < records.size() && !loads; ++i)
        loads = info[i].kind == RecKind::BusLoad && rails[info[i].item].ownedBy == r.deferred &&
                !keptRole(rails[info[i].item].role);
      if (loads)
        for (Instruction *v : versions) {
          if (!v->getParent() || !afterRegion(d, v->getParent()))
            continue;
          if (v->getParent() == pos.bb ? !(pos.before == v || cq::comesBefore(pos.before, v))
                                       : reaches(v->getParent(), pos.bb)) {
            barrier = v;
            break;
          }
        }
    }
    // The loop's exit block X: the one block outside the region the region's blocks branch to.
    auto exitBlock = [&](const Value *at) -> BasicBlock * {
      BasicBlock *X = nullptr;
      auto fromRegion = [&](const BasicBlock *b) {
        return any_of(d.region, [&](const BasicBlock *rb) { return reaches(rb, b); });
      };
      for (BasicBlock &lb : *pos.bb->getParent())
        if (beforeOrIn(d, &lb) && fromRegion(&lb))
          for (const BasicBlock *s : successors(&lb))
            if (!beforeOrIn(d, s)) {
              X = const_cast<BasicBlock *>(s);
            }
      if (!X || !X->getTerminator())
        internalError("uncompute: no exit block for a deferred item in " + pos.bb->getParent()->getName().str(), at);
      return X;
    };
    // cq-dyef: a barrier after the loop precedes the earliest deferred placement (116: the QFT's Ry on
    // the counting cells the modexp reverse reads, before y is measured). The reverse then runs where
    // the loop exits, before any barrier (the immediate placement, as before cq-fx3s), which is correct
    // when every exit rail is kept (measured, escaped, a kept merge's arm): its uses after the loop
    // read the copy taken in X, which stays, and the item undoes the rail itself. Any other exit rail
    // is still read after the loop by an item that has not run: cq::unimplemented, as before.
    // cq-4lqy (CR rule 14 case 1: "after the result is copied out (alloc + copy) a reverse loop pops"): an
    // exit rail that is not kept is then copied out in X like a kept one; the copy is the loop's output
    // (Role::Output, as before cq-fx3s), read by every use after the loop.
    bool copyAll = false;
    if (barrier) {
      copyAll = true;
      BasicBlock *X = exitBlock(rails[g].handle);
      BasicBlock *S = X->getSingleSuccessor();
      if (!S) {
        // cq-4lqy: X branches on: the reverse runs on every path leaving it, in a fresh block N that takes
        // X's terminator (X -> N -> X's successors).
        BasicBlock *N = BasicBlock::Create(X->getContext(), "", X->getParent(), X->getNextNode());
        N->splice(N->end(), X, X->getTerminator()->getIterator());
        emitted.insert(BranchInst::Create(N, X));
        for (BasicBlock *sb : successors(N))
          sb->replacePhiUsesWith(X, N);
        S = N;
      }
      if (beforeOrIn(d, S))
        internalError("uncompute: the loop's exit block of a deferred item does not continue in one block",
                      X->getTerminator());
      pos = {S, &*S->getFirstInsertionPt()};
    }
    // An exit rail that became kept (measured, escaped, a kept merge's arm) is kept by a copy taken
    // here, and the reverse loop undoes the rail itself (every trip's instance is undone alike).
    SmallVector<std::pair<RailId, Role>, 2> keptExits;
    for (RailId x : d.exits) {
      Rail &rx = rails[x];
      if (!keptRole(rx.role) && !copyAll)
        continue;
      // Rule 5 sentence 3, rule 14 case 1 (cq-mmdf3): a kept store's value or control rail is neither uncomputed nor
      // freed by the reverse loop, on no trip: it needs no copy, what follows the loop reads it in place.
      if (rx.storeKept && rx.condStores.empty())
        continue;
      // Rules 2, 5, 14 case 1 (cq-h0cn4): an exit rail a trip rotated is a register: a rotated rail is never uncomputed
      // (resolve's mirror leaves every trip's instance allocated), so no reverse can follow a copy-out by undoing it. What
      // follows the loop reads it in place, an ordinary value carried out.
      if (any_of(rx.hits, [&](Instruction *h) { return h->getParent() && beforeOrIn(d, h->getParent()); }))
        continue;
      // cq-4lqy: an exit rail rotated only after the loop, or one with no producer, is copied out the same way: the gates after the
      // loop act on the copy (retargetOutside moves them), the reverse loop undoes the rail itself.
      // Rule 5 (a kept rail is never uncomputed), rule 14 case 1: an exit rail that reaches later code
      // only through memory (no IR use outside the region; its readers are cell-load merges, M3) stays
      // with its kept role on every trip: no copy, the mirror leaves every instance alone (179).
      bool outsideUse = any_of(rx.handle->uses(), [&](const Use &u) {
        auto *ui = dyn_cast<Instruction>(u.getUser());
        return ui && ui->getParent() && !beforeOrIn(d, ui->getParent());
      });
      if (!outsideUse)
        continue;
      keptExits.push_back({x, keptRole(rx.role) ? rx.role : Role::Output});
    }
    BasicBlock *keptX = keptExits.empty() ? nullptr : exitBlock(rails[keptExits.front().first].handle);
    // Split.
    BasicBlock *P = pos.bb;
    Function *F = P->getParent();
    LLVMContext &C = F->getContext();
    BasicBlock *H = BasicBlock::Create(C, "", F, P);
    H->splice(H->end(), P, P->begin(), pos.before->getIterator());
    for (BasicBlock *pr : SmallVector<BasicBlock *, 4>(predecessors(P)))
      if (pr != H)
        pr->getTerminator()->replaceSuccessorWith(P, H);
    IRBuilder<> B(H);
    for (auto [x, role] : keptExits) {
      // The copy is taken where the loop exits (the one block outside the region its blocks branch
      // to), before any use after the loop: every such use reads the copy, which takes the kept role
      // (a measured rail is never freed), and the reverse loop undoes the rail itself.
      BasicBlock *X = keptX;
      Module &M = *F->getParent();
      Value *xh = rails[x].handle;
      std::optional<RailType> wo;
      if (rails[x].creator != kNone) {
        // The producer's spelling names the width (CR §1.2, §1.3).
        CallInst *pf = records[rails[x].creator].forward;
        bool unc = false;
        if (Function *cf = pf->getCalledFunction()) {
          if (auto t = abi::parseTemplate(cf->getName(), &unc))
            wo = templateResultType(*t);
          else if (auto k = abi::parseCore(cf->getName()); k && k->w.bits)
            wo = k->w;
        }
        if (!wo)
          wo = createdType(records[rails[x].creator]);
      }
      if (!wo || !wo->bits)
        wo = handleWidth(xh);
      if (!wo)
        internalError("uncompute: an exit rail with no producer whose width no runtime call names", xh);
      RailType w = *wo;
      SmallVector<Use *, 8> outside;
      for (Use &u : xh->uses())
        if (auto *ui = dyn_cast<Instruction>(u.getUser()); ui && ui->getParent() && !beforeOrIn(d, ui->getParent()))
          outside.push_back(&u);
      // cq-9kcq (rolled K-loop): X may already hold readers of x lowered after the loop (the rolled loop's exit block
      // continues into the code after it); the copy goes before the first of them, else at X's end.
      Instruction *at = X->getTerminator();
      for (Instruction &xi : *X)
        if (!isa<PHINode>(xi) && is_contained(xi.operands(), xh)) {
          at = &xi;
          break;
        }
      IRBuilder<> BXc(at);
      CallInst *f = track(BXc.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Alloc, w}),
                                         {Constant::getNullValue(irTypeOf(C, w))}));
      track(BXc.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Copy, w}), {xh, f}));
      for (Use *u : outside)
        u->set(f);
      RailId fid = newRail(f, role, "recordDeferred"); // may move rails: indices only from here
      retargetOutside(d, x, xh, f, fid);
      for (RailId m : SmallVector<RailId, 2>(rails[x].mergedInto)) {
        for (RailId &a : rails[m].arms)
          if (a == x)
            a = fid;
        rails[fid].mergedInto.push_back(m);
      }
      rails[x].mergedInto.clear();
      rails[x].role = Role::Garbage;
    }
    rails[g].released = true;
    mirrorExit = c.mode == Mode::Exit ? c.point->getParent() : nullptr;
    d.emit(B);
    mirrorExit = nullptr;
    for (auto [x, role] : keptExits)
      if (!rails[x].released)
        internalError("uncompute: the deferred reverse loop did not undo its kept exit rail", rails[x].handle);
    for (RailId x : d.exits)
      if (!rails[x].released && !keptRole(rails[x].role))
        internalError("uncompute: the deferred reverse loop did not undo its exit rail", rails[x].handle);
    if (B.GetInsertBlock()->getTerminator())
      internalError("uncompute: a deferred item left its builder in a terminated block", rails[g].handle);
    BranchInst *br = BranchInst::Create(P, B.GetInsertBlock());
    emitted.insert(br);
    setItemEnd(g, br->getParent(), br);
    d.placedAt = P;
  }

  // cq-4lqy: the copy f (rail fid) of a deferred item's exit rail x continues as the value after the loop:
  // records, in-place writes, noted uses and gates outside the item's region move from x to fid.
  void retargetOutside(const Deferred &d, RailId x, Value *xh, Value *f, RailId fid) {
    auto outside = [&](const Instruction *i) { return i && i->getParent() && !beforeOrIn(d, i->getParent()); };
    for (unsigned k = 0; k < records.size(); ++k) {
      if (!outside(records[k].forward))
        continue;
      for (Operand &o : records[k].ops)
        if (o.v == xh)
          o.v = f;
      for (RailId &y : info[k].reads)
        if (y == x) {
          y = fid;
          rails[fid].readerRecs.push_back(k);
          llvm::erase(rails[x].readerRecs, k);
        }
      if (records[k].out == x && k != rails[x].creator) {
        records[k].out = fid;
        if (info[k].item == x)
          info[k].item = fid;
        llvm::erase(rails[x].writes, k);
        rails[fid].writes.push_back(k);
      }
    }
    auto move = [&](auto &from, auto &to) {
      for (auto it = from.begin(); it != from.end();)
        if (outside(*it)) {
          to.push_back(*it);
          it = from.erase(it);
        } else {
          ++it;
        }
    };
    move(rails[x].hits, rails[fid].hits);
    move(rails[x].uses, rails[fid].uses);
  }

  // ---- a computed rail measured on some paths only (cq-8lf8, cq-4lqy) -------------------------------
  //
  // CR rule 2 (ruling 2026-11-02, cq-29ej): collapse is static. A rail measured on some classical paths
  // only is lowered as unmeasured: the consumer gives Role::Measured only to a rail measured on every path
  // from its definition to a return (spine::measuredOnEveryPath, on the source CFG), and otherwise measures
  // a kept basis copy and leaves the rail's role alone. Checked here once every block the definition
  // reaches is built: a Measured rail with a direct measurement from whose definition a return is reached
  // without passing one breaks that contract.
  static bool isMeasureOf(const User *u, const Value *h) {
    auto *c = dyn_cast<CallInst>(u);
    return c && c->getCalledFunction() && c->getCalledFunction()->getName().starts_with("cqrt_measure_") &&
           c->arg_size() && c->getArgOperand(0) == h;
  }

  void resolveUnmeasured(BasicBlock *) {
    for (RailId g = 0; g < rails.size(); ++g) {
      Rail &r = rails[g];
      if (r.role != Role::Measured || isMerge(g) || r.creator == kNone || info[r.creator].kind != RecKind::Template)
        continue;
      SmallPtrSet<const BasicBlock *, 4> mb;
      for (User *u : r.handle->users())
        if (isMeasureOf(u, r.handle) && cast<Instruction>(u)->getParent())
          mb.insert(cast<Instruction>(u)->getParent());
      const BasicBlock *D = defBlock(g);
      if (mb.empty() || mb.count(D))
        continue;
      SmallPtrSet<const BasicBlock *, 16> seen;
      SmallVector<const BasicBlock *, 16> w{D};
      bool open = false, unmeasuredRet = false;
      while (!w.empty() && !open) {
        const Instruction *t = w.pop_back_val()->getTerminator();
        if (!t) {
          open = true;
          break;
        }
        if (isa<ReturnInst>(t))
          unmeasuredRet = true;
        for (const BasicBlock *s : successors(t))
          if (s != D && !mb.count(s) && seen.insert(s).second)
            w.push_back(s);
      }
      if (!open && unmeasuredRet)
        internalError("uncompute: " + describe(r.handle) + " has Role::Measured but a return is reached from its "
                      "definition without passing its measurement (CR rule 2: a rail measured on some classical "
                      "paths only is lowered as unmeasured; the consumer measures a copy)",
                      records[r.creator].forward);
    }
  }

  void resolve(SmallVectorImpl<RailId> &cands, const Ctx &c) {
    // cq-g3h1i: dropBlocked and order read the same rails with nothing changed in between: each candidate's
    // readers and each reader's itemReads are computed once for both.
    DenseMap<RailId, SmallVector<RailId, 4>> readers, reads;
    readsMemo = &reads;
    dropBlocked(cands, c, c.mode == Mode::Mirror, &readers);
    SmallVector<RailId, 16> ord = order(cands, &readers);
    readsMemo = nullptr;
    for (RailId g : ord)
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
    if (t != out)
      internalError("uncompute: recordCore: `out` is not the gate's target rail", fwd);
    return t;
  };
  unsigned c = spec.ctl ? 1 : 0;
  switch (spec.op) {
  case Core::Alloc:
    return recordSeed(fwd);
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
    // cq-b9w7: the phi itself on a loop's back edge (a value carried unchanged around a classical loop, pred
    // JoinRepair) names what the phi named on entry: no arm of its own.
    for (Value *v : phi->incoming_values())
      if (v != merged)
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


SmallVector<RailId, 4> Uncompute::recordCall(CallInst *fwd, ArrayRef<Value *> outs, ArrayRef<Operand> extra,
                                             bool loadsBus) {
  Impl &I = *impl;
  if (!fwd || !isa<Function>(fwd->getCalledOperand()) || !fwd->getParent())
    internalError("uncompute: recordCall: the forward must be a direct call in a block", fwd);
  if (outs.empty())
    internalError("uncompute: recordCall: a call with no result rail", fwd);
  SmallVector<Operand, 8> ops;
  for (Value *a : fwd->args()) {
    bool h = I.byHandle.count(a) > 0;
    ops.push_back(Operand{a, h});
  }
  I.checkOps(fwd, ops, "recordCall");
  unsigned gi = I.groups.size();
  I.groups.push_back({fwd, {}, {}, {}});
  for (const Operand &e : extra) {
    if (e.handle) {
      RailId r = I.lookup(e.v, "recordCall", fwd);
      if (I.anyReleased(r))
        internalError("uncompute: recordCall: extra operand " + describe(e.v) + " was already freed", fwd);
    }
    ops.push_back(e);
    I.groups[gi].extra.push_back(e.v);
  }
  for (Value *h : outs)
    if (auto *ins = dyn_cast<Instruction>(h); !ins || !ins->getParent())
      internalError("uncompute: recordCall: a result handle that is not an instruction in a block", fwd);
  RailId lead = I.newRail(outs.front(), Role::Garbage, "recordCall");
  I.rails[lead].group = gi;
  I.rails[lead].loadCall = loadsBus;
  if (I.srcBlock)
    I.srcOf[fwd] = I.srcBlock;
  I.addRecord(fwd, abi::TemplateSpec{}, ops, lead, RecKind::Call, false);
  SmallVector<RailId, 4> ids{lead};
  for (size_t k = 1; k < outs.size(); ++k) {
    RailId m = I.newRail(outs[k], Role::Garbage, "recordCall");
    I.rails[m].arms = {lead};
    I.rails[m].group = gi;
    I.rails[lead].mergedInto.push_back(m);
    ids.push_back(m);
  }
  Impl::CallGroup &cg = I.groups[gi];
  cg.members.assign(ids.begin(), ids.end());
  cg.outs.assign(ids.begin(), ids.end());
  return ids;
}

void Uncompute::recordTableCall(CallInst *fwd, ArrayRef<Value *> outs, ArrayRef<RailType> widths) {
  if (widths.size() != outs.size())
    internalError("uncompute: recordTableCall: one width per result handle", fwd);
  SmallVector<RailId, 4> ids = recordCall(fwd, outs, {});
  Impl::CallGroup &cg = impl->groups[impl->rails[ids.front()].group];
  cg.table = true;
  cg.widths.assign(widths.begin(), widths.end());
}

void Uncompute::noteTwinName(CallInst *fwd, StringRef name) { impl->twinNames[fwd] = name.str(); }

void Uncompute::noteLoadsBus(RailId r) {
  Impl::Rail &x = impl->rail(r, "noteLoadsBus");
  x.loadCall = true;
  if (impl->srcBlock && x.creator != kNone)
    impl->srcOf[impl->records[x.creator].forward] = impl->srcBlock;
}

RailId Uncompute::recordBusLoad(CallInst *load, ArrayRef<Operand> ops) {
  Impl &I = *impl;
  if (!load || !load->getParent())
    internalError("uncompute: recordBusLoad needs a call in a block", load);
  I.checkOps(load, ops, "recordBusLoad");
  std::optional<abi::CoreSpec> spec = load->getCalledFunction() ? abi::parseCore(load->getCalledFunction()->getName())
                                                                : std::nullopt;
  if (!spec || spec->op != abi::Core::QramLoad || spec->unc)
    internalError("uncompute: recordBusLoad of a call that is no cqrt_qram_load_<W>", load);
  RailId out = I.newRail(load, Role::Garbage, "recordBusLoad");
  I.addRecord(load, *spec, ops, out, RecKind::BusLoad, false);
  return out;
}

void Uncompute::noteVersionChange(Instruction *at) {
  if (!at || !at->getParent())
    internalError("uncompute: noteVersionChange needs an instruction in a block", at);
  impl->versions.push_back(at);
  if (impl->srcBlock)
    impl->srcOf[at] = impl->srcBlock;
}

void Uncompute::noteSourceBlock(const BasicBlock *bb) { impl->srcBlock = bb; }

void Uncompute::noteClassicalArm(BasicBlock *join, BasicBlock *skip) { impl->armJoins[join] = skip; }

void Uncompute::flushIn(RailId rail, BasicBlock *block) { impl->flushAt[rail] = block; }

void Uncompute::flushRailsBefore(ArrayRef<RailId> gs, Instruction *point) {
  if (!point || !point->getParent())
    internalError("uncompute: flushRailsBefore needs an instruction in a block");
  Impl &I = *impl;
  I.syncPhiHits();
  BasicBlock *P = point->getParent();
  SmallVector<RailId, 16> cands;
  for (RailId g : gs) {
    if (g >= I.rails.size() || I.rails[g].ownedBy != kNone || I.frozen(g) || I.rails[g].deferred != kNone ||
        !I.resolvable(g) || !I.rails[g].exitsDone.empty())
      continue;
    if (any_of(I.anchors(g), [&](Instruction *a) {
          return a->getParent() != P || !cq::comesBefore(a, point) ||
                 (!isa<CallBase>(a) && !I.emitted.count(a) && !I.isMergeHandle(a));
        }))
      continue;
    I.flushAt[g] = P;
    cands.push_back(g);
  }
  I.pruneCleanups(&cands);
  Impl::Ctx c{Impl::Mode::Local, point, nullptr};
  I.resolve(cands, c);
  I.wrapLocal();
}

void Uncompute::noteCarried(Value *phi) { impl->rails[impl->lookup(phi, "noteCarried", phi)].carried = true; }

void Uncompute::noteKeptStore(CallInst *store, Value *value, Value *ctl) {
  Impl &I = *impl;
  if (!store || !store->getParent())
    internalError("uncompute: noteKeptStore needs a call in a block", store);
  for (Value *h : {value, ctl}) {
    if (!h)
      continue;
    RailId r = I.lookup(h, "noteKeptStore", store);
    Impl::Rail &x = I.rails[r];
    if (I.anyReleased(r))
      internalError("uncompute: noteKeptStore: " + describe(h) + " was already uncomputed and freed", store);
    // Rule 6: the old value is kept when it is the value or control rail of a kept store.
    if (x.cleanup) {
      for (RailId y : x.cleanup->reads)
        llvm::erase(I.rails[y].cleanupReaders, r);
      x.cleanup.reset();
    }
    // Rule 5 sentence 3, rule 14 (cq-mmdf3): a carried phi names the previous trip's rail, which the reverse loop undoes (the
    // last trip's is stored by no trip): the store reads a copy, and that copy is the rail kept for the trip that stored it.
    if (x.carried) {
      I.keepCopyForStore(r, store, h);
      continue;
    }
    // cq-j2r0j (CR rule 19 "Function pointers", rule 27): a declared clone's twin is called exactly once, at its rule-18
    // position; where rule 18 would keep a result (a store of it) the result is first copied into a fresh rail KEPT in its
    // place. The store reads that copy; the call's result stays garbage, which its twin zeroes. Every result of the call:
    // a member past the first names the lead as its arm (recordCall's U2 alias, no merge), and keeping it would keep the
    // lead, so a twin in a loop's reverse would never run (cq-03rdt: GSL complex_tri_invert_L3's gsl_complex_inverse).
    if (x.group != kNone && I.groups[x.group].table && !Impl::keptRole(x.role)) {
      I.keepCopyForStore(r, store, h);
      continue;
    }
    // cq-guzg3, cq-ii0vf: rule 5 keeps the rail with the store that ran (§6 item 1: a store's value and control rail). Where
    // a classical branch can bypass this store the rail is a rail like any other on those paths.
    bool plain = !Impl::keptRole(x.role) && x.creator != kNone && x.group == kNone && !x.loadCall && !I.isMerge(r) &&
                 x.mergedInto.empty();
    // So it is on the trips a store after the loop never reads, a rail its loop's reverse owns included (cq-qayew, rule 14
    // case 1: the result is copied out and the reverse undoes each trip).
    if (plain && I.inScope(x.creator) && Impl::repeatsWithout(I.defBlock(r), store->getParent())) {
      I.keepCopyForStore(r, store, h);
      continue;
    }
    // cq-o546l: a rail a loop's deferred reverse owns (an exit capture read in place after the loop) is such a trip instance
    // too: kept outright, the paths that skip the store would leave it live.
    if (plain && (I.inScope(x.creator) || (x.deferred == kNone && x.ownedBy == kNone)) &&
        Impl::bypassed(I.defBlock(r), store->getParent())) {
      if (I.inScope(x.creator))
        // An instance per trip, undone by the reverse loop (rule 14), which replays no store: the store reads a copy of
        // the rail, and that copy is the value or control rail rule 5 keeps, on exactly the trips the store ran.
        I.keepCopyForStore(r, store, h);
      else {
        // One instance: it stays a rail with an item, under the run flag "no store of it ran" (placeAt).
        x.condStores.push_back(store);
        x.storeKept = true;
      }
      continue;
    }
    // cq-xoc4: a merge (a classical phi or select of handles) whose store a classical branch can bypass: keeping the merge
    // keeps the arm it names on every path through it, the paths that skip the store included. The store reads a copy, the
    // rail rule 5 keeps where the store ran; the merge stays garbage and its arms are undone as usual.
    if (!Impl::keptRole(x.role) && I.isMerge(r) && Impl::bypassed(I.defBlock(r), store->getParent())) {
      I.keepCopyForStore(r, store, h);
      continue;
    }
    if (!Impl::keptRole(x.role))
      setRole(r, Role::Kept);
    I.rails[r].storeKept = true;
  }
}

Value *Uncompute::negatedAtomOf(Value *flag) const {
  const Impl &I = *impl;
  auto it = I.byHandle.find(flag);
  if (it == I.byHandle.end())
    return nullptr;
  const Impl::Rail &t = I.rails[it->second];
  if (t.creator == kNone || I.info[t.creator].kind != RecKind::Seed || t.writes.size() != 2)
    return nullptr;
  auto *seed = dyn_cast<ConstantInt>(I.records[t.creator].forward->getArgOperand(0));
  CallInst *x = I.records[t.writes[1]].forward;
  auto *openSpec = std::get_if<abi::CoreSpec>(&I.records[t.writes[0]].spec);
  auto *xSpec = std::get_if<abi::CoreSpec>(&I.records[t.writes[1]].spec);
  if (!seed || !seed->isZero() || !openSpec || openSpec->op != abi::Core::NotI1 || !xSpec ||
      xSpec->op != abi::Core::XorI1 || xSpec->ctl)
    return nullptr;
  Value *g = x->getArgOperand(0);
  auto gt = I.byHandle.find(g);
  if (gt == I.byHandle.end())
    return nullptr;
  // A gate on g since the flag was computed: g no longer holds what the flag negates.
  for (Instruction *h : I.rails[gt->second].hits)
    if (h->getParent() == x->getParent() && cq::comesBefore(x, h))
      return nullptr;
  return g;
}

void Uncompute::freezeLoadCopy(RailId r) {
  Impl &I = *impl;
  Impl::Rail &x = I.rail(r, "freezeLoadCopy");
  if (x.creator == kNone || I.info[x.creator].kind != RecKind::BusLoad)
    internalError("uncompute: freezeLoadCopy of a rail no bus load made", x.handle);
  if (x.released)
    internalError("uncompute: freezeLoadCopy of a load copy already un-copied", x.handle);
  if (!Impl::keptRole(x.role))
    x.role = Role::Frozen;
}

RailId Uncompute::idOf(Value *handle) const { return impl->lookup(handle, "idOf", handle); }

bool Uncompute::deferredExit(RailId r) const {
  for (const Impl::Deferred &d : impl->defs)
    if (is_contained(d.exits, r))
      return true;
  for (RailId a : impl->rails[r].arms)   // a merge of rails: its arms'
    if (a != r && deferredExit(a))
      return true;
  return false;
}

bool Uncompute::ownItem(RailId r) const {
  const Impl::Rail &x = impl->rails[r];
  return x.ownedBy == kNone && x.deferred == kNone && !impl->isMerge(r);
}

void Uncompute::mergeToRail(RailId m) {
  Impl::Rail &x = impl->rail(m, "mergeToRail");
  for (RailId a : x.arms)
    llvm::erase(impl->rails[a].mergedInto, m);
  x.arms.clear();
  x.role = Role::Garbage;
}

std::optional<Role> Uncompute::liveRole(RailId r) const {
  const Impl::Rail &x = impl->rails[r];
  if (x.released || !x.exitsDone.empty())
    return std::nullopt;
  return x.role;
}

bool Uncompute::railDependsOn(const Value *from, const Value *y) const {
  const Impl &I = *impl;
  auto fi = I.byHandle.find(from), yi = I.byHandle.find(y);
  if (fi == I.byHandle.end() || yi == I.byHandle.end())
    return false;
  DenseSet<RailId> seen;
  SmallVector<RailId, 16> work{fi->second};
  while (!work.empty()) {
    RailId r = work.pop_back_val();
    if (r == yi->second)
      return true;
    if (!seen.insert(r).second)
      continue;
    const Impl::Rail &x = I.rails[r];
    work.append(x.arms.begin(), x.arms.end());
    auto addReads = [&](unsigned rec) { work.append(I.info[rec].reads.begin(), I.info[rec].reads.end()); };
    if (x.creator != kNone)
      addReads(x.creator);
    for (unsigned w : x.writes)
      addReads(w);
  }
  return false;
}

void Uncompute::setRole(RailId r, Role role) {
  impl->syncPhiHits();   // cq-igqp
  Impl &I = *impl;
  Impl::Rail &x = I.rail(r, "setRole");
  if (x.released || !x.exitsDone.empty())
    internalError("uncompute: setRole on a rail that was already uncomputed", x.handle);
  if (x.group != kNone)
    x.explicitKept = Impl::keptRole(role);
  if (I.isMerge(r)) {
    // U1: a merge is never resolved itself; a kept role on it keeps whichever arm the classical
    // condition chose, and the others are cleaned under that condition (cq-lshe, keepMerge).
    if (role == Role::Seed)
      internalError("uncompute: setRole: Role::Seed on a merged handle", x.handle);
    if (Impl::keptRole(role))
      I.keepMerge(r, role);
    x.role = role;
    return;
  }
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
  if (impl->isMerge(target)) {
    // cq-bv91, cq-lshe (CR §0, rules 5, 9, 10): the gate hits the arm the merge chose. A kept arm takes
    // the hit; a resolvable one is hit only where the merge chose it (a classical choice), so its item and
    // the items that read it are kept there and run elsewhere (placeAt's run flag).
    for (RailId a : impl->leaves(target)) {
      if (impl->pending(a))
        impl->rails[a].condHits.push_back({gate, target});
      else
        impl->rails[a].hits.push_back(gate);
    }
    impl->rails[target].hits.push_back(gate);
    impl->syncPhiHits();   // cq-igqp: an arm may be a phi over handles
    return;
  }
  if (x.released)
    internalError("uncompute: gate on " + describe(x.handle) + " after it was uncomputed and freed", gate);
  x.hits.push_back(gate);
  impl->syncPhiHits();   // cq-igqp: the rails a phi over handles may name
}


void Uncompute::cleanupBijective(RailId oldRail, const abi::TemplateSpec &inverse, ArrayRef<Operand> ops) {
  Impl::Rail &x = impl->rail(oldRail, "cleanupBijective");
  if (x.storeKept)
    return;   // rule 6: the old value is kept when it is the value or control rail of a kept store
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

bool Uncompute::hasCleanup(RailId oldRail) const { return impl->rails[oldRail].cleanup.has_value(); }

bool Uncompute::withdrawCleanup(RailId oldRail) {
  Impl::Rail &x = impl->rail(oldRail, "withdrawCleanup");
  if (!x.cleanup || !x.cleanup->alts.empty() || x.released || !x.exitsDone.empty())
    return false;
  for (RailId y : x.cleanup->reads)
    llvm::erase(impl->rails[y].cleanupReaders, oldRail);
  x.cleanup.reset();
  return true;
}

void Uncompute::cleanupBijectiveUnder(RailId oldRail, Value *guard, const abi::TemplateSpec &inverse,
                                      ArrayRef<Operand> ops, bool everyPath) {
  Impl::Rail &x = impl->rail(oldRail, "cleanupBijectiveUnder");
  if (x.storeKept)
    return;   // rule 6: the old value is kept when it is the value or control rail of a kept store
  if (!guard || !guard->getType()->isIntegerTy(1))
    internalError("uncompute: cleanupBijectiveUnder without a classical i1 guard", x.handle);
  if (x.released || !x.exitsDone.empty())
    internalError("uncompute: cleanupBijectiveUnder of a rail already uncomputed", x.handle);
  if (impl->isMerge(oldRail))
    internalError("uncompute: cleanupBijectiveUnder of a merged handle", x.handle);
  if (x.cleanup && x.cleanup->alts.empty())
    internalError("uncompute: cleanupBijectiveUnder of a rail with an unguarded clean-up", x.handle);
  if (!x.cleanup)
    x.cleanup = Impl::Cleanup{};
  Impl::Cleanup::Alt a{guard, inverse, SmallVector<Operand, 3>(ops.begin(), ops.end()), {}};
  for (const Operand &o : ops) {
    if (!o.handle)
      continue;
    RailId r = impl->lookup(o.v, "cleanupBijectiveUnder", x.handle);
    if (r == oldRail)
      internalError("uncompute: rule 6 inverse reads the rail it cleans", x.handle);
    if (impl->rails[r].released)
      internalError("uncompute: rule 6 operand already uncomputed", o.v);
    if (!is_contained(a.reads, r))
      a.reads.push_back(r);
    if (!is_contained(x.cleanup->reads, r)) {
      x.cleanup->reads.push_back(r);
      impl->rails[r].cleanupReaders.push_back(oldRail);
    }
  }
  x.cleanup->alts.push_back(std::move(a));
  x.cleanup->everyPath = everyPath;
}



void Uncompute::flushBefore(Instruction *point) { flushBefore(point, nullptr); }

void Uncompute::flushBefore(Instruction *point, ArrayRef<Value *> *liveLater) {
  if (!point || !point->getParent())
    internalError("uncompute: flushBefore needs an instruction in a block");
  Impl &I = *impl;
  I.syncPhiHits();   // cq-igqp: before candidates are chosen
  Impl::Ctx c{Impl::Mode::Local, point, nullptr};
  BasicBlock *P = point->getParent();
  SmallVector<RailId, 16> cands, deferred;
  for (RailId g = 0; g < I.rails.size(); ++g) {
    if (I.rails[g].ownedBy != kNone)
      continue; // F1: mirrored by its deferred item
    if (I.frozen(g))
      continue; // cq-4593: pending at an open cq_invert region's begin, placed after its end
    if (I.rails[g].deferred != kNone) {
      if (I.resolvable(g))
        deferred.push_back(g);
      continue;
    }
    if (!I.resolvable(g) || !I.rails[g].exitsDone.empty() || (I.defBlock(g) != P && I.flushAt.lookup(g) != P))
      continue;
    bool ok = true;
    for (Instruction *a : I.anchors(g))
      if (a->getParent() != P || !cq::comesBefore(a, point) ||
          (!isa<CallBase>(a) && !I.emitted.count(a) && !I.isMergeHandle(a))) {
        ok = false;
        break;
      }
    if (ok)
      cands.push_back(g);
  }
  I.pruneCleanups(&cands);
  I.resolve(cands, c);
  I.wrapLocal();
  // F1: a deferred item goes last, once every use of its exit rails after the loop lies before P in
  // P's block and every reader of them is resolved.
  if (!liveLater) {
    // cq-k0v13 (rules 14, 18): the tape is one stack: items ready at one point run last loop first (order()'s ties).
    // To a fixed point: an item may wait for an older reader.
    for (bool progress = true; progress;) {
      progress = false;
      for (RailId g : reverse(deferred)) {
        if (!I.resolvable(g) || !I.deferredLocalReady(g, point))
          continue;
        if (any_of(I.readersOf(g), [&](RailId o) { return I.pending(o) && !I.done(o, c); }))
          continue;
        I.place(g, c);
        progress = true;
      }
    }
    return;
  }
  // cq-nqa6 (U7): arm-local rails and deferred items, to a fixed point (an item may be a reader of the
  // other kind: 117's C-block compare reads the reverse loop's exit rail, which reads the trip-0 test).
  DenseSet<RailId> live;
  for (Value *h : *liveLater)
    if (auto it = I.byHandle.find(h); it != I.byHandle.end())
      for (RailId l : I.leaves(it->second))
        for (RailId n : I.names(l))
          live.insert(n);
  for (bool progress = true; progress;) {
    progress = false;
    SmallVector<RailId, 16> span;
    for (RailId g = 0; g < I.rails.size(); ++g)
      if (!I.frozen(g) && I.spanReady(g, point, live))
        span.push_back(g);
    I.dropBlocked(span, c, false);
    for (RailId g : I.order(span))
      if (I.resolvable(g)) {
        I.placeSpan(g, point);
        progress = true;
      }
    for (RailId g = I.rails.size(); g-- > 0;) {   // cq-k0v13: last loop first, as above
      if (I.rails[g].deferred == kNone || I.frozen(g) || !I.resolvable(g) || !I.deferredLocalReady(g, point, true))
        continue;
      if (any_of(I.readersOf(g), [&](RailId o) { return I.pending(o) && !I.done(o, c); }))
        continue;
      // cq-73zea (rule 5; rule 14 case 1 with Q1): an exit rail a later instruction still reads (the loop's exit value
      // a classical join below takes in, its phi not built yet: a zero-trip skip into C) holds the item back, as
      // spanReady holds a live rail; the item frees its exit rails.
      if (any_of(I.defs[I.rails[g].deferred].exits, [&](RailId x) {
            return any_of(I.names(x), [&](RailId n) { return live.count(n) != 0; });
          }))
        continue;
      I.place(g, c);
      progress = true;
    }
  }
}

// cq-4593 (CR rule 17: "the compiler places no uncompute of a rail allocated before the region inside it";
// placement is free, rule 5). The rails pending at begin stay pending while the region is open; at its end
// the end marker becomes a use of each that gained an anchor inside the region, so its item follows the
// end; one with none is placed after its last anchor before the begin. Regions nest.
void Uncompute::openInvert(Instruction *begin) {
  Impl &I = *impl;
  if (!begin || !begin->getParent())
    internalError("uncompute: openInvert needs an instruction in a block");
  DenseMap<RailId, SmallPtrSet<Instruction *, 8>> s;
  for (RailId g = 0; g < I.rails.size(); ++g)
    if (I.pending(g)) {
      SmallPtrSet<Instruction *, 8> &a = s[g];
      for (Instruction *x : I.anchors(g))
        a.insert(x);
    }
  I.invertFrozen.push_back(std::move(s));
  I.invertStart.push_back(RailId(I.rails.size()));
}

void Uncompute::closeInvert(Instruction *end) {
  Impl &I = *impl;
  if (!end || !end->getParent())
    internalError("uncompute: closeInvert needs an instruction in a block");
  if (I.invertFrozen.empty())
    return;   // the region was opened by another function's lowering (begin and end are run-time events)
  DenseMap<RailId, SmallPtrSet<Instruction *, 8>> s = I.invertFrozen.pop_back_val();
  I.lastRegionStart = I.invertStart.pop_back_val();
  for (auto &[g, before] : s)
    if (I.pending(g) && any_of(I.anchors(g), [&](Instruction *x) { return !before.count(x); })) {
      if (!is_contained(I.rails[g].uses, end))
        I.rails[g].uses.push_back(end);
    }
}

// cq-5n3n (CR rule 17 with rule 5): the region closeInvert just closed inverts its own gates, so a rail the
// region computed is uncomputed inside it, before `end` (the compute/uncompute pair reverses into itself);
// a reader after the region recomputes it (the caller). Candidates: the rails made since the region's
// begin that are still pending (garbage or seeds, no merge, no deferred or owned item, no clean-up), less
// those `keep` names and every candidate a kept or pending non-candidate rail reads. Their items are placed
// before `end`; returns their handles.
SmallVector<Value *, 8> Uncompute::resolveRegionMade(Instruction *end, function_ref<bool(Value *)> keep) {
  Impl &I = *impl;
  SmallVector<Value *, 8> out;
  if (I.lastRegionStart == kNone || !end || !end->getParent())
    return out;
  RailId start = I.lastRegionStart;
  I.lastRegionStart = kNone;
  // cq-oyirf (CR rule 17 "A value made in the region and read after its end"): a rule-14 reverse loop the region's loop
  // deferred after its readers (recordDeferred) whose readers all lie in the region is placed before end too, once the
  // rails read in the region are placed; the rails it read (the seed, a test before the loop) are then candidates in turn.
  // To a fixed point.
  for (bool progress = true; progress;) {
    progress = false;
    size_t before = out.size();
    resolveRegionMadeOnce(end, keep, start, out);
    progress = out.size() != before;
    Impl::Ctx c{Impl::Mode::Local, end, nullptr};
    for (RailId g = I.rails.size(); g-- > start;) {   // last loop first (cq-k0v13)
      // (An item whose exit rails nothing reads after the loop has no anchor: it is ready here as well.)
      if (I.rails[g].deferred == kNone || I.frozen(g) || !I.resolvable(g) ||
          !(I.deferredAnchors(I.defs[I.rails[g].deferred]).empty() || I.deferredLocalReady(g, end)))
        continue;
      if (any_of(I.readersOf(g), [&](RailId o) { return I.pending(o) && !I.done(o, c); }))
        continue;
      I.place(g, c);
      progress = true;
    }
  }
  return out;
}

void Uncompute::resolveRegionMadeOnce(Instruction *end, function_ref<bool(Value *)> keep, RailId start,
                                      SmallVectorImpl<Value *> &out) {
  Impl &I = *impl;
  I.pruneCleanups();
  SmallVector<RailId, 16> cands;
  for (RailId g = start; g < I.rails.size(); ++g) {
    const Impl::Rail &r = I.rails[g];
    if (!I.resolvable(g) || I.frozen(g) || r.ownedBy != kNone || r.deferred != kNone || I.isMerge(g) || r.cleanup ||
        !r.exitsDone.empty() || !r.handle || keep(r.handle))
      continue;
    if (any_of(I.anchors(g), [&](Instruction *a) { return a == end || Impl::after(a, end); }))
      continue;
    const BasicBlock *D = I.defBlock(g);
    if (!D || !Impl::dominates(D, end->getParent()))
      continue;   // made in an arm inside the region: its arm's own flush places it
    // cq-oyirf: a rolled loop's header phi over its entry rail (a value the region made before the loop) is no such merge:
    // the loop's reverse reads the entry rail last (a pending reverse keeps it, below), and nothing frees it but its own item.
    if (any_of(r.handle->users(), [&](const User *u) {
          if (!isa<PHINode>(u) && !isa<SelectInst>(u))
            return false;
          auto it = I.byHandle.find(u);
          return it == I.byHandle.end() || !I.rails[it->second].carried;
        }))
      continue;   // an arm of a merge: the merge's own item frees it where the path took it
    cands.push_back(g);
  }
  // A candidate whose pending reader is no candidate stays (its reader still needs it).
  for (bool changed = true; changed;) {
    changed = false;
    for (unsigned i = 0; i < cands.size(); ++i)
      if (any_of(I.readersOf(cands[i]), [&](RailId o) {
            return I.pending(o) && !I.rails[o].released && I.rails[o].exitsDone.empty() && !is_contained(cands, o);
          })) {
        cands.erase(cands.begin() + i);
        changed = true;
        break;
      }
  }
  if (cands.empty())
    return;
  for (RailId g : cands)
    out.push_back(I.rails[g].handle);
  // Rule 5 as anywhere: each item as early as its uses and barriers allow, by the end at the latest. Those
  // made in end's block take the local placement (a non-diagonal gate on what an item reads comes after it);
  // the others are placed at end.
  SmallVector<RailId, 16> local, far;
  for (RailId g : cands)
    (I.defBlock(g) == end->getParent() ? local : far).push_back(g);
  if (!local.empty()) {
    Impl::Ctx c{Impl::Mode::Local, end, nullptr};
    I.resolve(local, c);
    I.wrapLocal();
  }
  if (!far.empty())
    resolveAt(end, far);
}

void Uncompute::resolveAt(Instruction *P, ArrayRef<RailId> list) {
  impl->pruneCleanups();
  Impl &I = *impl;
  if (!P || !P->getParent())
    internalError("uncompute: resolveAt needs an instruction in a block");
  BasicBlock *Pb = P->getParent();
  SmallVector<RailId, 16> cands;
  for (RailId g : list) {
    Impl::Rail &x = I.rail(g, "resolveAt");
    if (x.ownedBy != kNone || x.deferred != kNone || I.isMerge(g))
      internalError("uncompute: resolveAt: " + describe(x.handle) +
                        " is a merge or belongs to a deferred item (resolved with it)",
                    P);
    if (!I.resolvable(g) || !x.exitsDone.empty())
      continue; // kept, or resolved already
    if (!is_contained(cands, g))
      cands.push_back(g);
  }
  // A construction's own intermediate between two listed rails (a gep's scaled index, between the index and the
  // address, resolvePreheader's list naming only instructions' results): a pending reader nothing reads past the
  // point goes with what it reads (rule 5). One with a later use stays the stop below.
  for (size_t i = 0; i < cands.size(); ++i)
    for (RailId o : I.readersOf(cands[i])) {
      Impl::Rail &y = I.rails[o];
      if (is_contained(cands, o) || !I.resolvable(o) || !y.exitsDone.empty() || y.released || y.ownedBy != kNone ||
          y.deferred != kNone || I.isMerge(o))
        continue;
      if (none_of(I.anchors(o), [&](Instruction *a) { return a == P || Impl::after(a, P); }))
        cands.push_back(o);
    }
  for (RailId g : cands) {
    Impl::Rail &x = I.rails[g];
    const BasicBlock *D = I.defBlock(g);
    const Instruction *def = x.creator != kNone ? I.records[x.creator].forward : dyn_cast<Instruction>(x.handle);
    if (!Impl::dominates(D, Pb) || (D == Pb && def && !cq::comesBefore(def, P)))
      internalError("uncompute: resolveAt: the definition of " + describe(x.handle) + " does not dominate the point", P);
    for (Instruction *a : I.anchors(g))
      if (a == P || Impl::after(a, P))
        internalError("uncompute: resolveAt: " + describe(x.handle) + " is still used after the point", a);
    for (RailId o : I.readersOf(g))
      if (I.pending(o) && !I.rails[o].released && I.rails[o].exitsDone.empty() && !is_contained(cands, o))
        internalError("uncompute: resolveAt: " + describe(x.handle) + " is read by the pending item of " +
                          describe(I.rails[o].handle) + ", which is not resolved with it",
                      P);
    // CR §0: resolved for good here, so every path from its definition to a return passes the point.
    SmallPtrSet<const BasicBlock *, 16> seen{D};
    SmallVector<const BasicBlock *, 16> work{D};
    while (!work.empty()) {
      const BasicBlock *b = work.pop_back_val();
      if (b == Pb)
        continue; // passes the point (a definition in Pb comes before it, checked above)
      const Instruction *t = b->getTerminator();
      if (!t || isa<ReturnInst>(t) || isa<UnreachableInst>(t)) {
        if (t && isa<ReturnInst>(t))
          internalError("uncompute: resolveAt: a path from the definition of " + describe(x.handle) +
                            " reaches a return without passing the point",
                        P);
        continue;
      }
      for (const BasicBlock *sb : successors(t))
        if (seen.insert(sb).second)
          work.push_back(sb);
    }
  }
  for (RailId g : I.order(cands))
    if (I.resolvable(g))
      I.placeAt(g, {Pb, P}, true);
  I.wrapLocal();
}

void Uncompute::flushAtExit(ReturnInst *ret) {
  if (!ret || !ret->getParent())
    internalError("uncompute: flushAtExit needs a return in a block");
  Impl &I = *impl;
  // U2: a twin zeroes every result of its call, so either every member is kept or none is. CR rule 18
  // (ruling 2026-11-02, cq-75n4): when some results of one call are measured and others are dead, each
  // measured one is copied into a fresh rail right after the call (cqrt_alloc_<W>(0), cqrt_copy_<W>), the
  // measurements read the copies (Role::Measured), and the call's own result rails are garbage the twin
  // zeroes: the twin always zeroes every result it returned, and no measured rail is ever gated.
  for (size_t gi = 0; gi < I.groups.size(); ++gi) {
    SmallVector<RailId, 4> members = I.groups[gi].members;
    bool anyKept = false, anyDead = false;
    for (RailId m : members)
      (I.rails[m].explicitKept ? anyKept : anyDead) = true;
    // Rules 19, 27 (cq-j2r0j): a table clone's twin is called exactly once, so a table group whose every
    // result is kept is copied out as in the mixed case ("after the result is copied into a fresh rail that
    // is KEPT in its place"); the call's own results are garbage its twin zeroes and frees.
    if (!anyKept || (!anyDead && !I.groups[gi].table))
      continue;
    CallInst *fwd = I.groups[gi].fwd;
    for (RailId m : members) {
      if (!I.rails[m].explicitKept)
        continue;
      if (I.rails[m].role != Role::Measured) {
        // CR rule 18 twin point (cq-4lqy): a result still live where the twin runs is first copied out
        // (cqrt_copy_<W> into a fresh rail) and the copy continues as the value: it takes every later use,
        // record, gate and the kept role; the call's own result rail is garbage the twin zeroes.
        std::optional<RailType> known;
        const Impl::CallGroup &cg = I.groups[gi];
        for (size_t k = 0; k < cg.outs.size() && k < cg.widths.size(); ++k)
          if (cg.outs[k] == m)
            known = cg.widths[k];
        I.copyOutResult(m, fwd, known);
        continue;
      }
      Value *h = I.rails[m].handle;
      auto *hI = dyn_cast<Instruction>(h);
      SmallVector<CallInst *, 2> meas;
      for (User *u : h->users())
        if (auto *mc = dyn_cast<CallInst>(u);
            mc && mc->getCalledFunction() && mc->getCalledFunction()->getName().starts_with("cqrt_measure_"))
          meas.push_back(mc);
      if (!hI || !hI->getNextNode() || meas.empty())
        internalError("uncompute: a measured result of a clone call with no cqrt_measure reading it", fwd);
      Module &M = *fwd->getModule();
      RailType w = railTypeOf(meas.front()->getType());
      IRBuilder<> B(hI->getNextNode());
      CallInst *c = I.track(B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Alloc, w}),
                                         {Constant::getNullValue(irTypeOf(M.getContext(), w))}));
      I.track(B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Copy, w}), {h, c}));
      for (CallInst *mc : meas)
        mc->replaceUsesOfWith(h, c);
      I.rails[m].role = Role::Garbage;
      I.rails[m].explicitKept = false;
      I.newRail(c, Role::Measured, "flushAtExit"); // may move rails: indices only from here
    }
    // A measured member other than the group's lead kept the lead through the U2 alias (keepPhi of a
    // cell-load merge): no member names a kept rail any more, so none is kept.
    for (RailId m : members)
      if (Impl::keptRole(I.rails[m].role))
        I.rails[m].role = Role::Garbage;
  }
  // After the twin-point copies: a member they made garbage again prunes the clean-ups whose old content its
  // twin reads (cq-05pa).
  impl->pruneCleanups();
  Impl::Ctx c{Impl::Mode::Exit, ret, nullptr};
  BasicBlock *Rb = ret->getParent();
  SmallVector<RailId, 16> cands;
  // cq-4tkb4: nothing below changes the CFG until wrapLocal but a deferred item's placement (which suspends the cache).
  std::optional<Impl::ReachScope> reach;
  reach.emplace(*Rb->getParent());
  for (RailId g = 0; g < I.rails.size(); ++g) {
    if (!I.resolvable(g) || I.done(g, c) || I.rails[g].ownedBy != kNone)
      continue;
    if (unsigned di = I.rails[g].deferred; di != kNone) {
      // F1: placed here when its loop reaches this return (the item branches around itself on a path
      // where the loop did not run).
      if (any_of(I.defs[di].region, [&](const BasicBlock *rb) { return Impl::reaches(rb, Rb); })) {
        cands.push_back(g);
      }
      continue;
    }
    const BasicBlock *D = I.defBlock(g);
    if (!Impl::reaches(D, Rb))
      continue;
    if (Impl::onCycle(D) && (!I.rails[g].keepers.empty() || (!Impl::dominates(D, Rb) && !I.rails[g].mergedInto.empty()))) {
      // cq-lshe: an arm on a cycle (a phi over arm-local handles in a loop, or an arm a kept merge in the
      // loop chooses on some passes only): resolved per instance (cyclePoint).
      I.cycleArm.insert(g);
      cands.push_back(g);
      continue;
    }
    if (!Impl::dominates(D, Rb) && !Impl::onCycle(D)) {
      // cq-ut4k: placed here under its arm's selector (wrapArmItems).
      I.armLocal.insert(g);
      cands.push_back(g);
      continue;
    }
    if (!Impl::dominates(D, Rb))
      internalError("uncompute: " + describe(I.rails[g].handle) +
                        " is still pending at a return its definition does not dominate (an arm was not flushed)",
                    ret);
    cands.push_back(g);
  }
  I.resolve(cands, c);
  I.resolveUnmeasured(Rb); // cq-8lf8
  reach.reset();
  I.wrapLocal();
  I.wrapArmItems(*Rb->getParent());
  I.armLocal.clear();
  I.cycleArm.clear();
}

bool Uncompute::recorded(const Value *handle) const { return impl->byHandle.count(handle) != 0; }

void Uncompute::recordDeferred(ArrayRef<unsigned> scopes, ArrayRef<RailId> exitRails,
                               std::function<void(IRBuilder<> &)> emit, ArrayRef<RailId> reads,
                               ArrayRef<unsigned> hostScopes) {
  Impl &I = *impl;
  if (!emit)
    internalError("uncompute: recordDeferred without an emitter");
  unsigned di = I.defs.size();
  Impl::Deferred d;
  d.emit = std::move(emit);
  d.hostScopes.assign(hostScopes.begin(), hostScopes.end());
  d.scopes.assign(scopes.begin(), scopes.end());
  for (unsigned s : scopes) {
    if (s >= I.scopes.size() || I.scopes[s].open)
      internalError("uncompute: recordDeferred over a scope that is not closed: " + std::to_string(s));
    for (unsigned rec = I.scopes[s].begin; rec < I.scopes[s].end; ++rec) {
      if (I.info[rec].item == kNone || !I.scopes[s].left.count(I.info[rec].item))
        d.region.insert(I.records[rec].forward->getParent());
      if (isCreator(I.info[rec].kind) && I.info[rec].item != kNone && !I.scopes[s].left.count(I.info[rec].item)) {
        I.rails[I.info[rec].item].ownedBy = di;
      }
    }
  }
  if (exitRails.empty())
    internalError("uncompute: recordDeferred without exit rails");
  for (RailId x : exitRails) {
    // cq-03rdt (CR rules 18, 14): a call's result past the first names the lead (recordCall's U2 alias); the lead's twin
    // zeroes and frees every result, so the item's exit rail is the lead.
    if (I.rail(x, "recordDeferred").group != kNone)
      x = I.groups[I.rails[x].group].members.front();
    Impl::Rail &rx = I.rail(x, "recordDeferred");
    if (rx.ownedBy != di || rx.released || I.isMerge(x))
      internalError("uncompute: recordDeferred: an exit rail that is not a pending rail of the item's scopes", rx.handle);
    if (!is_contained(d.exits, x))
      d.exits.push_back(x);
  }
  RailId g = I.rails.size();
  I.rails.emplace_back();
  I.rails.back().handle = I.rails[d.exits.front()].handle;
  I.rails.back().deferred = di;
  d.pseudo = g;
  for (RailId r : reads) {
    Impl::Rail &rr = I.rail(r, "recordDeferred");
    if (rr.ownedBy == di)
      internalError("uncompute: recordDeferred: a read rail owned by the item", rr.handle);
    if (!is_contained(d.reads, r)) {
      d.reads.push_back(r);
      rr.cleanupReaders.push_back(g);
    }
  }
  I.defs.push_back(std::move(d));
  // Rule 14: a loop's reverse inside this item's scopes (a loop of a classical exit's arm) is part of this item: placed in
  // its mirror, never by itself at a return.
  for (unsigned e = 0; e < di; ++e) {
    Impl::Rail &pe = I.rails[I.defs[e].pseudo];
    if (!pe.released && pe.ownedBy == kNone &&
        any_of(I.defs[e].exits, [&](RailId x) { return I.rails[x].ownedBy == di; }))
      pe.ownedBy = di;
  }
}

unsigned Uncompute::openScope() {
  unsigned id = impl->scopes.size();
  impl->scopes.push_back({static_cast<unsigned>(impl->records.size()), kNone, true});
  impl->openStack.push_back(id);
  return id;
}

void Uncompute::beginTripFlush(ArrayRef<unsigned> segScopes) {
  impl->tripFlush.emplace_back(segScopes.begin(), segScopes.end());
}

void Uncompute::endTripFlush() {
  if (impl->tripFlush.empty())
    internalError("uncompute: endTripFlush without beginTripFlush");
  impl->tripFlush.pop_back();
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

void Uncompute::leaveScope(unsigned s, const BasicBlock *head) {
  Impl &I = *impl;
  if (s >= I.scopes.size())
    internalError("uncompute: no scope " + std::to_string(s));
  Impl::Scope &sc = I.scopes[s];
  unsigned end = sc.open ? I.records.size() : sc.end;
  auto outside = [&](const CallInst *i) { return !Impl::reaches(head, i->getParent()); };
  for (unsigned rec = sc.begin; rec < end; ++rec)
    if (isCreator(I.info[rec].kind) && I.info[rec].item != kNone && outside(I.records[rec].forward) &&
        all_of(I.rails[I.info[rec].item].writes, [&](unsigned w) { return outside(I.records[w].forward); }))
      sc.left.insert(I.info[rec].item);   // a rail a trip writes stays: the trip's mirror undoes those writes
  // So does a rail that reads one that stays: an operand outlives every _unc that reads it (rule 5).
  for (bool changed = true; changed;) {
    changed = false;
    for (unsigned rec = sc.begin; rec < end; ++rec) {
      RailId g = I.info[rec].item;
      if (!isCreator(I.info[rec].kind) || g == kNone || sc.left.count(g))
        continue;
      for (RailId o : I.readersOf(g))
        if (sc.left.erase(o))
          changed = true;
    }
  }
}

bool Uncompute::leftScope(unsigned s, const Value *h) const {
  auto it = impl->byHandle.find(h);
  return it != impl->byHandle.end() && impl->scopes[s].left.count(it->second);
}

bool Uncompute::mirroring() const { return impl->inMirror; }

bool Uncompute::invertOpen() const { return !impl->invertFrozen.empty(); }

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
    if (cr != kNone && cr >= sc.begin && cr < end && !sc.left.count(g) && I.resolvable(g))
      cands.push_back(g);
  }
  bool wasInMirror = I.inMirror;
  I.inMirror = true;
  for (bool grew = true; grew;) {
    grew = false;
    for (unsigned k = 0; k < cands.size() && !grew; ++k)
      for (RailId o : I.readersOf(cands[k]))
        if (I.rails[o].deferred != kNone && I.resolvable(o) && !is_contained(cands, o)) {
          cands.push_back(o);
          grew = true;
          break;
        }
  }
  I.resolve(cands, c);
  I.inMirror = wasInMirror;
}

} // namespace cq

namespace cq {
} // namespace cq
