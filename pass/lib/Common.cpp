// cq::unimplemented and cq::internalError (scaffold). The type helpers of Common.h are the abi
// module's (pass/lib/abi/).
#include "cq/Common.h"

#include <functional>
#include <map>
#include <memory>
#include <string>

#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/IR/Dominators.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Module.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/IR/Value.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

namespace {
[[noreturn]] void fail(llvm::StringRef prefix, llvm::StringRef what, const llvm::Value *at, const char *file = nullptr,
                       int line = 0) {
  std::string msg;
  llvm::raw_string_ostream os(msg);
  os << prefix << what;
  if (at)
    os << "\n  at: " << *at;
  if (file) {
    llvm::StringRef f(file);
    size_t p = f.find("pass/");
    os << "\n  site: " << (p == llvm::StringRef::npos ? f : f.substr(p)) << ":" << line;
  }
  // No crash diagnostics: a clean non-zero exit. opt removes its output file on the way out.
  llvm::report_fatal_error(llvm::Twine(os.str()), /*gen_crash_diag=*/false);
}
} // namespace

namespace cq {
void (unimplemented)(llvm::StringRef what, const llvm::Value *at) { fail("cq: unimplemented: ", what, at); }
void (internalError)(llvm::StringRef what, const llvm::Value *at) { fail("cq: internal error: ", what, at); }
void unimplementedAt(const char *file, int line, llvm::StringRef what, const llvm::Value *at) {
  fail("cq: unimplemented: ", what, at, file, line);
}
void internalErrorAt(const char *file, int line, llvm::StringRef what, const llvm::Value *at) {
  fail("cq: internal error: ", what, at, file, line);
}
void noteUnbuiltAt(const char *file, int line, llvm::StringRef what, const llvm::Value *at) {
  llvm::StringRef f(file);
  size_t p = f.find("pass/");
  llvm::errs() << "cq: note: unbuilt: " << what << "  site: " << (p == llvm::StringRef::npos ? f : f.substr(p)) << ":"
               << line;
  if (at) {
    std::string s;
    llvm::raw_string_ostream os(s);
    os << *at;
    llvm::errs() << "  at: " << llvm::StringRef(os.str()).trim();
  }
  llvm::errs() << "\n";
}
} // namespace cq

