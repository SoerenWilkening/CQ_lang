// Unit test of the spine's rule 18 copy-out at a clone's return (cq-b0w).
//
// calls::materialize is still a stub (cq-w1-calls), so this binary is linked with every pass module
// except calls/Calls.cpp and supplies a test double of Calls.cpp's functions: materialize makes an
// empty clone with the CR §1.4 name and the clone signature (a quantum formal or result is an i32
// handle); every other Calls.cpp function stays unimplemented. Each case is a small module whose
// clone is a library-build root (TaintOptions::roots), so only non-entry specializations are
// constructed. The lowered clone is checked with the structural verifier and by text against the
// spelling of 06, 07, 33 and 34.
//
//   spine_clone_return            run every case
//   spine_clone_return <case>     run one case
#include <cstdio>
#include <cstdlib>
#include <functional>
#include <map>
#include <memory>
#include <regex>
#include <string>
#include <vector>

#include "cq/Abi.h"
#include "cq/Bus.h"
#include "cq/Calls.h"
#include "../../pass/lib/calls/CallsInternal.h"
#include "cq/Common.h"
#include "cq/Loops.h"
#include "cq/Lowering.h"
#include "cq/Taint.h"
#include "cq/Verify.h"

#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

// ---- test double of pass/lib/calls/Calls.cpp ------------------------------------------------------
namespace cq::calls {
const TaintInfo *testTaint = nullptr;   // the taint construct() runs under (resultQuantum)
Function *materialize(Module &M, const Specialization &S) {
  abi::CloneSpec cs{S.F->getName().str(), S.mask.empty() ? "v" : S.mask, S.bounds, S.ctl, S.pure, false, S.table};
  LLVMContext &C = M.getContext();
  std::vector<Type *> params;
  if (S.ctl)
    params.push_back(handleTy(C));
  for (unsigned i = 0; i < S.F->arg_size(); ++i)
    params.push_back(i < S.mask.size() && S.mask[i] == '1' ? handleTy(C) : S.F->getArg(i)->getType());
  if (S.table)
    params.push_back(Type::getInt32Ty(C));
  Type *rt = S.F->getReturnType();
  if (!rt->isVoidTy() && testTaint->resultQuantum(S, 0))
    rt = handleTy(C);
  Function *NF = Function::Create(FunctionType::get(rt, params, false), GlobalValue::InternalLinkage,
                                  abi::name(cs), &M);
  NF->setCallingConv(CallingConv::Fast);
  return NF;
}
// As Calls.cpp: rule 18's twin test, which the spine's rule 6 consults.
bool hasTwin(const TaintInfo &T, const Specialization &S) {
  return !bus::writesMemory(T, *S.F) && !T.noTwinByEffects(S);
}
void lowerLifted(LoweringContext &, CallBase &) { unimplemented("calls: calls::lowerLifted"); }
void lowerLiftedVia(LoweringContext &, CallBase &, ArrayRef<unsigned>) { unimplemented("calls: calls::lowerLiftedVia"); }
void lowerIndirect(LoweringContext &, CallBase &) { unimplemented("calls: calls::lowerIndirect"); }
void lowerSignal(LoweringContext &, CallBase &) { unimplemented("calls: calls::lowerSignal"); }
void lowerRaise(LoweringContext &, CallBase &) { unimplemented("calls: calls::lowerRaise"); }
void noteRun(LoweringContext &) {}
void insertActivationCounter(LoweringContext &) {}
ArrayRef<const CallBase *> mintSites(const TaintInfo &, const Specialization &) { return {}; }
void noteMint(LoweringContext &, CallInst &, BasicBlock *, Instruction *) {}
Value *mintHandle(LoweringContext &, const CallBase &) { return nullptr; }
unsigned mintCount(const Function &) { return 0; }
std::vector<TableRow> takeTableRows(const Module &) { return {}; }
Constant *sigString(Module &, FunctionType *) { return nullptr; }
GlobalVariable *activationCounter(Module &, StringRef) { return nullptr; }
void lowerDeclared(LoweringContext &, CallBase &) { unimplemented("calls: calls::lowerDeclared"); }
void lowerVarargs(LoweringContext &, Instruction &) { unimplemented("calls: calls::lowerVarargs"); }
void lowerAsm(LoweringContext &, CallBase &) { unimplemented("calls: calls::lowerAsm"); }
SmallVector<Type *, 4> variadicTypes(const TaintInfo &, const Specialization &, const Value *) { return {}; }
} // namespace cq::calls

