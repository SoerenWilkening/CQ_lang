// cq-41y3: CR rule 2, "dominated uses of the measured SSA value denote the outcome" and "a value
// computed only from measured rails and classical values is classical ... a merge under such a flag
// is a classical select". A read of a measured value at a point its cq_measure_* call dominates is
// classical: a compare and the branch or select on it (the bead's repros meas.c, meas2.c, meas3.c),
// a later phi edge, a store, a call actual. A read the measurement does not dominate keeps its taint,
// and a rule 14 exit read (quantum exit trip) stays quantum. A value computed from the register
// before its measurement is not decided here (cq-r6bc).
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

; meas.c: a branch on the measured register, a phase and a value arm under it.
define i32 @meas(i32 %x0, double %th, i32 %y0, double %t2) {
entry:
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  %m = tail call i32 @cq_measure_si32(i32 %x)
  %c = icmp sgt i32 %x, 3
  br i1 %c, label %arm, label %join
arm:
  tail call void @cq_phi(double 4.000000e-01)
  %y9 = add nsw i32 %y0, 9
  br label %join
join:
  %y = phi i32 [ %y9, %arm ], [ %y0, %entry ]
  %z3 = mul nsw i32 %y, 3
  %z = add nsw i32 %z3, %m
  %zq = tail call i32 @cq_theta_si32(i32 %z, double %t2)
  %r = tail call i32 @cq_measure_si32(i32 %zq)
  ret i32 %r
}

; meas3.c: a select on the measured register; the register stored, passed and returned after it.
define i32 @meas3(i32 %x0, double %th, i32 %y0, i32 %k) {
entry:
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  %m = tail call i32 @cq_measure_si32(i32 %x)
  %c = icmp sgt i32 %x, 3
  %y = select i1 %c, i32 %y0, i32 %k
  store i32 %x, ptr @g, align 4
  %u = tail call i32 @use(i32 %x)
  %z = tail call i32 @cq_theta_si32(i32 %y0, double 5.000000e-01)
  %s = add nsw i32 %z, %y
  %r = tail call i32 @cq_measure_si32(i32 %s)
  %r2 = add nsw i32 %r, %u
  ret i32 %r2
}

define i32 @use(i32 %w) {
  %w1 = add i32 %w, 1
  ret i32 %w1
}

; Measured in one arm of a classical branch: reads in that arm are classical, a phi edge from it is
; classical, a phi edge and a read the measurement does not dominate keep the taint.
define i32 @partial(i32 %x0, double %th, i32 %k) {
entry:
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  %ck = icmp sgt i32 %k, 0
  br i1 %ck, label %a, label %b
a:
  %m = tail call i32 @cq_measure_si32(i32 %x)
  %ia = add i32 %x, 1
  br label %join
b:
  br label %join
join:
  %p = phi i32 [ %x, %a ], [ 5, %b ]
  %pq = phi i32 [ %x, %a ], [ %x, %b ]
  %after = add i32 %x, 2
  %s = add i32 %p, %pq
  %r = tail call i32 @cq_measure_si32(i32 %s)
  ret i32 %r
}

; Measured inside a loop whose exit is quantum: in the trip after the measurement the read is
; classical; read after the loop it is the exit value merged over the quantum exit trip (rule 14).
define i32 @inloop(i32 %x0, double %th, i32 %q0) {
entry:
  %q = tail call i32 @cq_theta_si32(i32 %q0, double %th)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %v = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  %m = tail call i32 @cq_measure_si32(i32 %v)
  %w = add i32 %v, 2
  %i1 = add nuw nsw i32 %i, 1
  %go = icmp ne i32 %q, %i1
  br i1 %go, label %loop, label %out
out:
  %e = add i32 %v, 1
  ret i32 %e
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)
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
    Err.print("taint_measured", errs());
    return 2;
  }
  cq::TaintInfo T = cq::computeTaint(*M, {});

  // The register itself stays a rail; its compare after the measurement is classical, so the arm is
  // classical control (the phase in it is a global phase, rule 12) and the merge is a classical phi.
  Function &A = *M->getFunction("meas");
  expectQ(T, A, {{"x", true}, {"m", false}, {"c", false}, {"y", false}, {"z", false}, {"zq", true}});
  if (const cq::Specialization *S = entryOf(T, &A)) {
    CHECK(!T.controlTainted(blk(A, "arm"), *S), "@meas %arm: chosen by a measured value");
    CHECK(!T.controlTainted(blk(A, "join"), *S), "@meas %join");
  }

  Function &B = *M->getFunction("meas3");
  expectQ(T, B, {{"c", false}, {"y", false}, {"z", true}, {"s", true}, {"u", false}});
  if (const cq::Specialization *S = entryOf(T, &B)) {
    const cq::Specialization *U = T.calleeSpecialization(*cast<CallBase>(named(B, "u")), *S);
    // An untainted callee is an ordinary call of the original (no specialization).
    CHECK(!U, "@meas3: @use called with the measured register is not a quantum clone");
    CHECK(!T.isTainted(*M->getFunction("use")), "@use: called only with classical actuals");
  }

  Function &P = *M->getFunction("partial");
  expectQ(T, P, {{"ia", false}, {"p", false}, {"pq", true}, {"after", true}, {"s", true}});

  Function &L = *M->getFunction("inloop");
  expectQ(T, L, {{"go", true}, {"w", false}, {"e", true}});

  outs() << "taint_measured: " << checks << " checks, " << failures << " failures\n";
  return failures ? 1 : 0;
}
