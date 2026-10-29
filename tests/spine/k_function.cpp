// Unit test of LoweringContext::K(const llvm::Function &) (cq-x2lh): the K of a function, which may
// be a declaration (rule 27's trailing K of a declared clone), resolved as K(const Loop *) is
// (CLAUDE.md "K per loop": per-function flag, CQ_K's `__cq_k_<f>`, global flag, default 4).
#include <cstdio>
#include <string>

#include "cq/Loops.h"
#include "cq/Lowering.h"
#include "cq/Taint.h"

#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

static const char *IR = R"(
@__cq_k_ext_k = internal constant i32 9
@__cq_k_def_k = internal constant i32 7
declare i32 @ext(i32)
declare i32 @ext_k(i32)
define i32 @def(i32 %x) {
  ret i32 %x
}
define i32 @def_k(i32 %x) {
  ret i32 %x
}
)";

int main() {
  LLVMContext C;
  SMDiagnostic err;
  auto M = parseAssemblyString(IR, err, C);
  if (!M) {
    err.print("spine_k_function", errs());
    return 1;
  }
  cq::TaintInfo T = cq::computeTaint(*M, cq::TaintOptions{});
  int failures = 0;
  auto check = [&](const char *what, const cq::loops::KOptions &KO, const char *fn, unsigned want) {
    cq::Specialization S{M->getFunction("def"), "0"};
    cq::LoweringContext ctx(*M, T, S, KO);
    unsigned got = ctx.K(*M->getFunction(fn));
    if (got != want) {
      ++failures;
      std::fprintf(stderr, "FAIL %s: K(@%s) = %u, want %u\n", what, fn, got, want);
    }
  };
  cq::loops::KOptions none, global, perFn;
  global.global = 11;
  perFn.global = 11;
  perFn.perFunction = {{"ext", 5}, {"ext_k", 6}, {"def_k", 8}};
  // default 4
  check("default", none, "ext", 4);
  check("default", none, "def", 4);
  // CQ_K over the default, on a declaration and a definition
  check("cq_k", none, "ext_k", 9);
  check("cq_k", none, "def_k", 7);
  // the global flag below CQ_K, above the default
  check("global", global, "ext", 11);
  check("global", global, "def", 11);
  check("global", global, "ext_k", 9);
  // the per-function flag over everything
  check("flag", perFn, "ext", 5);
  check("flag", perFn, "ext_k", 6);
  check("flag", perFn, "def_k", 8);
  check("flag", perFn, "def", 11);
  if (failures)
    return 1;
  std::printf("spine_k_function: ok\n");
  return 0;
}
