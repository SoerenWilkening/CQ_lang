// Unit test of the spine's dispatch of a loop as a unit whose exit block is also reached by a
// zero-trip guard's skip edge (cq-gio4; 41 phase_in_loop's %7, 177's four loops).
//
// loops::lowerClassical is still a stub (cq-w1-loops-classical), so this binary is linked with every
// pass module except loops/classical/Classical.cpp and supplies a test double: it emits one marker
// call (@loop_unit) at the builder, binds every loop value read outside the loop to the classical
// constant 7 (a quantum one is a test error), and leaves the builder there. The spine must then end
// the unit with a jump to the exit block (not merge the exit into the loop's last block), keep the
// guard's skip edge to the same exit block, and give a classical phi of the exit block its loop
// incoming from the block the unit ended in. The function is checked with the structural verifier,
// the LLVM verifier, and by text. A unit with two or more exit edges into an exit block with a phi
// must stop with cq: unimplemented (cq-qjm9; the reviewer's p1.ll and p4.ll; cq-9us4's a1.ll, where the
// loop sits in a quantum arm), run in a forked child. A unit whose header carries a planned classical
// guard (cq-uevr, 26's shape) must emit it before the unit, the unit in its taken block.
//
//   spine_loop_exit_join            run every case
//   spine_loop_exit_join <case>     run one case
#include <cstdio>
#include <cstdlib>
#include <functional>
#include <map>
#include <memory>
#include <regex>
#include <string>
#include <vector>

#include <sys/wait.h>
#include <unistd.h>

#include "cq/Common.h"
#include "cq/Loops.h"
#include "cq/Lowering.h"
#include "cq/Taint.h"
#include "cq/Verify.h"
#include "cq/Calls.h"

#include "llvm/Analysis/LoopInfo.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

// ---- test double of pass/lib/loops/classical/Classical.cpp ----------------------------------------
namespace cq::loops {
unsigned units = 0;
void lowerClassical(LoweringContext &ctx, Loop &L, Case) {
  ++units;
  IRBuilder<> &B = ctx.B();
  FunctionCallee m = ctx.M.getOrInsertFunction("loop_unit", FunctionType::get(B.getVoidTy(), false));
  B.CreateCall(m);
  for (BasicBlock *b : L.blocks())
    for (Instruction &I : *b)
      for (User *u : I.users())
        if (auto *ui = dyn_cast<Instruction>(u); ui && !L.contains(ui)) {
          if (ctx.T.isQuantum(&I, ctx.S))
            internalError("test double: a quantum loop value read after the loop", &I);
          ctx.bind(&I, ConstantInt::get(I.getType(), 7));
          break;
        }
}
} // namespace cq::loops

namespace {

int failures = 0;

void fail(const std::string &c, const std::string &msg) {
  ++failures;
  std::fprintf(stderr, "FAIL %s: %s\n", c.c_str(), msg.c_str());
}

std::string lower(const std::string &c, const char *ir, const char *fn) {
  LLVMContext ctx;
  SMDiagnostic err;
  std::unique_ptr<Module> M = parseAssemblyString(ir, err, ctx);
  if (!M) {
    err.print("spine_loop_exit_join", errs());
    std::exit(2);
  }
  cq::TaintInfo T = cq::computeTaint(*M, cq::TaintOptions{});
  cq::loops::KOptions KO;
  cq::loops::units = 0;
  for (const cq::Specialization &S : T.specializations())
    cq::construct(*M, T, S, KO);
  cq::calls::finalize(*M);
  cq::verifyLowered(*M);
  std::string vs;
  raw_string_ostream vos(vs);
  if (verifyModule(*M, &vos))
    fail(c, "llvm verifier: " + vos.str());
  if (cq::loops::units != 1)
    fail(c, "the loop was dispatched " + std::to_string(cq::loops::units) + " times, expected once");
  std::string s;
  raw_string_ostream os(s);
  M->getFunction(fn)->print(os);
  std::printf("---- %s\n%s", c.c_str(), os.str().c_str());
  return os.str();
}

void expectCount(const std::string &c, const std::string &body, const std::string &rx, unsigned n) {
  std::regex r(rx);
  unsigned got = std::distance(std::sregex_iterator(body.begin(), body.end(), r), std::sregex_iterator());
  if (got != n)
    fail(c, "'" + rx + "' occurs " + std::to_string(got) + " times, expected " + std::to_string(n));
}

// The label of the block holding the first match of rx (the "N:" line above it; "" = entry).
std::string blockOf(const std::string &body, const std::string &rx) {
  std::smatch m;
  if (!std::regex_search(body, m, std::regex(rx)))
    return "?";
  std::string before = body.substr(0, m.position(0));
  std::regex lbl(R"(\n(\d+):)");
  std::string last = "";
  for (auto it = std::sregex_iterator(before.begin(), before.end(), lbl); it != std::sregex_iterator(); ++it)
    last = (*it)[1];
  return last;
}

// 41's phase_in_loop: the guard `n > 0` skips the loop straight to its exit block, which measures.
const char *kGuarded = R"(
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @f(i32 %x0, double %th, i32 %n, double %phi) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %g = icmp sgt i32 %n, 0
  br i1 %g, label %body, label %exit

exit:
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m

body:
  %i = phi i32 [ %i1, %latch ], [ 0, %entry ]
  %c = icmp eq i32 %x, %i
  br i1 %c, label %then, label %latch

then:
  call void @cq_phi(double %phi)
  br label %latch

latch:
  %i1 = add nuw nsw i32 %i, 1
  %d = icmp eq i32 %i1, %n
  br i1 %d, label %exit, label %body
}
)";

