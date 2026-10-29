// cq-cvwx: CR rules 16 and 27. A call of a body-less function is a host effect (rule 16) only by its
// attributes and semantics, never by name: a library function the target knows whose call may act
// beyond its pointer arguments (writes other memory such as errno or a stream, may throw, may not
// return). A known function whose only writes go through its pointer arguments (frexp, modf:
// memory(argmem: write)) computes into the caller's memory, so with a quantum argument it is a
// declared clone (rule 27) like any other body-less callee, and every object it may write through a
// pointer argument holds a handle after the call (rule 3 through memory and calls). A pointer the
// call only reads leaves its object as it was.
#include <cstdio>
#include <string>

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

// The attributes are what clang 19 -O1 gives these declarations for x86_64-apple-macosx (the bead's
// repro frexp.c, and modf/remquo/strtol compiled the same way).
static const char *IR = R"(
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; frexp.c: frexp(q, &e) with q quantum.
define double @f_frexp(double %x0) {
  %e = alloca i32, align 4
  %q = tail call double @cq_theta_f64(double %x0, double 1.000000e+00)
  %m = call double @frexp(double %q, ptr nonnull %e)
  %ei = load i32, ptr %e, align 4
  %ed = sitofp i32 %ei to double
  %r = fadd double %m, %ed
  ret double %r
}

; modf(q, &ip): memory(argmem: write) as frexp.
define double @f_modf(double %x0) {
  %ip = alloca double, align 8
  %q = tail call double @cq_theta_f64(double %x0, double 1.000000e+00)
  %fr = call double @modf(double %q, ptr nonnull %ip)
  %i = load double, ptr %ip, align 8
  %r = fadd double %fr, %i
  ret double %r
}

; frexp with a classical argument: an ordinary call, the object stays classical.
define double @f_frexp_classical(double %x0, double %t) {
  %e = alloca i32, align 4
  %m = call double @frexp(double %x0, ptr nonnull %e)
  %ei = load i32, ptr %e, align 4
  %q = tail call i32 @cq_theta_si32(i32 %ei, double %t)
  %qd = sitofp i32 %q to double
  %r = fadd double %m, %qd
  ret double %r
}

; remquo: memory(write), it may write memory beyond its arguments: a host effect.
define double @f_remquo(double %x0, double %y) {
  %qu = alloca i32, align 4
  %q = tail call double @cq_theta_f64(double %x0, double 1.000000e+00)
  %r = call double @remquo(double %q, double %y, ptr nonnull %qu)
  ret double %r
}

; strtol of a string holding a handle: no memory attribute (errno), a host effect.
define i64 @f_strtol(i8 %c, ptr %endp) {
  %s = alloca [2 x i8], align 1
  %q = tail call signext i8 @cq_theta_si8(i8 %c, double 1.000000e+00)
  store i8 %q, ptr %s, align 1
  %s1 = getelementptr inbounds i8, ptr %s, i64 1
  store i8 0, ptr %s1, align 1
  %v = call i64 @strtol(ptr nonnull %s, ptr %endp, i32 10)
  ret i64 %v
}

; An unknown body-less function that only reads its pointer argument: a declared clone that writes
; nothing.
define i32 @f_reader(i32 %x0) {
  %b = alloca i32, align 4
  store i32 7, ptr %b, align 4
  %q = tail call i32 @cq_theta_si32(i32 %x0, double 1.000000e+00)
  %r = call i32 @ext_read(i32 %q, ptr nonnull %b)
  %l = load i32, ptr %b, align 4
  %s = add i32 %r, %l
  ret i32 %s
}

declare double @cq_theta_f64(double, double)
declare i32 @cq_theta_si32(i32, double)
declare i8 @cq_theta_si8(i8, double)
declare double @frexp(double noundef, ptr nocapture noundef) #0
declare double @modf(double noundef, ptr nocapture noundef) #0
declare double @remquo(double noundef, double noundef, ptr nocapture noundef) #1
declare i64 @strtol(ptr noundef readonly, ptr nocapture noundef, i32 noundef) #2
declare i32 @ext_read(i32, ptr nocapture readonly) #3

attributes #0 = { mustprogress nofree nounwind willreturn memory(argmem: write) }
attributes #1 = { mustprogress nofree nounwind willreturn memory(write) }
attributes #2 = { mustprogress nofree nounwind willreturn }
attributes #3 = { mustprogress nofree nounwind willreturn memory(argmem: read) }
)";