namespace cq {
using namespace llvm;
// A library function LLVM knows by semantics (TargetLibraryInfo for the module's triple), with its
// LibFunc in lf.
// The C name a declared clone is named after (CR §1.4 fn). Rule 18: an LLVM math intrinsic on a
// quantum operand is the call of the libm function of the same name: llvm.<n>.<types> is n for a
// double, nf for a float, nl for an x86_fp80 first operand (175).
std::string calleeName(const Function &F, const Value *at) {
  if (!F.isIntrinsic())
    return F.getName().str();
  StringRef n = F.getName();
  if (!n.consume_front("llvm.") || n.empty())
    internalError("calls: an intrinsic whose name is not llvm.<name>.<types>", at);
  std::string base = n.take_until([](char c) { return c == '.'; }).str();
  Type *t = F.arg_size() ? F.getFunctionType()->getParamType(0) : nullptr;
  // The intrinsics whose C function has another name (taint's libmNameOf names the same): IEEE 754-2019
  // minimum/maximum are C23 fminimum/fmaximum; powi has no C name and is LLVM's own libcall,
  // compiler-rt's __powi<m>f2.
  if (F.getIntrinsicID() == Intrinsic::minimum)
    base = "fminimum";
  else if (F.getIntrinsicID() == Intrinsic::maximum)
    base = "fmaximum";
  else if (F.getIntrinsicID() == Intrinsic::powi && t &&
           (t->isFloatTy() || t->isDoubleTy() || t->isX86_FP80Ty()))
    return t->isFloatTy() ? "__powisf2" : t->isDoubleTy() ? "__powidf2" : "__powixf2";
  if (t && t->isDoubleTy())
    return base;
  if (t && t->isFloatTy())
    return base + "f";
  if (t && t->isX86_FP80Ty())
    return base + "l";
  // Owner 2026-11-03 (no fences): whatever LLVM does. Codegen promotes half/bfloat to float and scalarises a vector
  // per element, so the name is the element type's: half/bfloat -> the float name, anything else the double name.
  if (Type *e = t ? t->getScalarType() : nullptr; e && (e->isHalfTy() || e->isBFloatTy() || e->isFloatTy()))
    return base + "f";
  if (Type *e = t ? t->getScalarType() : nullptr; e && e->isX86_FP80Ty())
    return base + "l";
  return base;
}

bool libFuncOf(const Function &F, LibFunc &lf) {
  static thread_local std::unique_ptr<TargetLibraryInfoImpl> impl;
  static thread_local std::string triple;
  const Module *M = F.getParent();
  if (!impl || triple != M->getTargetTriple()) {
    triple = M->getTargetTriple();
    impl = std::make_unique<TargetLibraryInfoImpl>(Triple(triple));
  }
  TargetLibraryInfo TLI(*impl, &F);
  if (TLI.getLibFunc(F, lf))
    return true;
  // cq-my17 (99): an asm label "\01_n" on a Mach-O target (global prefix '_') is the symbol of C
  // function n (the Darwin headers label fwrite, fputs, ... this way). It is that library function
  // when n's prototype is (TLI checks it on a scratch declaration named n).
  StringRef n = F.getName();
  const DataLayout &DL = M->getDataLayout();
  if (!n.starts_with("\01") || DL.getGlobalPrefix() != '_' || !n.drop_front(1).starts_with("_"))
    return false;
  // Keyed by content (triple, name, prototype), never by a Function pointer another module may reuse.
  std::string key = M->getTargetTriple() + '\n' + n.str() + '\n';
  {
    raw_string_ostream os(key);
    F.getFunctionType()->print(os);
  }
  static thread_local std::map<std::string, std::pair<bool, LibFunc>> cache;
  if (auto it = cache.find(key); it != cache.end()) {
    lf = it->second.second;
    return it->second.first;
  }
  LLVMContext C;
  Module scratch("cq-libfunc", C);
  scratch.setTargetTriple(M->getTargetTriple());
  scratch.setDataLayout(DL);
  // Rebuild the prototype in the scratch context (opaque pointers: every type is context-free here).
  std::function<Type *(Type *)> tr = [&](Type *t) -> Type * {
    if (t->isVoidTy()) return Type::getVoidTy(C);
    if (t->isIntegerTy()) return Type::getIntNTy(C, t->getIntegerBitWidth());
    if (t->isPointerTy()) return PointerType::get(C, t->getPointerAddressSpace());
    if (t->isFloatTy()) return Type::getFloatTy(C);
    if (t->isDoubleTy()) return Type::getDoubleTy(C);
    if (t->isX86_FP80Ty()) return Type::getX86_FP80Ty(C);
    if (t->isFP128Ty()) return Type::getFP128Ty(C);
    return nullptr;
  };
  FunctionType *FT = F.getFunctionType();
  Type *ret = tr(FT->getReturnType());
  SmallVector<Type *, 8> ps;
  bool ok = ret != nullptr;
  for (Type *p : FT->params()) {
    Type *t = tr(p);
    ok = ok && t;
    ps.push_back(t);
  }
  bool known = false;
  if (ok) {
    Function *D = Function::Create(FunctionType::get(ret, ps, FT->isVarArg()), GlobalValue::ExternalLinkage,
                                   n.drop_front(2), &scratch);
    TargetLibraryInfo STLI(*impl, D);
    known = STLI.getLibFunc(*D, lf);
  }
  cache[key] = {known, lf};
  return known;
}

namespace {
template <typename Fn> bool withSCEV(const BasicBlock &header, Fn fn) {
  Function &F = const_cast<Function &>(*header.getParent());
  DominatorTree DT(F);
  LoopInfo LI(DT);
  AssumptionCache AC(F);
  TargetLibraryInfoImpl TLII(Triple(F.getParent()->getTargetTriple()));
  TargetLibraryInfo TLI(TLII, &F);
  ScalarEvolution SE(F, TLI, AC, DT, LI);
  Loop *L = LI.getLoopFor(&header);
  while (L && L->getHeader() != &header)
    L = L->getParentLoop();
  if (!L)
    internalError("exitCountKnown: no loop headed by the block", header.getTerminator());
  return fn(SE, *L);
}
} // namespace

bool exitCountKnown(const BasicBlock &header, const BasicBlock &exiting) {
  return withSCEV(header, [&](ScalarEvolution &SE, Loop &L) {
    return !isa<SCEVCouldNotCompute>(SE.getExitCount(&L, &exiting, ScalarEvolution::SymbolicMaximum));
  });
}

bool exitCondCountKnown(const BasicBlock &header, const Value &cond, bool exitIfTrue) {
  return withSCEV(header, [&](ScalarEvolution &SE, Loop &L) {
    ScalarEvolution::ExitLimit EL =
        SE.computeExitLimitFromCond(&L, const_cast<Value *>(&cond), exitIfTrue, /*ControlsOnlyExit=*/false);
    return !isa<SCEVCouldNotCompute>(EL.SymbolicMaxNotTaken);
  });
}
} // namespace cq