void caseGuarded() {
  const char *c = "guarded";
  std::string b = lower(c, kGuarded, "f");
  // The entry branches classically to the unit and to the exit; the unit jumps to the exit; the
  // exit block measures and returns, once.
  std::smatch g;
  if (!std::regex_search(b, g, std::regex(R"(br i1 %\w+, label %(\d+), label %(\d+))")))
    return fail(c, "no classical guard branch");
  std::string unitBlk = g[1], exitBlk = g[2];
  if (blockOf(b, R"(call void @loop_unit\(\))") != unitBlk)
    fail(c, "the unit is not lowered in the guard's taken block " + unitBlk);
  if (blockOf(b, R"(call i32 @cqrt_measure_i32\()") != exitBlk)
    fail(c, "the measurement is not in the guard's skip target " + exitBlk);
  expectCount(c, b, R"(call void @loop_unit\(\)\s+br label %)" + exitBlk + R"(\b)", 1);
  expectCount(c, b, R"(cqrt_measure_i32)", 1);
  expectCount(c, b, R"(\bret i32)", 1);
}

// The exit block has a classical phi over the guard edge and the loop's exit edge.
const char *kPhi = R"(
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @h(i32 %x0, double %th, i32 %n, double %phi) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %g = icmp sgt i32 %n, 0
  br i1 %g, label %body, label %exit

exit:
  %r = phi i32 [ 0, %entry ], [ %i1, %latch ]
  %m = call i32 @cq_measure_si32(i32 %x)
  %s = add i32 %m, %r
  ret i32 %s

body:
  %i = phi i32 [ %i1, %latch ], [ 0, %entry ]
  %c = icmp eq i32 %x, %i
  br i1 %c, label %then, label %latch

then:
  call void @cq_phi(double %phi)
  br label %latch

latch:
  %i1 = add nuw nsw i32 %i, 1
  %d = icmp eq i32 %i1, %n
  br i1 %d, label %exit, label %body
}
)";

void casePhi() {
  const char *c = "phi";
  std::string b = lower(c, kPhi, "h");
  std::smatch p;
  if (!std::regex_search(b, p, std::regex(R"(phi i32 \[ (\w+), %(\d+) \], \[ (\w+), %(\d+) \])")))
    return fail(c, "no two-incoming classical phi in the exit block");
  std::string unitBlk = blockOf(b, R"(call void @loop_unit\(\))");
  std::map<std::string, std::string> in{{p[2], p[1]}, {p[4], p[3]}};
  if (!in.count(unitBlk) || in[unitBlk] != "7")
    fail(c, "the phi's incoming from the unit's block " + unitBlk + " is not the loop's exit value 7");
  bool fromEntry = false;
  for (auto &kv : in)
    fromEntry |= kv.first != unitBlk && kv.second == "0";
  if (!fromEntry)
    fail(c, "the phi has no incoming 0 from the guard's block");
}

