// Unit test of M1 (cq-arch 2026-11-01): mem::slotCellsBeforeCall / slotCellsAfterCall, a caller's slot
// object handed to a quantum clone (CR rules 18, 20, §1.4).
//
// TaintInfo::cellsWritten (T2) is still a stub and calls::lowerLifted does not call M1 yet (both are
// stream A's), so this binary is linked with every pass module except calls/Calls.cpp and supplies a
// test double of Calls.cpp's functions: materialize declares the clone with the CR §1.4 name (a quantum
// formal an i32 handle, a pointer formal the pointer); lowerLifted does what the M1 contract asks of calls
// (Before, the forward call, After, recordCall(fwd, outs, slotOuts = After, extra = Before)). The cells the
// clone writes come from mem-slots' seam detail::cellsWrittenOverride (pass/lib/mem/slots/SlotsTest.h).
// Only the entry specialization is constructed (the clone stays a declaration).
//
// Cases (the clone fill(int *p, int x) { p[1] = p[0] + x; } writes cell 1 of the caller's int a[2]; cell 0
// holds a register r, read only through the cell so that the store moves it there, cq-dr4o; the quantum
// scalar x makes the call a Lift (a call whose only quantum input is behind the pointer is Classical today: cq-vnh9)):
//  - forward: the load of a[1] after the call forwards to the handle loaded right after the call; the
//    twin runs after its last reader with the old content poison (a[1] never written), then the handle is
//    freed.
//  - old: a[1] = 7 before the call: the seed alloc_i32(7) is the twin's old-content operand and is freed
//    after the twin (106's a.out).
//  - noreload: nothing reads the cells after the call: the twin and the free follow the after-call load.
//  - keep_cell0: a load of a[0] after the call forwards past it to r (the clone writes only cell 1).
//  - old_twin: as old, a[1] read by an add: the twin gets the seed as a[1]'s old content.
//  - record: 163's sret record (see caseRecord).
//  - garbage_read: a[0] = r + 1 (garbage) and the clone has a twin: the garbage is uncomputed after the
//    twin (Uncompute::noteCallReads, U4).
//
//   mem_slots_slot_cells            run every case
//   mem_slots_slot_cells <case>     run one case
#include <cstdio>
#include <cstdlib>
#include <functional>
#include <map>
#include <memory>
#include <regex>
#include <string>
#include <vector>


#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Common.h"
#include "cq/Loops.h"
#include "cq/Lowering.h"
#include "cq/Memory.h"
#include "cq/Taint.h"
#include "cq/Uncompute.h"
#include "../../pass/lib/mem/slots/SlotsTest.h"

#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

// ---- test double of pass/lib/calls/Calls.cpp ------------------------------------------------------
namespace cq::calls {
Function *materialize(Module &M, const Specialization &S) {
  abi::CloneSpec cs{S.F->getName().str(), S.mask, S.bounds, S.ctl, S.pure, S.adj, S.depth, false};
  std::string name = abi::name(cs);
  if (Function *F = M.getFunction(name))
    return F;
  LLVMContext &C = M.getContext();
  std::vector<Type *> params;
  size_t d = 0, scalars = 0;
  for (Argument &A : S.F->args())
    scalars += !A.getType()->isPointerTy();
  for (Argument &A : S.F->args()) {
    if (A.getType()->isPointerTy()) {
      params.push_back(A.getType());
      d += S.mask.size() - scalars;   // the test's one pointer formal: one digit per pointee cell
      continue;
    }
    params.push_back(d < S.mask.size() && S.mask[d] == '1' ? handleTy(C) : A.getType());
    ++d;
  }
  Function *NF = Function::Create(FunctionType::get(Type::getVoidTy(C), params, false),
                                  GlobalValue::ExternalLinkage, name, &M);
  return NF;
}
void lowerLifted(LoweringContext &ctx, CallBase &CB) {
  const Specialization *S = ctx.T.calleeSpecialization(CB, ctx.S);
  if (!S)
    internalError("test double: no clone for the call", &CB);
  Function *C = materialize(ctx.M, *S);
  SmallVector<Value *, 4> args;
  SmallVector<Operand, 4> extra;
  std::vector<unsigned> ptrArgs;
  for (unsigned i = 0; i < CB.arg_size(); ++i) {
    if (CB.getArgOperand(i)->getType()->isPointerTy()) {
      ptrArgs.push_back(i);
      for (Value *v : mem::slotCellsBeforeCall(ctx, CB, i))
        extra.push_back(Operand{v, !isa<PoisonValue>(v)});
    }
    args.push_back(ctx.operand(CB.getArgOperand(i)).v);
  }
  CallInst *call = ctx.B().CreateCall(C, args);
  SmallVector<Value *, 4> slotOuts;
  for (unsigned i : ptrArgs)
    for (Value *v : mem::slotCellsAfterCall(ctx, CB, i, call))
      slotOuts.push_back(v);
  if (!slotOuts.empty())
    ctx.unc().recordCall(call, {}, slotOuts, extra);
}
void lowerIndirect(LoweringContext &, CallBase &) { unimplemented("calls: calls::lowerIndirect"); }
void lowerDeclared(LoweringContext &, CallBase &) { unimplemented("calls: calls::lowerDeclared"); }
void lowerVarargs(LoweringContext &, Instruction &) { unimplemented("calls: calls::lowerVarargs"); }
// No variadic save area exists here (lowerVarargs, which makes them, is unimplemented in this double):
// the queries answer as the real ones do on an empty area table.
bool lowerVaAreaLoad(LoweringContext &, LoadInst &) { return false; }
bool isVaArea(LoweringContext &, ObjectId) { return false; }
void lowerAsm(LoweringContext &, CallBase &) { unimplemented("calls: calls::lowerAsm"); }
void emitTwin(LoweringContext &, CallBase &) { unimplemented("calls: calls::emitTwin"); }
void lowerLiftedVia(LoweringContext &, CallBase &, ArrayRef<unsigned>) {
  unimplemented("calls: calls::lowerLiftedVia");
}
} // namespace cq::calls

