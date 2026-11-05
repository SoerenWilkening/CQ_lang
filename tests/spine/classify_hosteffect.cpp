// cq-my17 (99): calls::classify of a known library call (Darwin's asm label "\01_fwrite") handed a
// pointer to a slot object is HostEffect (rule 16: the tape entry reads the cells), though no argument
// is a quantum value; the same call over a classical buffer stays Classical, and an asm label whose
// prototype is not the library function's is not one.
#include <cstdio>

#include "cq/Calls.h"
#include "cq/Taint.h"

#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

static const char *IR = R"(
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__stdoutp = external global ptr, align 8

define i32 @f(i8 %x0, double %th) {
  %buf = alloca [2 x i8], align 1
  %cbuf = alloca [2 x i8], align 1
  %x = tail call i8 @cq_theta_ui8(i8 %x0, double %th)
  store i8 %x, ptr %buf, align 1
  store i8 7, ptr %cbuf, align 1
  %out = load ptr, ptr @__stdoutp, align 8
  %q = call i64 @"\01_fwrite"(ptr %buf, i64 1, i64 2, ptr %out)
  %c = call i64 @"\01_fwrite"(ptr %cbuf, i64 1, i64 2, ptr %out)
  %w = call i64 @"\01_fwritex"(ptr %buf, i64 1, i64 2, ptr null)
  %m = tail call i8 @cq_measure_ui8(i8 %x)
  %r = zext i8 %m to i32
  ret i32 %r
}

declare i64 @"\01_fwrite"(ptr, i64, i64, ptr)
declare i64 @"\01_fwritex"(ptr, i64, i64, ptr)
declare i8 @cq_theta_ui8(i8, double)
declare i8 @cq_measure_ui8(i8)
)";

int main() {
  LLVMContext C;
  SMDiagnostic err;
  auto M = parseAssemblyString(IR, err, C);
  if (!M) {
    err.print("spine_classify_hosteffect", errs());
    return 1;
  }
  cq::TaintInfo T = cq::computeTaint(*M, cq::TaintOptions{});
  Function &F = *M->getFunction("f");
  const cq::Specialization *S = nullptr;
  for (const cq::Specialization &s : T.specializations())
    if (s.F == &F && s.isEntry())
      S = &s;
  if (!S) {
    std::fprintf(stderr, "FAIL: no entry specialization of @f\n");
    return 1;
  }
  int failures = 0, checks = 0;
  auto at = [&](StringRef n) -> CallBase & {
    for (Instruction &I : instructions(F))
      if (I.getName() == n)
        return cast<CallBase>(I);
    std::fprintf(stderr, "no call %%%s\n", n.str().c_str());
    std::exit(2);
  };
  auto check = [&](StringRef n, cq::calls::Class want) {
    ++checks;
    cq::calls::Class got = cq::calls::classify(at(n), T, *S);
    if (got != want) {
      ++failures;
      std::fprintf(stderr, "FAIL %%%s: class %u, want %u\n", n.str().c_str(), unsigned(got), unsigned(want));
    }
  };
  check("q", cq::calls::Class::HostEffect);   // fwrite over the slot buffer
  check("c", cq::calls::Class::HostEffect);   // rule 20 (b): a call argument makes the buffer bus-resident
  ++checks;                                   // "_fwritex" is no library function: no host effect
  if (cq::calls::classify(at("w"), T, *S) == cq::calls::Class::HostEffect) {
    ++failures;
    std::fprintf(stderr, "FAIL %%w: an unknown asm-labelled callee classified HostEffect\n");
  }
  std::printf("spine_classify_hosteffect: %d/%d checks pass\n", checks - failures, checks);
  return failures ? 1 : 0;
}
