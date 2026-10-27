// cq::unimplemented and cq::internalError (scaffold). The type helpers of Common.h are the abi
// module's (pass/lib/abi/).
#include "cq/Common.h"

#include "llvm/ADT/Twine.h"
#include "llvm/IR/Value.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

namespace {
[[noreturn]] void fail(llvm::StringRef prefix, llvm::StringRef what, const llvm::Value *at) {
  std::string msg;
  llvm::raw_string_ostream os(msg);
  os << prefix << what;
  if (at)
    os << "\n  at: " << *at;
  // No crash diagnostics: a clean non-zero exit. opt removes its output file on the way out.
  llvm::report_fatal_error(llvm::Twine(os.str()), /*gen_crash_diag=*/false);
}
} // namespace

namespace cq {
void unimplemented(llvm::StringRef what, const llvm::Value *at) { fail("cq: unimplemented: ", what, at); }
void internalError(llvm::StringRef what, const llvm::Value *at) { fail("cq: internal error: ", what, at); }
} // namespace cq
