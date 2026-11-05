// cq-0ia: TaintInfo answers 'classical' for every value of the analysed module that no taint fact
// reached (an instruction, including one in an unreachable block, an argument, a constant, a
// global), and a value created after computeTaint is still an internal error (owner ruling on
// cq-5k5). The internal error exits the process, so that case runs in a forked child.
#include <cstdio>
#include <string>
#include <sys/wait.h>
#include <unistd.h>

#include "cq/Taint.h"

#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/IRBuilder.h"
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

@g = global i32 7

define i32 @f(i32 %x0, double %th, i32 %c) {
entry:
  %q = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  %y = add nsw i32 %q, %c
  %m = tail call i32 @cq_measure_si32(i32 %y)
  %z = icmp eq i32 %c, 0
  %gv = load i32, ptr @g
  %s = select i1 %z, i32 %gv, i32 %c
  %r = add i32 %m, %s
  ret i32 %r
dead:
  %d = mul i32 %c, 3
  ret i32 %d
}

define i32 @plain(i32 %a) {
  %b = shl i32 %a, 1
  ret i32 %b
}

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

static const cq::Specialization *entryOf(const cq::TaintInfo &T, const Function *F) {
  for (const cq::Specialization &S : T.specializations())
    if (S.F == F && S.isEntry())
      return &S;
  return nullptr;
}

int main() {
  LLVMContext Ctx;
  SMDiagnostic Err;
  std::unique_ptr<Module> M = parseAssemblyString(IR, Err, Ctx);
  if (!M) {
    Err.print("taint_lookup", errs());
    return 2;
  }
  Function &F = *M->getFunction("f");
  cq::TaintInfo T = cq::computeTaint(*M, {});
  const cq::Specialization *S = entryOf(T, &F);
  CHECK(S, "no in-place specialization of @f");
  if (!S)
    return 1;

  // The quantum values stay quantum.
  CHECK(T.isQuantum(named(F, "q"), *S), "%q (cq_theta result) quantum");
  CHECK(T.isQuantum(named(F, "y"), *S), "%y quantum");
  // Classical instructions no taint fact touched answer 'classical', not an internal error.
  for (const char *n : {"m", "z", "d"}) {
    CHECK(!T.isQuantum(named(F, n), *S), "%" << n << " classical");
    auto fm = T.fieldMask(named(F, n), *S);
    CHECK(fm.size() == 1 && !fm[0], "%" << n << " fieldMask {0}");
  }
  // Rule 3: every load is a bus load and its result a rail, the values computed from it too.
  for (const char *n : {"gv", "s", "r"})
    CHECK(T.isQuantum(named(F, n), *S), "%" << n << " quantum (a bus load)");
  // Arguments, a constant, a global.
  CHECK(!T.isQuantum(F.getArg(0), *S), "%x0 classical");
  CHECK(!T.isQuantum(F.getArg(2), *S), "%c classical");
  CHECK(!T.isQuantum(ConstantInt::get(Type::getInt32Ty(Ctx), 3), *S), "i32 3 classical");
  CHECK(!T.isQuantum(M->getNamedGlobal("g"), *S), "@g classical");
  // A function with no taint at all: its values answer 'classical' too, when it has a
  // specialization.
  Function &P = *M->getFunction("plain");
  CHECK(!T.isTainted(P), "@plain not tainted");
  if (const cq::Specialization *SP = entryOf(T, &P)) {
    CHECK(!T.isQuantum(P.getArg(0), *SP), "@plain %a classical");
    CHECK(!T.isQuantum(named(P, "b"), *SP), "@plain %b classical");
  }

  // A value created after computeTaint has no answer: an internal error (cq-5k5), in a child.
  {
    IRBuilder<> B(named(F, "r"));
    Value *late = B.CreateAdd(F.getArg(2), B.getInt32(1), "late");
    int pfd[2];
    if (pipe(pfd) != 0)
      return 2;
    fflush(nullptr);
    pid_t pid = fork();
    if (pid == 0) {
      dup2(pfd[1], 2);
      close(pfd[0]);
      close(pfd[1]);
      (void)T.isQuantum(late, *S);
      _exit(0); // reached only when the lookup answered
    }
    close(pfd[1]);
    std::string out;
    char buf[512];
    ssize_t k;
    while ((k = read(pfd[0], buf, sizeof buf)) > 0)
      out.append(buf, size_t(k));
    close(pfd[0]);
    int status = 0;
    waitpid(pid, &status, 0);
    bool exitedNonZero = WIFEXITED(status) && WEXITSTATUS(status) != 0;
    CHECK(exitedNonZero, "a value created after computeTaint still errors (status " << status << ")");
    CHECK(out.find("cq: internal error: taint: no taint answer for this value (cq-5k5)") !=
              std::string::npos,
          "the child's message names cq-5k5; got: " << out);
  }

  outs() << "taint_lookup: " << (checks - failures) << "/" << checks << " checks pass\n";
  return failures ? 1 : 0;
}
