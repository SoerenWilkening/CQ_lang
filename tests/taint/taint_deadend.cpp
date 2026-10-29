// cq-820w: an edge into a dead end (no return reachable: a noreturn call + unreachable, or a bare
// unreachable) does not restrict its siblings for control dependence (CR rule 16: after a noreturn
// arm the program continues uncontrolled). The dead end itself stays control dependent on the
// branch into it; a phi whose incoming edge only a dead-end branch "chooses" is not quantum.
// Witnesses 45 (both functions), 49 (the switch join), 22 (both joins, cq-fv9n), 108 trap_q, plus synthetic shapes.
#include <cstdio>
#include <string>

#include "cq/Taint.h"
#include "../../pass/lib/taint/DeadEnd.h"

#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
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

; A phi whose incoming edge from %m is "chosen" only by a branch whose other arm aborts: classical.
define i32 @phi_after_abort(i32 %a, double %th, i32 %k) {
entry:
  %x = tail call i32 @cq_theta_si32(i32 %a, double %th)
  %c0 = icmp eq i32 %a, 0
  br i1 %c0, label %m, label %j
m:
  %c1 = icmp sgt i32 %x, %k
  br i1 %c1, label %die, label %j
die:
  tail call void @abort()
  unreachable
j:
  %p = phi i32 [ 1, %entry ], [ 2, %m ]
  %r = add i32 %p, %x
  ret i32 %r
}

; Contrast: both arms live, the phi is chosen by the quantum branch.
define i32 @phi_both_live(i32 %a, double %th, i32 %k) {
entry:
  %x = tail call i32 @cq_theta_si32(i32 %a, double %th)
  %c1 = icmp sgt i32 %x, %k
  br i1 %c1, label %t, label %j
t:
  br label %j
j:
  %p = phi i32 [ 1, %entry ], [ 2, %t ]
  %r = add i32 %p, %x
  ret i32 %r
}

; A loop whose body may abort on a quantum condition: the latch and the loop's exit are uncontrolled.
define i32 @loop_abort(i32 %a, double %th, i32 %n) {
entry:
  %x = tail call i32 @cq_theta_si32(i32 %a, double %th)
  br label %h
h:
  %i = phi i32 [ 0, %entry ], [ %i1, %latch ]
  %c = icmp eq i32 %x, %i
  br i1 %c, label %die, label %latch
die:
  tail call void @abort()
  unreachable
latch:
  %i1 = add i32 %i, 1
  %d = icmp slt i32 %i1, %n
  br i1 %d, label %h, label %exit
exit:
  ret i32 %i1
}

; Nested: the abort under q2 inside the q1 arm. The q1 arm's continuation stays dependent on q1
; only; the join is uncontrolled; the dead region (a classical branch to two noreturn calls) is
; dependent on both.
define i32 @nested(i32 %a, double %th, i32 %k, i32 %c) {
entry:
  %x = tail call i32 @cq_theta_si32(i32 %a, double %th)
  %q1 = icmp sgt i32 %x, %k
  br i1 %q1, label %arm, label %join
arm:
  %q2 = icmp eq i32 %x, %c
  br i1 %q2, label %dead, label %cont
dead:
  %cc = icmp eq i32 %c, 0
  br i1 %cc, label %d1, label %d2
d1:
  tail call void @abort()
  unreachable
d2:
  tail call void @exit(i32 1)
  unreachable
cont:
  %y = add i32 %x, 1
  br label %join
join:
  %p = phi i32 [ %y, %cont ], [ %x, %entry ]
  ret i32 %p
}

declare i32 @cq_theta_si32(i32, double)
declare void @abort() noreturn nounwind
declare void @exit(i32) noreturn nounwind
)";

static BasicBlock *blk(Function &F, StringRef n) {
  for (BasicBlock &B : F) {
    std::string s;
    raw_string_ostream os(s);
    B.printAsOperand(os, false);
    if (B.getName() == n || os.str() == ("%" + n).str())
      return &B;
  }
  errs() << "no block " << n << " in " << F.getName() << "\n";
  std::exit(2);
}

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

// Expect controlTainted for each named block of F: '1' tainted, '0' not.
static void expectCT(const cq::TaintInfo &T, Function &F, std::initializer_list<std::pair<const char *, bool>> want) {
  const cq::Specialization *S = entryOf(T, &F);
  CHECK(S, "no entry specialization of @" << F.getName());
  if (!S)
    return;
  for (auto &[n, w] : want)
    CHECK(T.controlTainted(blk(F, n), *S) == w,
          "@" << F.getName() << " block " << n << ": controlTainted " << !w << ", want " << w);
}

