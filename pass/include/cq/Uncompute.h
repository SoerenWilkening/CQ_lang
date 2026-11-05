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
  // out and emits <callee>_unc(outs..., fwd args..., extra...), then cqrt_free of each out. Every one kept: nothing
  // emitted; some kept and some not: unimplemented. Returns outs' ids. Rule 18: loadsBus: the callee loads from the
  // bus, so the results are loads for rule 5: the twin runs before the next version change on every path or the
  // results are KEPT and no twin is called.
  llvm::SmallVector<RailId, 4> recordCall(llvm::CallInst *fwd, llvm::ArrayRef<llvm::Value *> outs,
                                          llvm::ArrayRef<Operand> extra, bool loadsBus = false);
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
  // Rule 5 sentence 3: the value rail (a seed included) and the control rail of a kept store are kept: Role::Kept,
  // never resolved; a load copy that is the value rail is Role::Overtaken (un-copied, not freed) per rule 5.
  void noteKeptStore(llvm::CallInst *store, llvm::Value *value, llvm::Value *ctl);
  // Rule 2/10: a load copy a rotation acted on, or that is measured: never un-copied, Role::Frozen / Role::Measured.
  void freezeLoadCopy(RailId);
  // U5 (cq-arch 2026-11-01, CR rule 5): emits before P the items of the listed pending rails. P is
  // dominated by each rail's definition and every use and reader item of each lies before P on every
  // path; otherwise an internal error.
  void resolveAt(llvm::Instruction *P, llvm::ArrayRef<RailId> rails);
  RailId idOf(llvm::Value *handle) const;
  void setRole(RailId, Role);
  // cq-gujb (CR rules 5, 9, 20): a rail a construction will read again after flushes the walker places before
  // that read (a clone cell's value, read by the cell's later accesses): no flush resolves it until unpin.
  void pin(RailId);
  void unpin(RailId);
  // U7 (cq-g1ty, CR rule 7; 129): the role of a rail not yet uncomputed or freed anywhere, else nullopt.
  std::optional<Role> liveRole(RailId) const;
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
  // cq-5n3n (CR rule 17, rule 5): right after closeInvert(end), the items of the rails the closed region made
  // and nothing pending reads any more, unless keep(handle), are placed before end; returns their handles
  // (a later reader recomputes them after end).
  llvm::SmallVector<llvm::Value *, 8> resolveRegionMade(llvm::Instruction *end,
                                                        llvm::function_ref<bool(llvm::Value *)> keep);
  unsigned openScope(); void closeScope(unsigned);
  llvm::ArrayRef<Record> scopeRecords(unsigned) const;
  void emitMirror(unsigned scope, llvm::IRBuilder<> &);
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
