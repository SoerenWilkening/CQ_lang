// Frozen interface (cq-arch, with owner amendments A2 and A4 of 2026-10-27 and freeze beads cq-k1w, cq-bq0 (U1),
// cq-fx3s (F1), M3 and U2 (cq-arch 2026-11-01)).
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
  void recordDeferred(llvm::ArrayRef<unsigned> scopes, llvm::ArrayRef<RailId> exitRails,
                      std::function<void(llvm::IRBuilder<> &)> emit, llvm::ArrayRef<RailId> reads);
  // K1: storage owned by module uncompute.
private:
  struct Impl; std::shared_ptr<Impl> impl;
};
}
