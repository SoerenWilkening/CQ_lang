// Private to pass/lib/calls: what Calls.cpp and Finalize.cpp share of the clone table (rule 19, §1.3, §1.4).
#pragma once

#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Module.h"

#include <string>
#include <vector>

namespace cq::calls {
// One row of the module's clone table: the function's name and C function type (read before the lowered own symbols
// replaced the originals), its table clones by symbol, and whether their twins leave the results allocated (§1.4).
struct TableRow {
  std::string fn;
  llvm::FunctionType *type;
  std::string forward, ctl;
  bool keepsResults = false;
};
std::vector<TableRow> takeTableRows(const llvm::Module &);
// The LLVM function type as a private C string (§1.3 `sig`), one per type.
llvm::Constant *sigString(llvm::Module &, llvm::FunctionType *);
// §1.4: @__cq_act_<fn>, internal i32 0.
llvm::GlobalVariable *activationCounter(llvm::Module &, llvm::StringRef fn);
} // namespace cq::calls
