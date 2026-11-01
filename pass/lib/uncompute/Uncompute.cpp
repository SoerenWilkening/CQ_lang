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
//        xor_i1 (involutions: undone by the same call, BACKEND_ABI §1.8, §1.9) and qram_store on the
//        bus `out` (undone by its _unc as an item of its own, POP(k), see QRAM versions below);
//      with a fresh result (`out` is ignored, the new rail's id is returned): qram_load (Role::Garbage,
//        undone by its _unc(h, args...)), qram_alloc (Role::Seed, released by cqrt_qram_free),
//        qram_realloc (cq-vtfq, CR §1.3: ops (a, classical n); a' is a bus of its own, Role::Seed, released
//        by qram_realloc_<W>_unc(a', n_old) after every POP and load un-copy on a'; n_old is a's qram_alloc
//        or qram_realloc size; a's qram_free, its POPs and its load un-copies follow that release; a kept a'
//        with a resolvable item on a is unimplemented), alloc (= recordSeed). Any other core gate is not reversible and is an internal error here.
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
//  - recordCellLoad(load, mayName) (M3, cq-arch 2026-11-01; CR rules 5, 20): load is a new-IR load of
//    a slot cell's handle that names at run time one of mayName (recorded, unfreed rails). It is a
//    merge as above with mayName as its arms: never resolved itself, a use of it is a use of every arm,
//    a barrier on it binds every arm. It has no join, so a kept role on it (or on a merge naming it)
//    keeps every resolvable arm, with no edge logic. mayName empty is an internal error.
//  - recordCall(fwd, outs, slotOuts, extra) (U2, cq-arch 2026-11-01; CR §1.4, rules 18, 27): the result
//    rails of one clone call. The first member (outs, then slotOuts) is the leader: it carries a Call
//    record over fwd's arguments and extra (their handles are its reads) and the group's one item; every
//    other member is a merge over the leader alone (as a cell load: a use of it is a use of the leader,
//    a kept role on it keeps the leader). The item emits <callee>_unc(outs..., fwd args..., extra...)
//    (C calling convention) and then cqrt_free of every member in order. Every member kept: nothing.
//    A kept leader with a member that was not given a kept role itself is unimplemented at flushAtExit
//    (the twin would zero the kept results); KeptEntangled (a barrier) keeps all of them. The item
//    follows the definitions of every member and of every extra operand defined after fwd (cq-b73i).
//  - noteCallReads(fwd, rails) (U4, cq-arch 2026-11-01; CR rule 5): rails in caller cells the clone call
//    fwd reads (its twin recompute-reads them). They are reads of fwd's group item, as fwd's handle
//    arguments are: their own items follow it, and a barrier on one binds it. It may come before or
//    after fwd's recordCall (or its recordTemplate, a clone with one result). Beyond the noted ones, a
//    clone call (a callee that is not a cq_template_ or cqrt_ function) reads every pending rail that
//    may sit in a cell of its twin's footprint (railCells), cq-w2a-calls: the objects its pointer
//    arguments point to, the globals the C body accesses, and every object reachable from outside the
//    frame when the body accesses memory through a pointer it loaded (cq-99z6). A write into the
//    footprint between the call and its twin is a barrier of the call's item; a cell the clone writes
//    (slotOuts) that the footprint reaches by a second route is unimplemented (cq-aqk1).
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
//  - QRAM versions (amendment A2, cq-w6ie). A bus's stores s_1..s_m in program order are each an item
//    POP(k) (the store's _unc alone), which reads the store's index, value and control rails. A load
//    made after s_k reads version v_k. POP(k) follows every use of the bus, POP(k+1) and the un-copy
//    of every load reading v_j, j >= k; a load reading v_k is un-copied after every POP(j), j > k (the
//    cell holds v_k again), so a later popped store is no barrier for it. The bus's item is
//    cqrt_qram_free alone, after every POP and load un-copy (77: pop the rmw store, sum, old, the
//    index, then the initializers). A kept bus (a global, Output) has no POP: its stores stay and stay
//    barriers. A POP made KeptEntangled by a hit on a rail it reads keeps every earlier POP, every load
//    reading an earlier version, and the bus.
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
//    the copy (which takes the role), and the item undoes the rail itself; a rotated one is unimplemented.
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
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/ADT/MapVector.h"
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
  QramAlloc, // nothing to undo, released by cqrt_qram_free
  QramRealloc, // CR §1.3 a' = qram_realloc_<W>(a, n): nothing to undo, released by qram_realloc_<W>_unc(a', n_old)
  QramLoad,  // fresh out, undone by name_unc(out, args...)
  Involution,// in place on out, undone by the same call
  QramStore, // in place on the object, undone by name_unc(args...)
  Call,      // U2: a clone call's results, undone together by name_unc(outs..., args..., extra...)
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
    RailId item = kNone;          // the item that undoes it: out, or a QRAM store's POP (A2)
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
    SmallVector<Instruction *, 1> aliasHits; // cq-zh7z: gates on another handle that may name this rail
    SmallVector<unsigned, 4> readerRecs; // records with this rail among their reads
    SmallVector<RailId, 2> cleanupReaders; // rails whose rule 6 clean-up reads this rail
    std::optional<Cleanup> cleanup;
    SmallPtrSet<const BasicBlock *, 2> exitsDone; // returns this rail was placed for
    SmallVector<RailId, 2> arms;       // U1: non-empty iff this rail is a merge (its handle aliases one arm)
    SmallVector<RailId, 2> mergedInto; // U1: the merges that name this rail as an arm
    bool cellLoad = false;             // M3: a merge that is a load of a slot cell's handle
    unsigned group = kNone;            // U2: the call group this rail is a member of
    bool explicitKept = false;         // U2: setRole gave this rail a kept role itself
    // A2 (cq-w6ie): QRAM versions. A bus's stores s_1..s_m (program order) are POP items of their
    // own; a load records, per bus it may read, the number k of stores made before it (it reads v_k).
    RailId popBus = kNone;             // POP(popK) of this bus: a pseudo rail, handle = the store call
    unsigned popK = 0;                 // 1-based
    SmallVector<RailId, 4> pops;       // on a bus: POP(1..m)
    SmallVector<RailId, 4> loads;      // on a bus: the loads that recorded a version on it
    SmallVector<std::pair<RailId, unsigned>, 1> versions; // on a load: (bus, k)
    SmallVector<RailId, 1> reallocs;   // cq-vtfq: on a bus, the buses qram_realloc made from it (a')
    // cq-sodl: the edges this arm was freed on (the block P ending the edge, the kept merge m that
    // does not choose it there). A later read of the arm not through m on a path leaving P is caught.
    SmallVector<std::pair<BasicBlock *, RailId>, 1> edgeFrees;
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
    RailId pseudo = kNone;
    BasicBlock *placedAt = nullptr;            // the block the program continues in after the item
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
  std::vector<Deferred> defs;
  // U2: one clone call's results. members[0] (the leader, an out or else a slotOut) carries the Call
  // record and the item; every other member is a merge over the leader alone (cellLoad, no join), so a
  // use of it is a use of the leader and a kept role on it keeps the leader.
  struct CallGroup {
    CallInst *fwd;
    SmallVector<RailId, 4> outs, slotOuts, members;
    SmallVector<Value *, 4> extra;
  };
  std::vector<CallGroup> groups;
  // U4: rails in caller cells a clone call reads (noteCallReads, before or after its recordCall).
  DenseMap<const CallInst *, SmallVector<RailId, 4>> callReads;
  void addCallRead(unsigned rec, RailId r) {
    if (is_contained(info[rec].reads, r) || r == info[rec].item)
      return;
    info[rec].reads.push_back(r);
    rails[r].readerRecs.push_back(rec);
  }
  // The record of a clone call (a U2 group's Call record, or a single result's template record).
  unsigned callRecord(const CallInst *fwd) const {
    for (unsigned k = 0; k < records.size(); ++k)
      if (records[k].forward == fwd && (info[k].kind == RecKind::Call || info[k].kind == RecKind::Template))
        return k;
    return kNone;
  }
  // A clone call's twin reads the objects its pointer arguments point to (CR rule 5, 164: the handle
  // cells of a slot record the clone loads): every pending rail that may sit in a cell of one of them
  // when the call runs (railCells: stored there, or copied there by a memory intrinsic) is a read of
  // the call's record, so its item follows the twin. U4's noted reads are a subset.
  void addObjectReads(CallInst *fwd, unsigned rec) {
    const DataLayout &DL = fwd->getModule()->getDataLayout();
    Footprint fp = footprint(fwd);
    if (fp.empty())
      return;
    for (RailId g = 0; g < rails.size(); ++g) {
      if (g == info[rec].item || isMerge(g) || rails[g].released || rails[g].popBus != kNone ||
          rails[g].deferred != kNone)
        continue;
      if (auto *d = dyn_cast<Instruction>(rails[g].handle); d && !(d != fwd && after(fwd, d)))
        continue;
      SmallVector<Cell, 8> cells;
      railCells(g, cells);
      for (const Cell &c : cells)
        if (any_of(fp.objs, [&](const Cell &o) { return mayAlias(o, c, DL); }) ||
            (fp.unbounded && reachable(c.ptr))) {
          addCallRead(rec, g);
          break;
        }
    }
  }
  void takeCallReads(CallInst *fwd, unsigned rec) {
    for (RailId r : callReads.lookup(fwd))
      addCallRead(rec, r);
    addObjectReads(fwd, rec);
  }
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

  // ---- memory aliases of handles (cq-zh7z, cq-vdaa) ---------------------------------------------
  // A handle reaches memory by a store of it (a slot cell) and is read back by a load, which is a
  // rail of its own (recordExternal). A cell is a pointer and the byte size accessed through it
  // (0: unknown extent, the whole object from there on).
  struct Cell {
    const Value *ptr;
    uint64_t size;
    bool operator==(const Cell &o) const { return ptr == o.ptr && size == o.size; }
  };
  static uint64_t accessSize(Type *t, const DataLayout &DL) {
    TypeSize ts = DL.getTypeStoreSize(t);
    return ts.isScalable() ? 0 : ts.getFixedValue();
  }
  // The cells a rail may sit in, closed over copies (cq-vdaa): the pointers its handle (or a merge
  // naming it) was stored to or loaded from; then every load of the function that may read one of
  // those cells may be the rail, so the cells that load (or a phi or select of it) is stored to join
  // the set; a memcpy or memmove whose source may overlap a cell copies the rail to an unknown cell
  // of its destination object. Repeated to a fixed point.
  void railCells(RailId y, SmallVectorImpl<Cell> &out) const {
    SmallVector<const Value *, 8> vals;
    for (RailId n : names(y))
      if (rails[n].handle && !is_contained(vals, rails[n].handle))
        vals.push_back(rails[n].handle);
    const Function *F = nullptr;
    for (const Value *v : vals)
      if (auto *I = dyn_cast<Instruction>(v)) {
        F = I->getFunction();
        break;
      } else if (auto *A = dyn_cast<Argument>(v)) {
        F = A->getParent();
        break;
      }
    if (!F)
      return;
    const DataLayout &DL = F->getDataLayout();
    auto addCell = [&](Cell c) {
      if (!is_contained(out, c))
        out.push_back(c);
    };
    auto addVal = [&](const Value *v) {
      if (!is_contained(vals, v))
        vals.push_back(v);
    };
    size_t vi = 0, ci = 0;
    while (vi < vals.size() || ci < out.size()) {
      // Values to the cells they sit in.
      for (; vi < vals.size(); ++vi) {
        const Value *h = vals[vi];
        if (auto *ld = dyn_cast<LoadInst>(h))
          addCell({ld->getPointerOperand(), accessSize(ld->getType(), DL)});
        for (const User *u : h->users()) {
          if (auto *st = dyn_cast<StoreInst>(u); st && st->getValueOperand() == h)
            addCell({st->getPointerOperand(), accessSize(h->getType(), DL)});
          else if (isa<PHINode>(u) || (isa<SelectInst>(u) && cast<SelectInst>(u)->getCondition() != h))
            addVal(u);
        }
      }
      // Cells to the loads and copies that may read them.
      for (; ci < out.size(); ++ci) {
        Cell c = out[ci];
        for (const Instruction &I : instructions(*F)) {
          if (auto *ld = dyn_cast<LoadInst>(&I)) {
            if (mayAlias(c, {ld->getPointerOperand(), accessSize(ld->getType(), DL)}, DL))
              addVal(ld);
          } else if (auto *mt = dyn_cast<MemTransferInst>(&I)) {
            if (mayAlias(c, {mt->getRawSource(), 0}, DL))
              addCell({getUnderlyingObject(mt->getRawDest()), 0});
          }
        }
      }
    }
  }
  // Base object plus constant and variable byte offsets, through GEPs.
  struct Addr {
    const Value *base;
    APInt off{64, 0};
    MapVector<Value *, APInt> vars;
    bool exact = true;
  };
  static Addr decompose(const Value *p, const DataLayout &DL) {
    Addr a;
    for (unsigned depth = 0; depth < 16; ++depth) {
      p = p->stripPointerCasts();
      auto *g = dyn_cast<GEPOperator>(p);
      if (!g)
        break;
      if (!g->collectOffset(DL, 64, a.vars, a.off)) {
        a.exact = false;
        p = getUnderlyingObject(p);
        break;
      }
      p = g->getPointerOperand();
    }
    a.base = p;
    return a;
  }
  static bool identified(const Value *v) { return isa<AllocaInst>(v) || isa<GlobalVariable>(v); }
  // False only when the two cells provably do not overlap.
  static bool mayAlias(const Cell &p, const Cell &q, const DataLayout &DL) {
    if (p.ptr == q.ptr)
      return true;
    Addr a = decompose(p.ptr, DL), b = decompose(q.ptr, DL);
    if (a.base != b.base) {
      const Value *ua = getUnderlyingObject(a.base), *ub = getUnderlyingObject(b.base);
      return !(ua != ub && identified(ua) && identified(ub));
    }
    if (!a.exact || !b.exact || a.vars.size() != b.vars.size() || p.size == 0 || q.size == 0)
      return true;
    for (auto &kv : a.vars) {
      auto it = b.vars.find(kv.first);
      if (it == b.vars.end() || it->second != kv.second)
        return true;
    }
    // [a.off, a.off + p.size) and [b.off, b.off + q.size) overlap.
    return a.off.slt(b.off + q.size) && b.off.slt(a.off + p.size);
  }
  // A gate on target may hit every other live rail that sits in a cell target's handle may share.
  void noteAliasHits(RailId target, Instruction *gate) {
    const DataLayout &DL = gate->getModule()->getDataLayout();
    SmallVector<RailId, 4> self = leaves(target);
    SmallVector<Cell, 8> mine;
    for (RailId t : self)
      railCells(t, mine);
    if (mine.empty())
      return;
    for (RailId y = 0; y < rails.size(); ++y) {
      Rail &ry = rails[y];
      if (isMerge(y) || ry.released || ry.popBus != kNone || ry.deferred != kNone || is_contained(self, y))
        continue;
      SmallVector<Cell, 8> theirs;
      railCells(y, theirs);
      bool hit = false;
      for (const Cell &p : mine)
        for (const Cell &q : theirs)
          hit = hit || mayAlias(p, q, DL);
      if (hit)
        ry.aliasHits.push_back(gate);
    }
  }

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
        checkEdgeRead(r, fwd, who);
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

  bool isPop(RailId g) const { return rails[g].popBus != kNone; }

  // A bus whose stores are popped: one that is itself resolved (a kept bus, e.g. a global, Output,
  // keeps every store; a KeptEntangled bus keeps the stores below a kept POP).
  bool busPoppable(RailId b) const {
    const Rail &r = rails[b];
    return !r.cleanup && r.arms.empty() && (r.role == Role::Seed || r.role == Role::Garbage);
  }

  // The store record w is (or will be) popped before the bus is released.
  bool storePopped(unsigned w) const {
    RailId p = info[w].item;
    return info[w].kind == RecKind::QramStore && isPop(p) && rails[p].role == Role::Garbage &&
           busPoppable(rails[p].popBus);
  }

  bool resolvable(RailId g) const {
    const Rail &r = rails[g];
    if (r.popBus != kNone)
      return !r.released && r.role == Role::Garbage && busPoppable(r.popBus);
    return !r.released && r.arms.empty() && (r.cleanup || r.role == Role::Garbage || r.role == Role::Seed);
  }

  bool directRelease(RailId g) const {
    const Rail &r = rails[g];
    if (r.cleanup || r.role != Role::Seed)
      return false;
    if (r.creator != kNone && info[r.creator].kind == RecKind::QramRealloc)
      return false; // cq-vtfq: its item reads the old bus, which is released after it
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
      if (info[w].kind != RecKind::QramStore) // A2: each store is its own POP item
        out.push_back(w);
    return out;
  }

  SmallVector<RailId, 4> itemReads(RailId g) const {
    const Rail &r = rails[g];
    if (r.deferred != kNone)
      return SmallVector<RailId, 4>(defs[r.deferred].reads.begin(), defs[r.deferred].reads.end());
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
    // To a fixed point: dropping one clean-up makes its rail plain garbage again, which may now be a
    // garbage reader of an earlier clean-up's operand (164's clone: %6 = %7 - %3 kept while %7's own
    // clean-up through the result was still there, then %7's dropped: a cycle).
    for (bool again = true; again;) {
      again = false;
      for (RailId g = 0; g < rails.size(); ++g)
        if (pruneOne(g))
          again = true;
    }
  }
  bool pruneOne(RailId g) {
    Rail &r = rails[g];
    if (!r.cleanup || r.released)
      return false;
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
    return true;
  }

  // Rails whose item reads g, directly or through a merge that may name g (U1).
  SmallVector<RailId, 4> readersOf(RailId g) const {
    if (rails[g].deferred != kNone) {
      // F1: the item frees its exit rails, so every rail outside it whose item reads one goes first.
      const Deferred &d = defs[rails[g].deferred];
      SmallVector<RailId, 4> out;
      for (RailId x : d.exits)
        for (RailId o : readersOf(x))
          if (o != g && rails[o].ownedBy != rails[g].deferred && !is_contained(out, o))
            out.push_back(o);
      return out;
    }
    SmallVector<RailId, 4> ns = names(g);
    SmallVector<RailId, 4> cand;
    for (RailId n : ns) {
      for (unsigned rec : rails[n].readerRecs)
        if (!is_contained(cand, info[rec].item))
          cand.push_back(info[rec].item);
      for (RailId o : rails[n].cleanupReaders)
        if (!is_contained(cand, o))
          cand.push_back(o);
    }
    SmallVector<RailId, 4> out;
    for (RailId o : cand) {
      if (o == g)
        continue;
      SmallVector<RailId, 4> rd = itemReads(o);
      if (!any_of(ns, [&](RailId n) { return is_contained(rd, n); }))
        continue;
      // F1: a reader owned by a deferred item not yet placed is undone by that item.
      if (unsigned di = rails[o].ownedBy; di != kNone && rails[g].ownedBy != di && !rails[defs[di].pseudo].released)
        o = defs[di].pseudo;
      if (o != g && !is_contained(out, o))
        out.push_back(o);
    }
    for (RailId o : versionBefore(g))
      if (!is_contained(out, o))
        out.push_back(o);
    return out;
  }

  // A2 (cq-w6ie): the QRAM version order, items that must precede g's item beyond its readers.
  //  - POP(k) follows POP(k+1) (last in, first out) and the un-copy of every load reading v_j, j >= k;
  //  - a load reading v_k is un-copied after POP(j) for every j > k (the cell holds v_k again);
  //  - the bus (cqrt_qram_free) follows every POP (its loads are readers already).
  SmallVector<RailId, 4> versionBefore(RailId g) const {
    const Rail &r = rails[g];
    SmallVector<RailId, 4> out;
    if (r.popBus != kNone) {
      const Rail &b = rails[r.popBus];
      if (r.popK < b.pops.size())
        out.push_back(b.pops[r.popK]);
      for (RailId l : b.loads)
        for (auto [bus, k] : rails[l].versions)
          if (bus == r.popBus && k >= r.popK && !is_contained(out, l))
            out.push_back(l);
      // cq-vtfq: a store through a is popped once every realloc result a' of a is undone (a is the
      // bus again only after qram_realloc_unc).
      for (RailId a2 : b.reallocs)
        if (!is_contained(out, a2))
          out.push_back(a2);
      return out;
    }
    for (auto [bus, k] : r.versions) {
      for (unsigned j = k; j < rails[bus].pops.size(); ++j)
        out.push_back(rails[bus].pops[j]);
      for (RailId a2 : rails[bus].reallocs) // cq-vtfq: a load through a is un-copied after a' is undone
        if (!is_contained(out, a2))
          out.push_back(a2);
    }
    out.append(r.pops.begin(), r.pops.end());
    return out;
  }

  // POP(k) of a bus is kept (a non-diagonal gate hit a rail it reads): its store stays, so every
  // earlier store stays, every load reading an earlier version cannot be un-copied, and the bus is
  // never freed (CR §0; A4).
  void keepBelow(RailId g) {
    RailId b = rails[g].popBus;
    for (unsigned j = 1; j < rails[g].popK; ++j)
      rails[rails[b].pops[j - 1]].role = Role::KeptEntangled;
    for (RailId l : rails[b].loads)
      for (auto [bus, k] : rails[l].versions)
        if (bus == b && k < rails[g].popK && resolvable(l)) {
          rails[l].role = Role::KeptEntangled;
          rails[l].cleanup.reset();
        }
    rails[b].role = Role::KeptEntangled;
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
    if (r.popBus != kNone) {
      // POP(k) follows every use of the bus (those after s_k are the ones that matter).
      SmallVector<Instruction *, 8> out = anchors(r.popBus);
      out.push_back(records[r.creator].forward);
      return out;
    }
    SmallVector<Instruction *, 8> out;
    if (r.creator != kNone)
      out.push_back(records[r.creator].forward);
    if (r.group != kNone && r.creator != kNone && info[r.creator].kind == RecKind::Call) {
      // cq-b73i: the group's item names every member's handle and extra operand, so it follows their
      // definitions even when nothing uses them (a slotOut loaded after the call and never read).
      const CallGroup &cg = groups[r.group];
      for (RailId m : cg.members)
        if (auto *i = dyn_cast<Instruction>(rails[m].handle))
          out.push_back(i);
      for (Value *e : cg.extra)
        if (auto *i = dyn_cast<Instruction>(e); i && i->getParent() && !(i->getParent() == cg.fwd->getParent() && i->comesBefore(cg.fwd)))
          out.push_back(i);
    }
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

  // cq-99z6 (orchestrator decision under CR rule 5 and NORTHSTAR p2, owner may override): the memory a
  // clone call's twin reads or writes when it runs (it recomputes the clone's body): the objects its
  // pointer arguments point to, every non-constant global the clone (transitively) accesses, and, when
  // the clone accesses memory through a pointer that is neither a formal, a global nor its own frame (a
  // loaded pointer, a call's result, an unknown callee), every object reachable from outside the
  // caller's frame (`unbounded`). Summarized on the original bodies, which survive until the end of the
  // run.
  struct MemSummary {
    SmallVector<const GlobalVariable *, 4> globals;
    bool unbounded = false;
  };
  struct Footprint {
    SmallVector<Cell, 4> objs;   // pointer arguments and globals (whole objects: size 0)
    bool unbounded = false;
    bool empty() const { return objs.empty() && !unbounded; }
  };
  static bool isRuntimeName(StringRef n) { return n.starts_with("cq_template_") || n.starts_with("cqrt_"); }
  // The C callee a clone (or a twin, or a declared clone) recomputes, or null.
  static const Function *cloneSource(const Function &cf) {
    std::optional<abi::CloneSpec> s = abi::parseClone(cf.getName());
    if (!s)
      return nullptr;
    return cf.getParent()->getFunction(s->fn);
  }
  // Classifies an address used by F: a formal or F's frame is fine (a formal's object is classified at
  // F's call site), a non-constant global is recorded, anything else makes the footprint unbounded.
  static void classifyAddr(const Value *p, MemSummary &S) {
    SmallVector<const Value *, 4> objs;
    getUnderlyingObjects(p, objs);
    for (const Value *u : objs) {
      if (isa<Argument>(u) || isa<AllocaInst>(u) || isa<ConstantPointerNull>(u) || isa<UndefValue>(u))
        continue;
      if (auto *g = dyn_cast<GlobalVariable>(u)) {
        if (!g->isConstant() && !is_contained(S.globals, g))
          S.globals.push_back(g);
        continue;
      }
      if (isa<Function>(u))
        continue;
      S.unbounded = true;
    }
  }
  static void summarize(const Function &F, MemSummary &S, SmallPtrSetImpl<const Function *> &seen) {
    if (!seen.insert(&F).second)
      return;
    if (F.isDeclaration()) {
      if (F.isIntrinsic() || F.doesNotAccessMemory() || F.onlyWritesMemory() || F.onlyAccessesArgMemory() ||
          isRuntimeName(F.getName()) || F.getName().starts_with("cq_"))
        return;
      S.unbounded = true;
      return;
    }
    for (const Instruction &I : instructions(F)) {
      if (!I.mayReadOrWriteMemory())
        continue;
      if (auto *L = dyn_cast<LoadInst>(&I))
        classifyAddr(L->getPointerOperand(), S);
      else if (auto *St = dyn_cast<StoreInst>(&I))
        classifyAddr(St->getPointerOperand(), S);
      else if (auto *A = dyn_cast<AtomicRMWInst>(&I))
        classifyAddr(A->getPointerOperand(), S);
      else if (auto *X = dyn_cast<AtomicCmpXchgInst>(&I))
        classifyAddr(X->getPointerOperand(), S);
      else if (auto *CB = dyn_cast<CallBase>(&I)) {
        if (auto *ii = dyn_cast<IntrinsicInst>(CB); ii && (ii->isLifetimeStartOrEnd() || ii->isAssumeLikeIntrinsic()))
          continue;
        const Function *G = CB->getCalledFunction();
        if (!G || CB->isInlineAsm()) {
          S.unbounded = true;
          continue;
        }
        if (CB->doesNotAccessMemory())
          continue;
        // The callee's own accesses (its formals' objects are its actuals here).
        for (const Value *a : CB->args())
          if (a->getType()->isPointerTy())
            classifyAddr(a, S);
        if (G->isIntrinsic() && !isa<MemIntrinsic>(CB) && !CB->onlyAccessesArgMemory())
          S.unbounded = true;
        else if (!G->isIntrinsic())
          summarize(*G, S, seen);
      } else {
        S.unbounded = true;   // va_arg, fence and the like
      }
    }
  }
  mutable DenseMap<const Function *, MemSummary> summaries;
  const MemSummary &summaryOf(const Function *F) const {
    auto it = summaries.find(F);
    if (it == summaries.end()) {
      MemSummary S;
      SmallPtrSet<const Function *, 8> seen;
      summarize(*F, S, seen);
      it = summaries.try_emplace(F, std::move(S)).first;
    }
    return it->second;
  }
  Footprint footprint(const CallInst *fwd) const {
    Footprint fp;
    const Function *cf = fwd->getCalledFunction();
    if (!cf || isRuntimeName(cf->getName()))
      return fp;
    for (const Value *a : fwd->args())
      if (a->getType()->isPointerTy())
        fp.objs.push_back({a, 0});
    const Function *src = cloneSource(*cf);
    if (!src)
      return fp;   // a declared clone of an LLVM math intrinsic (no C body): its pointer arguments only
    const MemSummary &S = summaryOf(src);
    for (const GlobalVariable *g : S.globals)
      fp.objs.push_back({g, 0});
    fp.unbounded = S.unbounded;
    return fp;
  }
  // May code outside the caller's frame reach the object p points into: a global, a formal's object,
  // an unknown pointer, or an alloca whose address escapes (stored, converted, or passed to a callee
  // that may capture it).
  static bool reachable(const Value *p) {
    const Value *u = getUnderlyingObject(p);
    auto *AI = dyn_cast<AllocaInst>(u);
    if (!AI)
      return true;
    SmallVector<const Value *, 8> work{AI};
    SmallPtrSet<const Value *, 16> seen{AI};
    while (!work.empty()) {
      const Value *v = work.pop_back_val();
      for (const Use &U : v->uses()) {
        const User *us = U.getUser();
        if (isa<GetElementPtrInst>(us) || isa<BitCastInst>(us) || isa<AddrSpaceCastInst>(us) ||
            isa<SelectInst>(us) || isa<PHINode>(us)) {
          if (seen.insert(us).second)
            work.push_back(us);
          continue;
        }
        if (isa<LoadInst>(us) || isa<ICmpInst>(us) || isa<MemIntrinsic>(us))
          continue;
        if (auto *st = dyn_cast<StoreInst>(us)) {
          if (st->getValueOperand() == v)
            return true;
          continue;
        }
        if (auto *cb = dyn_cast<CallBase>(us)) {
          if (auto *ii = dyn_cast<IntrinsicInst>(cb); ii && (ii->isLifetimeStartOrEnd() || ii->isAssumeLikeIntrinsic()))
            continue;
          if (!cb->isArgOperand(&U))
            return true;
          const Function *cf = cb->getCalledFunction();
          if (cf && isRuntimeName(cf->getName()))
            continue;
          if (cb->doesNotCapture(cb->getArgOperandNo(&U)))
            continue;
          // A clone (or its twin) captures nothing when the C function it recomputes captures no
          // pointer formal.
          if (const Function *src = cf ? cloneSource(*cf) : nullptr; src && !src->isDeclaration() &&
              all_of(src->args(), [](const Argument &a) { return !a.getType()->isPointerTy() || a.hasNoCaptureAttr(); }))
            continue;
          return true;
        }
        return true;   // ptrtoint, ret, an atomic's value, ...
      }
    }
    return false;
  }
  // Does call cb (after a clone call whose twin has footprint fp) possibly write fp's memory?
  bool callMayWrite(const CallBase *cb, const Footprint &fp, const DataLayout &DL) const {
    auto hits = [&](const Value *p) {
      return any_of(fp.objs, [&](const Cell &c) { return mayAlias(c, {p, 0}, DL); }) ||
             (fp.unbounded && reachable(p));
    };
    for (const Value *a : cb->args())
      if (a->getType()->isPointerTy() && hits(a))
        return true;
    const Function *cf = cb->getCalledFunction();
    bool beyondArgs = !cb->onlyAccessesArgMemory();
    const Function *src = cf ? cloneSource(*cf) : nullptr;
    if (!src && cf && !cf->isDeclaration() && !cf->isIntrinsic())
      src = cf;   // a defined classical callee
    if (src && !src->isDeclaration()) {
      // The callee's own summary decides (its pointer arguments are checked above).
      const MemSummary &S = summaryOf(src);
      if (!S.unbounded)
        return any_of(S.globals, [&](const GlobalVariable *g) { return hits(g); });
      beyondArgs = true;
    }
    if (!beyondArgs)
      return false;
    // A callee that may write memory beyond its arguments reaches every object code outside the frame can.
    return fp.unbounded || any_of(fp.objs, [&](const Cell &c) { return reachable(c.ptr); });
  }

  enum class Bar { Hit, Write, AliasHit, PointeeWrite };
  // cq-fwto (orchestrator decision under CR rule 5, NORTHSTAR p2): a clone's twin reads the objects its
  // pointer arguments point to when it runs, so every instruction after the forward call that may write
  // one of them is a barrier of the call's item: a store, an atomic or a memory intrinsic whose address
  // may overlap the object, or a call (other than one uncompute emitted or one that only reads memory)
  // taking a pointer that may (not a runtime gate or template). A clone call counts: a classical store
  // inside it is not visible here.
  template <typename AfterFn>
  void pointeeWrites(CallInst *fwd, AfterFn &&isAfter, SmallVectorImpl<std::pair<Instruction *, Bar>> &out) const {
    const DataLayout &DL = fwd->getModule()->getDataLayout();
    Footprint fp = footprint(fwd);
    if (fp.empty())
      return;
    // cq-99z6: a write into the footprint: an address that may overlap one of its objects, or, for an
    // unbounded footprint, any address reachable from outside the caller's frame.
    auto hits = [&](const Value *p, uint64_t size) {
      return any_of(fp.objs, [&](const Cell &c) { return mayAlias(c, {p, size}, DL); }) ||
             (fp.unbounded && reachable(p));
    };
    for (Instruction &i : instructions(*fwd->getFunction())) {
      if (&i == fwd || emitted.count(&i) || !isAfter(&i))
        continue;
      bool w = false;
      if (auto *st = dyn_cast<StoreInst>(&i))
        w = hits(st->getPointerOperand(), accessSize(st->getValueOperand()->getType(), DL));
      else if (auto *rmw = dyn_cast<AtomicRMWInst>(&i))
        w = hits(rmw->getPointerOperand(), 0);
      else if (auto *cx = dyn_cast<AtomicCmpXchgInst>(&i))
        w = hits(cx->getPointerOperand(), 0);
      else if (auto *mi = dyn_cast<MemIntrinsic>(&i))
        w = hits(mi->getRawDest(), 0);
      else if (auto *cb = dyn_cast<CallBase>(&i)) {
        if (auto *ii = dyn_cast<IntrinsicInst>(cb); ii && (ii->isLifetimeStartOrEnd() || ii->isAssumeLikeIntrinsic()))
          continue;
        if (cb->onlyReadsMemory())
          continue;
        // Runtime gates and templates (a QROM table read included) write no C object.
        if (Function *cf = cb->getCalledFunction(); cf && isRuntimeName(cf->getName()))
          continue;
        w = callMayWrite(cb, fp, DL);
      } else if (i.mayWriteToMemory()) {
        w = true;   // a fence, va_arg, ...
      }
      if (w)
        out.push_back({&i, Bar::PointeeWrite});
    }
  }

  // The barrier events of g's item: (event, kind) that must not precede the item.
  SmallVector<std::pair<Instruction *, Bar>, 4> barriers(RailId g) const {
    SmallVector<std::pair<Instruction *, Bar>, 4> out;
    auto eventsOf = [&](RailId x, auto &&isAfterBase, bool popsFirst = false) {
      const Rail &rx = rails[x];
      for (Instruction *h : rx.hits)
        if (isAfterBase(h))
          out.push_back({h, Bar::Hit});
      for (Instruction *h : rx.aliasHits)
        if (isAfterBase(h))
          out.push_back({h, Bar::AliasHit});
      if (x == g)
        return; // g's own writes are undone by its item
      for (unsigned w : rx.writes)
        if (isAfterBase(records[w].forward) && !(popsFirst && storePopped(w)))
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
      if (info[rec].kind == RecKind::Call || info[rec].kind == RecKind::Template) // a clone call (one result: a template record)
        pointeeWrites(cast<CallInst>(records[rec].forward), afterRec, out);
      // A2: a later store on a load's bus is popped before the load is un-copied (not a barrier),
      // unless the bus keeps its stores.
      bool popsFirst = info[rec].kind == RecKind::QramLoad;
      for (RailId x0 : info[rec].reads)
        for (RailId x : leaves(x0)) // U1: a read of a merge reads one of its arms
          eventsOf(x, afterRec, popsFirst);
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
      for (Instruction *h : r.aliasHits)
        out.push_back({h, Bar::AliasHit});
    }
    // De-duplicate (an event may be reachable through several records).
    SmallVector<std::pair<Instruction *, Bar>, 4> uniq;
    for (auto &e : out)
      if (!is_contained(uniq, e))
        uniq.push_back(e);
    return uniq;
  }

  // ---- kept merges (cq-bv91) --------------------------------------------------------------------

  // A kept role on the phi merge m: each arm is kept itself on the paths where m chooses it, and an
  // arm that also reaches m's join along an edge where m does not choose it is resolved at the end
  // of that edge's block (its "own path"), before the join. The arm then carries the kept role: on
  // every path that reaches a return through the join exactly one arm of m is live (128; the exit
  // phi of a classically bounded loop, 25: the zero-trip seed is freed on the loop path).
  void keepMerge(RailId m, Role role) {
    // The rails m may name (arms, nested merges, transitively) that are resolvable before the role is
    // set: the decisions below read this snapshot, so the order of m's arms changes nothing.
    DenseSet<RailId> live;
    for (RailId x : closure(m))
      if (resolvable(x))
        live.insert(x);
    // A kept role on a classical select (m itself or nested) with a resolvable arm: keeping only the
    // chosen arm needs a branch on the condition (cq-aqeq). Checked before anything is changed.
    for (RailId n : closure(m))
      if (isMerge(n) && !rails[n].cellLoad && !isa<PHINode>(rails[n].handle))
        for (RailId a : leaves(n))
          if (live.count(a))
            unimplemented("uncompute: a kept role on a classical select over handles whose arm " +
                              describe(rails[a].handle) +
                              " is still resolvable (keeping only the chosen arm needs a branch on the condition)",
                          cast<Instruction>(rails[n].handle));
    keepPhi(m, role, live);
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

  // chain: the kept phi merges from the outermost down to m. An arm is followed from its definition
  // to the first join of the chain it enters: an edge into that join whose incoming value may name
  // the arm (through nested merges too, cq-sodl) chooses it; any other edge leaves it unchosen there,
  // and it is resolved at the end of that edge's block.
  void keepPhi(RailId m, Role role, const DenseSet<RailId> &live, SmallVector<RailId, 4> chain = {}) {
    if (rails[m].cellLoad) {
      // M3: a cell load has no join; every arm it may name is kept (nested merges keep theirs).
      for (RailId a : SmallVector<RailId, 2>(rails[m].arms)) {
        if (isMerge(a)) {
          keepPhi(a, role, live, chain);
          rails[a].role = role;
        } else if (live.count(a)) {
          rails[a].role = role;
        }
      }
      return;
    }
    Value *mh = rails[m].handle;
    auto *phi = dyn_cast<PHINode>(mh);
    if (!phi)
      return; // a select whose resolvable arms were refused above: every arm is kept already
    chain.push_back(m);
    for (RailId a : SmallVector<RailId, 2>(rails[m].arms)) {
      Rail &ra = rails[a];
      if (ra.released || !ra.exitsDone.empty())
        internalError("uncompute: setRole: an arm of a merged handle was already uncomputed", ra.handle);
      auto joinOf = [&](const BasicBlock *s) -> RailId {
        for (RailId k : chain)
          if (cast<PHINode>(rails[k].handle)->getParent() == s)
            return k;
        return kNone;
      };
      auto chooses = [&](RailId k, const BasicBlock *from) {
        auto *pk = cast<PHINode>(rails[k].handle);
        Value *in = pk->getIncomingValueForBlock(from);
        return in && is_contained(closure(lookup(in, "setRole", pk)), a);
      };
      const BasicBlock *D = defBlock(a);
      SmallVector<std::pair<BasicBlock *, RailId>, 2> unchosen;
      SmallPtrSet<const BasicBlock *, 16> seen;
      SmallVector<const BasicBlock *, 16> work{D};
      seen.insert(D);
      while (!work.empty()) {
        const BasicBlock *b = work.pop_back_val();
        const Instruction *t = b->getTerminator();
        if (!t || isa<ReturnInst>(t) || isa<UnreachableInst>(t))
          unimplemented("uncompute: an arm of a kept merged handle, " + describe(ra.handle) +
                            ", may reach a return or a block not yet emitted without passing the merge's join",
                        phi);
        for (const BasicBlock *s : successors(t)) {
          if (RailId k = joinOf(s); k != kNone) {
            std::pair<BasicBlock *, RailId> e{const_cast<BasicBlock *>(b), k};
            if (!chooses(k, b) && !is_contained(unchosen, e))
              unchosen.push_back(e);
            continue;
          }
          if (s != D && seen.insert(s).second)
            work.push_back(s);
        }
      }
      if (isMerge(a)) {
        if (!unchosen.empty())
          unimplemented("uncompute: a nested merged arm, " + describe(ra.handle) +
                            ", reaches a kept merge's join along an edge that does not choose it",
                        phi);
        keepPhi(a, role, live, chain);
        ra.role = role;
        continue;
      }
      if (!live.count(a))
        continue;   // already kept before this role: it stays as it is on its paths
      for (auto [P, k] : unchosen)
        if (!itemEnd.count({a, P}))
          resolveOnEdge(a, P, names(k), cast<PHINode>(rails[k].handle), k);
      ra.role = role;
    }
  }

  // cq-sodl: is there a path leaving P (P's own tail included) to B that does not pass D again? A
  // pass through D defines a new instance of a rail defined there.
  static bool reachesAfterEdge(const BasicBlock *P, const BasicBlock *B, const BasicBlock *D) {
    if (B == P)
      return true;
    SmallPtrSet<const BasicBlock *, 16> seen;
    SmallVector<const BasicBlock *, 16> work{P};
    while (!work.empty()) {
      const BasicBlock *b = work.pop_back_val();
      const Instruction *t = b->getTerminator();
      if (!t)
        continue;
      for (const BasicBlock *s : successors(t)) {
        if (s == D)
          continue;
        if (s == B)
          return true;
        if (seen.insert(s).second)
          work.push_back(s);
      }
    }
    return false;
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

  // Does reading r read x other than through the merge m (r == x, or a merge naming x by an arm
  // path that avoids m)?
  bool readsPast(RailId r, RailId x, RailId m) const {
    if (r == m)
      return false;
    if (r == x)
      return true;
    for (RailId a : rails[r].arms)
      if (readsPast(a, x, m))
        return true;
    return false;
  }

  // cq-sodl: a read of r at `at` (null: no position known) after an edge where a rail r may name was
  // freed because the merge did not choose it there. On a path leaving that edge the rail is gone.
  void checkEdgeRead(RailId r, const Instruction *at, const char *who) const {
    for (RailId x : closure(r))
      for (auto [P, m] : rails[x].edgeFrees) {
        if (!readsPast(r, x, m))
          continue;
        if (at && at->getParent() && !reachesAfterEdge(P, at->getParent(), defBlock(x)))
          continue;
        unimplemented(std::string("uncompute: ") + who + ": an arm of a kept merged handle, " +
                          describe(rails[x].handle) +
                          ", is read after the edge where the merge does not choose it and it was freed" +
                          (at ? "" : " (no position: assumed after)"),
                      at ? static_cast<const Value *>(at) : rails[x].handle);
      }
  }

  // At a return: every IR user of an edge-freed arm's handle (beyond the merges, checked at
  // recordMerge, and our own items) lies where the arm still exists on its path.
  //
  // cq-1dgy: nor may a path leaving P come back, without passing x's definition, to P itself (the
  // free runs again on the same instance: double free) or to the incoming block of a merge phi whose
  // incoming value there may name x (a later iteration chooses the freed instance: use after free).
  // The output CFG is complete only once the loops around P are emitted (their back edges are not
  // there yet when the role is set), so this is checked at each return, with checkEdgeUsers.
  void checkEdgeLoops() const {
    for (RailId x = 0; x < rails.size(); ++x)
      for (auto [P, m] : rails[x].edgeFrees) {
        const BasicBlock *D = defBlock(x);
        auto refuse = [&](const BasicBlock *b) {
          unimplemented("uncompute: an arm of a kept merged handle, " + describe(rails[x].handle) +
                            ", freed at the end of an edge where the merge does not choose it, is reached again "
                            "from that edge without being redefined (a loop around the join)",
                        b->getTerminator());
        };
        if (reachesAgain(P, P, {D}))
          refuse(P);
        // A merge n reads x where an operand may name it: a phi at the end of that incoming block, a
        // select at its own block. An operand naming x only through a nested merge r is re-chosen
        // whenever the path passes r's definition, so such a path does not read the freed instance.
        auto check = [&](Value *v, const BasicBlock *at) {
          auto it = byHandle.find(v);
          if (it == byHandle.end() || !is_contained(closure(it->second), x))
            return;
          SmallVector<const BasicBlock *, 2> avoid{D};
          if (it->second != x)
            avoid.push_back(defBlock(it->second));
          if (reachesAgain(P, at, avoid))
            refuse(at);
        };
        for (RailId n : names(x)) {
          if (n == x)
            continue;
          if (auto *phi = dyn_cast<PHINode>(rails[n].handle)) {
            for (unsigned j = 0; j < phi->getNumIncomingValues(); ++j)
              check(phi->getIncomingValue(j), phi->getIncomingBlock(j));
          } else if (auto *sel = dyn_cast<SelectInst>(rails[n].handle)) {
            check(sel->getTrueValue(), sel->getParent());
            check(sel->getFalseValue(), sel->getParent());
          }
        }
      }
  }

  void checkEdgeUsers() const {
    checkEdgeLoops();
    for (RailId x = 0; x < rails.size(); ++x)
      for (auto [P, m] : rails[x].edgeFrees)
        for (User *u : rails[x].handle->users()) {
          auto *i = dyn_cast<Instruction>(u);
          if (!i || !i->getParent() || emitted.count(i) || isMergeHandle(i))
            continue;
          if (i->getParent() == P) {
            auto it = itemEnd.find({x, P});
            if (it == itemEnd.end() || i->comesBefore(it->second))
              continue;
          } else if (!reachesAfterEdge(P, i->getParent(), defBlock(x))) {
            continue;
          }
          unimplemented("uncompute: an arm of a kept merged handle, " + describe(rails[x].handle) +
                            ", is used after the edge where the merge does not choose it and it was freed",
                        i);
        }
  }

  // Resolve the arm a at the end of P, a block whose only successor is the join of the merge phi,
  // which does not choose a from P. After P, a is not read on that path: the merge (and every merge
  // that names a only through it) names another arm there.
  void resolveOnEdge(RailId a, BasicBlock *P, ArrayRef<RailId> mNames, PHINode *phi, RailId m) {
    Rail &ra = rails[a];
    Instruction *T = P->getTerminator();
    if (T->getNumSuccessors() != 1)
      unimplemented("uncompute: an arm of a kept merged handle is unchosen on an edge whose block also branches "
                        "elsewhere: " + describe(ra.handle),
                    T);
    if (!dominates(defBlock(a), P))
      unimplemented("uncompute: an arm of a kept merged handle may or may not exist where its edge leaves: " +
                        describe(ra.handle),
                    T);
    // No direct use of a (nor through another merge) may follow P.
    SmallVector<Instruction *, 8> uses;
    if (ra.creator != kNone)
      uses.push_back(records[ra.creator].forward);
    for (unsigned w : ra.writes)
      uses.push_back(records[w].forward);
    SmallVector<RailId, 4> others;
    for (RailId n : names(a))
      if (!is_contained(mNames, n))
        others.push_back(n);
    for (RailId n : others) {
      for (User *u : rails[n].handle->users()) {
        auto *i = dyn_cast<Instruction>(u);
        if (!i || i == phi)
          continue;
        // A phi reads its incoming value at the end of the incoming block (cq-sodl: an outer merge
        // choosing the arm from another edge).
        if (auto *up = dyn_cast<PHINode>(i)) {
          for (unsigned j = 0; j < up->getNumIncomingValues(); ++j)
            if (up->getIncomingValue(j) == rails[n].handle)
              uses.push_back(up->getIncomingBlock(j)->getTerminator());
          continue;
        }
        uses.push_back(i);
      }
      uses.append(rails[n].uses.begin(), rails[n].uses.end());
    }
    for (Instruction *u : uses)
      if (u->getParent() != P && reaches(P, u->getParent()))
        unimplemented("uncompute: an arm of a kept merged handle, " + describe(ra.handle) +
                          ", is still used after an edge where the merge does not choose it",
                      u);
    // Its readers must already be resolved (or kept): their items would need it on this path.
    for (RailId n : others) {
      SmallVector<RailId, 4> rd;
      for (unsigned rec : rails[n].readerRecs)
        rd.push_back(info[rec].item);
      rd.append(rails[n].cleanupReaders.begin(), rails[n].cleanupReaders.end());
      for (RailId o : rd)
        if (o != a && !rails[o].released && (resolvable(o) || !rails[o].exitsDone.empty() || rails[o].cleanup))
          unimplemented("uncompute: an arm of a kept merged handle, " + describe(ra.handle) +
                            ", is read by a pending rail " + describe(rails[o].handle) +
                            " where the merge does not choose it",
                        T);
    }
    for (auto [e, kind] : barriers(a))
      if (e->getParent() == P || reaches(e->getParent(), P))
        unimplemented("uncompute: a barrier precedes the resolution of an unchosen arm of a kept merged handle, " +
                          describe(ra.handle),
                      e);
    IRBuilder<> B(T);
    Instruction *end = emitItem(a, B);
    itemEnd[{a, P}] = end;
    ra.edgeFrees.push_back({P, m}); // cq-sodl: any later read past m on a path leaving P is caught
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

  // cq-vtfq: the logical size a bus was made with (qram_alloc's n, a realloc's n).
  Value *busSize(RailId b) const {
    const Rail &r = rails[b];
    if (r.creator == kNone)
      unimplemented("uncompute: a qram_realloc of a bus this function did not allocate (its logical size is not "
                    "known here)",
                    r.handle);
    CallInst *f = records[r.creator].forward;
    switch (info[r.creator].kind) {
    case RecKind::QramAlloc:
      return f->getArgOperand(0);
    case RecKind::QramRealloc:
      return f->getArgOperand(1);
    default:
      internalError("uncompute: a qram_realloc operand that is not a bus", f);
    }
  }

  CallInst *emitRelease(RailId g, IRBuilder<> &B) {
    Rail &r = rails[g];
    Module &M = *B.GetInsertBlock()->getModule();
    LLVMContext &C = M.getContext();
    FunctionType *FT = FunctionType::get(Type::getVoidTy(C), {Type::getInt32Ty(C)}, false);
    if (r.creator != kNone && info[r.creator].kind == RecKind::QramRealloc) {
      // CR §1.3: qram_realloc_<W>_unc(a', n_old); a is the bus again afterwards. a' reads a, so a's
      // qram_free follows this item; a's POPs and load un-copies follow it by versionBefore.
      CallInst *fwd = records[r.creator].forward;
      RailId a = info[r.creator].reads.front();
      FunctionType *UT = FunctionType::get(Type::getVoidTy(C), {Type::getInt32Ty(C), Type::getInt32Ty(C)}, false);
      return track(B.CreateCall(declareFn(M, (fwd->getCalledFunction()->getName() + "_unc").str(), UT, fwd),
                                {r.handle, busSize(a)}));
    }
    return track(B.CreateCall(declareFn(M, r.qram ? "cqrt_qram_free" : "cqrt_free", FT, r.handle), {r.handle}));
  }

  Instruction *emitItem(RailId g, IRBuilder<> &B) {
    Rail &r = rails[g];
    {
      // cq-vtfq: an item that names a bus a (its qram_free, a POP, a load un-copy) runs after every
      // realloc result a' of a is undone; a kept a' (never undone) leaves a replaced for good.
      SmallVector<RailId, 2> buses;
      if (r.qram)
        buses.push_back(g);
      if (r.popBus != kNone)
        buses.push_back(r.popBus);
      for (auto [b, k] : r.versions)
        buses.push_back(b);
      for (RailId b : buses)
        for (RailId a2 : rails[b].reallocs)
          if (rails[a2].cleanup || (rails[a2].role != Role::Seed && rails[a2].role != Role::Garbage))
            unimplemented("uncompute: an item on a QRAM bus whose qram_realloc result is kept (the old bus is "
                          "never restored)",
                          rails[a2].handle);
    }
    if (r.group != kNone && r.creator != kNone && info[r.creator].kind == RecKind::Call) {
      // U2: twin(outs..., fwd args..., extra...), then free every out and slotOut in order.
      const CallGroup &cg = groups[r.group];
      CallInst *fwd = cg.fwd;
      Module &M = *B.GetInsertBlock()->getModule();
      LLVMContext &C = M.getContext();
      SmallVector<Type *, 8> ps;
      SmallVector<Value *, 8> args;
      for (RailId o : cg.outs) {
        ps.push_back(Type::getInt32Ty(C));
        args.push_back(rails[o].handle);
      }
      for (Value *a : fwd->args()) {
        ps.push_back(a->getType());
        args.push_back(a);
      }
      for (Value *e : cg.extra) {
        ps.push_back(e->getType());
        args.push_back(e);
      }
      FunctionType *TT = FunctionType::get(Type::getVoidTy(C), ps, false);
      track(B.CreateCall(declareFn(M, (fwd->getCalledFunction()->getName() + "_unc").str(), TT, fwd), args));
      FunctionType *FT = FunctionType::get(Type::getVoidTy(C), {Type::getInt32Ty(C)}, false);
      Instruction *last = nullptr;
      for (RailId o : cg.members)
        last = o == g ? emitRelease(g, B) : track(B.CreateCall(declareFn(M, "cqrt_free", FT, rails[o].handle),
                                                               {rails[o].handle}));
      return last;
    }
    if (r.popBus != kNone) {
      // A2: POP(k) is the store's _unc alone; the bus's own item frees it.
      CallInst *fwd = records[r.creator].forward;
      return track(B.CreateCall(uncOf(fwd, false), argsOf(fwd, nullptr)));
    }
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
          info[r.creator].kind != RecKind::QramAlloc && info[r.creator].kind != RecKind::QramRealloc)
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
          internalError("uncompute: a QRAM store is undone by its own POP item", fwd);
        case RecKind::Call:
          internalError("uncompute: a call group's record outside its leader's item", fwd);
        case RecKind::Seed:
        case RecKind::QramAlloc:
        case RecKind::QramRealloc:
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
    if (!resolvable(g))
      return; // kept by a POP placed earlier in this batch (keepBelow)
    if (r.deferred != kNone)
      return placeDeferred(g, c);
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
    placeAt(g, pos, local);
  }

  // Emits g's item at pos after rule 5's barrier check (local: resolved for good).
  void placeAt(RailId g, Pos pos, bool local) {
    Rail &r = rails[g];
    // Rule 5's invariant.
    bool kept = false;
    for (auto [e, kind] : barriers(g)) {
      bool violated;
      if (e->getParent() == pos.bb)
        violated = !(pos.before == e || pos.before->comesBefore(e));
      else if (reaches(e->getParent(), pos.bb))
        unimplemented("uncompute: a barrier in another block lies between a rail and its uncompute", e);
      else
        violated = false;
      if (!violated)
        continue;
      if (kind == Bar::PointeeWrite)
        unimplemented("uncompute: a write that may change an object a clone call's pointer argument points to lies "
                      "between the call and its twin's earliest placement, " + describe(r.handle) +
                          " (cq-fwto: the twin reads the object when it runs)",
                      e);
      if (kind == Bar::Write)
        unimplemented("uncompute: an in-place write on an operand rail precedes the earliest uncompute of " +
                          describe(r.handle),
                      e);
      // cq-zh7z: the gate's handle may name an operand rail through memory (a store or load of a
      // cell that may hold it). Rule 5 needs the _unc before the gate when it is that rail, and CR §0 needs
      // it cleaned when it is not; which one holds is only known at run time.
      if (kind == Bar::AliasHit)
        unimplemented("uncompute: a non-diagonal gate on a handle that may name an operand rail of " +
                          describe(r.handle) +
                          " through a slot cell precedes its earliest uncompute (whether it hits that rail is "
                          "decided at run time)",
                      e);
      kept = true;
    }
    if (kept) {
      r.role = Role::KeptEntangled;
      r.cleanup.reset();
      if (r.popBus != kNone)
        keepBelow(g);
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

  // flushBefore(P) may place the item only where every use of its exit rails after the loop lies in
  // P's block before P (and there is at least one: before the exit values' readers are lowered there
  // is none). Uses still to be lowered are the caller's contract, as for any rail flushBefore resolves.
  bool deferredLocalReady(RailId g, Instruction *point) const {
    const Deferred &d = defs[rails[g].deferred];
    SmallVector<Instruction *, 8> as = deferredAnchors(d);
    if (as.empty())
      return false;
    for (Instruction *a : as)
      if (a->getParent() != point->getParent() || !a->comesBefore(point))
        return false;
    // Never inside another region whose own records are still pending (a later rule-14 loop's trip, its
    // back edges cut while it flushes per trip, or a cq_invert region): the item would run per trip.
    const BasicBlock *P = point->getParent();
    for (const Scope &sc : scopes) {
      if (sc.open)
        return false;
      for (unsigned rec = sc.begin; rec < sc.end; ++rec) {
        RailId it = info[rec].item;
        if (it == kNone || rails[it].ownedBy == rails[g].deferred || !resolvable(it))
          continue;
        if (reaches(records[rec].forward->getParent(), P))
          return false;
      }
    }
    return true;
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
    Rail &r = rails[g];
    Deferred &d = defs[r.deferred];
    SmallVector<Instruction *, 12> as = deferredAnchors(d);
    for (RailId o : readersOf(g))
      for (auto &kv : itemEnd)
        if (kv.first.first == o)
          as.push_back(kv.second);
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
      internalError("uncompute: a deferred item inside a mirror", r.handle);
    }
    if (!pos.before)
      internalError("uncompute: no insertion point for a deferred item", r.handle);
    // Rule 5: every rail the item reads (and every exit rail) must still hold the value its records
    // read. A non-diagonal gate or an in-place write after the loop that the placement does not
    // precede would be undone against the changed rail.
    SmallVector<RailId, 8> xs;
    for (RailId x0 : d.reads)
      for (RailId x : leaves(x0))
        if (!is_contained(xs, x))
          xs.push_back(x);
    for (RailId x : d.exits)
      if (!is_contained(xs, x))
        xs.push_back(x);
    Instruction *barrier = nullptr;
    RailId barrierRail = kNone;
    for (RailId x : xs) {
      SmallVector<Instruction *, 8> evs(rails[x].hits.begin(), rails[x].hits.end());
      evs.append(rails[x].aliasHits.begin(), rails[x].aliasHits.end());
      for (unsigned w : rails[x].writes)
        if (rails[x].ownedBy == kNone)
          evs.push_back(records[w].forward);
      for (Instruction *e : evs) {
        if (!e->getParent() || !afterRegion(d, e->getParent()))
          continue;
        bool violated = e->getParent() == pos.bb ? !(pos.before == e || pos.before->comesBefore(e))
                                                 : reaches(e->getParent(), pos.bb);
        if (violated && !barrier) {
          barrier = e;
          barrierRail = x;
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
              if (X && X != s)
                unimplemented("uncompute: a deferred rule-14 reverse loop whose loop has more than one exit block",
                              dyn_cast<Instruction>(at));
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
    if (barrier) {
      for (RailId x : d.exits)
        if (!keptRole(rails[x].role))
          unimplemented("uncompute: a non-diagonal gate or an in-place write on a rail the deferred rule-14 reverse "
                            "loop reads (" + describe(rails[barrierRail].handle) +
                            ") precedes its earliest placement, and an exit rail it frees (" +
                            describe(rails[x].handle) + ") is not kept, so it cannot run where the loop exits",
                        barrier);
      BasicBlock *X = exitBlock(rails[g].handle);
      BasicBlock *S = X->getSingleSuccessor();
      if (!S || beforeOrIn(d, S))
        internalError("uncompute: the loop's exit block of a deferred item does not continue in one block",
                      X->getTerminator());
      pos = {S, &*S->getFirstInsertionPt()};
    }
    // An exit rail that became kept (measured, escaped, a kept merge's arm) is kept by a copy taken
    // here, and the reverse loop undoes the rail itself (every trip's instance is undone alike).
    SmallVector<std::pair<RailId, Role>, 2> keptExits;
    for (RailId x : d.exits) {
      Rail &rx = rails[x];
      if (!keptRole(rx.role))
        continue;
      if (!rx.hits.empty() || !rx.aliasHits.empty() || rx.creator == kNone || rx.cleanup)
        unimplemented("uncompute: a kept exit rail of a deferred rule-14 reverse loop that was rotated or has no "
                          "producer: " + describe(rx.handle),
                      cast<Instruction>(rx.handle));
      // Rule 5 (a kept rail is never uncomputed), rule 14 case 1: an exit rail that reaches later code
      // only through memory (no IR use outside the region; its readers are cell-load merges, M3) stays
      // with its kept role on every trip: no copy, the mirror leaves every instance alone (179).
      bool outsideUse = any_of(rx.handle->uses(), [&](const Use &u) {
        auto *ui = dyn_cast<Instruction>(u.getUser());
        return ui && ui->getParent() && !beforeOrIn(d, ui->getParent());
      });
      if (!outsideUse)
        continue;
      keptExits.push_back({x, rx.role});
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
      RailType w = createdType(records[rails[x].creator]);
      Value *xh = rails[x].handle;
      SmallVector<Use *, 8> outside;
      for (Use &u : xh->uses())
        if (auto *ui = dyn_cast<Instruction>(u.getUser()); ui && ui->getParent() && !beforeOrIn(d, ui->getParent()))
          outside.push_back(&u);
      IRBuilder<> BXc(X->getTerminator());
      CallInst *f = track(BXc.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Alloc, w}),
                                         {Constant::getNullValue(irTypeOf(C, w))}));
      track(BXc.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Copy, w}), {xh, f}));
      for (Use *u : outside)
        u->set(f);
      RailId fid = newRail(f, role, "recordDeferred"); // may move rails: indices only from here
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
    d.emit(B);
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
    itemEnd[{g, br->getParent()}] = br;
    d.placedAt = P;
  }

  // At a return R: a deferred item already placed must lie on every path from its loop to R.
  void checkDeferredPaths(BasicBlock *Rb) const {
    for (const Deferred &d : defs) {
      if (!d.placedAt)
        continue;
      for (const BasicBlock *rb : d.region)
        if (reachesAgain(rb, Rb, {d.placedAt}) || rb == Rb)
          unimplemented("uncompute: a return is reached from a classically bounded loop by a path that avoids its "
                            "deferred reverse loop (the loop's exit values are read on another path only)",
                        Rb->getTerminator());
    }
  }

  // ---- a computed rail measured on some paths only (cq-8lf8) ---------------------------------------
  //
  // CR rule 2 keeps a measured rail allocated; a role is per rail, so Role::Measured also kept the rail
  // on the paths that never reach its measurement, where it is garbage (r8: y = 3x + 1 measured on an
  // early return, the loop path left y live). On those paths the rail is resolved like any garbage, at
  // the end of the unmeasured region: in each block P that no measurement of it reaches but from which
  // the program leaves that region (a return, or the single edge into a block a measurement reaches),
  // right after the last use in P. An edge into a block from which a measurement is still reachable is
  // no such exit: the rail stays kept on that path (cq-zpe8: freed there, a later measurement after the
  // join read a freed rail). Its sources may be gone by then (they were freed as soon as the
  // rail looked kept), so the item recomputes the rail into a fresh t from kept rails (replaying the
  // records of every resolvable source too), copies t into the rail (|0>, rule 6's clean-up shape),
  // undoes the recomputation in reverse and frees (Bennett's compute-copy-uncompute, local to P).
  // Unimplemented: a measured rail defined in a loop (one that reaches its measurement, or one whose
  // unmeasured paths reach a P: only the loop's construction knows its old instances), a P that also branches
  // elsewhere, a use or a pending reader after P, a barrier on a kept rail the item reads between its
  // record and the item, a source that is a merge, a QRAM rail, a loop's deferred rail or written in
  // place after the record that read it.
  DenseSet<std::pair<RailId, const BasicBlock *>> unmeasuredDone;

  static bool isMeasureOf(const User *u, const Value *h) {
    auto *c = dyn_cast<CallInst>(u);
    return c && c->getCalledFunction() && c->getCalledFunction()->getName().starts_with("cqrt_measure_") &&
           c->arg_size() && c->getArgOperand(0) == h;
  }

  void resolveUnmeasured(BasicBlock *Rb) {
    for (RailId g = 0; g < rails.size(); ++g) {
      Rail &r = rails[g];
      if (r.role != Role::Measured || r.released || isMerge(g) || r.creator == kNone || r.cleanup || r.qram ||
          r.popBus != kNone || info[r.creator].kind != RecKind::Template || !r.hits.empty() || !r.aliasHits.empty())
        continue;
      SmallPtrSet<const BasicBlock *, 4> mb;
      for (User *u : r.handle->users())
        if (isMeasureOf(u, r.handle) && cast<Instruction>(u)->getParent())
          mb.insert(cast<Instruction>(u)->getParent());
      const BasicBlock *D = defBlock(g);
      if (mb.empty() || mb.count(D) || !reaches(D, Rb))
        continue;
      Instruction *at = records[r.creator].forward;
      // Decided once every block reachable from the definition is emitted: a later return's flush
      // sees them (a function's last return is lowered after the blocks that reach it).
      {
        bool open = false;
        SmallPtrSet<const BasicBlock *, 16> seen{D};
        SmallVector<const BasicBlock *, 16> w{D};
        while (!w.empty() && !open) {
          const Instruction *t = w.pop_back_val()->getTerminator();
          if (!t) {
            open = true;
            break;
          }
          for (const BasicBlock *s : successors(t))
            if (seen.insert(s).second)
              w.push_back(s);
        }
        if (open)
          continue;
      }
      // Blocks a measurement reaches, and the blocks reached from D without passing one.
      SmallPtrSet<const BasicBlock *, 16> mreach(mb.begin(), mb.end());
      SmallVector<const BasicBlock *, 16> work(mb.begin(), mb.end());
      auto succs = [&](const BasicBlock *b) {
        const Instruction *t = b->getTerminator();
        if (!t)
          unimplemented("uncompute: a rail measured on some paths only, " + describe(r.handle) +
                            ", reaches a block not yet emitted",
                        at);
        return successors(b);
      };
      while (!work.empty())
        for (const BasicBlock *s : succs(work.pop_back_val()))
          if (mreach.insert(s).second)
            work.push_back(s);
      if (mreach.count(D))
        unimplemented("uncompute: a rail measured on some paths only, " + describe(r.handle) +
                          ", is defined in a loop that reaches its measurement",
                      at);
      SmallPtrSet<const BasicBlock *, 16> un{D};
      work.assign({D});
      SmallVector<BasicBlock *, 4> ps;
      bool cyclic = false;
      while (!work.empty()) {
        const BasicBlock *b = work.pop_back_val();
        if (mreach.count(b))
          continue;
        const Instruction *t = b->getTerminator();
        bool exits = isa<ReturnInst>(t);
        for (const BasicBlock *s : succs(b)) {
          if (s == D) {
            cyclic = true;   // a new instance: the loop's construction owns the old one
            continue;
          }
          if (mb.count(s))
            continue;   // the edge into a measurement: measured on that path
          if (mreach.count(s)) {
            // cq-zpe8: a measurement still reachable after the join reads the rail on this path too, so
            // it stays kept here (a clean-up would free it before that measurement).
            if (llvm::none_of(mb, [&](const BasicBlock *m) { return reaches(s, m); }))
              exits = true;
          } else if (un.insert(s).second)
            work.push_back(s);
        }
        if (exits)
          ps.push_back(const_cast<BasicBlock *>(b));
      }
      if (cyclic && !ps.empty())
        unimplemented("uncompute: a rail measured on some paths only, " + describe(r.handle) +
                          ", is defined in a loop and leaves its unmeasured paths in " + describe(ps.front()),
                      at);
      // cq-50qq: a return reached both from a measurement and from D on a path that never measures
      // the rail (it crossed a join from which a later measurement was still reachable, then left
      // without it). On those paths the rail is garbage there; the branches that decide it are
      // classical (a measurement in a quantum arm runs on every path, rule 2), so the item runs under
      // a classical flag "measured on this path" (false after D, true after each measurement block),
      // branched around on the measured paths, where the rail stays kept.
      SmallPtrSet<const BasicBlock *, 16> psSet(ps.begin(), ps.end());
      SmallVector<BasicBlock *, 4> mixed;
      {
        SmallPtrSet<const BasicBlock *, 16> seen{D};
        SmallVector<const BasicBlock *, 16> w{D};
        while (!w.empty()) {
          const BasicBlock *b = w.pop_back_val();
          if (psSet.count(b))
            continue;   // resolved on its own exit edge
          if (mreach.count(b) && isa<ReturnInst>(b->getTerminator()))
            mixed.push_back(const_cast<BasicBlock *>(b));
          for (const BasicBlock *s : succs(b))
            if (s != D && !mb.count(s) && seen.insert(s).second)
              w.push_back(s);
        }
      }
      if (cyclic && !mixed.empty())
        unimplemented("uncompute: a rail measured on some paths only, " + describe(r.handle) +
                          ", is defined in a loop and reaches a return unmeasured in " + describe(mixed.front()),
                      at);
      for (BasicBlock *P : ps)
        if (unmeasuredDone.insert({g, P}).second)
          resolveUnmeasuredAt(g, P);
      for (BasicBlock *R : mixed)
        if (unmeasuredDone.insert({g, R}).second) {
          // Built by hand: the construction fills its phis' incoming values later, and SSAUpdater
          // would read an empty phi as a block without predecessors.
          LLVMContext &C = R->getContext();
          DenseMap<const BasicBlock *, Value *> atEnd;
          std::function<Value *(const BasicBlock *)> flagAt = [&](const BasicBlock *b) -> Value * {
            if (auto it = atEnd.find(b); it != atEnd.end())
              return it->second;
            if (mb.count(b) || psSet.count(b))   // measured here, or cleaned on its exit edge already
              return atEnd[b] = ConstantInt::getTrue(C);
            if (b == D)
              return atEnd[b] = ConstantInt::getFalse(C);
            if (!dominates(D, b))
              return atEnd[b] = PoisonValue::get(Type::getInt1Ty(C));   // never on a path from D
            SmallVector<BasicBlock *, 4> pr(predecessors(const_cast<BasicBlock *>(b)));
            if (pr.size() == 1) {
              atEnd[b] = PoisonValue::get(Type::getInt1Ty(C));   // a single-predecessor cycle is unreachable
              Value *v = flagAt(pr.front());
              return atEnd[b] = v;
            }
            BasicBlock *bb = const_cast<BasicBlock *>(b);
            PHINode *phi = PHINode::Create(Type::getInt1Ty(C), pr.size(), "", bb->begin());
            emitted.insert(phi);
            atEnd[b] = phi;
            for (BasicBlock *p : pr)
              phi->addIncoming(flagAt(p), p);
            return phi;
          };
          resolveUnmeasuredAt(g, R, flagAt(R));
        }
    }
  }

  // measured: null, or a classical i1 that holds on the paths reaching P where the rail was measured;
  // the item then runs in a block of its own that those paths branch around.
  void resolveUnmeasuredAt(RailId g, BasicBlock *P, Value *measured = nullptr) {
    Rail &r = rails[g];
    Instruction *T = P->getTerminator();
    auto refuse = [&](const std::string &why, const Value *v) {
      unimplemented("uncompute: a rail measured on some paths only, " + describe(r.handle) + ", " + why, v);
    };
    if (!isa<ReturnInst>(T) && T->getNumSuccessors() != 1)
      refuse("leaves its unmeasured paths by a block that also branches elsewhere", T);
    if (!dominates(defBlock(g), P))
      refuse("may or may not exist where its unmeasured path leaves", T);
    // Its uses (through merges too) and the items of its readers must precede the item, in P.
    SmallVector<Instruction *, 8> as = anchors(g);
    for (RailId o : readersOf(g)) {
      if (resolvable(o) || !rails[o].exitsDone.empty())
        refuse("is read by a pending rail " + describe(rails[o].handle) + " on a path where it is not measured", T);
      for (auto &kv : itemEnd)
        if (kv.first.first == o)
          as.push_back(kv.second);
    }
    SmallVector<Instruction *, 8> inP;
    for (Instruction *a : as) {
      if (!a->getParent() || isMeasureOf(a, r.handle))
        continue;
      if (a->getParent() == P) {
        if (a->isTerminator())
          refuse("is read by the terminator of the block where its unmeasured path leaves", a);
        inP.push_back(a);
      } else if (reaches(P, a->getParent())) {
        refuse("is still used after the block where its unmeasured path leaves", a);
      }
    }
    Pos pos = afterLatest(P, inP, g);
    Instruction *prevAt = pos.before->getPrevNode();
    // Values at the item: kept rails as they are (no barrier since the record that read them), every
    // other source recomputed by replaying its records.
    DenseMap<Value *, Value *> vmap;
    SmallVector<RailId, 4> replayed;
    std::function<Value *(RailId, Instruction *)> valueOf;
    IRBuilder<> B(pos.before);
    auto inBetween = [&](Instruction *e, Instruction *rec) {
      if (e == rec || !after(e, rec))
        return false;
      if (e->getParent() == P)
        return e->comesBefore(pos.before);
      return reaches(e->getParent(), P);
    };
    auto remapped = [&](CallInst *fwd, Value *outFirst) {
      SmallVector<Value *, 6> a = argsOf(fwd, outFirst);
      for (unsigned i = outFirst ? 1 : 0; i < a.size(); ++i)
        if (auto it = vmap.find(a[i]); it != vmap.end())
          a[i] = it->second;
      return a;
    };
    valueOf = [&](RailId x, Instruction *rec) -> Value * {
      Rail &rx = rails[x];
      if (auto it = vmap.find(rx.handle); it != vmap.end())
        return it->second;
      // A source's records define the value g's record read however the source itself is cleaned (its
      // own item or a rule 6 clean-up), so a replay recomputes it either way.
      if (isMerge(x) || rx.qram || rx.popBus != kNone || rx.deferred != kNone || rx.ownedBy != kNone)
        refuse("reads " + describe(rx.handle) + ", which cannot be recomputed where it is resolved", T);
      if (x != g && keptRole(rx.role) && !rx.released && rx.exitsDone.empty()) {
        for (Instruction *e : rx.hits)
          if (inBetween(e, rec))
            refuse("reads " + describe(rx.handle) + ", which a non-diagonal gate hits before it is resolved", e);
        for (Instruction *e : rx.aliasHits)
          if (inBetween(e, rec))
            refuse("reads " + describe(rx.handle) + ", which a gate may hit through memory before it is resolved", e);
        for (unsigned w : rx.writes)
          if (inBetween(records[w].forward, rec))
            refuse("reads " + describe(rx.handle) + ", which is written in place before it is resolved",
                   records[w].forward);
        if (auto *hi = dyn_cast<Instruction>(rx.handle); hi && !dominates(hi->getParent(), P))
          refuse("reads " + describe(rx.handle) + ", which may not exist where it is resolved", T);
        return rx.handle;
      }
      // A resolvable source: replay its records (none after rec: the value rec read).
      if (rx.creator == kNone || !rx.hits.empty() || !rx.aliasHits.empty())
        refuse("reads " + describe(rx.handle) + ", which cannot be recomputed where it is resolved", T);
      SmallVector<unsigned, 4> recs{rx.creator};
      for (unsigned w : rx.writes) {
        if (info[w].kind != RecKind::Involution || (rec && after(records[w].forward, rec)))
          refuse("reads " + describe(rx.handle) + ", which is written in place", records[w].forward);
        recs.push_back(w);
      }
      Value *nh = nullptr;
      for (unsigned k : recs) {
        CallInst *fwd = records[k].forward;
        if (!dominates(fwd->getParent(), P))
          refuse("reads " + describe(rx.handle) + ", whose record may not run on its unmeasured path", fwd);
        for (RailId y : info[k].reads)
          valueOf(y, fwd);
        if (k == rx.creator) {
          if (info[k].kind != RecKind::Template && info[k].kind != RecKind::Seed)
            refuse("reads " + describe(rx.handle) + ", which cannot be recomputed where it is resolved", fwd);
          nh = track(B.CreateCall(fwd->getFunctionType(), fwd->getCalledOperand(), remapped(fwd, nullptr)));
          vmap[rx.handle] = nh;
        } else {
          track(B.CreateCall(fwd->getFunctionType(), fwd->getCalledOperand(), remapped(fwd, nullptr)));
        }
      }
      replayed.push_back(x);
      return nh;
    };
    // The rail itself: recompute its value into a fresh t, copy t into it (it becomes |0>, rule 6's
    // clean-up shape), then undo every recomputation in reverse and free.
    Value *t = valueOf(g, nullptr);
    abi::CoreSpec cp{abi::Core::Copy, createdType(records[r.creator])};
    track(B.CreateCall(abi::declare(*P->getModule(), cp), {t, r.handle}));
    auto undo = [&](unsigned k, Value *out) {
      CallInst *fwd = records[k].forward;
      switch (info[k].kind) {
      case RecKind::Template:
        track(B.CreateCall(uncOf(fwd, true), remapped(fwd, out)));
        break;
      case RecKind::Involution:
        track(B.CreateCall(fwd->getFunctionType(), fwd->getCalledOperand(), remapped(fwd, nullptr)));
        break;
      case RecKind::Seed:
        break;
      default:
        refuse("has a record that cannot be undone where it is resolved", fwd);
      }
    };
    LLVMContext &C = P->getContext();
    FunctionType *FT = FunctionType::get(Type::getVoidTy(C), {Type::getInt32Ty(C)}, false);
    for (auto it = replayed.rbegin(); it != replayed.rend(); ++it) {
      Rail &rx = rails[*it];
      Value *nh = vmap[rx.handle];
      for (auto w = rx.writes.rbegin(); w != rx.writes.rend(); ++w)
        undo(*w, nullptr);
      undo(rx.creator, nh);
      track(B.CreateCall(declareFn(*P->getModule(), "cqrt_free", FT, nh), {nh}));
    }
    emitRelease(g, B);
    if (!measured)
      return;
    // P's head (phis included) and its predecessors move to a fresh block H, the item to a block I of
    // its own; H branches to P on the measured paths and through I otherwise.
    Instruction *first = prevAt ? prevAt->getNextNode() : &P->front();
    Function *F = P->getParent();
    BasicBlock *H = BasicBlock::Create(C, "", F, P);
    BasicBlock *It = BasicBlock::Create(C, "", F, P);
    H->splice(H->end(), P, P->begin(), first->getIterator());
    It->splice(It->end(), P, first->getIterator(), pos.before->getIterator());
    for (BasicBlock *pr : SmallVector<BasicBlock *, 4>(predecessors(P)))
      pr->getTerminator()->replaceSuccessorWith(P, H);
    emitted.insert(BranchInst::Create(P, It, measured, H));
    emitted.insert(BranchInst::Create(P, It));
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
  unsigned rec = impl->addRecord(fwd, spec, ops, out, RecKind::Template, false);
  impl->takeCallReads(fwd, rec);
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
    if (ops.empty() || !ops[0].handle)
      internalError("uncompute: recordCore: a QRAM load's first operand is its bus", fwd);
    // A2: the load reads v_k, k = the stores made so far on each bus its operand may name.
    for (RailId b : impl->leaves(impl->lookup(ops[0].v, "recordCore", fwd))) {
      impl->rails[r].versions.push_back({b, static_cast<unsigned>(impl->rails[b].pops.size())});
      impl->rails[b].loads.push_back(r);
    }
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
  case Core::QramStore: {
    unsigned rec = impl->addRecord(fwd, spec, ops, target(c), RecKind::QramStore, false);
    // A2: the store is undone by its own item POP(k), a pseudo rail outside byHandle.
    RailId p = impl->rails.size();
    impl->rails.emplace_back();
    Impl::Rail &pr = impl->rails.back();
    pr.handle = fwd;
    pr.creator = rec;
    pr.popBus = out;
    pr.popK = impl->rails[out].pops.size() + 1;
    impl->rails[out].pops.push_back(p);
    impl->info[rec].item = p;
    return out;
  }
  case Core::QramRealloc: {
    // cq-vtfq, CR §1.3: a' = qram_realloc_<W>(a, n) is a bus of its own (stores and loads through it
    // record on it) whose release is qram_realloc_<W>_unc(a', n_old), after every POP and load un-copy
    // on a'; it reads a, so a's own item (cqrt_qram_free) follows it, and so does every POP of a store
    // and every un-copy of a load made through a (versionBefore). n is classical (a quantum size is
    // resized at its upper bound by the caller).
    if (ops.size() != 2 || !ops[0].handle || ops[1].handle)
      internalError("uncompute: recordCore: qram_realloc takes (bus, classical n)", fwd);
    RailId a = impl->lookup(ops[0].v, "recordCore", fwd);
    if (impl->isMerge(a))
      unimplemented("uncompute: a qram_realloc of a merged bus handle", fwd);
    if (!impl->rails[a].qram)
      internalError("uncompute: recordCore: qram_realloc of a rail that is not a QRAM bus", fwd);
    impl->busSize(a); // known here, or unimplemented now rather than at the release
    RailId r = impl->newRail(fwd, Role::Seed, "recordCore");
    impl->rails[r].qram = true;
    impl->addRecord(fwd, spec, ops, r, RecKind::QramRealloc, false);
    impl->rails[a].reallocs.push_back(r);
    return r;
  }
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
    // cq-sodl: a phi arm is read at the end of its incoming block, a select arm at the select.
    const Instruction *at = merged;
    if (auto *phi = dyn_cast<PHINode>(merged))
      for (unsigned i = 0; i < phi->getNumIncomingValues(); ++i)
        if (phi->getIncomingValue(i) == v)
          I.checkEdgeRead(a, phi->getIncomingBlock(i)->getTerminator(), "recordMerge");
    if (!isa<PHINode>(merged))
      I.checkEdgeRead(a, at, "recordMerge");
    if (!is_contained(arms, a))
      arms.push_back(a);
  }
  RailId m = I.newRail(merged, Role::Garbage, "recordMerge");
  I.rails[m].arms = arms;
  for (RailId a : arms)
    I.rails[a].mergedInto.push_back(m);
  return m;
}

RailId Uncompute::recordCellLoad(Instruction *load, ArrayRef<RailId> mayName) {
  Impl &I = *impl;
  if (!load || !load->getParent())
    internalError("uncompute: recordCellLoad needs an instruction in a block");
  if (mayName.empty())
    internalError("uncompute: recordCellLoad: a cell load that may name no rail", load);
  SmallVector<RailId, 2> arms;
  for (RailId a : mayName) {
    I.rail(a, "recordCellLoad");
    if (I.anyReleased(a))
      internalError("uncompute: recordCellLoad: arm " + describe(I.rails[a].handle) +
                        " was already uncomputed and freed",
                    load);
    I.checkEdgeRead(a, load, "recordCellLoad");
    if (!is_contained(arms, a))
      arms.push_back(a);
  }
  RailId m = I.newRail(load, Role::Garbage, "recordCellLoad");
  I.rails[m].arms = arms;
  I.rails[m].cellLoad = true;
  for (RailId a : arms)
    I.rails[a].mergedInto.push_back(m);
  return m;
}

SmallVector<RailId, 4> Uncompute::recordCall(CallInst *fwd, ArrayRef<Value *> outs, ArrayRef<Value *> slotOuts,
                                             ArrayRef<Operand> extra) {
  Impl &I = *impl;
  if (!fwd || !fwd->getCalledFunction() || !fwd->getParent())
    internalError("uncompute: recordCall: the forward must be a direct call in a block", fwd);
  if (outs.empty() && slotOuts.empty())
    internalError("uncompute: recordCall: a call with no result rail", fwd);
  SmallVector<Operand, 8> ops;
  for (Value *a : fwd->args()) {
    bool h = I.byHandle.count(a) > 0;
    ops.push_back(Operand{a, h});
  }
  I.checkOps(fwd, ops, "recordCall");
  unsigned gi = I.groups.size();
  I.groups.push_back({fwd, {}, {}, {}, {}});
  for (const Operand &e : extra) {
    if (e.handle) {
      RailId r = I.lookup(e.v, "recordCall", fwd);
      if (I.anyReleased(r))
        internalError("uncompute: recordCall: extra operand " + describe(e.v) + " was already freed", fwd);
    }
    ops.push_back(e);
    I.groups[gi].extra.push_back(e.v);
  }
  SmallVector<Value *, 8> all(outs.begin(), outs.end());
  all.append(slotOuts.begin(), slotOuts.end());
  for (Value *h : all)
    if (auto *ins = dyn_cast<Instruction>(h); !ins || !ins->getParent())
      internalError("uncompute: recordCall: a result handle that is not an instruction in a block", fwd);
  RailId lead = I.newRail(all.front(), Role::Garbage, "recordCall");
  I.rails[lead].group = gi;
  unsigned rec = I.addRecord(fwd, abi::TemplateSpec{}, ops, lead, RecKind::Call, false);
  I.takeCallReads(fwd, rec);
  // cq-aqk1: the twin restores each caller cell the clone wrote (slotOuts) and reads the cell's handle
  // through the formal that wrote it (finalize); a read of the same cell by another route (a second
  // pointer argument that may alias it, a global, memory reached through a loaded pointer) would see
  // the forward's handle instead of the old content. Unimplemented.
  {
    const DataLayout &DL = fwd->getModule()->getDataLayout();
    Impl::Footprint fp = I.footprint(fwd);
    for (Value *h : slotOuts) {
      auto *L = dyn_cast<LoadInst>(h);
      if (!L)
        internalError("uncompute: recordCall: a slot out that is not a load of the caller's cell", fwd);
      Impl::Cell cell{L->getPointerOperand(), Impl::accessSize(L->getType(), DL)};
      unsigned routes = 0;
      for (const Impl::Cell &o : fp.objs)
        routes += Impl::mayAlias(o, cell, DL);
      routes += fp.unbounded && Impl::reachable(cell.ptr);
      if (routes > 1)
        unimplemented("uncompute: a clone call whose twin may read a caller cell the clone writes by another "
                      "route than the writing pointer (aliasing pointer arguments, a global, or memory reached "
                      "through a loaded pointer: cq-aqk1)",
                      fwd);
    }
  }
  SmallVector<RailId, 4> ids{lead};
  for (size_t k = 1; k < all.size(); ++k) {
    RailId m = I.newRail(all[k], Role::Garbage, "recordCall");
    I.rails[m].arms = {lead};
    I.rails[m].cellLoad = true;
    I.rails[m].group = gi;
    I.rails[lead].mergedInto.push_back(m);
    ids.push_back(m);
  }
  Impl::CallGroup &cg = I.groups[gi];
  cg.members.assign(ids.begin(), ids.end());
  cg.outs.assign(ids.begin(), ids.begin() + outs.size());
  cg.slotOuts.assign(ids.begin() + outs.size(), ids.end());
  return ids;
}

void Uncompute::noteCallReads(CallInst *fwd, ArrayRef<RailId> reads) {
  Impl &I = *impl;
  if (!fwd || !fwd->getParent())
    internalError("uncompute: noteCallReads needs a call in a block", fwd);
  for (RailId r : reads) {
    I.rail(r, "noteCallReads");
    if (I.anyReleased(r))
      internalError("uncompute: noteCallReads: " + describe(I.rails[r].handle) + " was already uncomputed and freed",
                    fwd);
    I.checkEdgeRead(r, fwd, "noteCallReads");
    SmallVector<RailId, 4> &v = I.callReads[fwd];
    if (!is_contained(v, r))
      v.push_back(r);
    // Recorded already: the call's record reads it from now on.
    if (unsigned rec = I.callRecord(fwd); rec != kNone)
      I.addCallRead(rec, r);
  }
}

RailId Uncompute::idOf(Value *handle) const { return impl->lookup(handle, "idOf", handle); }

void Uncompute::setRole(RailId r, Role role) {
  Impl &I = *impl;
  Impl::Rail &x = I.rail(r, "setRole");
  if (x.released || !x.exitsDone.empty())
    internalError("uncompute: setRole on a rail that was already uncomputed", x.handle);
  if (x.group != kNone)
    x.explicitKept = Impl::keptRole(role);
  if (I.isMerge(r)) {
    // U1: a merge is never resolved itself; a kept role on it would have to keep whichever arm the
    // classical condition chose and clean the others, which no static role can say. It is accepted
    // only where it changes nothing: every arm it may name is already kept.
    if (role == Role::Seed)
      internalError("uncompute: setRole: Role::Seed on a merged handle", x.handle);
    I.checkEdgeRead(r, nullptr, "setRole");
    if (Impl::keptRole(role))
      I.keepMerge(r, role);   // cq-bv91: the chosen arm is kept on each path
    x.role = role;
    return;
  }
  if (!Impl::keptRole(role) && !x.cleanup)
    for (RailId m : I.names(r))
      if (m != r && Impl::keptRole(I.rails[m].role))
        internalError("uncompute: setRole: a resolvable role on an arm of a kept merged handle", x.handle);
  I.checkEdgeRead(r, nullptr, "setRole");
  x.role = role;
}

void Uncompute::noteUse(RailId r, Instruction *consumer) {
  Impl::Rail &x = impl->rail(r, "noteUse");
  if (!consumer)
    internalError("uncompute: noteUse without a consumer", x.handle);
  if (impl->anyReleased(r))
    internalError("uncompute: use of " + describe(x.handle) + " after it was uncomputed and freed", consumer);
  impl->checkEdgeRead(r, consumer, "noteUse");
  x.uses.push_back(consumer);
}

void Uncompute::noteNonDiagonal(RailId target, Instruction *gate) {
  Impl::Rail &x = impl->rail(target, "noteNonDiagonal");
  if (!gate)
    internalError("uncompute: noteNonDiagonal without a gate", x.handle);
  impl->checkEdgeRead(target, gate, "noteNonDiagonal");
  if (impl->isMerge(target)) {
    // cq-bv91: the gate hits the arm the merge chose; every arm must already be kept (setRole first),
    // so the hit binds only the items that read the merge or an arm.
    for (RailId a : impl->leaves(target)) {
      if (impl->resolvable(a))
        unimplemented("uncompute: a non-diagonal gate on a merged handle whose arm " +
                          describe(impl->rails[a].handle) + " is not kept (set the kept role first)",
                      gate);
      impl->rails[a].hits.push_back(gate);
    }
    impl->rails[target].hits.push_back(gate);
    impl->noteAliasHits(target, gate);
    return;
  }
  if (x.released)
    internalError("uncompute: gate on " + describe(x.handle) + " after it was uncomputed and freed", gate);
  x.hits.push_back(gate);
  impl->noteAliasHits(target, gate);
}

void Uncompute::cleanupBijective(RailId oldRail, const abi::TemplateSpec &inverse, ArrayRef<Operand> ops) {
  Impl::Rail &x = impl->rail(oldRail, "cleanupBijective");
  if (x.released || !x.exitsDone.empty())
    internalError("uncompute: cleanupBijective of a rail already uncomputed", x.handle);
  if (x.cleanup)
    internalError("uncompute: cleanupBijective requested twice", x.handle);
  if (impl->isMerge(oldRail))
    internalError("uncompute: cleanupBijective of a merged handle", x.handle);
  impl->checkEdgeRead(oldRail, nullptr, "cleanupBijective");
  Impl::Cleanup cl{inverse, SmallVector<Operand, 3>(ops.begin(), ops.end()), {}};
  for (const Operand &o : ops) {
    if (!o.handle)
      continue;
    RailId r = impl->lookup(o.v, "cleanupBijective", x.handle);
    if (r == oldRail)
      internalError("uncompute: rule 6 inverse reads the rail it cleans", x.handle);
    if (impl->rails[r].released)
      internalError("uncompute: rule 6 operand already uncomputed", o.v);
    impl->checkEdgeRead(r, nullptr, "cleanupBijective");
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
  SmallVector<RailId, 16> cands, deferred;
  for (RailId g = 0; g < I.rails.size(); ++g) {
    if (I.rails[g].ownedBy != kNone)
      continue; // F1: mirrored by its deferred item
    if (I.rails[g].deferred != kNone) {
      if (I.resolvable(g))
        deferred.push_back(g);
      continue;
    }
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
  // F1: a deferred item goes last, once every use of its exit rails after the loop lies before P in
  // P's block and every reader of them is resolved.
  for (RailId g : deferred) {
    if (!I.deferredLocalReady(g, point))
      continue;
    if (any_of(I.readersOf(g), [&](RailId o) { return I.resolvable(o) && !I.done(o, c); }))
      continue;
    I.place(g, c);
  }
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
  for (RailId g : cands) {
    Impl::Rail &x = I.rails[g];
    const BasicBlock *D = I.defBlock(g);
    const Instruction *def = x.creator != kNone ? I.records[x.creator].forward : dyn_cast<Instruction>(x.handle);
    if (!Impl::dominates(D, Pb) || (D == Pb && def && !def->comesBefore(P)))
      internalError("uncompute: resolveAt: the definition of " + describe(x.handle) + " does not dominate the point", P);
    for (Instruction *a : I.anchors(g))
      if (a == P || Impl::after(a, P))
        internalError("uncompute: resolveAt: " + describe(x.handle) + " is still used after the point", a);
    for (RailId o : I.readersOf(g))
      if (I.resolvable(o) && !I.rails[o].released && I.rails[o].exitsDone.empty() && !is_contained(cands, o))
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
}

void Uncompute::flushAtExit(ReturnInst *ret) {
  impl->pruneCleanups();
  if (!ret || !ret->getParent())
    internalError("uncompute: flushAtExit needs a return in a block");
  Impl &I = *impl;
  I.checkEdgeUsers();
  // U2: a twin zeroes every result of its call, so either every member is kept or none is.
  for (const Impl::CallGroup &cg : I.groups) {
    const Impl::Rail &lead = I.rails[cg.members.front()];
    if (!Impl::keptRole(lead.role) || lead.role == Role::KeptEntangled)
      continue;
    for (RailId m : cg.members)
      if (!I.rails[m].explicitKept)
        unimplemented("uncompute: a call whose results are partly kept (" + describe(I.rails[m].handle) +
                          " is not; its twin would zero the kept ones)",
                      cg.fwd);
  }
  Impl::Ctx c{Impl::Mode::Exit, ret, nullptr};
  BasicBlock *Rb = ret->getParent();
  SmallVector<RailId, 16> cands, defc;
  for (RailId g = 0; g < I.rails.size(); ++g) {
    if (!I.resolvable(g) || I.done(g, c) || I.rails[g].ownedBy != kNone)
      continue;
    if (unsigned di = I.rails[g].deferred; di != kNone) {
      // F1: placed here when its loop reaches this return (the item branches around itself on a path
      // where the loop did not run).
      if (any_of(I.defs[di].region, [&](const BasicBlock *rb) { return Impl::reaches(rb, Rb); })) {
        cands.push_back(g);
        defc.push_back(g);
      }
      continue;
    }
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
  I.resolveUnmeasured(Rb); // cq-8lf8
  for (RailId g : defc)
    if (!I.rails[g].released)
      unimplemented("uncompute: a deferred rule-14 reverse loop could not be placed before a return its loop reaches "
                        "(a reader of its exit values is still pending)",
                    ret);
  I.checkDeferredPaths(Rb);
}

void Uncompute::recordDeferred(ArrayRef<unsigned> scopes, ArrayRef<RailId> exitRails,
                               std::function<void(IRBuilder<> &)> emit, ArrayRef<RailId> reads) {
  Impl &I = *impl;
  if (exitRails.empty() || !emit)
    internalError("uncompute: recordDeferred without exit rails or an emitter");
  unsigned di = I.defs.size();
  Impl::Deferred d;
  d.emit = std::move(emit);
  for (unsigned s : scopes) {
    if (s >= I.scopes.size() || I.scopes[s].open)
      internalError("uncompute: recordDeferred over a scope that is not closed: " + std::to_string(s));
    for (unsigned rec = I.scopes[s].begin; rec < I.scopes[s].end; ++rec) {
      d.region.insert(I.records[rec].forward->getParent());
      if (isCreator(I.info[rec].kind) && I.info[rec].item != kNone)
        I.rails[I.info[rec].item].ownedBy = di;
    }
  }
  for (RailId x : exitRails) {
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
