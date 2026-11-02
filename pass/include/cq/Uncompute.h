// Frozen interface (cq-arch, with owner amendments A2 and A4 of 2026-10-27 and freeze beads cq-k1w, cq-bq0 (U1),
// cq-fx3s (F1), M3, U2, M3b and F1b (cq-arch 2026-11-01)).
// Changes only under cq-arch's freeze rule.
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
enum class Role : uint8_t { Garbage, Seed, UserRegister, Result, Output, Measured, Frozen, Tape, Abort,
                            KeptOverflow, Escaped, KeptEntangled };
// A2: a record is a template or a core gate (QRAM store/load, controlled copy, xorc).
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
  // M3 (cq-arch 2026-11-01, CR rules 5, 20): load (a new-IR load of a slot cell's handle) names at run
  // time one of mayName (recorded, unfreed rails the stores may have left in the cell). A merge (U1)
  // over those arms: never resolved itself; a use of it is a use of every arm; a barrier on it binds
  // every arm; a kept role on it keeps every arm. mayName empty is an internal error.
  RailId recordCellLoad(llvm::Instruction *load, llvm::ArrayRef<RailId> mayName);
  // M3b (cq-arch 2026-11-01, CR rules 5, 20): loadA and loadB are two new-IR loads of slot cells
  // (recordCellLoad loads or user-register loads) that read provably different cells of one object with
  // no store of a pre-existing handle into the object between them: at run time they name different
  // rails (one rail per cell, cq-dr4o), so a non-diagonal gate on one is no AliasHit on a record reading
  // the other. mem-slots calls it for each such pair it lowers. M3c (cq-arch 2026-11-01, 114): loadB may
  // instead be a fresh rail mem-slots stored into another cell than loadA's after loadA, with no handle
  // of the object ever moved between its cells: loadA never names it either.
  void noteCellsDistinct(llvm::Instruction *loadA, llvm::Instruction *loadB);
  // U2 (cq-arch 2026-11-01, CR §1.4, rules 18, 27): the result rails of one clone call fwd, undone
  // together by its twin. outs: one handle per quantum result field in field order (fwd itself for a
  // single i32 result, else extractvalues of fwd); slotOuts: handles the caller loaded from cells the
  // clone wrote (freed by the item, not passed); extra: twin operands after fwd's arguments. Each out
  // and slotOut is a new rail, Role::Garbage. The item follows every use of every out and slotOut and
  // emits <callee>_unc(outs..., fwd args..., extra...), then cqrt_free of each out and slotOut. Every
  // one kept: nothing emitted; some kept and some not: unimplemented. Returns outs' ids, then slotOuts'.
  // cq-necw (CR rules 6, 18): a group of one slotOut and no out that a rule 6 clean-up cleans (cleanupBijective,
  // the new content of a cell an _inv<c> cleans) has no twin: its item is that clean-up.
  llvm::SmallVector<RailId, 4> recordCall(llvm::CallInst *fwd, llvm::ArrayRef<llvm::Value *> outs,
                                          llvm::ArrayRef<llvm::Value *> slotOuts, llvm::ArrayRef<Operand> extra);
  // U7 (cq-r8-d, CR rule 27 Pointers; 190): fwd is a void declared clone call that may overwrite cells
  // of caller objects passed as triples with handles it minted; extra (classical) is one snapshot pointer
  // per marked object. Returns a pseudo rail (no handle of its own): its item emits
  // <callee>_unc(fwd args..., extra...) and frees nothing. The item follows every use of a cell load
  // recorded over the pseudo (recordCellLoad: a read of a cell the clone may have written) and precedes
  // the items of the rails the call reads (its footprint, noteCallReads). A kept role on such a load
  // keeps its other arms; the pseudo stays pending (the twin always runs). Inside an open scope:
  // unimplemented.
  RailId recordDeclaredWrites(llvm::CallInst *fwd, llvm::ArrayRef<Operand> extra);
  // cq-i9wk (CR rule 19): the last n extra operands of fwd's call group (recordCall) are the registers a kept
  // clone returned after its results; its twin takes them first: <callee>_unc(those n..., outs..., fwd
  // args..., the other extra...).
  void noteCallExtraFirst(llvm::CallInst *fwd, unsigned n);
  // U4 (cq-arch 2026-11-01, CR rule 5): rails in caller cells a clone call reads (its twin
  // recompute-reads them): the call group's item reads them, so their own items follow it.
  void noteCallReads(llvm::CallInst *fwd, llvm::ArrayRef<RailId> rails);
  // U5 (cq-arch 2026-11-01, CR rule 5): emits before P the items of the listed pending rails. P is
  // dominated by each rail's definition and every use and reader item of each lies before P on every
  // path; otherwise an internal error.
  void resolveAt(llvm::Instruction *P, llvm::ArrayRef<RailId> rails);
  // U6 (cq-arch 2026-11-01, CR rules 5, 18, §1.3): the call group of fwd (recordCall made) reads QRAM bus
  // `bus` as it is now, version k = the stores recorded on it so far (its twin recompute-reads it): its item
  // follows POP(j) of every store recorded on bus after this note and precedes POP(k) and the bus's release,
  // as a QRAM load reading v_k (A2). Consumer: mem-qram noteCalleeQramStores.
  void noteCallBusRead(llvm::CallInst *fwd, RailId bus);
  RailId idOf(llvm::Value *handle) const;
  void setRole(RailId, Role);
  // U7 (cq-g1ty, CR rule 7; 129): the role of a rail not yet uncomputed or freed anywhere, else nullopt.
  std::optional<Role> liveRole(RailId) const;
  void noteUse(RailId, llvm::Instruction *consumer);
  void noteNonDiagonal(RailId target, llvm::Instruction *gate);
  // U9 (cq-c969, CR rules 5, 17): may `gate` (noted by noteNonDiagonal, directly or as an alias hit not
  // ruled out by M3b) hit a rail `handle` may name at run time? false for a value that is no recorded rail.
  bool mayHit(const llvm::Value *handle, const llvm::Instruction *gate) const;
  void cleanupBijective(RailId oldRail, const abi::TemplateSpec &inverse, llvm::ArrayRef<Operand>);
  // cq-mgkr (CR rule 6, dead on one classical path only; ruling cq-mzqo): oldRail is dead where the classical
  // i1 `guard` holds (the path on which a classical merge chose its bijective image) and cleaned there as
  // cleanupBijective cleans it; on the paths where no such guard holds its item is its plain one (its records
  // undone, a seed freed, nothing for a kept role). Called once per such path; never with cleanupBijective.
  // everyPath: the guards of all the calls for oldRail cover every path (no plain part).
  void cleanupBijectiveUnder(RailId oldRail, llvm::Value *guard, const abi::TemplateSpec &inverse,
                             llvm::ArrayRef<Operand>, bool everyPath = false);
  // U8 (cq-xivx, CR rule 18, §1.4 _inv<c>): rule 6 clean-up of oldRail through a call: its item emits
  // inv(args..., old handle) (inv's calling convention) and then frees oldRail. The handles of args and
  // alsoReads are the clean-up's reads (as cleanupBijective's operands: placement, barriers, pruning).
  void cleanupByCall(RailId oldRail, llvm::Function *inv, llvm::ArrayRef<Operand> args,
                     llvm::ArrayRef<llvm::Value *> alsoReads);
  // cq-p8r6 (CR rules 6, 18): a dead old cell rail a clone call overwrote whose clean-up (_inv<c>) is not
  // built for its shape. Registered as cleanupByCall would be (same reads, so pruned exactly when the call's
  // twin runs and restores the cell); a clean-up that survives to be placed stops with
  // unimplemented(what, at) instead of keeping the old rail silently.
  void cleanupUnbuilt(RailId oldRail, const std::string &what, const llvm::Instruction *at,
                      llvm::ArrayRef<llvm::Value *> alsoReads);
  void flushBefore(llvm::Instruction *point);       // due _unc + cqrt_free, reverse dependency order
  // U7 (cq-nqa6, CR rules 5, 8, 9): flushBefore, and also, before P, the item of each arm-local rail (defined
  // in a block that does not dominate P, every use and reader item before P, every path from its block
  // reaching P) under its block's selector, and each deferred item that is then ready, to a fixed point.
  // liveLater: the handles an instruction lowered after P may still read (the caller's contract).
  void flushBefore(llvm::Instruction *point, llvm::ArrayRef<llvm::Value *> *liveLater);
  void flushAtExit(llvm::ReturnInst *);
  unsigned openScope(); void closeScope(unsigned);
  llvm::ArrayRef<Record> scopeRecords(unsigned) const;
  void emitMirror(unsigned scope, llvm::IRBuilder<> &);
  // F1 (freeze bead cq-fx3s, CR rule 14): a deferred item, the reverse loop of a classically bounded
  // loop placed after the readers of the loop's exit values. The rails created by records of `scopes`
  // are owned by the item (no flush resolves them; emit mirrors them); exitRails (owned) are read after
  // the loop; reads are the rails the item reads (not owned). emit is called once, with the builder at
  // the end of a fresh unterminated block, and leaves it at the end of an unterminated block.
  // F1b (cq-arch 2026-11-01, CR rule 14, §1.3): a QRAM store record in the item's scopes makes the item
  // a writer of that bus: the item follows POP(j) of every store recorded on the bus after the item's
  // scopes closed and the un-copy of every load of the bus made after them, and precedes the bus's
  // release (cqrt_qram_free); exitRails may be empty when the scopes hold such a store and the bus has
  // a use after the loop (the placement anchors are then those uses).
  // F2 (cq-arch 2026-11-01, CR rules 5, 14; 176): hostScopes, the scopes of an enclosing rule-14 region
  // whose trip the item runs in (a trip-local sub-loop's reverse): their pending records do not keep the
  // item from a local placement inside that region (they are the region's own, undone by its reverse).
  // busUseFollows (F1c, 72, 188): exitRails is empty and a bus an owned store writes has a use after the
  // loop in the original program that is not lowered yet (the loop is lowered before it); the uses anchor
  // the item once they exist.
  void recordDeferred(llvm::ArrayRef<unsigned> scopes, llvm::ArrayRef<RailId> exitRails,
                      std::function<void(llvm::IRBuilder<> &)> emit, llvm::ArrayRef<RailId> reads,
                      llvm::ArrayRef<unsigned> hostScopes = {}, bool busUseFollows = false);
  // K1: storage owned by module uncompute.
private:
  struct Impl; std::shared_ptr<Impl> impl;
};
}
