// cq-wxch: a loop exit test written with the negated-condition selects -O1 emits, select c, t, true
// (!c | t) and select c, false, f (!c & f), or with xor x, true (!x), has its classical disjunct
// (rule 14 case 3): the counter stays classical, as spine's loops::classify reads it (cq-dtvp).
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

static const char *IR = R"(
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; The bead's repro (tests/spine/probes/blocked/exit_select_negated.ll): exit on
; select(i + 1 < n, q, true), i.e. !(i + 1 < n) | q.
define i32 @sel_or(i32 %x0, double %t, i32 %n) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %v = phi i32 [ %x, %entry ], [ %v1, %loop ]
  %v1 = add i32 %v, 1
  %i1 = add nuw nsw i32 %i, 1
  %c = icmp slt i32 %i1, %n
  %q = icmp eq i32 %v1, 7
  %e = select i1 %c, i1 %q, i1 true
  br i1 %e, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %v1)
  ret i32 %m
}

; Stay on select(i + 1 >= n, false, q), i.e. !(i + 1 >= n) & q (exit on false).
define i32 @sel_and(i32 %x0, double %t, i32 %n) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %v = phi i32 [ %x, %entry ], [ %v1, %loop ]
  %v1 = add i32 %v, 1
  %i1 = add nuw nsw i32 %i, 1
  %c = icmp sge i32 %i1, %n
  %q = icmp ne i32 %v1, 7
  %go = select i1 %c, i1 false, i1 %q
  br i1 %go, label %loop, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %v1)
  ret i32 %m
}

; Exit on xor(and(i + 1 < n, q), true) and on xor(true, ...), i.e. !(more & q).
define i32 @xor_not(i32 %x0, double %t, i32 %n) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %v = phi i32 [ %x, %entry ], [ %v1, %loop ]
  %v1 = add i32 %v, 1
  %i1 = add nuw nsw i32 %i, 1
  %c = icmp slt i32 %i1, %n
  %q = icmp ne i32 %v1, 7
  %go = and i1 %c, %q
  %e = xor i1 true, %go
  br i1 %e, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %v1)
  ret i32 %m
}

; Contrast: select(c, q, true) exiting on false gives no forcing leaf (exit needs c & !q).
define i32 @sel_or_wrong_polarity(i32 %x0, double %t, i32 %n) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %v = phi i32 [ %x, %entry ], [ %v1, %loop ]
  %v1 = add i32 %v, 1
  %i1 = add nuw nsw i32 %i, 1
  %c = icmp slt i32 %i1, %n
  %q = icmp eq i32 %v1, 7
  %e = select i1 %c, i1 %q, i1 true
  br i1 %e, label %loop, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %v1)
  ret i32 %m
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
)";

static Instruction *named(Function &F, StringRef n) {
  for (Instruction &I : instructions(F))
    if (I.getName() == n)
      return &I;
  errs() << "no instruction %" << n << " in @" << F.getName() << "\n";
  std::exit(2);
}

static BasicBlock *blk(Function &F, StringRef n) {
  for (BasicBlock &B : F)
    if (B.getName() == n)
      return &B;
  errs() << "no block " << n << " in @" << F.getName() << "\n";
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

int main() {
  LLVMContext Ctx;
  SMDiagnostic Err;
  std::unique_ptr<Module> M = parseAssemblyString(IR, Err, Ctx);
  if (!M) {
    Err.print("taint_exitselect", errs());
    return 2;
  }
  cq::TaintInfo T = cq::computeTaint(*M, {});

  // Rule 14 case 3: the counter and the classical disjunct stay classical, the carried value and
  // the exit test are quantum.
  for (const char *f : {"sel_or", "sel_and", "xor_not"})
    expectQ(T, *M->getFunction(f),
            {{"i", false}, {"i1", false}, {"c", false}, {"v", true}, {"v1", true}, {"q", true}});
  // No classical disjunct forces the exit (K cutoff): the carried value is quantum, the counter an
  // affine induction, classical in the loop (CR rule 14 at f981c89, cq-rmaf).
  expectQ(T, *M->getFunction("sel_or_wrong_polarity"), {{"i", false}, {"v", true}});

  outs() << "taint_exitselect: " << checks << " checks, " << failures << " failures\n";
  return failures ? 1 : 0;
}
