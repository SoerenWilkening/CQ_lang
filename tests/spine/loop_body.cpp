// Unit test of the two entry points a rule-14 loop module uses (cq-ofn6, Lowering.h):
// lowerInstruction (the spine's dispatch of one original body instruction, with the walker's
// per-instruction state set from it) and LoweringContext::rebind (a loop value read after the loop
// rebound to its exit value).
//
// loops::lowerClassical is still a stub (cq-w1-loops-classical), so this binary is linked with every
// pass module except loops/classical/Classical.cpp and supplies a test double, a fake loop module
// that lowers ONE trip: it binds each header phi to its preheader incoming, lowers every non-phi,
// non-terminator instruction of the loop (in loop block order) through lowerInstruction, checks
// after each call that currentPredicate() is again the unit's (top), and then, for each quantum loop
// value read after the loop, copies its rail into a fresh rail f (alloc + copy, recorded) and
// rebinds the value to f. The walker ends the unit and lowers the exit block. Checks:
//  - body: the body's quantum add is one template, and the cq_phi in the quantum arm %then is
//    lowered under that arm's predicate (an rz on the predicate's rail; under top, rule 12 would emit nothing).
//  - rebind: the measurement after the loop reads f (the alloc the double made), not the add's rail.
//  - trip (cq-99f7): the double lowers the body of kTrip under a trip rail %trip (an i1 seed it
//    mints and records) through lowerInstruction(ctx, I, trip): the cq_theta in the body's top block
//    is an Ry controlled on %trip; the cq_phi at top is rz_i1 on %trip (no rule 12 deletion); the
//    cq_phi in the quantum arm is rz_i1 on the conjunction %trip & (x == i): a fresh i1 rail
//    (alloc 0, and_i1(%trip, cond, c)) uncomputed (the same and_i1 again) and freed after the phase.
//  - two_trips (cq-lx8f): the double lowers the body twice (an unrolled trip: the header phi %i is
//    rebound to its latch incoming in between), so lowerInstruction meets instructions that are
//    already bound and replaces their bindings. Both trips' add and icmp rails are computed,
//    uncomputed and freed (the first trip's records do not leak when its bindings are replaced), and
//    the exit copy reads the second trip's add.
//  - exit_phi_bound / non_exit_phi_bound (cq-lx8f) on kExit, whose exit block has an LCSSA phi %yl
//    of %y and a later block a phi %z of %yl (classical choice): bound by the loop module (to a fresh
//    rail %exitphi), %yl keeps that binding and the walker does not merge it again (%z's classical
//    phi reads %exitphi); a phi outside the unit's exit blocks that the loop module binds (%z) is
//    still an internal error (bound twice).
//  - exit_join_latch / exit_join_header (cq-qctz) on kJoinLatch / kJoinHeader: a zero-trip guard
//    skips the loop to its exit block, whose quantum phi %r = [%x, guard edge], [%v, loop edge]
//    (%v a register defined before the loop, so no arm-local rail is merged: cq-ut4k) the loop
//    module does not bind. The walker merges it classically, and its loop incoming comes from the
//    block the unit ended in, whether the exiting block is the latch or the header. The add after
//    it reads the merged %r (a measurement of the merged handle itself is cq-bv91).
//  - rebind_unbound / lower_phi: rebind of an unbound value and lowerInstruction of a phi are
//    internal errors (forked child).
// The function is checked with the structural verifier and the LLVM verifier.
//
//   spine_loop_body            run every case
//   spine_loop_body <case>     run one case
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

#include "cq/Calls.h"
#include "cq/Common.h"
#include "cq/Loops.h"
#include "cq/Lowering.h"
#include "cq/Predicate.h"
#include "cq/Taint.h"
#include "cq/Uncompute.h"
#include "cq/Verify.h"

#include "llvm/Analysis/LoopInfo.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {
int failures = 0;
void fail(const std::string &c, const std::string &msg) {
  ++failures;
  std::fprintf(stderr, "FAIL %s: %s\n", c.c_str(), msg.c_str());
}
// What the double does besides lowering the body.
enum class Mode { Lower, LowerPhi, RebindUnbound, Trip, TwoTrips, ExitPhiBound, NonExitPhiBound };
Mode mode = Mode::Lower;
std::string curCase;
} // namespace

