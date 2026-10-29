// cq-bxc4: a phi whose join J is itself control dependent on a tainted terminator T is still chosen
// by T when, given that J is reached, which incoming edge entered J depends on T (rules 9, 13): a
// switch case block entered both by the switch and by a fallthrough, an if/else-if join whose last
// arm returns. It is not chosen when T's arms merge again before a classical choice of J's edge, and
// a loop header's phis stay rule 14's. Witnesses 22 (%12), 123 (%10), 175 libm_cbrt_q (%22).
#include <cstdio>
#include <string>

#include "cq/Taint.h"

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

; if (x&1) r=5; else if (x&2) r=7; else return 3; -- the join depends on both branches, and which
; edge enters it is x&1's choice: quantum (review switch-h1 p7).
define i32 @if_elif_ret(i32 %a, double %th) {
entry:
  %x = tail call i32 @cq_theta_si32(i32 %a, double %th)
  %b0 = and i32 %x, 1
  %c0 = icmp ne i32 %b0, 0
  br i1 %c0, label %t1, label %e1
t1:
  br label %j
e1:
  %b1 = and i32 %x, 2
  %c1 = icmp ne i32 %b1, 0
  br i1 %c1, label %t2, label %ret3
t2:
  br label %j
ret3:
  ret i32 3
j:
  %r = phi i32 [ 5, %t1 ], [ 7, %t2 ]
  ret i32 %r
}

; A case block entered by the switch and by the previous case's fallthrough (123's shape): quantum.
define i32 @fallthrough(i32 %a, double %th, i32 %k) {
entry:
  %x = tail call i32 @cq_theta_si32(i32 %a, double %th)
  switch i32 %x, label %out [
    i32 0, label %c0
    i32 1, label %j
  ]
c0:
  %k1 = add i32 %k, 1
  br label %j
j:
  %r = phi i32 [ %k, %entry ], [ %k1, %c0 ]
  %r3 = mul i32 %r, 3
  br label %out
out:
  %o = phi i32 [ %k, %entry ], [ %r3, %j ]
  ret i32 %o
}

; The switch's two arms merge at %m before a classical branch picks J's edge; J still depends on
; the switch (its default returns). Given J, the edge is %c's: classical.
define i32 @merged_first(i32 %a, double %th, i1 %c) {
entry:
  %x = tail call i32 @cq_theta_si32(i32 %a, double %th)
  switch i32 %x, label %ret0 [
    i32 0, label %s0
    i32 1, label %s1
  ]
s0:
  br label %m
s1:
  br label %m
m:
  br i1 %c, label %p1, label %p2
p1:
  br label %j
p2:
  br label %j
ret0:
  ret i32 0
j:
  %r = phi i32 [ 1, %p1 ], [ 2, %p2 ]
  ret i32 %r
}

; Rule 14 case 3 (classical bound, quantum break): the header depends on the break, the counter phi
; stays classical (loopHeaderRule), the exit phi is chosen by the break.
define i32 @loop_break(i32 %a, double %th, i32 %n) {
entry:
  %x = tail call i32 @cq_theta_si32(i32 %a, double %th)
  br label %h
h:
  %i = phi i32 [ 0, %entry ], [ %i1, %latch ]
  %q = icmp eq i32 %i, %x
  br i1 %q, label %exit, label %latch
latch:
  %i1 = add nsw i32 %i, 1
  %d = icmp slt i32 %i1, %n
  br i1 %d, label %h, label %exit
exit:
  %e = phi i32 [ 1, %h ], [ 2, %latch ]
  ret i32 %e
}

declare i32 @cq_theta_si32(i32, double)
)";

static Instruction *named(Function &F, StringRef n) {
  for (Instruction &I : instructions(F))
    if (I.getName() == n)
      return &I;
  errs() << "no instruction %" << n << "\n";
  std::exit(2);
}

// An unnamed instruction by its slot (%N) in the printed function.
static Instruction *slot(Function &F, StringRef n) {
  for (Instruction &I : instructions(F)) {
    if (I.getType()->isVoidTy())
      continue;
    std::string s;
    raw_string_ostream os(s);
    I.printAsOperand(os, false);
    if (os.str() == ("%" + n).str())
      return &I;
  }
  errs() << "no instruction %" << n << " in " << F.getName() << "\n";
  std::exit(2);
}