static std::unique_ptr<Module> loadSpec(LLVMContext &Ctx, const std::string &rel) {
  SMDiagnostic Err;
  auto M = parseIRFile(std::string(CQ_SPEC_DIR) + "/examples/" + rel, Err, Ctx);
  if (!M) {
    Err.print("taint_deadend", errs());
    ++failures;
  }
  return M;
}

int main() {
  LLVMContext Ctx;
  SMDiagnostic Err;
  std::unique_ptr<Module> M = parseAssemblyString(IR, Err, Ctx);
  if (!M) {
    Err.print("taint_deadend", errs());
    return 2;
  }
  // The one dead-end definition.
  {
    cq::taint_detail::DeadEnds D(*M->getFunction("nested"));
    Function &F = *M->getFunction("nested");
    for (const char *n : {"dead", "d1", "d2"})
      CHECK(D.isDeadEnd(blk(F, n)), "@nested " << n << " is a dead end");
    for (const char *n : {"entry", "arm", "cont", "join"})
      CHECK(!D.isDeadEnd(blk(F, n)), "@nested " << n << " reaches a return");
  }
  cq::TaintInfo T = cq::computeTaint(*M, {});
  {
    Function &F = *M->getFunction("phi_after_abort");
    expectCT(T, F, {{"m", false}, {"die", true}, {"j", false}});
    const cq::Specialization *S = entryOf(T, &F);
    if (S)
      CHECK(!T.isQuantum(named(F, "p"), *S), "@phi_after_abort %p classical: %m has one live successor");
  }
  {
    Function &F = *M->getFunction("phi_both_live");
    expectCT(T, F, {{"t", true}, {"j", false}});
    const cq::Specialization *S = entryOf(T, &F);
    if (S)
      CHECK(T.isQuantum(named(F, "p"), *S), "@phi_both_live %p quantum (contrast)");
  }
  expectCT(T, *M->getFunction("loop_abort"), {{"h", false}, {"die", true}, {"latch", false}, {"exit", false}});
  expectCT(T, *M->getFunction("nested"),
           {{"arm", true}, {"dead", true}, {"d1", true}, {"d2", true}, {"cont", true}, {"join", false}});

  // The spec witnesses.
  if (auto M45 = loadSpec(Ctx, "45_unreachable_arm/unreachable_arm.O1.ll")) {
    cq::TaintInfo T45 = cq::computeTaint(*M45, {});
    for (const char *f : {"unreachable_arm", "abort_then_rotate"})
      expectCT(T45, *M45->getFunction(f), {{"4", false}, {"7", true}, {"8", false}});
  }
  if (auto M49 = loadSpec(Ctx, "49_switch_shared_unreachable/switch_shared_unreachable.O1.ll")) {
    cq::TaintInfo T49 = cq::computeTaint(*M49, {});
    expectCT(T49, *M49->getFunction("switch_shared_unreachable"),
             {{"7", true}, {"9", true}, {"11", true}, {"13", true}, {"14", false}});
  }
  // cq-fv9n: a quantum switch whose default is a bare unreachable; the join after it (switch_value
  // %15, switch_phase %13) is not control dependent on the switch, so the spine may place the ret.
  if (auto M22 = loadSpec(Ctx, "22_switch_quantum/switch_quantum.O1.ll")) {
    cq::TaintInfo T22 = cq::computeTaint(*M22, {});
    expectCT(T22, *M22->getFunction("switch_value"),
             {{"8", true}, {"10", true}, {"12", true}, {"14", true}, {"15", false}});
    expectCT(T22, *M22->getFunction("switch_phase"),
             {{"8", true}, {"9", true}, {"10", true}, {"11", true}, {"13", false}});
  }
  if (auto M108 = loadSpec(Ctx, "108_arch_primitives/arch_primitives.O1.ll")) {
    cq::TaintInfo T108 = cq::computeTaint(*M108, {});
    expectCT(T108, *M108->getFunction("trap_q"), {{"6", true}, {"7", false}});
  }
  outs() << "taint_deadend: " << checks << " checks, " << failures << " failures\n";
  return failures ? 1 : 0;
}