// ---- test double of pass/lib/loops/classical/Classical.cpp ----------------------------------------
namespace cq::loops::rolled {
class Region;
} // namespace cq::loops::rolled
namespace cq::loops::exits {
llvm::Value *lowerClassicalInTrip(cq::LoweringContext &, llvm::Loop &, llvm::Value *, bool) {
  cq::internalError("test double: lowerClassicalInTrip");
  return nullptr;
}
std::shared_ptr<cq::loops::rolled::Region> lowerClassicalSubInTrip(cq::LoweringContext &, llvm::Loop &, llvm::Value *,
                                                                  llvm::BasicBlock *, llvm::Value *&) {
  cq::internalError("test double: lowerClassicalSubInTrip");
  return nullptr;
}
} // namespace cq::loops::exits

namespace cq::loops {
unsigned units = 0;
void lowerClassical(LoweringContext &ctx, Loop &L, Case) {
  ++units;
  BasicBlock *pre = L.getLoopPreheader();
  if (!pre)
    internalError("test double: no preheader");
  for (PHINode &phi : L.getHeader()->phis()) {
    if (mode == Mode::LowerPhi)
      lowerInstruction(ctx, phi);   // must stop
    ctx.bindFields(&phi, {ctx.operand(phi.getIncomingValueForBlock(pre))});
  }
  Value *trip = nullptr;
  if (mode == Mode::Trip) {
    RailType i1{Kind::Int, 1};
    CallInst *t = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getTrue(ctx.M.getContext())});
    t->setName("trip");
    ctx.unc().recordSeed(t);
    trip = t;
  }
  for (unsigned t = 0; t < (mode == Mode::TwoTrips ? 2u : 1u); ++t) {
    if (t > 0)
      for (PHINode &phi : L.getHeader()->phis())
        ctx.rebind(&phi, {ctx.operand(phi.getIncomingValueForBlock(L.getLoopLatch()))});
    for (BasicBlock *b : L.blocks())
      for (Instruction &I : *b) {
        if (isa<PHINode>(I) || I.isTerminator())
          continue;
        if (trip)
          lowerInstruction(ctx, I, trip);
        else
          lowerInstruction(ctx, I);
        if (!ctx.currentPredicate().isTop())
          fail(curCase, "currentPredicate() not restored to the unit's after lowerInstruction");
      }
  }
  if (mode == Mode::RebindUnbound) {
    // An argument of another function is never bound here.
    ctx.rebind(ctx.M.getFunction("other")->getArg(0), {Operand{ctx.B().getInt32(0), false}});
  }
  for (BasicBlock *b : L.blocks())
    for (Instruction &I : *b)
      for (User *u : I.users())
        if (auto *ui = dyn_cast<Instruction>(u); ui && !L.contains(ui)) {
          if (!ctx.T.isQuantum(&I, ctx.S))
            internalError("test double: a classical loop value read after the loop", &I);
          RailType w = railTypeOf(I.getType());
          CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                     {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
          f->setName("exitcopy");
          RailId fid = ctx.unc().recordSeed(f);
          abi::CoreSpec cp{abi::Core::Copy, w};
          Operand v = ctx.operand(&I);
          CallInst *c = ctx.emitCore(cp, {v.v, f});
          ctx.unc().recordCore(c, cp, {v, Operand{f, true}}, fid);
          ctx.rebind(&I, {Operand{f, true}});
          break;
        }
  // The exit-block phi %yl (exit_phi_bound), and also the later block's phi %z (non_exit_phi_bound),
  // bound by the loop module to a fresh rail holding a copy of %x.
  for (const char *bindPhi : {"yl", "z"}) {
    if (mode != Mode::NonExitPhiBound && (mode != Mode::ExitPhiBound || std::string(bindPhi) != "yl"))
      continue;
    Function *F = L.getHeader()->getParent();
    for (BasicBlock &b : *F)
      for (PHINode &phi : b.phis())
        if (phi.getName() == bindPhi) {
          RailType w = railTypeOf(phi.getType());
          CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                     {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
          f->setName("exitphi");
          RailId fid = ctx.unc().recordSeed(f);
          abi::CoreSpec cp{abi::Core::Copy, w};
          Operand v = ctx.operand(&*F->getEntryBlock().begin());   // %x, the rotated register
          CallInst *c = ctx.emitCore(cp, {v.v, f});
          ctx.unc().recordCore(c, cp, {v, Operand{f, true}}, fid);
          ctx.bindFields(&phi, {Operand{f, true}});
        }
  }
}
} // namespace cq::loops