namespace {

int failures = 0;

void fail(const std::string &c, const std::string &msg) {
  ++failures;
  std::fprintf(stderr, "FAIL %s: %s\n", c.c_str(), msg.c_str());
}

// The cells the clone writes through its pointer formal (argument 0): cell 1 by default.
SmallVector<unsigned, 4> written{1};
void installCells() {
  cq::mem::detail::cellsWrittenOverride() = [](const cq::Specialization &, unsigned argNo) {
    return argNo == 0 ? written : SmallVector<unsigned, 4>{};
  };
}

std::string module(const std::string &before, const std::string &after) {
  return R"(
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal void @fill(ptr nocapture %p, i32 %x) noinline {
  %q = getelementptr inbounds i32, ptr %p, i64 1
  %z = load i32, ptr %p, align 4
  %y = add i32 %z, %x
  store i32 %y, ptr %q, align 4
  ret void
}

define i32 @f(i32 %x0, double %th, i32 %r0) {
  %a = alloca [2 x i32], align 4
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %r = call i32 @cq_theta_si32(i32 %r0, double %th)
  %a1 = getelementptr inbounds i32, ptr %a, i64 1
)" + before + R"(
  call void @fill(ptr nonnull %a, i32 %x)
)" + after + R"(
}
)";
}

std::string lower(const std::string &c, const std::string &ir) {
  LLVMContext ctx;
  SMDiagnostic err;
  std::unique_ptr<Module> M = parseAssemblyString(ir, err, ctx);
  if (!M) {
    err.print("mem_slots_slot_cells", errs());
    std::exit(2);
  }
  installCells();
  cq::TaintInfo T = cq::computeTaint(*M, cq::TaintOptions{});
  cq::loops::KOptions KO;
  for (const cq::Specialization &S : T.specializations())
    if (S.isEntry())
      cq::construct(*M, T, S, KO);
  std::string vs;
  raw_string_ostream vos(vs);
  if (verifyModule(*M, &vos))
    fail(c, "llvm verifier: " + vos.str());
  Function *F = nullptr;
  for (Function &G : *M)
    if (!G.isDeclaration() && (G.getName() == "f.cq.entry" || G.getName() == "g.cq.entry"))
      F = &G;
  if (!F) {
    fail(c, "no lowered f");
    return "";
  }
  std::string s;
  raw_string_ostream os(s);
  F->print(os);
  std::printf("---- %s\n%s", c.c_str(), os.str().c_str());
  return os.str();
}