static const cq::Specialization *entryOf(const cq::TaintInfo &T, const Function *F) {
  for (const cq::Specialization &S : T.specializations())
    if (S.F == F && S.isEntry())
      return &S;
  return nullptr;
}

static void expectQ(const cq::TaintInfo &T, Function &F, Instruction *I, bool want, const char *why) {
  const cq::Specialization *S = entryOf(T, &F);
  CHECK(S, "no entry specialization of @" << F.getName());
  if (!S)
    return;
  std::string s;
  raw_string_ostream os(s);
  I->printAsOperand(os, false);
  CHECK(T.isQuantum(I, *S) == want,
        "@" << F.getName() << " " << os.str() << ": quantum " << !want << ", want " << want << " (" << why << ")");
}

static void expectBlockCT(const cq::TaintInfo &T, Function &F, Instruction *I, bool want) {
  const cq::Specialization *S = entryOf(T, &F);
  if (S)
    CHECK(T.controlTainted(I->getParent(), *S) == want,
          "@" << F.getName() << " block of %" << I->getName() << ": controlTainted, want " << want);
}

int main() {
  LLVMContext Ctx;
  SMDiagnostic Err;
  std::unique_ptr<Module> M = parseAssemblyString(IR, Err, Ctx);
  if (!M) {
    Err.print("taint_joinchoice", errs());
    return 2;
  }
  cq::TaintInfo T = cq::computeTaint(*M, {});
  {
    Function &F = *M->getFunction("if_elif_ret");
    expectBlockCT(T, F, named(F, "r"), true);
    expectQ(T, F, named(F, "r"), true, "the edge is x&1's choice");
  }
  {
    Function &F = *M->getFunction("fallthrough");
    expectBlockCT(T, F, named(F, "r"), true);
    expectQ(T, F, named(F, "r"), true, "case 1 direct vs case 0 fallthrough");
    expectQ(T, F, named(F, "r3"), true, "reads the chosen phi");
    expectQ(T, F, named(F, "o"), true, "join after the switch (edgeChosen)");
  }
  {
    Function &F = *M->getFunction("merged_first");
    expectBlockCT(T, F, named(F, "r"), true);
    expectQ(T, F, named(F, "r"), false, "the switch's arms merge before %c picks the edge");
  }
  {
    Function &F = *M->getFunction("loop_break");
    expectQ(T, F, named(F, "i"), false, "rule 14 case 3: the counter stays classical");
    expectQ(T, F, named(F, "e"), true, "the exit edge is the break's choice");
  }

  // The spec witnesses.
  auto load = [&](const char *rel) {
    SMDiagnostic E;
    auto X = parseIRFile(std::string(CQ_SPEC_DIR) + "/examples/" + rel, E, Ctx);
    if (!X) {
      E.print("taint_joinchoice", errs());
      ++failures;
    }
    return X;
  };
  if (auto X = load("22_switch_quantum/switch_quantum.O1.ll")) {
    cq::TaintInfo TX = cq::computeTaint(*X, {});
    Function &F = *X->getFunction("switch_phase");
    expectQ(TX, F, slot(F, "12"), true, "the phase of the selected case, at a shared case block");
  }
  if (auto X = load("123_enum_switch_fallthrough/enum_switch_fallthrough.O1.ll")) {
    cq::TaintInfo TX = cq::computeTaint(*X, {});
    Function &F = *X->getFunction("enum_switch_fallthrough");
    expectQ(TX, F, slot(F, "10"), true, "BLUE direct vs GREEN fallthrough");
    expectQ(TX, F, slot(F, "11"), true, "reads %10");
  }
  if (auto X = load("175_libm_quantum/libm_quantum.O1.ll")) {
    cq::TaintInfo TX = cq::computeTaint(*X, {});
    Function &F = *X->getFunction("libm_cbrt_q");
    expectQ(TX, F, slot(F, "22"), true, "the cbrt bias constant chosen by the subnormal test");
  }
  std::printf("taint_joinchoice: %d checks, %d failures\n", checks, failures);
  return failures ? 1 : 0;
}
