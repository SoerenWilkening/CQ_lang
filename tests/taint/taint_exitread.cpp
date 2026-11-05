// cq-1v3i: a value defined in a loop whose next trip is decided by a tainted terminator (rule 14) is,
// read outside that loop, the exit value merged over the quantum exit trip: quantum whatever reads
// it (a later phi, a select, a direct use, a return, a store, a call actual, a branch condition),
// also from an inner loop whose own exit is classical. Inside the loop the classical-bound case
// (case 3) keeps the driving phis classical, and an address computed after the loop from the trip
// index stays classical-offset (121).
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

@g = global i32 0

; The bead's repro (exitphi.c): a classical bound with a quantum exit; the loaded value is read
; after the loop by a phi, a select and an add, its address by a GEP.
define i32 @exitphi(i32 %x0, double %th, i32 %cap, i32 %c, ptr %tab) {
entry:
  %q = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  %capx = sext i32 %cap to i64
  br label %loop
loop:
  %i = phi i64 [ %i1, %loop ], [ 0, %entry ]
  %p = getelementptr inbounds i32, ptr %tab, i64 %i
  %x = load i32, ptr %p, align 4
  %i1 = add nuw nsw i64 %i, 1
  %more = icmp slt i64 %i1, %capx
  %ne = icmp ne i32 %q, %x
  %go = and i1 %more, %ne
  br i1 %go, label %loop, label %after
after:
  %cc = icmp eq i32 %c, 0
  tail call void @ext()
  br i1 %cc, label %t, label %join
t:
  tail call void @ext()
  br label %join
join:
  %r = phi i32 [ 7, %t ], [ %x, %after ]
  %s = select i1 %cc, i32 %x, i32 3
  %a = add i32 %x, 1
  %ep = getelementptr inbounds i32, ptr %tab, i64 %i1
  %ev = load i32, ptr %ep, align 4
  %m = tail call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; The trip index returned, stored, passed and branched on after the loop.
define i64 @exitret(i32 %x0, double %th, i64 %cap, ptr %tab) {
entry:
  %q = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  br label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %i1, %loop ]
  %i1 = add nuw nsw i64 %i, 1
  %more = icmp slt i64 %i1, %cap
  %p = getelementptr inbounds i32, ptr %tab, i64 %i1
  %x = load i32, ptr %p, align 4
  %ne = icmp ne i32 %q, %x
  %go = and i1 %more, %ne
  br i1 %go, label %loop, label %after
after:
  store i32 %x, ptr @g, align 4
  %u = tail call i32 @use(i32 %x)
  %big = icmp sgt i32 %x, 3
  br i1 %big, label %arm, label %done
arm:
  tail call void @ext()
  br label %done
done:
  ret i64 %i1
}

define internal i32 @use(i32 %v) {
  %w = add i32 %v, 1
  ret i32 %w
}

; An inner loop with a classical exit inside an outer loop with a quantum exit: the inner value read
; after the outer loop is the outer loop's exit value.
define i32 @nested(i32 %x0, double %th, i32 %n, ptr %tab) {
entry:
  %q = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  br label %outer
outer:
  %o = phi i32 [ 0, %entry ], [ %o1, %olatch ]
  br label %inner
inner:
  %j = phi i32 [ 0, %outer ], [ %j1, %inner ]
  %acc = phi i32 [ %o, %outer ], [ %acc1, %inner ]
  %acc1 = add i32 %acc, %j
  %j1 = add i32 %j, 1
  %idone = icmp eq i32 %j1, %n
  br i1 %idone, label %olatch, label %inner
olatch:
  %o1 = add i32 %o, 1
  %omore = icmp slt i32 %o1, %n
  %one = icmp ne i32 %q, %acc1
  %ogo = and i1 %omore, %one
  br i1 %ogo, label %outer, label %after
after:
  %r = add i32 %acc1, 1
  ret i32 %r
}

; Contrast: a loop with a classical exit; its value read after it stays classical.
define i32 @classical_exit(i32 %x0, double %th, i32 %n) {
entry:
  %q = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %i1 = add i32 %i, 1
  %done = icmp eq i32 %i1, %n
  br i1 %done, label %after, label %loop
after:
  %r = add i32 %i1, 1
  %y = add i32 %r, %q
  ret i32 %y
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @ext()
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
    Err.print("taint_exitread", errs());
    return 2;
  }
  cq::TaintInfo T = cq::computeTaint(*M, {});

  // Case 3: the bound's phi and the per-trip load stay classical inside the loop; the exit value is
  // quantum in every reader after it; the address after the loop stays classical-offset (121), its
  // load is the exit value.
  Function &E = *M->getFunction("exitphi");
  expectQ(T, E,
          {{"i", false}, {"x", true}, {"i1", false}, {"more", false}, {"go", true},
           {"r", true}, {"s", true}, {"a", true}, {"ev", true}});

  Function &R = *M->getFunction("exitret");
  expectQ(T, R, {{"i", false}, {"i1", false}, {"x", true}, {"big", true}, {"u", true}});
  if (const cq::Specialization *S = entryOf(T, &R)) {
    CHECK(T.resultQuantum(*S, 0), "@exitret returns the exit trip index: quantum");
    CHECK(T.controlTainted(blk(R, "arm"), *S), "@exitret %arm is chosen by the exit value");
    const cq::Specialization *U =
        T.calleeSpecialization(*cast<CallBase>(named(R, "u")), *S);
    CHECK(U, "@exitret: no specialization for the call of @use");
    if (U)
      CHECK(T.isQuantum(named(*M->getFunction("use"), "w"), *U),
            "@use called with the exit value: its formal is quantum");
  }

  Function &N = *M->getFunction("nested");
  expectQ(T, N, {{"j", false}, {"j1", false}, {"r", true}});

  Function &C = *M->getFunction("classical_exit");
  expectQ(T, C, {{"i", false}, {"i1", false}, {"r", false}, {"y", true}});

  outs() << "taint_exitread: " << checks << " checks, " << failures << " failures\n";
  return failures ? 1 : 0;
}