// Each regex must match, in order, successive parts of the body.
void expectInOrder(const std::string &c, const std::string &body, const std::vector<std::string> &rxs) {
  size_t at = 0;
  for (const std::string &rx : rxs) {
    std::smatch m;
    std::string rest = body.substr(at);
    if (!std::regex_search(rest, m, std::regex(rx))) {
      fail(c, "missing (in order): " + rx);
      return;
    }
    at += size_t(m.position(0) + m.length(0));
  }
}

void expectCount(const std::string &c, const std::string &body, const std::string &rx, unsigned n) {
  std::regex re(rx);
  auto b = std::sregex_iterator(body.begin(), body.end(), re), e = std::sregex_iterator();
  unsigned k = unsigned(std::distance(b, e));
  if (k != n)
    fail(c, "'" + rx + "' occurs " + std::to_string(k) + " times, expected " + std::to_string(n));
}

const char *kStoreX = "  store i32 %r, ptr %a, align 4\n";

void caseForward() {
  const char *c = "forward";
  std::string b = lower(c, module(kStoreX, R"(
  %v = load i32, ptr %a1, align 4
  %v0 = load i32, ptr %a, align 4
  %s = add i32 %v, %v0
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m)"));
  expectInOrder(c, b, {R"(call void @__cq_q_fill_\w+\(ptr %\w+, i32 %\w+\))",
                       R"((%\w+) = load i32, ptr (%\w+), align 4)", R"(call i32 @cq_template_add_i32\()",
                       R"(call void @__cq_q_fill_\w+_unc\(ptr %\w+, i32 %\w+, i32 poison\))",
                       R"(call void @cqrt_free\()", R"(call i32 @cqrt_measure_i32\()"});
  expectCount(c, b, R"(load i32)", 1);
}

void caseOld() {
  const char *c = "old";
  std::string b = lower(c, module(std::string(kStoreX) + "  store i32 7, ptr %a1, align 4\n", R"(
  %v = load i32, ptr %a1, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m)"));
  // a[1]'s new handle is measured (kept): no twin; the seed is still the cell's old content and freed.
  expectInOrder(c, b, {R"((%\w+) = call i32 @cqrt_alloc_i32\(i32 7\))", R"(call void @__cq_q_fill_\w+\()",
                       R"(load i32)", R"(call i32 @cqrt_measure_i32\()"});
  expectCount(c, b, R"(_unc\()", 0);
}

void caseOldTwin() {
  const char *c = "old_twin";
  std::string b = lower(c, module(std::string(kStoreX) + "  store i32 7, ptr %a1, align 4\n", R"(
  %v = load i32, ptr %a1, align 4
  %v0 = load i32, ptr %a, align 4
  %s = add i32 %v, %v0
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m)"));
  std::smatch m;
  std::regex seed(R"((%\w+) = call i32 @cqrt_alloc_i32\(i32 7\))");
  if (!std::regex_search(b, m, seed)) {
    fail(c, "no seed alloc_i32(7)");
    return;
  }
  std::string sd = m[1];
  expectInOrder(c, b, {R"(call void @__cq_q_fill_\w+\()", R"(load i32)", R"(call i32 @cq_template_add_i32\()",
                       R"(call void @__cq_q_fill_\w+_unc\(ptr %\w+, i32 %\w+, i32 )" + sd + R"(\))",
                       R"(call void @cqrt_free\()", R"(call i32 @cqrt_measure_i32\()"});
  expectCount(c, b, R"(call void @cqrt_free\(i32 )" + sd + R"(\))", 1);
}

void caseNoReload() {
  const char *c = "noreload";
  std::string b = lower(c, module(kStoreX, R"(
  ret i32 0)"));
  expectInOrder(c, b, {R"(call void @__cq_q_fill_\w+\()", R"((%\w+) = load i32)",
                       R"(call void @__cq_q_fill_\w+_unc\(ptr %\w+, i32 %\w+, i32 poison\))",
                       R"(call void @cqrt_free\()"});
}

void caseKeepCell0() {
  const char *c = "keep_cell0";
  std::string b = lower(c, module(kStoreX, R"(
  %v = load i32, ptr %a, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m)"));
  // a[0] forwards past the call to r itself: the measurement reads the register's handle.
  std::smatch m;
  std::string tail = b;
  std::regex alloc(R"((%\w+) = call i32 @cqrt_alloc_i32\(i32 %2\))");   // r = cq_theta(r0)
  if (!std::regex_search(tail, m, alloc))
    fail(c, "no register x");
  else
    expectInOrder(c, b, {R"(call void @__cq_q_fill_\w+\()",
                         R"(call i32 @cqrt_measure_i32\(i32 )" + std::string(m[1]) + R"(\))"});
  expectCount(c, b, R"(load i32)", 1);   // only the after-call load of a[1]
}

void caseGarbageRead() {
  const char *c = "garbage_read";
  std::string b = lower(c, module("  %g = add i32 %r, 1\n  store i32 %g, ptr %a, align 4\n", R"(
  %v = load i32, ptr %a1, align 4
  %v0 = load i32, ptr %a, align 4
  %s = add i32 %v, %v0
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m)"));
  // U4: the garbage g in a[0], read by the clone and recompute-read by its twin, is uncomputed after the twin.
  expectInOrder(c, b, {R"((%\w+) = call i32 @cq_template_add_i32_hl\(i32 %\w+, i32 1\))",
                       R"(call void @__cq_q_fill_\w+\()", R"(call void @__cq_q_fill_\w+_unc\()",
                       R"(call void @cq_template_add_i32_hl_unc\()"});
}

// Rules 20, 26 (163's shape): an sret record { long a, b, c } filled by a clone that stores handles into
// a and b and the classical c. The caller's record is { i32, i32, i64 }: a and b are handle cells loaded
// right after the call, c is a classical cell read from memory; the twin follows the last reader.
void caseRecord() {
  const char *c = "record";
  written = {0, 1};
  std::string b = lower(c, R"(
%struct.big = type { i64, i64, i64 }
declare i64 @cq_theta_sl(i64, double)
declare i64 @cq_measure_sl(i64)

define internal void @mk(ptr nocapture writeonly sret(%struct.big) %r, i64 %x, i64 %c) noinline {
  %a = add nsw i64 %x, %c
  store i64 %a, ptr %r, align 8
  %pb = getelementptr inbounds i8, ptr %r, i64 8
  %m = mul nsw i64 %x, %c
  store i64 %m, ptr %pb, align 8
  %pc = getelementptr inbounds i8, ptr %r, i64 16
  store i64 %c, ptr %pc, align 8
  ret void
}

define i64 @g(i64 %x0, double %th, i64 %c) {
  %r = alloca %struct.big, align 8
  %x = call i64 @cq_theta_sl(i64 %x0, double %th)
  call void @mk(ptr nonnull sret(%struct.big) %r, i64 %x, i64 %c)
  %a = load i64, ptr %r, align 8
  %pb = getelementptr inbounds i8, ptr %r, i64 8
  %b = load i64, ptr %pb, align 8
  %pc = getelementptr inbounds i8, ptr %r, i64 16
  %cc = load i64, ptr %pc, align 8
  %s1 = add nsw i64 %b, %a
  %s = add nsw i64 %s1, %cc
  %m = call i64 @cq_measure_sl(i64 %s)
  ret i64 %m
}
)");
  written = {1};
  expectInOrder(c, b, {R"((%\w+) = alloca \{ i32, i32, i64 \}, align 8)",
                       R"(call void @__cq_q_mk_\w+\(ptr %\w+, i32 %\w+, i64 %2\))", R"(load i32, ptr %\w+, align 4)",
                       R"(getelementptr inbounds \{ i32, i32, i64 \}, ptr %\w+, i32 0, i32 1)",
                       R"(load i32, ptr %\w+, align 4)",
                       R"(getelementptr inbounds \{ i32, i32, i64 \}, ptr %\w+, i32 0, i32 2)",
                       R"(load i64, ptr %\w+, align 8)", R"(call i32 @cq_template_add_i64\()",
                       R"(call void @__cq_q_mk_\w+_unc\(ptr %\w+, i32 %\w+, i64 %2, i32 poison, i32 poison\))",
                       R"(call void @cqrt_free\()", R"(call void @cqrt_free\()", R"(call i64 @cqrt_measure_i64\()"});
  expectCount(c, b, R"(call i32 @cq_template_add_i64_hl\()", 1);
  expectCount(c, b, R"(store )", 0);   // the clone fills the record; the caller stores nothing
}

} // namespace

int main(int argc, char **argv) {
  std::map<std::string, std::function<void()>> cases{{"forward", caseForward},       {"old", caseOld},
                                                     {"old_twin", caseOldTwin},      {"noreload", caseNoReload},
                                                     {"keep_cell0", caseKeepCell0}, {"garbage_read", caseGarbageRead},
                                                     {"record", caseRecord}};
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