static Instruction *named(Function &F, StringRef n) {
  for (Instruction &I : instructions(F))
    if (I.getName() == n)
      return &I;
  errs() << "no instruction %" << n << " in @" << F.getName() << "\n";
  std::exit(2);
}

static const cq::Specialization *entryOf(const cq::TaintInfo &T, const Function *F) {
  for (const cq::Specialization &S : T.specializations())
    if (S.F == F && S.isEntry())
      return &S;
  return nullptr;
}

static void expectQ(const cq::TaintInfo &T, Function &F,
                    std::initializer_list<std::pair<const char *, bool>> want) {
  const cq::Specialization *S = entryOf(T, &F);
  CHECK(S, "no entry specialization of @" << F.getName());
  if (!S)
    return;
  for (auto &[n, w] : want)
    CHECK(T.isQuantum(named(F, n), *S) == w,
          "@" << F.getName() << " %" << n << ": quantum " << !w << ", want " << w);
}

// The call's callee specialization: a declared clone of the callee (rule 27), or none.
static const cq::Specialization *callee(const cq::TaintInfo &T, Function &F, StringRef call) {
  const cq::Specialization *S = entryOf(T, &F);
  if (!S)
    return nullptr;
  return T.calleeSpecialization(*cast<CallBase>(named(F, call)), *S);
}

static cq::ObjClass classOfAlloca(const cq::TaintInfo &T, Function &F, StringRef n) {
  return T.classOf(T.objectOf(named(F, n)));
}

int main() {
  LLVMContext Ctx;
  SMDiagnostic Err;
  std::unique_ptr<Module> M = parseAssemblyString(IR, Err, Ctx);
  if (!M) {
    Err.print("taint_libwriter", errs());
    return 2;
  }
  cq::TaintInfo T = cq::computeTaint(*M, {});

  for (const char *fn : {"f_frexp", "f_modf"}) {
    Function &F = *M->getFunction(fn);
    const char *call = std::string(fn) == "f_frexp" ? "m" : "fr";
    const char *slot = std::string(fn) == "f_frexp" ? "e" : "ip";
    const char *load = std::string(fn) == "f_frexp" ? "ei" : "i";
    const cq::Specialization *C = callee(T, F, call);
    CHECK(C, "@" << fn << ": an argmem-only writer with a quantum argument is a declared clone (rule 27)");
    if (C) {
      CHECK(C->F->isDeclaration() && !C->isEntry(), "@" << fn << ": the clone is of the body-less callee");
      CHECK(C->mask.size() == 4 && C->mask[0] == '1',
            "@" << fn << ": mask " << C->mask << ", want 1 then the pointer's three digits");
    }
    expectQ(T, F, {{call, true}, {load, true}, {"r", true}});
    CHECK(classOfAlloca(T, F, slot) == cq::ObjClass::Slot,
          "@" << fn << " %" << slot << ": written by the declared clone, holds a handle (slot)");
  }

  {
    Function &F = *M->getFunction("f_frexp_classical");
    CHECK(!callee(T, F, "m"), "@f_frexp_classical: no quantum argument, an ordinary call");
    expectQ(T, F, {{"m", false}, {"ei", false}, {"q", true}});
    CHECK(classOfAlloca(T, F, "e") == cq::ObjClass::Classical, "@f_frexp_classical %e: classical memory");
  }
  {
    Function &F = *M->getFunction("f_remquo");
    CHECK(!callee(T, F, "r"), "@f_remquo: memory(write) may act beyond its arguments: a host effect");
    CHECK(classOfAlloca(T, F, "qu") == cq::ObjClass::Classical, "@f_remquo %qu: a host effect writes no handle");
  }
  {
    Function &F = *M->getFunction("f_strtol");
    CHECK(!callee(T, F, "v"), "@f_strtol: no memory attribute (errno): a host effect");
  }
  {
    Function &F = *M->getFunction("f_reader");
    CHECK(callee(T, F, "r"), "@f_reader: an unknown body-less callee with a quantum argument is a declared clone");
    expectQ(T, F, {{"r", true}, {"l", false}});
    CHECK(classOfAlloca(T, F, "b") == cq::ObjClass::Classical,
          "@f_reader %b: a readonly pointer argument leaves the object classical");
  }

  outs() << "taint_libwriter: " << checks << " checks, " << failures << " failures\n";
  return failures ? 1 : 0;
}
