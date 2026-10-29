// tests/loops-cutoff: loops::resolveK (CLAUDE.md "K per loop": per-function flag, CQ_K constant
// __cq_k_<f>, global flag, 4) and loops::tripBound (SCEV's constant maximum; a header-tested loop
// counts bodies, one less than header runs).
#include "cq/Loops.h"

#include <cstdio>
#include <cstdlib>

#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/TargetParser/Triple.h"

using namespace llvm;

static int failures = 0;
static void check(bool ok, const char *what) {
  std::printf("%s %s\n", ok ? "ok  " : "FAIL", what);
  failures += !ok;
}

static const char *IR = R"(
target triple = "x86_64-apple-macosx16.0.0"
@__cq_k_g = internal constant i32 7
define void @f() { ret void }
define void @g() { ret void }
; bottom-tested: i = 0 .. (n & 3), header executions <= 4
define void @rot(i32 %n) {
entry:
  %m = and i32 %n, 3
  br label %h
h:
  %i = phi i32 [ 0, %entry ], [ %i1, %h ]
  %i1 = add nuw nsw i32 %i, 1
  %c = icmp ult i32 %i, %m
  br i1 %c, label %h, label %x
x:
  ret void
}
; header-tested: for (i = 0; i < (n & 3); i++) body; header runs <= 4, bodies <= 3
define void @hdr(i32 %n) {
entry:
  %m = and i32 %n, 3
  br label %h
h:
  %i = phi i32 [ 0, %entry ], [ %i1, %b ]
  %c = icmp ult i32 %i, %m
  br i1 %c, label %b, label %x
b:
  %i1 = add nuw nsw i32 %i, 1
  br label %h
x:
  ret void
}
; unbounded: while (x > k) x = x * 3 + 1
define void @wild(i32 %x0, i32 %k) {
entry:
  br label %h
h:
  %x = phi i32 [ %x0, %entry ], [ %x1, %h ]
  %t = mul i32 %x, 3
  %x1 = add i32 %t, 1
  %c = icmp ugt i32 %x1, %k
  br i1 %c, label %h, label %e
e:
  ret void
}
)";

static std::optional<uint64_t> bound(Function &F) {
  DominatorTree DT(F);
  LoopInfo LI(DT);
  TargetLibraryInfoImpl TLII(Triple(F.getParent()->getTargetTriple()));
  TargetLibraryInfo TLI(TLII, &F);
  AssumptionCache AC(F);
  ScalarEvolution SE(F, TLI, AC, DT, LI);
  return cq::loops::tripBound(*LI.getTopLevelLoops().front(), SE);
}

int main() {
  LLVMContext C;
  SMDiagnostic err;
  std::unique_ptr<Module> M = parseAssemblyString(IR, err, C);
  if (!M) {
    err.print("k_and_bound", errs());
    return 1;
  }
  Function &f = *M->getFunction("f"), &g = *M->getFunction("g");
  cq::loops::KOptions none;
  check(cq::loops::resolveK(f, none) == 4, "default K is 4");
  check(cq::loops::resolveK(g, none) == 7, "CQ_K constant __cq_k_g gives 7");
  cq::loops::KOptions glob;
  glob.global = 9;
  check(cq::loops::resolveK(f, glob) == 9, "global flag over the default");
  check(cq::loops::resolveK(g, glob) == 7, "CQ_K over the global flag");
  cq::loops::KOptions per = glob;
  per.perFunction["g"] = 2;
  check(cq::loops::resolveK(g, per) == 2, "per-function flag over CQ_K");
  check(cq::loops::resolveK(f, per) == 9, "per-function flag of another function does not apply");

  auto r = bound(*M->getFunction("rot"));
  check(r && *r == 4, "bottom-tested loop: B = header executions (4)");
  auto h = bound(*M->getFunction("hdr"));
  check(h && *h == 3, "header-tested loop: B = bodies (3)");
  check(!bound(*M->getFunction("wild")), "no bound known");
  return failures ? 1 : 0;
}