// cq-uevr: the loop's header is reached only through a quantum branch on %a = %g & %q (26's shape,
// without its exit phi), so its predicate g & q has the classical factor %g that no classical edge
// establishes: planGuards plans a guard for the unit's header. It must be emitted before the unit
// (the unit runs only under it, its skip edge going to the exit block), not dropped.
const char *kGuardedHeader = R"(
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @u(i32 %x0, double %th, i32 %n, double %phi) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %g = icmp sgt i32 %n, 0
  %q = icmp eq i32 %x, 3
  %a = and i1 %g, %q
  br i1 %a, label %body, label %exit

exit:
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m

body:
  %i = phi i32 [ %i1, %latch ], [ 0, %entry ]
  %c = icmp eq i32 %x, %i
  br i1 %c, label %then, label %latch

then:
  call void @cq_phi(double %phi)
  br label %latch

latch:
  %i1 = add nuw nsw i32 %i, 1
  %d = icmp eq i32 %i1, %n
  br i1 %d, label %exit, label %body
}
)";

void caseGuardedHeader() {
  const char *c = "guarded_header";
  std::string b = lower(c, kGuardedHeader, "u");
  // The guard: a classical branch on %g (the argument test n > 0), to the unit's block and to the
  // exit block; the unit then jumps to the exit block, which measures and returns once.
  std::smatch g;
  if (!std::regex_search(b, g, std::regex(R"(%(\w+) = icmp sgt i32 %n, 0[\s\S]*?br i1 %(\w+), label %(\d+), label %(\d+))")))
    return fail(c, "no classical guard branch");
  if (g[1] != g[2])
    fail(c, "the guard branch is not on the classical factor n > 0");
  std::string unitBlk = g[3], skipBlk = g[4];
  if (blockOf(b, R"(call void @loop_unit\(\))") != unitBlk)
    fail(c, "the unit is not lowered in the guard's taken block " + unitBlk);
  if (blockOf(b, R"(call i32 @cqrt_measure_i32\()") != skipBlk)
    fail(c, "the measurement is not in the guard's skip target " + skipBlk);
  expectCount(c, b, R"(call void @loop_unit\(\))", 1);
  expectCount(c, b, R"(br i1 )", 1);
  expectCount(c, b, R"(cqrt_measure_i32)", 1);
  expectCount(c, b, R"(\bret i32)", 1);
}

// Runs the lowering in a forked child and expects it to stop with cq: unimplemented naming cq-qjm9
// and printing the exit block's phi (rx matches it).
void expectUnimplemented(const std::string &c, const char *ir, const std::string &phiRx) {
  int pfd[2];
  if (pipe(pfd) != 0)
    std::exit(2);
  std::fflush(nullptr);
  pid_t pid = fork();
  if (pid == 0) {
    dup2(pfd[1], 2);
    close(pfd[0]);
    close(pfd[1]);
    LLVMContext ctx;
    SMDiagnostic err;
    std::unique_ptr<Module> M = parseAssemblyString(ir, err, ctx);
    if (!M)
      _exit(3);
    cq::TaintInfo T = cq::computeTaint(*M, cq::TaintOptions{});
    cq::loops::KOptions KO;
    for (const cq::Specialization &S : T.specializations())
      cq::construct(*M, T, S, KO);
    cq::calls::finalize(*M);
    cq::verifyLowered(*M);
    _exit(0); // reached only when the lowering did not stop
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
  std::printf("---- %s\n%s", c.c_str(), out.c_str());
  if (!(WIFEXITED(status) && WEXITSTATUS(status) != 0 && WEXITSTATUS(status) != 3))
    return fail(c, "the lowering did not stop (status " + std::to_string(status) + ")");
  if (out.find("cq: unimplemented: spine: a loop unit with more than one exit edge") == std::string::npos ||
      out.find("cq-qjm9") == std::string::npos)
    fail(c, "the stop is not the cq-qjm9 unimplemented");
  if (!std::regex_search(out, std::regex(phiRx)))
    fail(c, "the message does not print the exit block's phi");
}

// The reviewer's p1.ll: two exit edges (%brk, %latch) into %exit, which the guard also reaches and
// which has a classical phi.
const char *kTwoExits = R"(
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @h(i32 %x0, double %th, i32 %n, i32 %k, double %phi) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %g = icmp sgt i32 %n, 0
  br i1 %g, label %body, label %exit
exit:
  %r = phi i32 [ 0, %entry ], [ %i1, %latch ], [ 100, %brk ]
  %m = call i32 @cq_measure_si32(i32 %x)
  %s = add i32 %m, %r
  ret i32 %s
body:
  %i = phi i32 [ %i1, %latch ], [ 0, %entry ]
  %c = icmp eq i32 %x, %i
  br i1 %c, label %then, label %brk
then:
  call void @cq_phi(double %phi)
  br label %brk
brk:
  %e = icmp eq i32 %i, %k
  br i1 %e, label %exit, label %latch
latch:
  %i1 = add nuw nsw i32 %i, 1
  %d = icmp eq i32 %i1, %n
  br i1 %d, label %exit, label %body
}
)";

