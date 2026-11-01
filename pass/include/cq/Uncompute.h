// Frozen interface (cq-arch, with owner amendments A2 and A4 of 2026-10-27 and freeze beads cq-k1w, cq-bq0 (U1),
// cq-fx3s (F1), M3, U2, M3b and F1b (cq-arch 2026-11-01)).
// Changes only under cq-arch's freeze rule.
#pragma once

#include <functional>
#include <memory>
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
  // the other. mem-slots calls it for each such pair it lowers.
  void noteCellsDistinct(llvm::Instruction *loadA, llvm::Instruction *loadB);
  // U2 (cq-arch 2026-11-01, CR §1.4, rules 18, 27): the result rails of one clone call fwd, undone
  // together by its twin. outs: one handle per quantum result field in field order (fwd itself for a
  // single i32 result, else extractvalues of fwd); slotOuts: handles the caller loaded from cells the
  // clone wrote (freed by the item, not passed); extra: twin operands after fwd's arguments. Each out
  // and slotOut is a new rail, Role::Garbage. The item follows every use of every out and slotOut and
  // emits <callee>_unc(outs..., fwd args..., extra...), then cqrt_free of each out and slotOut. Every
  // one kept: nothing emitted; some kept and some not: unimplemented. Returns outs' ids, then slotOuts'.
  llvm::SmallVector<RailId, 4> recordCall(llvm::CallInst *fwd, llvm::ArrayRef<llvm::Value *> outs,
                                          llvm::ArrayRef<llvm::Value *> slotOuts, llvm::ArrayRef<Operand> extra);
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
  void noteUse(RailId, llvm::Instruction *consumer);
  void noteNonDiagonal(RailId target, llvm::Instruction *gate);
  void cleanupBijective(RailId oldRail, const abi::TemplateSpec &inverse, llvm::ArrayRef<Operand>);
  void flushBefore(llvm::Instruction *point);       // due _unc + cqrt_free, reverse dependency order
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