namespace {

int failures = 0;

void fail(const std::string &c, const std::string &msg) {
  ++failures;
  std::fprintf(stderr, "FAIL %s: %s\n", c.c_str(), msg.c_str());
}

std::string printFn(const Function &F) {
  std::string s;
  raw_string_ostream os(s);
  F.print(os);
  return os.str();
}

// Lower `ir` with the clone `root` as a library-build root; return the clone's printed body.
std::string lower(const std::string &c, const char *ir, const char *root) {
  LLVMContext ctx;
  SMDiagnostic err;
  std::unique_ptr<Module> M = parseAssemblyString(ir, err, ctx);
  if (!M) {
    err.print("spine_clone_return", errs());
    std::exit(2);
  }
  cq::TaintOptions TO;
  TO.roots.push_back(*cq::abi::parseClone(root));
  cq::TaintInfo T = cq::computeTaint(*M, TO);
  cq::calls::testTaint = &T;
  cq::loops::KOptions KO;
  for (const cq::Specialization &S : T.specializations())
    cq::construct(*M, T, S, KO);
  cq::calls::finalize(*M);
  cq::verifyLowered(*M);
  std::string vs;
  raw_string_ostream vos(vs);
  if (verifyModule(*M, &vos))
    fail(c, "llvm verifier: " + vos.str());
  Function *F = M->getFunction(root);
  if (!F) {
    fail(c, std::string("no clone ") + root);
    return "";
  }
  std::string body = printFn(*F);
  std::printf("---- %s\n%s", c.c_str(), body.c_str());
  return body;
}

// Each regex must match, in order, successive parts of the body.
void expectInOrder(const std::string &c, const std::string &body, const std::vector<std::string> &rxs) {
  size_t pos = 0;
  for (const std::string &rx : rxs) {
    std::smatch m;
    std::string rest = body.substr(pos);
    if (!std::regex_search(rest, m, std::regex(rx))) {
      fail(c, "missing (in order): " + rx);
      return;
    }
    pos += m.position(0) + m.length(0);
  }
}

void expectCount(const std::string &c, const std::string &body, const std::string &rx, unsigned n) {
  std::regex r(rx);
  unsigned got = std::distance(std::sregex_iterator(body.begin(), body.end(), r), std::sregex_iterator());
  if (got != n)
    fail(c, "'" + rx + "' occurs " + std::to_string(got) + " times, expected " + std::to_string(n));
}

// 06/07's f: x*x + y with x quantum. The result is copied into a fresh rail before the body's
// uncompute, the fresh rail is returned and never freed, the body's rails are.
void caseBody() {
  const char *c = "body";
  std::string b = lower(c, R"(
define i32 @f(i32 %x, i32 %y) {
  %m = mul nsw i32 %x, %x
  %a = add nsw i32 %m, %y
  ret i32 %a
}
)",
                        "__cq_q_f_10");
  expectInOrder(c, b,
                {R"(define internal fastcc i32 @__cq_q_f_10\(i32 %0, i32 %1\))",
                 R"((%\d+) = call i32 @cq_template_mul_i32\(i32 %0, i32 %0\))",
                 R"((%\d+) = call i32 @cq_template_add_i32_hl\()",
                 R"((%\d+) = call i32 @cqrt_alloc_i32\(i32 0\))",
                 R"(call void @cqrt_copy_i32\(i32 %\d+, i32 %\d+\))",
                 R"(call void @cq_template_add_i32_hl_unc\()",
                 R"(call void @cq_template_mul_i32_unc\()",
                 R"(ret i32 %\d+)"});
  // The copy's source is the add rail and its target is the returned rail.
  std::smatch add, alloc, copy, ret;
  std::regex_search(b, add, std::regex(R"((%\d+) = call i32 @cq_template_add_i32_hl\()"));
  std::regex_search(b, alloc, std::regex(R"((%\d+) = call i32 @cqrt_alloc_i32\(i32 0\))"));
  std::regex_search(b, copy, std::regex(R"(cqrt_copy_i32\(i32 (%\d+), i32 (%\d+)\))"));
  std::regex_search(b, ret, std::regex(R"(ret i32 (%\d+))"));
  if (copy.empty() || add.empty() || alloc.empty() || ret.empty() || copy[1] != add[1] ||
      copy[2] != alloc[1] || ret[1] != alloc[1])
    fail(c, "copy-out is not copy_i32(<add rail>, <fresh rail>) with the fresh rail returned");
  else {
    expectCount(c, b, "cqrt_free\\(i32 " + std::string(alloc[1]) + "\\)", 0);
    expectCount(c, b, "cqrt_free\\(i32 " + std::string(add[1]) + "\\)", 1);
  }
  expectCount(c, b, R"(cqrt_free\(i32 %0\))", 0);   // the caller's rail
}

// A clone returning its quantum formal: the caller's rail is copied, never freed or returned.
void caseFormal() {
  const char *c = "formal";
  std::string b = lower(c, R"(
define i32 @id(i32 %x) {
  ret i32 %x
}
)",
                        "__cq_q_id_1");
  expectInOrder(c, b,
                {R"((%\d+) = call i32 @cqrt_alloc_i32\(i32 0\))", R"(call void @cqrt_copy_i32\(i32 %0, i32 %\d+\))",
                 R"(ret i32 %[1-9]\d*)"});
  expectCount(c, b, R"(cqrt_free)", 0);
}

// An fp result: the copy is at the result's width (copy_f64), the fresh rail seeded with 0.0.
void caseFp() {
  const char *c = "fp";
  std::string b = lower(c, R"(
define double @g(double %x, double %y) {
  %s = fadd double %x, %y
  ret double %s
}
)",
                        "__cq_q_g_10");
  expectInOrder(c, b,
                {R"(define internal fastcc i32 @__cq_q_g_10\(i32 %0, double %1\))",
                 R"(call i32 @cq_template_fadd_f64_hl\()", R"(call i32 @cqrt_alloc_f64\(double 0\.0+e\+00\))",
                 R"(call void @cqrt_copy_f64\()", R"(call void @cq_template_fadd_f64_hl_unc\()", R"(ret i32 %)"});
}

// A clone whose result does not depend on its quantum formal returns the classical value as is.
void caseClassical() {
  const char *c = "classical";
  std::string b = lower(c, R"(
define i32 @k(i32 %x, i32 %y) {
  %m = mul nsw i32 %x, %x
  %a = add nsw i32 %y, 1
  ret i32 %a
}
)",
                        "__cq_q_k_10");
  expectInOrder(c, b, {R"((%\d+) = add nsw i32 %1, 1)", R"(ret i32 %\d+)"});
  expectCount(c, b, R"(cqrt_alloc|cqrt_copy)", 0);
}

} // namespace

int main(int argc, char **argv) {
  std::map<std::string, std::function<void()>> cases{
      {"body", caseBody}, {"formal", caseFormal}, {"fp", caseFp}, {"classical", caseClassical}};
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