// The reviewer's p4.ll: a nest whose outer loop leaves to %exit from the inner header and the outer
// latch.
const char *kNestedExits = R"(
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @h(i32 %x0, double %th, i32 %n, i32 %k, double %phi) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %g = icmp sgt i32 %n, 0
  br i1 %g, label %outer, label %exit
outer:
  %i = phi i32 [ %i1, %olatch ], [ 0, %entry ]
  br label %inner
inner:
  %j = phi i32 [ %j1, %ilatch ], [ 0, %outer ]
  %c = icmp eq i32 %x, %j
  call void @cq_phi(double %phi)
  %j1 = add i32 %j, 1
  %e = icmp eq i32 %j1, %k
  %e2 = icmp eq i32 %j1, %i
  br i1 %e2, label %exit, label %ilatch
ilatch:
  br i1 %e, label %olatch, label %inner
olatch:
  %i1 = add nuw nsw i32 %i, 1
  %d = icmp eq i32 %i1, %n
  br i1 %d, label %exit, label %outer
exit:
  %r = phi i32 [ 0, %entry ], [ %i, %olatch ], [ %i, %inner ]
  %m = call i32 @cq_measure_si32(i32 %x)
  %s = add i32 %m, %r
  ret i32 %s
}
)";

// cq-9us4's a1.ll: the loop sits in the quantum arm of %q, so the unit continues at next(b, exit)
// rather than at %join; its two exit edges (%brk, %latch) into %join must still stop.
const char *kArmExits = R"(
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @h(i32 %x0, double %th, i32 %n, i32 %k, double %phi) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %q = icmp eq i32 %x, 3
  br i1 %q, label %body, label %els
els:
  br label %join
body:
  %i = phi i32 [ %i1, %latch ], [ 0, %entry ]
  %c = icmp eq i32 %x, %i
  br i1 %c, label %then, label %brk
then:
  call void @cq_phi(double %phi)
  br label %brk
brk:
  %e = icmp eq i32 %i, %k
  br i1 %e, label %join, label %latch
latch:
  %i1 = add nuw nsw i32 %i, 1
  %d = icmp eq i32 %i1, %n
  br i1 %d, label %join, label %body
join:
  %r = phi i32 [ 5, %els ], [ %i1, %latch ], [ 100, %brk ]
  %m = call i32 @cq_measure_si32(i32 %x)
  %s = add i32 %m, %r
  ret i32 %s
}
)";

void caseTwoExits() { expectUnimplemented("two_exits", kTwoExits, R"(at: +%r = phi i32 \[ 0, %entry \])"); }
void caseArmExits() { expectUnimplemented("arm_exits", kArmExits, R"(at: +%r = phi i32 \[ 5, %els \])"); }
void caseNestedExits() {
  expectUnimplemented("nested_exits", kNestedExits, R"(at: +%r = phi i32 \[ 0, %entry \])");
}

} // namespace

int main(int argc, char **argv) {
  std::map<std::string, std::function<void()>> cases{{"guarded", caseGuarded},
                                                        {"guarded_header", caseGuardedHeader},
                                                        {"phi", casePhi},
                                                        {"two_exits", caseTwoExits},
                                                        {"nested_exits", caseNestedExits},
                                                        {"arm_exits", caseArmExits}};
  if (argc > 1) {
    auto it = cases.find(argv[1]);
    if (it == cases.end()) {
      std::fprintf(stderr, "unknown case %s\n", argv[1]);
      return 2;
    }
    it->second();
  } else {
    for (auto &kv : cases)
      kv.second();
  }
  std::printf("%s\n", failures ? "FAILED" : "ok");
  return failures ? 1 : 0;
}
