// cq-prvy (95, 109): clang -O1's va_arg expansion reads the variadic actuals through the va_list's
// reg_save_area / overflow_arg_area pointers. llvm.va_start names one save-area object of the frame
// whose cells hold handles when a variadic actual is quantum (CR §1.4, rules 3, 20); va_copy copies
// the va_list's area pointers. The va_arg loads and the clone's result are quantum.
#include <cstdlib>

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

// sum2(n, ...) reads two ints through ap (the register save area, as -O1 writes va_arg) and one
// through a va_copy of ap.
static const char *IR = R"(
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%va = type { i32, i32, ptr, ptr }

define i32 @top(i32 %x0, double %th, i32 %a) {
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  %r = tail call i32 (i32, ...) @sum2(i32 1, i32 %a, i32 %x)
  %c = tail call i32 (i32, ...) @sum2(i32 1, i32 %a, i32 %a)
  %s = add i32 %r, %c
  %m = tail call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}

define internal i32 @sum2(i32 %n, ...) noinline {
  %ap = alloca [1 x %va], align 16
  %bp = alloca [1 x %va], align 16
  call void @llvm.va_start.p0(ptr %ap)
  call void @llvm.va_copy.p0(ptr %bp, ptr %ap)
  %gp = load i32, ptr %ap, align 16
  %rsa.p = getelementptr inbounds i8, ptr %ap, i64 16
  %rsa = load ptr, ptr %rsa.p, align 16
  %off = zext i32 %gp to i64
  %slot0 = getelementptr i8, ptr %rsa, i64 %off
  %v0 = load i32, ptr %slot0, align 4
  %off1 = add i64 %off, 8
  %slot1 = getelementptr i8, ptr %rsa, i64 %off1
  %v1 = load i32, ptr %slot1, align 4
  %ofa.p = getelementptr inbounds i8, ptr %bp, i64 8
  %ofa = load ptr, ptr %ofa.p, align 8
  %v2 = load i32, ptr %ofa, align 4
  %brsa.p = getelementptr inbounds i8, ptr %bp, i64 16
  %brsa = load ptr, ptr %brsa.p, align 16
  %v3 = load i32, ptr %brsa, align 4
  call void @llvm.va_end.p0(ptr %bp)
  call void @llvm.va_end.p0(ptr %ap)
  %s0 = add i32 %v0, %v1
  %s1 = add i32 %s0, %v2
  %s = add i32 %s1, %v3
  ret i32 %s
}

declare void @llvm.va_start.p0(ptr)
declare void @llvm.va_copy.p0(ptr, ptr)
declare void @llvm.va_end.p0(ptr)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
)";

static Instruction *named(Function &F, StringRef n) {
  for (Instruction &I : instructions(F))
    if (I.getName() == n)
      return &I;
  errs() << "no instruction %" << n << "\n";
  std::exit(2);
}

int main() {
  LLVMContext Ctx;
  SMDiagnostic Err;
  std::unique_ptr<Module> M = parseAssemblyString(IR, Err, Ctx);
  if (!M) {
    Err.print("taint_varargs", errs());
    return 2;
  }
  Function &Top = *M->getFunction("top"), &Sum = *M->getFunction("sum2");
  cq::TaintInfo T = cq::computeTaint(*M, {});
  const cq::Specialization *E = nullptr, *Q = nullptr;
  for (const cq::Specialization &s : T.specializations()) {
    if (s.F == &Top && s.isEntry())
      E = &s;
    if (s.F == &Sum && s.mask == "001")
      Q = &s;
  }
  CHECK(E, "no entry specialization of @top");
  CHECK(Q, "no clone of @sum2 with mask 001 (per call-site arity, the third actual quantum)");
  if (!E || !Q)
    return 1;
  CHECK(T.isQuantum(named(Top, "r"), *E), "the call with a quantum vararg returns a quantum value");
  for (const char *v : {"v0", "v1", "v2", "v3", "s"})
    CHECK(T.isQuantum(named(Sum, v), *Q), "%" << v << " (a va_arg read) quantum in the 001 clone");
  for (const char *v : {"gp", "off", "rsa", "ofa", "brsa", "slot0"})
    CHECK(!T.isQuantum(named(Sum, v), *Q), "%" << v << " (va_list bookkeeping) classical");
  auto prov = T.provenance(named(Sum, "slot0"), *Q);
  CHECK(prov.size() == 1 && T.classOf(prov[0]) == cq::ObjClass::Slot,
        "the register save area is one slot object");
  auto prov2 = T.provenance(named(Sum, "ofa"), *Q);
  CHECK(prov2.size() == 1 && prov.size() == 1 && prov2[0] == prov[0],
        "the copied overflow area pointer points into the same save-area object");
  outs() << "taint_varargs: " << (checks - failures) << "/" << checks << " checks pass\n";
  return failures ? 1 : 0;
}
