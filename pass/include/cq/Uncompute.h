// Frozen interface (cq-arch, with owner amendments A2 and A4 of 2026-10-27 and freeze bead cq-k1w).
// Changes only under cq-arch's freeze rule.
#pragma once

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
  // K1: storage owned by module uncompute.
private:
  struct Impl; std::shared_ptr<Impl> impl;
};
}
