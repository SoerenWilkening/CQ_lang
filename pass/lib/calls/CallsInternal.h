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
// replaced the originals), its table clones by symbol, and whether each one's twin leaves the results allocated (§1.4).
struct TableRow {
  std::string fn;
  llvm::FunctionType *type;
  std::string forward, ctl;
  bool forwardKeepsResults = false, ctlKeepsResults = false;
  bool forwardPopsMints = false, ctlPopsMints = false;   // the twin pops a count of handles (§1.4, rulings3 F)
};
// Rule 19: the registers the clone's twin takes (Calls.cpp mintSites), recorded when it is materialized. The forward's code of a
// rotation carries !cq.mint with its index; a table clone's pushes !cq.mint.push. A call of a callee that rotates carries
// !cq.mint.call {first index, 1 when it is the callee's own symbol}; a void one !cq.mint.drop (a twin does not repeat it).
unsigned mintCount(const llvm::Function &clone);
std::vector<TableRow> takeTableRows(const llvm::Module &);
// The LLVM function type as a private C string (§1.3 `sig`), one per type.
llvm::Constant *sigString(llvm::Module &, llvm::FunctionType *);
// §1.4: @__cq_act_<fn>, internal i32 0.
llvm::GlobalVariable *activationCounter(llvm::Module &, llvm::StringRef fn);
} // namespace cq::calls
