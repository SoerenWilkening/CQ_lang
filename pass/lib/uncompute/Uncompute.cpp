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
//    cq-igqp: when x's handle is a phi or select over handles that is not a merge (a classically
//    bounded loop's header phi, recordExternal), g is also a gate on every rail it may name (through
//    nested phis, selects and merges; re-read before every placement, since the back edge is filled
//    after the gate): those rails are never uncomputed through it. An unchosen arm of a kept merge so
//    hit on every path to its edge stays allocated there (A4); on some paths only: unimplemented. A
//    rail already uncomputed and freed that such a gate reaches: unimplemented.
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
//  - noteCellsDistinct(a, b) (M3b, cq-arch 2026-11-01; CR rules 5, 20): the loads a and b of slot cells
//    name different rails at run time (mem-slots proved the cells different, one rail per cell). A
//    non-diagonal gate whose target handle is a (or b) is then no AliasHit barrier on the item of a
//    record that reads b (or a) itself: the alias hit it left on a rail b may name is skipped when that
//    rail is reached through the read of b. A direct hit (a merge arm both loads may name) and every
//    other route to the rail stay barriers.
//  - recordCall(fwd, outs, slotOuts, extra) (U2, cq-arch 2026-11-01; CR §1.4, rules 18, 27): the result
//    rails of one clone call. The first member (outs, then slotOuts) is the leader: it carries a Call
//    record over fwd's arguments and extra (their handles are its reads) and the group's one item; every
//    other member is a merge over the leader alone (as a cell load: a use of it is a use of the leader,
//    a kept role on it keeps the leader). The item emits <callee>_unc(outs..., fwd args..., extra...)
//    (C calling convention) and then cqrt_free of every member in order. Every member kept: nothing.
//    A kept leader with a member that was not given a kept role itself is unimplemented at flushAtExit
//    (the twin would zero the kept results); KeptEntangled (a barrier) keeps all of them. The item
//    follows the definitions of every member and of every extra operand defined after fwd (cq-b73i).
//    cq-necw: a group of one slotOut and no out whose member has a rule 6 clean-up emits that clean-up
//    instead of the twin (the cell's new content cleaned like an inline update's result, CR rules 6, 18).
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
//  - F1b (cq-arch 2026-11-01; CR rule 14, §1.3: 72, 188). A QRAM store recorded in the item's scopes is
//    popped by the item's mirror (its POP is owned) and makes the item a writer of that bus b (one the
//    scopes do not allocate): the item follows POP(j) of every store recorded on b after the scopes and
//    the un-copy of every load of b reading a version at or above the last owned POP, it reads b (b's
//    release, cqrt_qram_free, follows it), and every earlier POP or load un-copy that must follow an
//    owned POP follows the item. Every use of b after the loop anchors the item, and a later store on b
//    that is popped before the item is no barrier of it. exitRails may be empty when b has a use after
//    the loop; otherwise an empty list is an internal error.
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
    Function *via = nullptr;   // U8: the clean-up is the call via(ops..., old) (inverse unused)
    std::string unbuilt;                    // cq-p8r6: placed only to stop (cleanupUnbuilt)
    const Instruction *unbuiltAt = nullptr;
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
    RailId pseudo = kNone;
    BasicBlock *placedAt = nullptr;            // the block the program continues in after the item
    // F1b: the QRAM buses an owned store writes, each with the highest popK among its owned POPs.
    SmallVector<std::pair<RailId, unsigned>, 1> buses;
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
    bool declared = false;   // U7: recordDeclaredWrites (a pseudo leader: the twin alone, nothing freed)
    unsigned extraFirst = 0; // cq-i9wk: the last extraFirst extra operands lead the twin's operands
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
  // M3b: pairs of loads proven to name different rails (both orders), and the target handles each
  // noted non-diagonal gate was noted on.
  DenseSet<std::pair<const Value *, const Value *>> distinctLoads;
  DenseMap<const Instruction *, SmallVector<const Value *, 1>> gateTargets;
  // An alias hit of gate on a rail reached through a read of handle `via` that M3b rules out: every
  // handle the gate was noted on names a different rail than via at run time.
  bool aliasRuledOut(const Instruction *gate, const Value *via) const {
    if (!via || distinctLoads.empty())
      return false;
    auto it = gateTargets.find(gate);
    if (it == gateTargets.end() || it->second.empty())
      return false;
    return all_of(it->second, [&](const Value *t) { return distinctLoads.count({t, via}) > 0; });
  }
  DenseSet<const Instruction *> emitted;
  DenseMap<std::pair<RailId, const BasicBlock *>, Instruction *> itemEnd;
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
      if (ua != ub && identified(ua) && identified(ub))
        return false;
      // cq-lqz3: a pointer from outside the frame (a formal, a global, a loaded pointer, a call's result)
      // never points into an alloca whose address does not escape (185: a load of tk[i] next to the slot
      // arrays k[] and c[]).
      auto outside = [](const Value *u) {
        return isa<Argument>(u) || isa<GlobalValue>(u) || isa<LoadInst>(u) || isa<CallBase>(u);
      };
      if (ua != ub && ((isa<AllocaInst>(ua) && outside(ub) && !reachable(ua)) ||
                       (isa<AllocaInst>(ub) && outside(ua) && !reachable(ub))))
        return false;
      return true;
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
    return !r.cleanup && r.arms.empty() && (r.role == Role::Seed || r.role == Role::Garbage) && !replacedForGood(b);
  }
  // cq-lshe (CR §0, §1.3, rule 16): a bus whose qram_realloc result a' is kept (escaped, an output) is
  // replaced by a' for good: the object lives on, so the stores made through the old bus stay, the old bus
  // is never released, and a load of it cannot be un-copied once a store through a' may have changed a cell.
  bool replacedForGood(RailId b) const {
    for (RailId a2 : rails[b].reallocs)
      if (rails[a2].cleanup || keptRole(rails[a2].role) || replacedForGood(a2))
        return true;
    return false;
  }
  bool loadOfReplaced(RailId g) const {
    for (auto [b, k] : rails[g].versions)
      for (RailId a2 : rails[b].reallocs)
        if ((rails[a2].cleanup || keptRole(rails[a2].role) || replacedForGood(a2)) &&
            (!rails[a2].pops.empty() || replacedForGood(a2)))
          return true;
    return false;
  }

  // The store record w is (or will be) popped before the bus is released.
  bool storePopped(unsigned w) const {
    RailId p = info[w].item;
    return info[w].kind == RecKind::QramStore && isPop(p) && rails[p].role == Role::Garbage &&
           busPoppable(rails[p].popBus);
  }

  // cq-4593 (CR rule 17): the rails pending at each open cq_invert region's begin (openInvert), innermost
  // last. No flush places their items while the region is open.
  SmallVector<DenseSet<RailId>, 2> invertFrozen;
  bool frozen(RailId g) const {
    return any_of(invertFrozen, [&](const DenseSet<RailId> &s) { return s.count(g) != 0; });
  }

  bool resolvable(RailId g) const {
    const Rail &r = rails[g];
    if (r.popBus != kNone)
      return !r.released && r.role == Role::Garbage && busPoppable(r.popBus);
    if (r.qram && replacedForGood(g))
      return false;
    if (!r.versions.empty() && loadOfReplaced(g))
      return false;
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
    SmallVector<RailId, 4> out = ownReads(g);
    // cq-lshe: the rails the sandwich of the item reads (the operands of in-place writes it may undo and
    // redo around itself) outlive it too.
    if (rails[g].deferred == kNone)
      for (unsigned w : sandwichCands(g))
        for (RailId x : info[w].reads)
          if (x != g && !is_contained(out, x))
            out.push_back(x);
    return out;
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
    }
    for (unsigned rec : undone(g))
      for (RailId x : info[rec].reads)
        if (x != g && !is_contained(out, x))
          out.push_back(x);
    return out;
  }
  // cq-lshe (CR rule 5): the in-place write records that may lie between g's item's records and the item,
  // on a rail the item reads or on a rail such a write reads (transitively): a write after the record
  // that read the rail, except a QRAM store that a load's un-copy follows anyway (A2, popped first).
  SmallVector<unsigned, 4> sandwichCands(RailId g) const {
    SmallVector<unsigned, 4> out;
    const Rail &r = rails[g];
    if (r.deferred != kNone)
      return out;
    // (rail, the record that read it, a later store on it is popped first: a QRAM load's bus, A2)
    struct Rd { RailId x; const Instruction *at; bool popsFirst; };
    SmallVector<Rd, 8> R;
    auto addReads = [&](ArrayRef<RailId> xs, const Instruction *at, bool popsFirst) {
      for (RailId x0 : xs)
        for (RailId x : leaves(x0))
          if (x != g)
            R.push_back({x, at, popsFirst});
    };
    if (r.cleanup) {
      addReads(r.cleanup->reads, r.creator != kNone ? records[r.creator].forward : nullptr, false);
    } else {
      for (unsigned rec : undone(g))
        addReads(info[rec].reads, records[rec].forward, info[rec].kind == RecKind::QramLoad);
    }
    for (unsigned i = 0; i < R.size(); ++i) {
      Rd rd = R[i];
      for (unsigned w : rails[rd.x].writes) {
        const Instruction *f = records[w].forward;
        if (is_contained(out, w) || !f->getParent() || (rd.at && (f == rd.at || !after(f, rd.at))))
          continue;
        if (rd.popsFirst && storePopped(w))
          continue;   // A2: a later store on a load's bus is popped before the load is un-copied
        out.push_back(w);
        for (RailId y0 : info[w].reads)
          for (RailId y : leaves(y0))
            if (y != g)
              R.push_back({y, f, false});
      }
    }
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
  // `only`: prune the clean-ups of these rails alone (a local flush, cq-1jxg). A pending clean-up whose
  // operand is garbage now may find it kept later (a measurement after a later reader of the old value
  // in another block), so the decision waits until the old rail itself is resolved.
  void pruneCleanups(const SmallVectorImpl<RailId> *only = nullptr) {
    syncPhiHits();   // cq-igqp: before any placement
    // To a fixed point: dropping one clean-up makes its rail plain garbage again, which may now be a
    // garbage reader of an earlier clean-up's operand (164's clone: %6 = %7 - %3 kept while %7's own
    // clean-up through the result was still there, then %7's dropped: a cycle).
    for (bool again = true; again;) {
      again = false;
      for (RailId g = 0; g < rails.size(); ++g)
        if ((!only || is_contained(*only, g)) && pruneOne(g))
          again = true;
    }
  }
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
      // F1b: a writer of bus b follows POP(j) of every store recorded on b after its scopes and the
      // un-copy of every load of b made after them (a later version, k at or above its last owned POP).
      for (auto [b, top] : d.buses) {
        SmallVector<RailId, 8> later;
        for (RailId p : rails[b].pops)
          if (rails[p].popK > top && rails[p].ownedBy == kNone)
            later.push_back(p);
        for (RailId l : rails[b].loads)
          for (auto [bus, k] : rails[l].versions)
            if (bus == b && k >= top && rails[l].ownedBy != rails[g].deferred)
              later.push_back(l);
        for (RailId o : later) {
          o = ownerOf(o, g);
          if (o != g && !is_contained(out, o))
            out.push_back(o);
        }
      }
      return out;
    }
    SmallVector<RailId, 4> ns = ownNames(g); // cq-lshe: not the readers through a keeper
    SmallVector<RailId, 4> cand;
    // cq-lshe: an in-place write reading g is in the sandwich of the items that read its target (or, in
    // turn, a rail another such write reads): those items read g too (itemReads), so they are candidates.
    SmallVector<RailId, 4> targets;
    auto addCands = [&](RailId n) {
      for (unsigned rec : rails[n].readerRecs) {
        if (!is_contained(cand, info[rec].item))
          cand.push_back(info[rec].item);
        if (!isCreator(info[rec].kind))
          if (RailId t = records[rec].out; t < rails.size() && !is_contained(targets, t))
            targets.push_back(t);
      }
      for (RailId o : rails[n].cleanupReaders)
        if (!is_contained(cand, o))
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
      SmallVector<RailId, 4> rd = itemReads(o);
      if (!any_of(ns, [&](RailId n) { return is_contained(rd, n); }))
        continue;
      // F1: a reader owned by a deferred item not yet placed is undone by that item.
      if (unsigned di = rails[o].ownedBy; di != kNone && rails[g].ownedBy != di && !rails[defs[di].pseudo].released)
        o = defs[di].pseudo;
      if (o != g && !is_contained(out, o))
        out.push_back(o);
    }
    for (RailId o : versionBefore(g)) {
      o = ownerOf(o, g); // F1b: an owned POP or load is undone by its deferred item
      if (o != g && !is_contained(out, o))
        out.push_back(o);
    }
    return out;
  }
  // The item that undoes o as seen from g: o itself, or the pseudo rail of the deferred item that owns
  // o while that item is not placed (and g is not owned by it).
  RailId ownerOf(RailId o, RailId g) const {
    unsigned di = rails[o].ownedBy;
    if (di != kNone && rails[g].ownedBy != di && rails[g].deferred != di && !rails[defs[di].pseudo].released)
      return defs[di].pseudo;
    return o;
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
        // cq-hnqg: memory only the program cannot name (the constrained FP intrinsics' FP environment,
        // CR rule 23 state that eff-fenv carries) is no C object; its pointer actuals are classified above.
        if (G->isIntrinsic() && !isa<MemIntrinsic>(CB) && !CB->onlyAccessesArgMemory() &&
            !CB->onlyAccessesInaccessibleMemory() && !CB->onlyAccessesInaccessibleMemOrArgMem())
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
    auto eventsOf = [&](RailId x, auto &&isAfterBase, bool popsFirst = false, const Value *via = nullptr) {
      const Rail &rx = rails[x];
      for (Instruction *h : rx.hits)
        if (isAfterBase(h))
          out.push_back({h, Bar::Hit});
      for (Instruction *h : rx.aliasHits)
        if (isAfterBase(h) && !aliasRuledOut(h, via)) // M3b
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
          eventsOf(x, afterAll, false, rails[x0].handle);
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
          eventsOf(x, afterRec, popsFirst, rails[x0].handle);
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

  // ---- kept merges (cq-bv91, cq-lshe) -----------------------------------------------------------
  //
  // CR rule 9 (ruling 2026-10-27): a classical select or phi over handles names the chosen arm; a kept
  // role on it keeps the chosen arm, and every other arm is garbage on that path (CR §0: cleaned). The
  // choice is classical, so the lowering re-branches on it: each resolvable arm a the merge may name
  // gets the merge as a KEEPER and stays resolvable. Its item is placed like any garbage item, after a's
  // own uses (a use of the keeper is a use of a only where the keeper chose a, where a is kept), and
  // runs under the classical flag "a exists and no keeper chose it since" (flagAt; chooses(m, a) is the
  // choice spelled over the merge's own classical conditions: an i1 phi over its incoming edges, an i1
  // select on its condition). An arm a cell load may name (M3, the cell's content is not a classical
  // choice) is kept outright, as is a rail a deferred rule-14 item owns (its reverse loop undoes every
  // trip's instance; the copy taken where the loop exits keeps the role, placeDeferred).
  bool isDeclaredPseudo(RailId g) const {
    return rails[g].group != kNone && groups[rails[g].group].declared;
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
    if (rails[n].cellLoad) {
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
      if (resolvable(x))
        live.insert(x);
    for (RailId x : closure(m)) {
      if (x == m)
        continue;
      if (isMerge(x)) {
        rails[x].role = role;
        continue;
      }
      if (!live.count(x) || isDeclaredPseudo(x))
        continue;   // U7: a declared clone's twin runs whatever the caller keeps
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
    if (rails[n].cellLoad) {
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
  DenseMap<RailId, SmallVector<FlagEv, 2>> inheritedEvs;   // cq-4lqy: see placeAt (a POP kept on some paths)
  Value *flagAt(Instruction *at, ArrayRef<FlagEv> evs, bool dflt) {
    LLVMContext &C = at->getContext();
    Type *I1 = Type::getInt1Ty(C);
    Constant *T = ConstantInt::getTrue(C), *F = ConstantInt::getFalse(C);
    // The conditions first: they may add phis and selects beside merges.
    SmallVector<Value *, 8> conds;
    for (const FlagEv &e : evs)
      conds.push_back(e.set ? T : e.cond ? e.cond : e.merge == kNone ? static_cast<Value *>(T) : chooses(e.merge, e.arm));
    DenseMap<const BasicBlock *, SmallVector<unsigned, 2>> byBlock;
    for (unsigned i = 0; i < evs.size(); ++i)
      if (evs[i].at && evs[i].at->getParent())
        byBlock[evs[i].at->getParent()].push_back(i);
    for (auto &kv : byBlock)
      llvm::stable_sort(kv.second, [&](unsigned x, unsigned y) {
        return evs[x].at != evs[y].at && evs[x].at->comesBefore(evs[y].at);
      });
    std::vector<PHINode *> made;
    std::vector<Instruction *> ops;   // and/xor made here
    DenseMap<BasicBlock *, Value *> startOf, endOf;
    SmallPtrSet<BasicBlock *, 8> busy;
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
          if (!limit || (evs[i].at != limit && evs[i].at->comesBefore(limit)))
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
      if (ps.size() == 1) {
        if (!busy.insert(b).second)
          return F;   // a cycle of single-predecessor blocks is unreachable
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

  // CR §1.3 (cq-lshe, 2026-11-02): a realloc of a bus with a leaf the function did not allocate (a formal's,
  // a loaded one) reads the old logical size by cqrt_qram_size(a) right before the realloc; keyed by the
  // realloc's record, used by its release qram_realloc_<W>_unc(a', n_old).
  DenseMap<unsigned, Value *> reallocOldSize;
  bool foreignBus(RailId a) {
    return any_of(leaves(a), [&](RailId x) { return rails[x].creator == kNone; });
  }

  // cq-vtfq: the logical size a bus was made with (qram_alloc's n, a realloc's n).
  // cq-lshe (CR rule 9): a merged bus's size is its chosen arm's, a select over the arms' sizes on the
  // classical choice (chooses); at must lie where the merge's choice values are available (null: check only).
  Value *busSize(RailId b, Instruction *at = nullptr) {
    if (isMerge(b)) {
      SmallVector<RailId, 4> ls = leaves(b);
      for (RailId x : ls)
        busSize(x);
      if (!at)
        return nullptr;
      Value *v = busSize(ls.back(), at);
      for (unsigned i = ls.size() - 1; i-- > 0;) {
        Value *c = chooses(b, ls[i]);
        if (auto *k = dyn_cast<ConstantInt>(c)) {
          if (k->isOne())
            v = busSize(ls[i], at);
          continue;
        }
        v = track(SelectInst::Create(c, busSize(ls[i], at), v, "cq.n", at));
      }
      return v;
    }
    const Rail &r = rails[b];
    if (r.creator == kNone)
      internalError("uncompute: the size of a QRAM bus the function did not allocate (its realloc reads it by "
                    "cqrt_qram_size, foreignBus)",
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
      Value *n = reallocOldSize.lookup(r.creator);
      if (!n)
        n = busSize(a, &*B.GetInsertPoint());
      return track(B.CreateCall(declareFn(M, (fwd->getCalledFunction()->getName() + "_unc").str(), UT, fwd),
                                {r.handle, n}));
    }
    return track(B.CreateCall(declareFn(M, r.qram ? "cqrt_qram_free" : "cqrt_free", FT, r.handle), {r.handle}));
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
    {
      // cq-vtfq: an item that names a bus a (its qram_free, a POP, a load un-copy) runs after every
      // realloc result a' of a is undone; a kept a' (never undone) leaves a replaced for good.
      SmallVector<RailId, 2> buses;
      if (r.qram)
        buses.push_back(g);
      if (r.popBus != kNone)
        buses.push_back(r.popBus);
      if (loadOfReplaced(g))
        internalError("uncompute: a load un-copied after a store through a kept qram_realloc result", r.handle);
      for (RailId b : buses)
        for (RailId a2 : rails[b].reallocs)
          if (rails[a2].cleanup || (rails[a2].role != Role::Seed && rails[a2].role != Role::Garbage))
            internalError("uncompute: an item on a QRAM bus whose qram_realloc result is kept (replacedForGood "
                          "keeps every such item)",
                          rails[a2].handle);
    }
    // cq-necw (CR rules 6, 18): a group whose only member is a slotOut (no result) and that rule 6 cleans (the
    // new content of a cell an _inv<c> cleans, spine invCellImages) has no twin: its item is the clean-up.
    bool soleCellCleaned = r.cleanup && r.group != kNone && groups[r.group].outs.empty() &&
                           groups[r.group].members.size() == 1;
    if (r.group != kNone && r.creator != kNone && info[r.creator].kind == RecKind::Call && !soleCellCleaned) {
      // U2: twin(outs..., fwd args..., extra...), then free every out and slotOut in order.
      const CallGroup &cg = groups[r.group];
      CallInst *fwd = cg.fwd;
      Module &M = *B.GetInsertBlock()->getModule();
      LLVMContext &C = M.getContext();
      SmallVector<Type *, 8> ps;
      SmallVector<Value *, 8> args;
      size_t restExtra = cg.extra.size() - cg.extraFirst;
      for (size_t k = restExtra; k < cg.extra.size(); ++k) {
        ps.push_back(cg.extra[k]->getType());
        args.push_back(cg.extra[k]);
      }
      for (RailId o : cg.outs) {
        ps.push_back(Type::getInt32Ty(C));
        args.push_back(rails[o].handle);
      }
      for (Value *a : fwd->args()) {
        ps.push_back(a->getType());
        args.push_back(a);
      }
      for (size_t k = 0; k < restExtra; ++k) {
        ps.push_back(cg.extra[k]->getType());
        args.push_back(cg.extra[k]);
      }
      FunctionType *TT = FunctionType::get(Type::getVoidTy(C), ps, false);
      CallInst *twin = track(B.CreateCall(declareFn(M, (fwd->getCalledFunction()->getName() + "_unc").str(), TT, fwd),
                                          args));
      if (cg.declared)
        return twin;   // U7: the cells' rails are the clone's (the twin restores them) or the caller's own
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
      if (fwd->getCalledFunction() && !fwd->getCalledFunction()->getName().starts_with("cqrt_")) {
        // U6/U3: a store the clone made: its _unc from the record's spec and the caller's (bus, idx, v).
        abi::CoreSpec spec = std::get<abi::CoreSpec>(records[r.creator].spec);
        spec.unc = true;
        SmallVector<Value *, 3> args;
        for (const Operand &o : records[r.creator].ops)
          args.push_back(o.v);
        return track(B.CreateCall(abi::declare(*B.GetInsertBlock()->getModule(), spec), args));
      }
      return track(B.CreateCall(uncOf(fwd, false), argsOf(fwd, nullptr)));
    }
    if (r.cleanup && !r.cleanup->unbuilt.empty())
      unimplemented(r.cleanup->unbuilt, r.cleanup->unbuiltAt);
    if (r.cleanup && !r.cleanup->alts.empty())
      return emitGuardedCleanup(g, B);
    if (r.cleanup && r.cleanup->via) {
      // U8 (cq-xivx): via(ops..., old) zeroes old; free old.
      SmallVector<Value *, 6> args;
      for (const Operand &o : r.cleanup->ops)
        args.push_back(o.v);
      args.push_back(r.handle);
      CallInst *c = track(B.CreateCall(r.cleanup->via, args));
      c->setCallingConv(r.cleanup->via->getCallingConv());
      return emitRelease(g, B);
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

  // F1b: while a deferred item placed at a return emits its mirror, the items placed for that return
  // before it (a later POP on a bus the item writes) are done.
  const BasicBlock *mirrorExit = nullptr;
  bool done(RailId g, const Ctx &c) const {
    return rails[g].released || (c.mode == Mode::Exit && rails[g].exitsDone.count(c.point->getParent())) ||
           (c.mode == Mode::Mirror && mirrorExit && rails[g].exitsDone.count(mirrorExit));
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
    if (!local && cycleArm.count(g)) {
      // cq-lshe: an arm defined on a cycle, pending at a return its definition does not dominate. Each
      // instance is resolved in the pass that defined it, at a block every path from the definition
      // passes before it runs again or returns, after every use of the instance, under its run flag
      // (cleared by the item itself, so a later pass through the block before a redefinition is no
      // second free).
      BasicBlock *Bp = cyclePoint(g, as);
      if (!Bp)
        unimplemented("uncompute: an arm of a merged handle, " + describe(r.handle) +
                          ", is defined on a cycle and no block after its uses lies on every path from its definition "
                          "back to it or to a return (its instances cannot be resolved one by one)",
                      c.point);
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
    // cq-lshe (CR rule 6): a clean-up reads its inverse's operands, which must exist wherever the item runs; one
    // whose operand is defined on some paths to pos only (an arm) gives way to g's own uncompute.
    if (r.cleanup && !r.cleanup->via && r.cleanup->unbuilt.empty() && r.creator != kNone &&
        any_of(r.cleanup->reads, [&](RailId x) {
          auto *h = dyn_cast<Instruction>(rails[x].handle);
          return h && (!dominates(h->getParent(), pos.bb) || (h->getParent() == pos.bb && !h->comesBefore(pos.before)));
        })) {
      for (RailId x : r.cleanup->reads)
        llvm::erase(rails[x].cleanupReaders, g);
      r.cleanup.reset();
    }
    SmallVector<FlagEv, 8> evs;
    if (selfClear)
      evs.push_back({pos.before, false});
    bool gated = false;
    auto beforePos = [&](const Instruction *e) {
      return e->getParent() == pos.bb ? (e != pos.before && e->comesBefore(pos.before)) : reaches(e->getParent(), pos.bb);
    };
    bool written = false, pointee = false;
    for (auto [e, kind] : barriers(g)) {
      if (!beforePos(e))
        continue;
      if (kind == Bar::Hit) {
        evs.push_back({e, false});
        gated = true;
        continue;
      }
      if (kind == Bar::PointeeWrite) {
        pointee = true;
        continue;
      }
      if (kind == Bar::Write) {
        written = true;
        continue;
      }
      // cq-zh7z, cq-4lqy (CR §0, rule 5; §1.1: handles are classical values the lowered program may
      // compare): the gate's handle may name an operand rail x of g's item through memory (a cell that may
      // hold it). Where it does, x is entangled and g stays allocated on that path (as for a direct hit);
      // where it does not, g is cleaned as usual. Which one holds is decided at run time by comparing the
      // gate's handle with x's (handle 0, no rail, where x does not exist at the gate).
      evs.push_back({e, false, kNone, kNone, aliasHitCond(g, e)});
      gated = true;
    }
    // The record that defines g's value (the gates and choices before it concern an older instance).
    Instruction *def = r.creator != kNone ? records[r.creator].forward : dyn_cast<Instruction>(r.handle);
    // cq-lshe (CR rule 5; Bennett.jl value_eager lines 31-39): the in-place writes on rails the item reads
    // that run between g's record and pos are undone before the item and redone after it (sandwich).
    SmallVector<unsigned, 4> sandwich;
    if (written)
      sandwichOf(g, def, beforePos, sandwich, evs, gated);
    // cq-lshe (CR rule 18, cq-fwto): a write into the memory a clone call's twin reads, between the call and
    // the twin: the object is snapshotted after the call and swapped in around the twin.
    SmallVector<std::pair<CallInst *, Value *>, 2> swaps;
    if (pointee)
      swapsOf(g, swaps);
    for (RailId m : r.keepers)
      if (auto *mi = dyn_cast<Instruction>(rails[m].handle); mi && mi->getParent())
        evs.push_back({mi, false, m, g});
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
    // cq-4lqy: the hit events a later POP of the same bus left here (where it stayed, this item stays too).
    if (auto it = inheritedEvs.find(g); it != inheritedEvs.end())
      for (const FlagEv &e : it->second)
        if (e.at->getParent() && beforePos(e.at)) {
          evs.push_back(e);
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
          // Kept on every path to pos: entangled (A4), or chosen by a keeper on each of them.
          if (gated || r.keepers.empty()) {
            r.role = Role::KeptEntangled;
            r.cleanup.reset();
            if (r.popBus != kNone)
              keepBelow(g);
          } else {
            r.role = rails[r.keepers.front()].role;
          }
          return;
        }
        guard = false;
      }
    }
    if (guard && r.popBus != kNone) {
      // cq-4lqy (CR §1.3: pops are LIFO among stores that may touch the same cell; an unpopped store keeps its
      // slot and the object stays allocated, §0): POP(k) runs under its run flag; on the paths where a gate
      // kept it, every earlier POP, every load of an earlier version and the bus stay too (keepBelow, per
      // path): they inherit the clear events, so their own items run under the same condition.
      SmallVector<FlagEv, 4> clears;
      for (const FlagEv &e : evs)
        if (!e.set && e.at != def && e.at != pos.before)
          clears.push_back(e);
      RailId b = r.popBus;
      SmallVector<RailId, 8> below;
      for (unsigned j = 1; j < r.popK; ++j)
        below.push_back(rails[b].pops[j - 1]);
      for (RailId l : rails[b].loads)
        for (auto [bus, k] : rails[l].versions)
          if (bus == b && k < r.popK && !is_contained(below, l))
            below.push_back(l);
      below.push_back(b);
      for (RailId y : below)
        for (const FlagEv &e : clears)
          inheritedEvs[y].push_back(e);
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
    SmallVector<Value *, 2> tmps;
    for (auto [fwd, obj] : swaps)
      tmps.push_back(swapIn(fwd, obj, B));
    Instruction *prev = pos.before->getPrevNode();
    SmallVector<Seg, 4> segs;
    segOut = &segs;
    Instruction *end = emitItem(g, B);
    segOut = nullptr;
    Instruction *first = prev ? prev->getNextNode() : &pos.bb->front();
    if (!segs.empty()) {
      // cq-mgkr: a guarded rule 6 clean-up: each segment under its own condition (and the run flag).
      if (!sandwich.empty() || !swaps.empty())
        internalError("uncompute: a rule 6 clean-up under a classical guard with in-place writes or swaps around it",
                      r.handle);
      for (Seg &sg : segs) {
        Value *c = sg.cond;
        if (guard) {
          IRBuilder<> GB(sg.first);
          c = GB.CreateAnd(cond, c);
        }
        wraps.push_back({g, sg.first, sg.last, c});
      }
      itemEnd[{g, pos.bb}] = end;
      if (local)
        r.released = true;
      else
        r.exitsDone.insert(pos.bb);
      return;
    }
    Instruction *last = end;
    for (unsigned k = 0; k < swaps.size(); ++k)
      last = swapOut(swaps[k].second, tmps[k], B);
    for (unsigned k = 0; k < sandwich.size(); ++k)
      last = guarded(wcond[k], [&] { return emitWrite(sandwich[k], B, /*undo=*/false); });
    itemEnd[{g, pos.bb}] = last;
    if (local)
      r.released = true;
    else
      r.exitsDone.insert(pos.bb);
    if (guard && first != pos.before)
      wraps.push_back({g, first, end, cond});
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
          if (StringRef(t->op).starts_with("qrom_load") || (t->rm == abi::TemplateSpec::RmRail && i + 1 == c->arg_size()))
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
  void copyOutResult(RailId m, CallInst *fwd) {
    Value *h = rails[m].handle;
    auto *hI = dyn_cast<Instruction>(h);
    if (!hI || !hI->getNextNode())
      internalError("uncompute: a kept clone result that is not an instruction in a block", fwd);
    Module &M = *fwd->getModule();
    std::optional<RailType> wo = handleWidth(h);
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
    rc.aliasHits = std::move(rm.aliasHits);
    rm.aliasHits.clear();
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
    for (auto &kv : gateTargets)
      for (const Value *&t : kv.second)
        if (t == h)
          t = c;
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

  // cq-4lqy (CR §0, §1.1): the run-time condition "the alias gate e hits a rail g's item reads (or g)": an
  // icmp eq of each handle e was noted on against each such rail's handle as it is at e (0 where the rail
  // does not exist there), or'ed. Exact: a rail M3b rules out compares unequal at run time anyway.
  Value *aliasHitCond(RailId g, Instruction *e) {
    SmallVector<RailId, 8> xs{g};
    for (RailId x0 : itemReads(g))
      for (RailId x : leaves(x0))
        if (!is_contained(xs, x))
          xs.push_back(x);
    if (rails[g].cleanup)
      for (RailId x0 : rails[g].cleanup->reads)
        for (RailId x : leaves(x0))
          if (!is_contained(xs, x))
            xs.push_back(x);
    auto tg = gateTargets.find(e);
    if (tg == gateTargets.end() || tg->second.empty())
      internalError("uncompute: an alias hit by a gate with no noted target", e);
    LLVMContext &C = e->getContext();
    Type *I32 = Type::getInt32Ty(C);
    Value *any = nullptr;
    for (RailId x : xs) {
      if (!is_contained(rails[x].aliasHits, e))
        continue;
      Value *xh = rails[x].handle;
      Value *at = xh;
      if (auto *xi = dyn_cast<Instruction>(xh)) {
        BasicBlock *D = xi->getParent(), *Eb = e->getParent();
        if (!(D == Eb ? xi->comesBefore(e) : dominates(D, Eb))) {
          // x's handle as it is at e: 0 on the paths where it was not defined (CR §1.1).
          SmallVector<BasicBlock *, 4> ps(predecessors(Eb));
          if (D == Eb || ps.empty()) {
            at = ConstantInt::get(I32, 0);
          } else if (ps.size() == 1) {
            at = carryTo(ps[0], true, D, xh, ConstantInt::get(I32, 0), "cq.h");
          } else {
            PHINode *phi = PHINode::Create(I32, ps.size(), "cq.h");
            phi->insertInto(Eb, Eb->begin());
            emitted.insert(phi);
            for (BasicBlock *p : ps)
              phi->addIncoming(carryTo(p, true, D, xh, ConstantInt::get(I32, 0), "cq.h"), p);
            at = phi;
          }
        }
      }
      for (const Value *t : tg->second) {
        Value *eq = track(new ICmpInst(e, ICmpInst::ICMP_EQ, const_cast<Value *>(t), at, "cq.hit"));
        any = any ? track(BinaryOperator::CreateOr(any, eq, "cq.hit", e)) : eq;
      }
    }
    if (!any)
      internalError("uncompute: an alias-hit barrier with no rail of the item it may hit", e);
    return any;
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
      if (info[w].kind != RecKind::Involution && info[w].kind != RecKind::QramStore)
        internalError("uncompute: an in-place write record that is neither an involution nor a QRAM store", f);
      if (reachesAgain(f->getParent(), f->getParent(), {def ? def->getParent() : &f->getFunction()->getEntryBlock()}))
        unimplemented("uncompute: an in-place write on an operand rail of " + describe(rails[g].handle) +
                          " may run more than once between its record and its earliest uncompute (a loop "
                          "around the write that does not redefine the rail)",
                      f);
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
        return x->comesBefore(y);
      return reaches(x->getParent(), y->getParent()) && !reaches(y->getParent(), x->getParent());
    });
  }

  // An in-place write record undone (an involution: the same call; a QRAM store: its _unc) or redone.
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
    if (undo && info[w].kind == RecKind::QramStore)
      return track(B.CreateCall(uncOf(fwd, false), argsOf(fwd, nullptr)));
    return track(B.CreateCall(fwd->getFunctionType(), fwd->getCalledOperand(), argsOf(fwd, nullptr)));
  }

  // The objects the twin of a clone call g's item undoes reads (its footprint), each to be swapped back to
  // its content right after the call. An object of unknown extent (a formal's or the heap's, a dynamic
  // alloca, every object reachable from outside the frame) is unimplemented.
  void swapsOf(RailId g, SmallVectorImpl<std::pair<CallInst *, Value *>> &out) {
    for (unsigned rec : undone(g)) {
      if (info[rec].kind != RecKind::Call && info[rec].kind != RecKind::Template)
        continue;
      auto *fwd = cast<CallInst>(records[rec].forward);
      Footprint fp = footprint(fwd);
      if (fp.empty())
        continue;
      if (fp.unbounded)
        unimplemented("awaiting owner ruling: SPEC_ISSUES a write into a clone's footprint of unknown extent before "
                      "its twin: a write into memory a clone call's twin reads lies between the call and the twin "
                      "(" + describe(rails[g].handle) + "), and the clone reads memory reached through a pointer it "
                      "loaded or an unknown callee (its extent is not known: cq-99z6)",
                      fwd);
      for (const Cell &c : fp.objs) {
        Value *obj = const_cast<Value *>(getUnderlyingObject(c.ptr));
        bool sized = false;
        if (auto *AI = dyn_cast<AllocaInst>(obj))
          sized = AI->isStaticAlloca() && AI->getAllocationSize(fwd->getModule()->getDataLayout()).has_value();
        else if (auto *GV = dyn_cast<GlobalVariable>(obj))
          sized = GV->getValueType()->isSized();
        if (!sized)
          unimplemented("awaiting owner ruling: SPEC_ISSUES a write into a clone's footprint of unknown extent before "
                        "its twin: a write into memory a clone call's twin reads lies between the call and the twin "
                        "(" + describe(rails[g].handle) + "), in an object whose extent is not known here (a "
                        "formal's object, the heap, a dynamic alloca)",
                        fwd);
        if (!is_contained(out, std::make_pair(fwd, obj)))
          out.push_back({fwd, obj});
      }
    }
  }
  uint64_t objectSize(Value *obj) const {
    const DataLayout &DL = cast<Instruction>(obj) ? cast<Instruction>(obj)->getModule()->getDataLayout()
                                                  : cast<GlobalVariable>(obj)->getParent()->getDataLayout();
    if (auto *AI = dyn_cast<AllocaInst>(obj))
      return AI->getAllocationSize(DL)->getFixedValue();
    return DL.getTypeAllocSize(cast<GlobalVariable>(obj)->getValueType()).getFixedValue();
  }
  // A frame buffer of obj's size in the entry block.
  Value *frameCopy(Function &F, Value *obj, const Twine &name) {
    LLVMContext &C = F.getContext();
    IRBuilder<> E(&*F.getEntryBlock().getFirstInsertionPt());
    auto *a = E.CreateAlloca(ArrayType::get(Type::getInt8Ty(C), objectSize(obj)), nullptr, name);
    emitted.insert(a);
    return a;
  }
  DenseMap<std::pair<CallInst *, Value *>, Value *> snaps;
  Value *swapIn(CallInst *fwd, Value *obj, IRBuilder<> &B) {
    Function &F = *fwd->getFunction();
    uint64_t n = objectSize(obj);
    Value *&snap = snaps[{fwd, obj}];
    if (!snap) {
      snap = frameCopy(F, obj, "cq.snap");
      IRBuilder<> A(fwd->getNextNode());
      emitted.insert(A.CreateMemCpy(snap, MaybeAlign(1), obj, MaybeAlign(1), n));
    }
    Value *tmp = frameCopy(F, obj, "cq.cur");
    emitted.insert(B.CreateMemCpy(tmp, MaybeAlign(1), obj, MaybeAlign(1), n));
    emitted.insert(B.CreateMemCpy(obj, MaybeAlign(1), snap, MaybeAlign(1), n));
    return tmp;
  }
  Instruction *swapOut(Value *obj, Value *tmp, IRBuilder<> &B) {
    CallInst *c = B.CreateMemCpy(obj, MaybeAlign(1), tmp, MaybeAlign(1), objectSize(obj));
    emitted.insert(c);
    return c;
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
    for (BasicBlock *U : made)
      carryOperands(U);
  }

  // Every operand of an item block U that does not dominate it, carried to it (poison where it is not
  // defined; the run flag is false there).
  void carryOperands(BasicBlock *U) {
    Function &F = *U->getParent();
    BasicBlock *entry = &F.getEntryBlock();
    DenseMap<Value *, Value *> carried;
    for (Instruction &I : *U)
      for (Use &u : I.operands()) {
        auto *op = dyn_cast<Instruction>(u.get());
        if (!op || op->getParent() == U || dominates(op->getParent(), U))
          continue;
        Value *&c = carried[op];
        if (!c) {
          if (op->getParent() == entry)
            internalError("uncompute: an arm item operand in the entry that does not dominate the item", op);
          c = carryTo(U, false, op->getParent(), op, PoisonValue::get(op->getType()), op->getName());
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
  Value *carryTo(BasicBlock *at, bool atEnd, BasicBlock *D, Value *v, Value *dflt, const Twine &name) {
    DenseMap<BasicBlock *, Value *> memo;
    std::vector<PHINode *> made;
    std::function<Value *(BasicBlock *)> end = [&](BasicBlock *b) -> Value * {
      if (b == D)
        return v;
      if (auto it = memo.find(b); it != memo.end())
        return it->second;
      SmallVector<BasicBlock *, 4> ps(predecessors(b));
      if (ps.empty())
        return memo[b] = dflt;
      if (ps.size() == 1)
        return memo[b] = end(ps[0]);
      PHINode *phi = PHINode::Create(v->getType(), ps.size(), name);
      phi->insertInto(b, b->begin());
      memo[b] = phi;
      made.push_back(phi);
      for (BasicBlock *p : ps)
        phi->addIncoming(end(p), p);
      return phi;
    };
    Value *r;
    if (atEnd) {
      r = end(at);
    } else {
      SmallVector<BasicBlock *, 4> ps(predecessors(at));
      if (ps.size() != 1)
        internalError("uncompute: an arm item block with other than one predecessor", at->getTerminator());
      r = end(ps[0]);
    }
    bool changed = true;
    while (changed) {
      changed = false;
      for (PHINode *&phi : made) {
        if (!phi)
          continue;
        Value *same = nullptr;
        bool trivial = true;
        for (Value *in : phi->incoming_values()) {
          if (in == phi || in == same)
            continue;
          if (same) {
            trivial = false;
            break;
          }
          same = in;
        }
        if (!trivial || !same)
          continue;
        phi->replaceAllUsesWith(same);
        if (r == phi)
          r = same;
        phi->eraseFromParent();
        phi = nullptr;
        changed = true;
      }
    }
    return r;
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
    // F1b: every use of a bus the item writes after the loop (its loads and stores there).
    for (auto [b, top] : d.buses)
      for (RailId n : names(b))
        for (User *u : rails[n].handle->users())
          if (auto *i = dyn_cast<Instruction>(u); i && i->getParent() && !beforeOrIn(d, i->getParent()))
            as.push_back(i);
    return as;
  }

  // cq-nqa6 (U7, CR rules 5, 8, 9): an ARM-LOCAL rail at a flush point P (flushBefore with the caller's
  // liveness): defined in a block D that does not dominate P (a classical arm), read after the arm's join
  // (a merge, a phase's flags), every use and reader item already before P, and no instruction lowered
  // after P reading it (live: the caller's set, through every merge naming it). Its item is placed at P
  // for good under D's selector, as cq-ut4k does at a return: D and P on no cycle, every path from D
  // reaches P, the handle never reaches memory, a clone call or a return (only gate calls, merges and
  // classical selects read it), no call group or QRAM version.
  bool spanReady(RailId g, Instruction *point, const DenseSet<RailId> &live) const {
    const Rail &r = rails[g];
    if (r.ownedBy != kNone || r.deferred != kNone || !resolvable(g) || !r.exitsDone.empty() || r.group != kNone ||
        r.popBus != kNone || r.qram || r.cleanup || !r.versions.empty())
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
      for (auto &kv : itemEnd)
        if (kv.first.first == o)
          as.push_back(kv.second);
    for (Instruction *a : as) {
      const BasicBlock *A = a->getParent();
      if (!A)
        return false;
      if (A == P) {
        if (!a->comesBefore(point))
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
        if (!a->comesBefore(point))
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
    for (unsigned si = 0; si < scopes.size(); ++si) {
      const Scope &sc = scopes[si];
      if (sc.open)
        return false;
      if (is_contained(d.hostScopes, si))
        continue;   // F2: the hosting region's own records (its reverse undoes them)
      for (unsigned rec = sc.begin; rec < sc.end; ++rec) {
        RailId it = info[rec].item;
        if (it == kNone || rails[it].ownedBy == rails[g].deferred || !resolvable(it))
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
    // (rail, the handle it is read through: M3b rules out some alias hits for a read of a load).
    SmallVector<std::pair<RailId, const Value *>, 8> xs;
    for (RailId x0 : d.reads)
      for (RailId x : leaves(x0))
        if (!is_contained(xs, std::make_pair(x, (const Value *)rails[x0].handle)))
          xs.push_back({x, rails[x0].handle});
    for (RailId x : d.exits)
      if (!is_contained(xs, std::make_pair(x, (const Value *)nullptr)))
        xs.push_back({x, nullptr});
    Instruction *barrier = nullptr;
    RailId barrierRail = kNone;
    for (auto [x, via] : xs) {
      SmallVector<Instruction *, 8> evs(rails[x].hits.begin(), rails[x].hits.end());
      for (Instruction *h : rails[x].aliasHits)
        if (!aliasRuledOut(h, via))
          evs.push_back(h);
      bool written = any_of(d.buses, [&](const std::pair<RailId, unsigned> &bt) { return bt.first == x; });
      for (unsigned w : rails[x].writes)
        if (rails[x].ownedBy == kNone && !(written && storePopped(w))) // F1b: a later store is popped first
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
      // cq-9o04 (CR rules 5, 14; §0): a QRAM bus the item writes is restored by it (its stores are
      // popped), so a read of the bus after the loop must precede the item. Placed where the loop
      // exits, every such read would follow it and see the popped cells.
      for (auto [b, top] : d.buses)
        for (RailId nb : names(b))
          for (User *u : rails[nb].handle->users())
            if (auto *i = dyn_cast<Instruction>(u); i && i->getParent() && afterRegion(d, i->getParent()) &&
                                                    !emitted.count(i))
              unimplemented("uncompute: a non-diagonal gate or an in-place write on a rail the deferred rule-14 "
                                "reverse loop reads (" + describe(rails[barrierRail].handle) +
                                ") precedes a read after the loop of a QRAM the loop writes (" +
                                describe(rails[b].handle) +
                                "), which the reverse loop pops: it can run neither before that read nor after "
                                "the gate",
                            i);
    }
    // An exit rail that became kept (measured, escaped, a kept merge's arm) is kept by a copy taken
    // here, and the reverse loop undoes the rail itself (every trip's instance is undone alike).
    SmallVector<std::pair<RailId, Role>, 2> keptExits;
    for (RailId x : d.exits) {
      Rail &rx = rails[x];
      if (!keptRole(rx.role) && !copyAll)
        continue;
      // cq-4lqy: a rotated exit rail, or one with no producer, is copied out the same way: the gates after the
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
      IRBuilder<> BXc(X->getTerminator());
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
    itemEnd[{g, br->getParent()}] = br;
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
    move(rails[x].aliasHits, rails[fid].aliasHits);
    move(rails[x].uses, rails[fid].uses);
    for (auto &kv : gateTargets)
      if (outside(kv.first))
        for (const Value *&t : kv.second)
          if (t == xh)
            t = f;
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
  // U6/U3: a store the clone call fwd made inside the clone, recorded on the caller's bus with the call
  // as its forward: its operands ([flag,] bus, idx, v) are the caller's, not fwd's arguments (cq-pf4n: a
  // _controlled store under the flag the clone copied out). Allowed only once noteCallBusRead(fwd, bus) placed
  // the call group on that bus.
  bool cloneStore = false;
  if (spec.op == Core::QramStore && fwd && fwd->getCalledFunction() &&
      !fwd->getCalledFunction()->getName().starts_with("cqrt_")) {
    unsigned rec = impl->callRecord(fwd);
    if (rec == kNone || impl->info[rec].kind != RecKind::Call)
      internalError("uncompute: recordCore: a QRAM store whose forward is a clone call with no recordCall", fwd);
    RailId lead = impl->records[rec].out;
    unsigned k0 = spec.ctl ? 1 : 0;
    if (ops.size() != 3 + k0 || (spec.ctl && !ops[0].handle) || !ops[k0].handle || !ops[k0 + 2].handle ||
        out >= impl->rails.size())
      internalError("uncompute: recordCore: a clone call's QRAM store takes ([flag,] bus, idx, v)", fwd);
    for (auto [b, k] : impl->rails[lead].versions)
      cloneStore = cloneStore || b == out;
    if (!cloneStore)
      internalError("uncompute: recordCore: a clone call's QRAM store on a bus with no noteCallBusRead", fwd);
  }
  if (!cloneStore)
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
    // cq-lshe: a merged bus (a classical choice of buses) is reallocated as the arm it names: a' is a
    // realloc of every arm (each arm's items follow its release), released with the chosen arm's size.
    for (RailId b : impl->leaves(a))
      if (!impl->rails[b].qram)
        internalError("uncompute: recordCore: qram_realloc of a rail that is not a QRAM bus", fwd);
    // CR §1.3: a bus the function did not allocate (on some arm) has its old size read by cqrt_qram_size
    // right before the realloc (a classical host read, no gate); every other size is known statically.
    Value *oldSize = nullptr;
    if (impl->foreignBus(a)) {
      IRBuilder<> SB(fwd);
      oldSize = impl->track(SB.CreateCall(abi::declare(*fwd->getModule(), abi::CoreSpec{abi::Core::QramSize}),
                                          {ops[0].v}, "cq.n.old"));
    } else {
      impl->busSize(a);
    }
    RailId r = impl->newRail(fwd, Role::Seed, "recordCore");
    impl->rails[r].qram = true;
    unsigned rrec = impl->addRecord(fwd, spec, ops, r, RecKind::QramRealloc, false);
    if (oldSize)
      impl->reallocOldSize[rrec] = oldSize;
    for (RailId b : impl->leaves(a))
      impl->rails[b].reallocs.push_back(r);
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

void Uncompute::noteCallExtraFirst(CallInst *fwd, unsigned n) {
  Impl &I = *impl;
  for (Impl::CallGroup &cg : I.groups)
    if (cg.fwd == fwd && !cg.declared) {
      if (n > cg.extra.size())
        internalError("uncompute: noteCallExtraFirst: more leading operands than the call's extra operands", fwd);
      cg.extraFirst = n;
      return;
    }
  internalError("uncompute: noteCallExtraFirst: no call group recorded for this forward call", fwd);
}

RailId Uncompute::recordDeclaredWrites(CallInst *fwd, ArrayRef<Operand> extra) {
  Impl &I = *impl;
  if (!fwd || !fwd->getCalledFunction() || !fwd->getParent() || !fwd->getType()->isVoidTy())
    internalError("uncompute: recordDeclaredWrites: the forward must be a void direct call in a block", fwd);
  if (!I.openStack.empty())
    unimplemented("uncompute: a declared clone that may write caller cells inside an open scope (a classically "
                  "bounded loop's trip: its mirror would have to run the twin)",
                  fwd);
  SmallVector<Operand, 8> ops;
  for (Value *a : fwd->args())
    ops.push_back(Operand{a, I.byHandle.count(a) > 0});
  I.checkOps(fwd, ops, "recordDeclaredWrites");
  unsigned gi = I.groups.size();
  I.groups.push_back({fwd, {}, {}, {}, {}, true});
  for (const Operand &e : extra) {
    if (e.handle)
      internalError("uncompute: recordDeclaredWrites: a twin operand after the forward's that is a handle", fwd);
    ops.push_back(e);
    I.groups[gi].extra.push_back(e.v);
  }
  // The pseudo leader: no handle of its own (the twin frees nothing), so it is not in byHandle.
  RailId lead = I.rails.size();
  I.rails.emplace_back();
  I.rails.back().handle = fwd;
  I.rails.back().group = gi;
  unsigned rec = I.addRecord(fwd, abi::TemplateSpec{}, ops, lead, RecKind::Call, false);
  I.takeCallReads(fwd, rec);
  I.groups[gi].members.push_back(lead);
  return lead;
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
    SmallVector<RailId, 4> &v = I.callReads[fwd];
    if (!is_contained(v, r))
      v.push_back(r);
    // Recorded already: the call's record reads it from now on.
    if (unsigned rec = I.callRecord(fwd); rec != kNone)
      I.addCallRead(rec, r);
  }
}

RailId Uncompute::idOf(Value *handle) const { return impl->lookup(handle, "idOf", handle); }

bool Uncompute::mayHit(const Value *handle, const Instruction *gate) const {
  auto it = impl->byHandle.find(handle);
  if (it == impl->byHandle.end())
    return false;
  for (RailId g : impl->names(it->second))
    if (is_contained(impl->rails[g].hits, gate))
      return true;
  for (RailId x : impl->leaves(it->second)) {
    const Impl::Rail &r = impl->rails[x];
    if (is_contained(r.hits, gate))
      return true;
    for (auto [h, n] : r.condHits)
      if (h == gate)
        return true;
    if (is_contained(r.aliasHits, gate) && !impl->aliasRuledOut(gate, handle))
      return true;
  }
  return false;
}

std::optional<Role> Uncompute::liveRole(RailId r) const {
  const Impl::Rail &x = impl->rails[r];
  if (x.released || !x.exitsDone.empty())
    return std::nullopt;
  return x.role;
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
  if (!is_contained(impl->gateTargets[gate], x.handle))
    impl->gateTargets[gate].push_back(x.handle);
  if (impl->isMerge(target)) {
    // cq-bv91, cq-lshe (CR §0, rules 5, 9, 10): the gate hits the arm the merge chose. A kept arm takes
    // the hit; a resolvable one is hit only where the merge chose it (a classical choice), so its item and
    // the items that read it are kept there and run elsewhere (placeAt's run flag).
    for (RailId a : impl->leaves(target)) {
      if (impl->resolvable(a))
        impl->rails[a].condHits.push_back({gate, target});
      else
        impl->rails[a].hits.push_back(gate);
    }
    impl->rails[target].hits.push_back(gate);
    impl->noteAliasHits(target, gate);
    impl->syncPhiHits();   // cq-igqp: an arm may be a phi over handles
    return;
  }
  if (x.released)
    internalError("uncompute: gate on " + describe(x.handle) + " after it was uncomputed and freed", gate);
  x.hits.push_back(gate);
  impl->noteAliasHits(target, gate);
  impl->syncPhiHits();   // cq-igqp: the rails a phi over handles may name
}

void Uncompute::noteCellsDistinct(Instruction *loadA, Instruction *loadB) {
  if (!loadA || !loadB || !isa<LoadInst>(loadA))
    internalError("uncompute: noteCellsDistinct takes a load of a slot cell and a load or a stored rail",
                  loadA ? loadA : loadB);
  if (loadA == loadB)
    internalError("uncompute: noteCellsDistinct of a load with itself", loadA);
  impl->distinctLoads.insert({loadA, loadB});
  impl->distinctLoads.insert({loadB, loadA});
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

void Uncompute::cleanupBijectiveUnder(RailId oldRail, Value *guard, const abi::TemplateSpec &inverse,
                                      ArrayRef<Operand> ops, bool everyPath) {
  Impl::Rail &x = impl->rail(oldRail, "cleanupBijectiveUnder");
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

void Uncompute::cleanupByCall(RailId oldRail, Function *inv, ArrayRef<Operand> args, ArrayRef<Value *> alsoReads) {
  if (!inv)
    internalError("uncompute: cleanupByCall without a function");
  SmallVector<Operand, 6> ops(args.begin(), args.end());
  for (Value *v : alsoReads)
    ops.push_back(Operand{v, true});
  cleanupBijective(oldRail, abi::TemplateSpec{}, ops);
  Impl::Rail &x = impl->rails[oldRail];
  x.cleanup->via = inv;
  x.cleanup->ops.assign(args.begin(), args.end());
}

void Uncompute::cleanupUnbuilt(RailId oldRail, const std::string &what, const Instruction *at,
                               ArrayRef<Value *> alsoReads) {
  if (what.empty())
    internalError("uncompute: cleanupUnbuilt without a description", at);
  if (impl->isMerge(oldRail))
    unimplemented(what + " (the old content a merged handle)", at);
  SmallVector<Operand, 4> ops;
  for (Value *v : alsoReads)
    ops.push_back(Operand{v, true});
  cleanupBijective(oldRail, abi::TemplateSpec{}, ops);
  impl->rails[oldRail].cleanup->unbuilt = what;
  impl->rails[oldRail].cleanup->unbuiltAt = at;
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
  I.pruneCleanups(&cands);
  I.resolve(cands, c);
  I.wrapLocal();
  // F1: a deferred item goes last, once every use of its exit rails after the loop lies before P in
  // P's block and every reader of them is resolved.
  if (!liveLater) {
    for (RailId g : deferred) {
      if (!I.deferredLocalReady(g, point))
        continue;
      if (any_of(I.readersOf(g), [&](RailId o) { return I.resolvable(o) && !I.done(o, c); }))
        continue;
      I.place(g, c);
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
    for (RailId g = 0; g < I.rails.size(); ++g) {
      if (I.rails[g].deferred == kNone || I.frozen(g) || !I.resolvable(g) || !I.deferredLocalReady(g, point, true))
        continue;
      if (any_of(I.readersOf(g), [&](RailId o) { return I.resolvable(o) && !I.done(o, c); }))
        continue;
      I.place(g, c);
      progress = true;
    }
  }
}

// cq-4593 (CR rule 17: "the compiler places no uncompute of a rail allocated before the region inside it";
// placement is free, rule 5). The rails pending at begin stay pending while the region is open; at its end
// the end marker becomes a use of each, so their items follow it. Regions nest.
void Uncompute::openInvert(Instruction *begin) {
  Impl &I = *impl;
  if (!begin || !begin->getParent())
    internalError("uncompute: openInvert needs an instruction in a block");
  DenseSet<RailId> s;
  for (RailId g = 0; g < I.rails.size(); ++g)
    if (I.resolvable(g))
      s.insert(g);
  I.invertFrozen.push_back(std::move(s));
}

void Uncompute::closeInvert(Instruction *end) {
  Impl &I = *impl;
  if (!end || !end->getParent())
    internalError("uncompute: closeInvert needs an instruction in a block");
  if (I.invertFrozen.empty())
    return;   // the region was opened by another function's lowering (begin and end are run-time events)
  DenseSet<RailId> s = I.invertFrozen.pop_back_val();
  for (RailId g : s)
    if (I.resolvable(g)) {
      RailId t = I.rails[g].popBus != kNone ? I.rails[g].popBus : g;   // a POP follows its bus's uses
      if (!is_contained(I.rails[t].uses, end))
        I.rails[t].uses.push_back(end);
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
  I.wrapLocal();
}

void Uncompute::flushAtExit(ReturnInst *ret) {
  impl->pruneCleanups();
  if (!ret || !ret->getParent())
    internalError("uncompute: flushAtExit needs a return in a block");
  Impl &I = *impl;
  // U2: a twin zeroes every result of its call, so either every member is kept or none is. CR rule 18
  // (ruling 2026-11-02, cq-75n4): when some results of one call are measured and others are dead, each
  // measured one is copied into a fresh rail right after the call (cqrt_alloc_<W>(0), cqrt_copy_<W>), the
  // measurements read the copies (Role::Measured), and the call's own result rails are garbage the twin
  // zeroes: the twin always zeroes every result it returned, and no measured rail is ever gated.
  for (size_t gi = 0; gi < I.groups.size(); ++gi) {
    if (I.groups[gi].declared)
      continue;
    SmallVector<RailId, 4> members = I.groups[gi].members;
    bool anyKept = false, anyDead = false;
    for (RailId m : members)
      (I.rails[m].explicitKept ? anyKept : anyDead) = true;
    if (!anyKept || !anyDead)
      continue;
    CallInst *fwd = I.groups[gi].fwd;
    for (RailId m : members) {
      if (!I.rails[m].explicitKept)
        continue;
      if (I.rails[m].role != Role::Measured) {
        // CR rule 18 twin point (cq-4lqy): a result still live where the twin runs is first copied out
        // (cqrt_copy_<W> into a fresh rail) and the copy continues as the value: it takes every later use,
        // record, gate and the kept role; the call's own result rail is garbage the twin zeroes.
        I.copyOutResult(m, fwd);
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
  I.wrapLocal();
  I.wrapArmItems(*Rb->getParent());
  I.armLocal.clear();
  I.cycleArm.clear();
  for (RailId g : defc)
    if (!I.rails[g].released)
      unimplemented("uncompute: a deferred rule-14 reverse loop could not be placed before a return its loop reaches "
                        "(a reader of its exit values is still pending)",
                    ret);
  I.checkDeferredPaths(Rb);
}

void Uncompute::recordDeferred(ArrayRef<unsigned> scopes, ArrayRef<RailId> exitRails,
                               std::function<void(IRBuilder<> &)> emit, ArrayRef<RailId> reads,
                               ArrayRef<unsigned> hostScopes, bool busUseFollows) {
  Impl &I = *impl;
  if (!emit)
    internalError("uncompute: recordDeferred without an emitter");
  unsigned di = I.defs.size();
  Impl::Deferred d;
  d.emit = std::move(emit);
  d.hostScopes.assign(hostScopes.begin(), hostScopes.end());
  Value *firstStore = nullptr;
  for (unsigned s : scopes) {
    if (s >= I.scopes.size() || I.scopes[s].open)
      internalError("uncompute: recordDeferred over a scope that is not closed: " + std::to_string(s));
    for (unsigned rec = I.scopes[s].begin; rec < I.scopes[s].end; ++rec) {
      d.region.insert(I.records[rec].forward->getParent());
      if (isCreator(I.info[rec].kind) && I.info[rec].item != kNone)
        I.rails[I.info[rec].item].ownedBy = di;
      // F1b: a QRAM store of the scopes is popped by the item's mirror, which makes it a writer of the bus.
      if (I.info[rec].kind == RecKind::QramStore && I.info[rec].item != kNone && I.isPop(I.info[rec].item)) {
        RailId p = I.info[rec].item, b = I.rails[p].popBus;
        I.rails[p].ownedBy = di;
        if (I.rails[b].ownedBy == di)
          continue; // a bus the loop allocates is the item's own
        if (!firstStore)
          firstStore = I.records[rec].forward;
        auto it = find_if(d.buses, [&](const std::pair<RailId, unsigned> &bt) { return bt.first == b; });
        if (it == d.buses.end())
          d.buses.push_back({b, I.rails[p].popK});
        else
          it->second = std::max(it->second, I.rails[p].popK);
      }
    }
  }
  if (exitRails.empty()) {
    // F1b: no exit rail is allowed when a bus the item writes is used after the loop (those uses anchor it).
    bool busUsed = false;
    for (auto [b, top] : d.buses)
      for (RailId n : I.names(b))
        for (User *u : I.rails[n].handle->users())
          if (auto *ui = dyn_cast<Instruction>(u); ui && ui->getParent() && !I.beforeOrIn(d, ui->getParent()))
            busUsed = true;
    if (!busUsed && !(busUseFollows && !d.buses.empty()))
      internalError("uncompute: recordDeferred without exit rails and without a QRAM bus its stores write that is "
                    "used after the loop");
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
  I.rails.back().handle = d.exits.empty() ? firstStore : I.rails[d.exits.front()].handle;
  I.rails.back().deferred = di;
  d.pseudo = g;
  // F1b: the item reads each bus it writes, so the bus's release follows it.
  SmallVector<RailId, 8> allReads(reads.begin(), reads.end());
  for (auto [b, top] : d.buses)
    if (!is_contained(allReads, b))
      allReads.push_back(b);
  for (RailId r : allReads) {
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

namespace cq {
// U6 (cq-arch 2026-11-01): stub until stream A builds it.
// U6: the group's item is placed like a QRAM load reading v_k (A2 versionBefore): after POP(j) of every
// store recorded on the bus later (j > k), before POP(k) and the bus's release.
void Uncompute::noteCallBusRead(llvm::CallInst *fwd, RailId bus) {
  Impl &I = *impl;
  unsigned rec = I.callRecord(fwd);
  if (rec == kNone || I.info[rec].kind != RecKind::Call)
    internalError("uncompute: noteCallBusRead before recordCall of this clone call", fwd);
  RailId lead = I.records[rec].out;
  if (bus >= I.rails.size() || !I.rails[bus].qram || I.isMerge(bus))
    internalError("uncompute: noteCallBusRead of a rail that is not a single QRAM bus", fwd);
  if (!is_contained(I.info[rec].reads, bus))
    internalError("uncompute: noteCallBusRead of a bus the clone call does not take", fwd);
  for (auto [b, k] : I.rails[lead].versions)
    if (b == bus)
      internalError("uncompute: noteCallBusRead twice for one bus", fwd);
  I.rails[lead].versions.push_back({bus, static_cast<unsigned>(I.rails[bus].pops.size())});
  I.rails[bus].loads.push_back(lead);
}
} // namespace cq
