#pragma once

#include <functional>
#include <memory>
#include <optional>
#include <variant>

#include "cq/Abi.h"
#include "cq/Common.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

// Uncompute.h  (rules 5, 6, 7)
namespace cq {
using RailId = unsigned;
// A4: KeptEntangled, a garbage rail a non-diagonal gate made uncleanable; live at exit, counted in Kept.
// Kept: a kept rail a rule names (rules 5, 8, 14, 16, 18). Overtaken: a load copy un-copied and not freed (rule 5).
enum class Role : uint8_t { Garbage, Seed, UserRegister, Result, Output, Measured, Frozen, Tape, Abort,
                            KeptOverflow, Escaped, KeptEntangled, Kept, Overtaken };
// A2: a record is a template or a core gate (controlled copy, xorc).
struct Record { llvm::CallInst *forward; std::variant<abi::TemplateSpec, abi::CoreSpec> spec; llvm::SmallVector<Operand, 3> ops; RailId out; };
class Uncompute {
public:
  Uncompute();
  RailId recordTemplate(llvm::CallInst *fwd, const abi::TemplateSpec &, llvm::ArrayRef<Operand>);
  // A2
  RailId recordCore(llvm::CallInst *fwd, const abi::CoreSpec &, llvm::ArrayRef<Operand>, RailId out);
  RailId recordSeed(llvm::CallInst *alloc);
  RailId recordExternal(llvm::Value *handle, Role);
  // U1 (freeze bead cq-bq0, CR rule 9 at a58c3a4): a classical select or a complete phi whose every
  // value operand is a recorded rail; its handle is an alias (idOf works), never freed itself.
  RailId recordMerge(llvm::Instruction *merged);
  // U2 (CR §1.4, rules 18, 27): the result rails of one clone call fwd, undone together by its twin. outs: one handle
  // per quantum result field in field order (fwd itself for a single i32 result, else extractvalues of fwd); extra:
  // twin operands after fwd's arguments. Each out is a new rail, Role::Garbage. The item follows every use of every
  // out and emits <callee>_unc(outs..., extra..., fwd args...), then cqrt_free of each out. Every one kept: nothing
  // emitted; some kept and some not: unimplemented. Returns outs' ids. Rule 18: loadsBus: the callee loads from the
  // bus, so the results are loads for rule 5: the twin runs before the next version change on every path or the
  // results are KEPT and no twin is called.
  llvm::SmallVector<RailId, 4> recordCall(llvm::CallInst *fwd, llvm::ArrayRef<llvm::Value *> outs,
                                          llvm::ArrayRef<Operand> extra, bool loadsBus = false);
  // Rule 18, §1.4: fwd calls an own symbol; its twin is spelled `name` (the all-zero mask's _unc), not after the callee.
  void noteTwinName(llvm::CallInst *fwd, llvm::StringRef name);
  // Rules 19, 27: the results of a table clone call: its twin zeroes and frees them (the caller frees none), called once
  // after their last use. widths: each out's rail type (from the C result type), used where a kept result is copied
  // out before the twin (cq-j2r0j).
  void recordTableCall(llvm::CallInst *fwd, llvm::ArrayRef<llvm::Value *> outs, llvm::ArrayRef<RailType> widths);
  // Rule 18: the rail r is a result of a call of a clone that loads from the bus: its twin runs after the last consumer
  // and before the next version change on every path; where that change comes first r is KEPT and no twin is called.
  void noteLoadsBus(RailId r);
  // Rule 5 sentence 1: `load` is a new-IR cqrt_qram_load_<W>[_hl][_controlled] whose operands are ops ([c,] m, addr).
  // Item: the same call's _unc(h, ops...) right after the last reader (last consumer and its _unc; before a
  // measurement of the consumer), then cqrt_free(h) iff no version change (noteVersionChange) lies between the load
  // and that point on any path; otherwise un-copied, not freed (Role::Overtaken, kept). Address-rail operands are
  // readers of this item (their own items follow it).
  RailId recordBusLoad(llvm::CallInst *load, llvm::ArrayRef<Operand> ops);
  // A memory version change at new-IR point `at` (bus store, in-place swap pair, __cq_alloc, effect entry, host call
  // not memory(none|read), a call of a function that writes memory). Orders load items: an item placed after it frees
  // nothing.
  void noteVersionChange(llvm::Instruction *at);
  // The original block whose instruction is being lowered: rule 18 asks the program's paths, not the new IR's order.
  void noteSourceBlock(const llvm::BasicBlock *bb);
  // cq-jws5r (CR rules 8, 14): `join` ends a classical arm of a rule-14 trip: a conditional branch enters the arm
  // or the empty block `skip`, both end at `join`, and the arm's blocks are entered through that branch only. A run
  // flag whose events the arm does not reach is read across it without a walk (no other effect).
  void noteClassicalArm(llvm::BasicBlock *join, llvm::BasicBlock *skip);
  // cq-bqbty (CR rule 6 in a classically bounded loop): the next flushBefore at a point in `block` takes `rail` (a
  // carried value's header phi, whose clean-up reads its update) as if it were defined there: its update lies past a
  // classical join of the trip, in a later segment than the header's. Every anchor of the rail must lie in `block`.
  void flushIn(RailId rail, llvm::BasicBlock *block);
  // The same for these rails alone at `point` (a local flush of them only): their block is no segment's last.
  void flushRailsBefore(llvm::ArrayRef<RailId> rails, llvm::Instruction *point);
  // Rule 5 sentence 3: the value rail (a seed included) and the control rail of a kept store are kept: Role::Kept,
  // never resolved. Rule 5 sentence 1: a load copy that is the value rail is never un-copied, Role::Kept too.
  void noteKeptStore(llvm::CallInst *store, llvm::Value *value, llvm::Value *ctl);
  // A rule-14 header phi over handles whose rails the reverse loop undoes (no rule 6 register): a kept store of it reads a copy.
  void noteCarried(llvm::Value *phi);
  // Rule 8 (cq-5aus): the IR's flag g when `flag` is the false-edge rail of g, |0> then not_i1, xor_i1(g) and nothing
  // since, and g still holds that value; else nullptr. A kept store under it keeps g, not the negation: the store
  // reads g inside a closed X bracket and the kept rail holds the IR's SSA value (rule 5, 51, 55, 109).
  llvm::Value *negatedAtomOf(llvm::Value *flag) const;
  // Rule 2/10: a load copy a rotation acted on, or that is measured: never un-copied, Role::Frozen / Role::Measured.
  void freezeLoadCopy(RailId);
  // U5 (cq-arch 2026-11-01, CR rule 5): emits before P the items of the listed pending rails. P is
  // dominated by each rail's definition and every use and reader item of each lies before P on every
  // path; otherwise an internal error.
  void resolveAt(llvm::Instruction *P, llvm::ArrayRef<RailId> rails);
  RailId idOf(llvm::Value *handle) const;
  // Is the handle a recorded rail? A bus cell's load rail rotated in place, say, is not.
  bool recorded(const llvm::Value *handle) const;
  void setRole(RailId, Role);
  // Does the rail `from` hold a function of the rail `y`, through its records (control rails included), its in-place
  // writes and a merge's arms? false when either is no recorded rail.
  bool railDependsOn(const llvm::Value *from, const llvm::Value *y) const;
  // cq-gujb (CR rules 5, 9, 20): a rail a construction will read again after flushes the walker places before
  // that read (a clone cell's value, read by the cell's later accesses): no flush resolves it until unpin.
  void pin(RailId);
  void unpin(RailId);
  // U7 (cq-g1ty, CR rule 7; 129): the role of a rail not yet uncomputed or freed anywhere, else nullopt.
  std::optional<Role> liveRole(RailId) const;
  // Is the rail, or an arm of the merge it is, an exit rail of a deferred item (recordDeferred)? Its reverse must still
  // read it, so it cannot escape.
  bool deferredExit(RailId) const;
  // Rule 6 (204): a merge of kept rails becomes one rail of its own, Role::Garbage, which a clean-up may then clean; its
  // arms keep their roles.
  void mergeToRail(RailId);
  void noteUse(RailId, llvm::Instruction *consumer);
  void noteNonDiagonal(RailId target, llvm::Instruction *gate);
  // U9 (cq-c969, CR rules 5, 17): may `gate` (noted by noteNonDiagonal) hit a rail `handle` may name at run time? false
  // for a value that is no recorded rail.
  bool mayHit(const llvm::Value *handle, const llvm::Instruction *gate) const;
  void cleanupBijective(RailId oldRail, const abi::TemplateSpec &inverse, llvm::ArrayRef<Operand>);
  // cq-mgkr (CR rule 6, dead on one classical path only; ruling cq-mzqo): oldRail is dead where the classical
  // i1 `guard` holds (the path on which a classical merge chose its bijective image) and cleaned there as
  // cleanupBijective cleans it; on the paths where no such guard holds its item is its plain one (its records
  // undone, a seed freed, nothing for a kept role). Called once per such path; never with cleanupBijective.
  // everyPath: the guards of all the calls for oldRail cover every path (no plain part).
  void cleanupBijectiveUnder(RailId oldRail, llvm::Value *guard, const abi::TemplateSpec &inverse,
                             llvm::ArrayRef<Operand>, bool everyPath = false);
  // cq-2p9g (CR rule 6, the composite update): withdraws oldRail's unguarded clean-up while nothing has placed it yet;
  // false (nothing changed) otherwise.
  bool withdrawCleanup(RailId oldRail);
  // Has a rule 6 clean-up (cleanupBijective or cleanupBijectiveUnder) been requested for oldRail?
  bool hasCleanup(RailId oldRail) const;
  void flushBefore(llvm::Instruction *point);       // due _unc + cqrt_free, reverse dependency order
  // U7 (cq-nqa6, CR rules 5, 8, 9): flushBefore, and also, before P, the item of each arm-local rail (defined
  // in a block that does not dominate P, every use and reader item before P, every path from its block
  // reaching P) under its block's selector, and each deferred item that is then ready, to a fixed point.
  // liveLater: the handles an instruction lowered after P may still read (the caller's contract).
  void flushBefore(llvm::Instruction *point, llvm::ArrayRef<llvm::Value *> *liveLater);
  void flushAtExit(llvm::ReturnInst *);
  // cq-4593 (cq-arch 2026-11-02, CR rule 17): begin/end are the new-IR cqrt_invert_begin/_end calls of one
  // cq_invert region. No flush places the item of a rail pending at openInvert until closeInvert, which
  // notes end as a use of each that gained a use or reader inside the region (its item follows the end
  // marker); the others are placed after their last earlier anchor. Nested pairs nest; a closeInvert with
  // no open region (the begin was another function's) does nothing.
  void openInvert(llvm::Instruction *begin);
  void closeInvert(llvm::Instruction *end);
  // cq-037u2 (CR rule 17 with rule 14): is a cq_invert region of this lowering open (openInvert with no closeInvert yet)?
  bool invertOpen() const;
  // cq-5n3n (CR rule 17, rule 5): right after closeInvert(end), the items of the rails the closed region made
  // and nothing pending reads any more, unless keep(handle), are placed before end; returns their handles
  // (a later reader recomputes them after end).
  llvm::SmallVector<llvm::Value *, 8> resolveRegionMade(llvm::Instruction *end,
                                                        llvm::function_ref<bool(llvm::Value *)> keep);
  unsigned openScope(); void closeScope(unsigned);
  llvm::ArrayRef<Record> scopeRecords(unsigned) const;
  // Is a mirror being emitted? A deferred reverse placed in one runs in the scope's own reverse, under no guard of its own.
  bool mirroring() const;
  void emitMirror(unsigned scope, llvm::IRBuilder<> &);
  // CR rules 5, 14: a rail created by a record of the scope in a block the region (from `head`) does not reach (the flag
  // seed a predicate read in the region mints on an edge into a join above it) runs once, not per trip: it leaves the
  // scope, so neither its mirror nor a deferred item over the scope resolves it; a flush does, like any rail of its block.
  void leaveScope(unsigned scope, const llvm::BasicBlock *head);
  bool leftScope(unsigned scope, const llvm::Value *handle) const;
  // F1 (freeze bead cq-fx3s, CR rule 14): a deferred item, the reverse loop of a classically bounded
  // loop placed after the readers of the loop's exit values. The rails created by records of `scopes`
  // are owned by the item (no flush resolves them; emit mirrors them); exitRails (owned) are read after
  // the loop; reads are the rails the item reads (not owned). emit is called once, with the builder at
  // the end of a fresh unterminated block, and leaves it at the end of an unterminated block.
  // F2 (cq-arch 2026-11-01, CR rules 5, 14; 176): hostScopes, the scopes of an enclosing rule-14 region
  // whose trip the item runs in (a trip-local sub-loop's reverse): their pending records do not keep the
  // item from a local placement inside that region (they are the region's own, undone by its reverse).
  void recordDeferred(llvm::ArrayRef<unsigned> scopes, llvm::ArrayRef<RailId> exitRails,
                      std::function<void(llvm::IRBuilder<> &)> emit, llvm::ArrayRef<RailId> reads,
                      llvm::ArrayRef<unsigned> hostScopes = {});
  // K1: storage owned by module uncompute.
private:
  struct Impl; std::shared_ptr<Impl> impl;
};
}
