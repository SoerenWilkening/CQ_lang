// cq-tzqz (108): llvm.threadlocal.address(@g) is the base of @g's one object (rule 24, one thread):
// TaintInfo::objectOf answers @g's object for it (mem-slots roots a slot access there), and the
// object is a slot when a quantum value is stored through it.
#include "cq/Taint.h"

#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

static int failures = 0, checks = 0;
#define CHECK(c, msg)                                                                              \
  do {                                                                                             \
    ++checks;                                                                                      \
    if (!(c)) {                                                                                    \
      ++failures;                                                                                  \
      errs() << "FAIL " << __LINE__ << ": " << msg << "\n";                                        \
    }                                                                                              \
  } while (0)

static const char *IR = R"(
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tl = internal thread_local global i32 0, align 4

define i32 @f(i32 %x0, double %th) {
  %q = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  %a = tail call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @tl)
  store i32 %q, ptr %a, align 4
  %l = load i32, ptr %a, align 4
  %m = tail call i32 @cq_measure_si32(i32 %l)
  ret i32 %m
}

declare ptr @llvm.threadlocal.address.p0(ptr)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
)";

int main() {
  LLVMContext Ctx;
  SMDiagnostic Err;
  std::unique_ptr<Module> M = parseAssemblyString(IR, Err, Ctx);
  if (!M) {
    Err.print("taint_threadlocal", errs());
    return 2;
  }
  Function &F = *M->getFunction("f");
  cq::TaintInfo T = cq::computeTaint(*M, {});
  const cq::Specialization *S = nullptr;
  for (const cq::Specialization &s : T.specializations())
    if (s.F == &F && s.isEntry())
      S = &s;
  CHECK(S, "no entry specialization of @f");
  if (!S)
    return 1;
  Instruction *addr = nullptr, *ld = nullptr;
  for (Instruction &I : instructions(F)) {
    if (I.getName() == "a")
      addr = &I;
    if (I.getName() == "l")
      ld = &I;
  }
  GlobalVariable *G = M->getNamedGlobal("tl");
  cq::ObjectId og = T.objectOf(G);
  CHECK(T.objectOf(addr) == og, "objectOf(threadlocal.address(@tl)) is @tl's object");
  CHECK(T.classOf(og) == cq::ObjClass::Slot, "@tl holds a handle: a slot object");
  auto prov = T.provenance(addr, *S);
  CHECK(prov.size() == 1 && prov[0] == og, "provenance of the address is @tl's object");
  CHECK(!T.isQuantum(addr, *S), "the address is classical");
  CHECK(T.isQuantum(ld, *S), "the load through it reads the handle");
  outs() << "taint_threadlocal: " << (checks - failures) << "/" << checks << " checks pass\n";
  return failures ? 1 : 0;
}