namespace {

// A classically bounded loop with a quantum body: %y = x + i, and a phase in the quantum arm
// x == i. %y is read after the loop by the measurement.
const char *kLoop = R"(
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define void @other(i32 %a) {
  ret void
}

define i32 @f(i32 %x0, double %th, i32 %n, double %phi) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  br label %body

body:
  %i = phi i32 [ %i1, %latch ], [ 0, %entry ]
  %y = add i32 %x, %i
  %c = icmp eq i32 %x, %i
  br i1 %c, label %then, label %latch

then:
  call void @cq_phi(double %phi)
  br label %latch

latch:
  %i1 = add nuw nsw i32 %i, 1
  %d = icmp eq i32 %i1, %n
  br i1 %d, label %exit, label %body

exit:
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
)";

// kLoop's shape with a register %r rotated in the body's top block and a phase there too.
const char *kTrip = R"(
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @f(i32 %x0, double %th, i32 %n, double %phi, i32 %r0, double %t, double %p2) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %r = call i32 @cq_theta_si32(i32 %r0, double %th)
  br label %body

body:
  %i = phi i32 [ %i1, %latch ], [ 0, %entry ]
  %y = add i32 %x, %i
  %r2 = call i32 @cq_theta_si32(i32 %r, double %t)
  call void @cq_phi(double %p2)
  %c = icmp eq i32 %x, %i
  br i1 %c, label %then, label %latch

then:
  call void @cq_phi(double %phi)
  br label %latch

latch:
  %i1 = add nuw nsw i32 %i, 1
  %d = icmp eq i32 %i1, %n
  br i1 %d, label %exit, label %body

exit:
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
)";

// kLoop with an LCSSA phi %yl of %y in the exit block and a phi %z of %yl in a later block.
const char *kExit = R"(
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @f(i32 %x0, double %th, i32 %n, double %phi) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  br label %body

body:
  %i = phi i32 [ %i1, %latch ], [ 0, %entry ]
  %y = add i32 %x, %i
  %c = icmp eq i32 %x, %i
  br i1 %c, label %then, label %latch

then:
  call void @cq_phi(double %phi)
  br label %latch

latch:
  %i1 = add nuw nsw i32 %i, 1
  %d = icmp eq i32 %i1, %n
  br i1 %d, label %exit, label %body

exit:
  %yl = phi i32 [ %y, %latch ]
  %e = icmp eq i32 %n, 7
  br i1 %e, label %other, label %after

other:
  br label %after

after:
  %z = phi i32 [ %yl, %exit ], [ %x, %other ]
  %w = add i32 %z, 1
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}
)";

// A guarded loop exiting from its latch: the exit block's quantum phi %r merges the guard's %x and
// the loop edge's %v (cq-qctz; the shape of 27, 62, 139).
const char *kJoinLatch = R"(
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @f(i32 %x0, i32 %v0, double %th, i32 %n, double %phi) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %v = call i32 @cq_theta_si32(i32 %v0, double %th)
  %g = icmp sgt i32 %n, 0
  br i1 %g, label %pre, label %exit

pre:
  br label %body

body:
  %i = phi i32 [ %i1, %latch ], [ 0, %pre ]
  %y = add i32 %x, %i
  %c = icmp eq i32 %x, %i
  br i1 %c, label %then, label %latch

then:
  call void @cq_phi(double %phi)
  br label %latch

latch:
  %i1 = add nuw nsw i32 %i, 1
  %d = icmp eq i32 %i1, %n
  br i1 %d, label %exit, label %body

exit:
  %r = phi i32 [ %x, %entry ], [ %v, %latch ]
  %w = add i32 %r, 1
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}
)";

// The same with the exit test in the header (the shape of 25, 28, 57, 149).
const char *kJoinHeader = R"(
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %x0, i32 %v0, double %th, i32 %n) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %v = call i32 @cq_theta_si32(i32 %v0, double %th)
  %g = icmp sgt i32 %n, 0
  br i1 %g, label %pre, label %exit

pre:
  br label %body

body:
  %i = phi i32 [ %i1, %latch ], [ 0, %pre ]
  %y = add i32 %x, %i
  %d = icmp eq i32 %i, %n
  br i1 %d, label %exit, label %latch

latch:
  %i1 = add nuw nsw i32 %i, 1
  br label %body

exit:
  %r = phi i32 [ %x, %entry ], [ %v, %body ]
  %w = add i32 %r, 1
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}
)";

std::string lower(const std::string &c, Mode md = Mode::Lower, const char *ir = kLoop) {
  curCase = c;
  mode = md;
  LLVMContext ctx;
  SMDiagnostic err;
  std::unique_ptr<Module> M = parseAssemblyString(ir, err, ctx);
  if (!M) {
    err.print("spine_loop_body", errs());
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
  M->getFunction("f")->print(os);
  std::printf("---- %s\n%s", c.c_str(), os.str().c_str());
  return os.str();
}

unsigned count(const std::string &body, const std::string &rx) {
  std::regex r(rx);
  return std::distance(std::sregex_iterator(body.begin(), body.end(), r), std::sregex_iterator());
}

void caseBody() {
  const char *c = "body";
  std::string b = lower(c);
  if (count(b, R"(= call i32 @cq_template_add_i32_hl\(i32 %\d+, i32 0\))") != 1)
    fail(c, "the body's add is not one forward add template (one trip, i = 0)");
  // The phase in %then is under the quantum predicate x == i: a phase on the predicate's rail (the
  // icmp template's result); at the unit's top predicate rule 12 would delete it.
  std::smatch m;
  if (!std::regex_search(b, m, std::regex(R"(%(\d+) = call i32 @cq_template_icmp_eq_i32_hl\()")))
    return fail(c, "no icmp template for the arm's condition");
  if (count(b, R"(call void @cqrt_rz_i1\(i32 %)" + m[1].str() + R"(, double %phi\))") != 1)
    fail(c, "the cq_phi in the quantum arm is not a phase on the arm's predicate rail");
}

// The position of the first match of rx in body at or after from (npos when none).
size_t findAt(const std::string &body, const std::string &rx, size_t from = 0) {
  std::smatch m;
  std::string tail = body.substr(from);
  if (!std::regex_search(tail, m, std::regex(rx)))
    return std::string::npos;
  return from + size_t(m.position(0));
}

void caseTrip() {
  const char *c = "trip";
  std::string b = lower(c, Mode::Trip, kTrip);
  // The theta in the body's top block: an Ry on %r's rail controlled on the trip rail.
  if (count(b, R"(call void @cqrt_ry_i32_controlled\(i32 %trip, i32 %\d+, double %t\))") != 1)
    fail(c, "the body's cq_theta is not an Ry controlled on the trip rail");
  if (count(b, R"(call void @cqrt_ry_i32\(i32 %\d+, double %t\))") != 0)
    fail(c, "the body's cq_theta is also emitted uncontrolled");
  // The phase at the body's top: rz_i1 on the trip rail (rule 12's deletion is off under a trip).
  if (count(b, R"(call void @cqrt_rz_i1\(i32 %trip, double %p2\))") != 1)
    fail(c, "the top-level cq_phi in the body is not a phase on the trip rail");
  // The phase in the arm: rz_i1 on the conjunction of %trip and the arm's condition rail.
  std::smatch m;
  if (!std::regex_search(b, m, std::regex(R"(%(\d+) = call i32 @cq_template_icmp_eq_i32_hl\()")))
    return fail(c, "no icmp template for the arm's condition");
  std::string cond = m[1].str();
  std::smatch a;
  std::string andRx = R"(call void @cqrt_and_i1\(i32 %trip, i32 %)" + cond + R"(, i32 %(\d+)\))";
  if (!std::regex_search(b, a, std::regex(andRx)))
    return fail(c, "no conjunction and_i1(%trip, cond, c)");
  std::string conj = a[1].str();
  std::string andC = R"(call void @cqrt_and_i1\(i32 %trip, i32 %)" + cond + ", i32 %" + conj + R"(\))";
  size_t alloc = findAt(b, "%" + conj + R"( = call i32 @cqrt_alloc_i1\(i1 false\))");
  size_t fwd = findAt(b, andC);
  size_t rz = findAt(b, R"(call void @cqrt_rz_i1\(i32 %)" + conj + R"(, double %phi\))");
  size_t back = rz == std::string::npos ? rz : findAt(b, andC, rz);
  size_t fr = back == std::string::npos ? back : findAt(b, R"(call void @cqrt_free\(i32 %)" + conj + R"(\))", back);
  if (alloc == std::string::npos || fwd == std::string::npos || alloc > fwd)
    fail(c, "the conjunction rail is not a fresh alloc 0 before its and_i1");
  if (rz == std::string::npos || rz < fwd)
    fail(c, "the arm's cq_phi is not a phase on the conjunction rail after it is computed");
  if (count(b, R"(call void @cqrt_rz_i1\(i32 %\d+, double %phi\))") != 1)
    fail(c, "the arm's cq_phi is not exactly one phase");
  if (back == std::string::npos)
    fail(c, "the conjunction is not uncomputed (no second and_i1) after the phase");
  if (fr == std::string::npos)
    fail(c, "the conjunction rail is not freed after its uncompute");
  if (count(b, andC) != 2)
    fail(c, "the conjunction is computed and uncomputed other than once each");
}

// Every forward call of template tmpl: its result rail, and that the rail is uncomputed (tmpl_unc on
// it) and then freed.
std::vector<std::string> checkComputedUncomputed(const std::string &c, const std::string &b, const std::string &tmpl) {
  std::vector<std::string> rails;
  std::regex fwd("%(\\d+) = call i32 @" + tmpl + "\\(");
  for (auto it = std::sregex_iterator(b.begin(), b.end(), fwd); it != std::sregex_iterator(); ++it) {
    std::string r = (*it)[1].str();
    rails.push_back(r);
    size_t def = size_t(it->position(0));
    size_t unc = findAt(b, "call void @" + tmpl + "_unc\\(i32 %" + r + "[,)]", def);
    size_t fr = unc == std::string::npos ? unc : findAt(b, "call void @cqrt_free\\(i32 %" + r + "\\)", unc);
    if (unc == std::string::npos || fr == std::string::npos)
      fail(c, "rail %" + r + " of " + tmpl + " is not uncomputed and then freed");
  }
  return rails;
}

void caseTwoTrips() {
  const char *c = "two_trips";
  std::string b = lower(c, Mode::TwoTrips);
  std::vector<std::string> adds = checkComputedUncomputed(c, b, "cq_template_add_i32_hl");
  std::vector<std::string> cmps = checkComputedUncomputed(c, b, "cq_template_icmp_eq_i32_hl");
  if (adds.size() != 2 || cmps.size() != 2)
    return fail(c, "expected two trips of the add and the icmp, got " + std::to_string(adds.size()) + " and " +
                       std::to_string(cmps.size()));
  if (count(b, R"(call i32 @cq_template_add_i32_hl\(i32 %\d+, i32 0\))") != 1)
    fail(c, "the first trip's add is not x + 0");
  if (count(b, R"(call void @cqrt_rz_i1\(i32 %\d+, double %phi\))") != 2)
    fail(c, "not one arm phase per trip");
  if (count(b, R"(call void @cqrt_copy_i32\(i32 %)" + adds[1] + R"(, i32 %exitcopy\))") != 1)
    fail(c, "the exit copy does not read the second trip's add");
}

void caseExitPhiBound() {
  const char *c = "exit_phi_bound";
  std::string b = lower(c, Mode::ExitPhiBound, kExit);
  if (count(b, R"(%exitphi = call i32 @cqrt_alloc_i32\(i32 0\))") != 1)
    fail(c, "no exit phi rail");
  if (count(b, R"(%z = phi i32 \[[^\n]*%exitphi)") != 1)
    fail(c, "the phi after the exit block does not read the exit phi's loop-module binding");
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

void checkExitJoin(const std::string &c, const char *ir) {
  std::string b = lower(c, Mode::Lower, ir);
  std::smatch p;
  if (!std::regex_search(b, p, std::regex(R"(%r = phi i32 \[ %(\w+), %(\d+) \], \[ %(\w+), %(\d+) \])")))
    return fail(c, "no two-incoming classical phi %r in the exit block");
  std::map<std::string, std::string> in{{p[2], p[1]}, {p[4], p[3]}};
  std::string unitBlk = blockOf(b, R"(call i32 @cq_template_add_i32_hl\(i32 %\w+, i32 0\))");
  std::smatch x, v;
  if (!std::regex_search(b, x, std::regex(R"(%(\d+) = call i32 @cqrt_alloc_i32\(i32 %x0\))")) ||
      !std::regex_search(b, v, std::regex(R"(%(\d+) = call i32 @cqrt_alloc_i32\(i32 %v0\))")))
    return fail(c, "no rails for %x and %v");
  if (!in.count(unitBlk) || in[unitBlk] != v[1].str())
    fail(c, "the phi's incoming from the unit's block " + unitBlk + " is not %v's rail %" + v[1].str());
  if (!in.count("") && !in.count("0"))
    fail(c, "the phi has no incoming from the guard's block (the entry)");
  else if (in.count("0") ? in["0"] != x[1].str() : in[""] != x[1].str())
    fail(c, "the phi's incoming from the guard's block is not %x's rail %" + x[1].str());
  if (count(b, R"(call i32 @cq_template_add_i32_hl\(i32 %r, i32 1\))") != 1)
    fail(c, "the add after the exit block does not read the merged %r");
}

void caseExitJoinLatch() { checkExitJoin("exit_join_latch", kJoinLatch); }
void caseExitJoinHeader() { checkExitJoin("exit_join_header", kJoinHeader); }

void caseRebind() {
  const char *c = "rebind";
  std::string b = lower(c);
  if (count(b, R"(%exitcopy = call i32 @cqrt_alloc_i32\(i32 0\))") != 1)
    fail(c, "no exit copy rail");
  if (count(b, R"(call i32 @cqrt_measure_i32\(i32 %exitcopy\))") != 1)
    fail(c, "the measurement after the loop does not read the rebound exit value");
}

// Runs the lowering in a forked child and expects it to stop with cq: internal error containing msg.
void expectInternal(const std::string &c, Mode md, const std::string &msg, const char *ir = kLoop) {
  int pfd[2];
  if (pipe(pfd) != 0)
    std::exit(2);
  std::fflush(nullptr);
  pid_t pid = fork();
  if (pid == 0) {
    dup2(pfd[1], 2);
    close(pfd[0]);
    close(pfd[1]);
    mode = md;
    LLVMContext ctx;
    SMDiagnostic err;
    std::unique_ptr<Module> M = parseAssemblyString(ir, err, ctx);
    if (!M)
      _exit(3);
    cq::TaintInfo T = cq::computeTaint(*M, cq::TaintOptions{});
    cq::loops::KOptions KO;
    for (const cq::Specialization &S : T.specializations())
      cq::construct(*M, T, S, KO);
    _exit(0);   // reached only when the lowering did not stop
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
  if (out.find(msg) == std::string::npos)
    fail(c, "the stop does not say '" + msg + "'");
}

void caseNonExitPhiBound() {
  expectInternal("non_exit_phi_bound", Mode::NonExitPhiBound, "%z bound twice", kExit);
}

void caseRebindUnbound() { expectInternal("rebind_unbound", Mode::RebindUnbound, "rebind of %a, which is not bound"); }
void caseLowerPhi() { expectInternal("lower_phi", Mode::LowerPhi, "lowerInstruction of a phi or terminator"); }

} // namespace

int main(int argc, char **argv) {
  std::map<std::string, std::function<void()>> cases{{"body", caseBody},
                                                        {"rebind", caseRebind},
                                                        {"rebind_unbound", caseRebindUnbound},
                                                        {"lower_phi", caseLowerPhi},
                                                        {"trip", caseTrip},
                                                        {"two_trips", caseTwoTrips},
                                                        {"exit_phi_bound", caseExitPhiBound},
                                                        {"non_exit_phi_bound", caseNonExitPhiBound},
                                                        {"exit_join_latch", caseExitJoinLatch},
                                                        {"exit_join_header", caseExitJoinHeader}};
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
