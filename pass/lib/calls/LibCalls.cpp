// Calls with no body that clang -O1 on the corpus triple emits for code with no library call of that name, or for a plain
// library call: each is an ISO C or LLVM memory operation under another name, and rule 16's host boundary would read host
// bytes of QUANTUM cells and write bytes the bus never sees.
//
//  - Fortified forms (<secure/_string.h>, <secure/_stdio.h>): `__memcpy_chk` and friends are the plain intrinsic (rule 22),
//    `__strcpy_chk` and friends the plain function, `__sprintf_chk` and friends the plain formatter. The check itself goes:
//    the overflow it traps on is undefined behaviour in C, outside the domain.
//  - `memset_pattern4/8/16` (LoopIdiom's form of a store loop, Darwin): a rule-22 copy whose source repeats. It is written as
//    `llvm.memcpy` carrying !cq.pattern, the period, so residency, taint and classification ask what they ask of any
//    copy; bus::lowerMemIntrinsic reads the source modulo the period. A tagged copy that stays the instruction goes back to
//    the host call in calls::finalize (restoreHostPatterns); its destination is host-resident.
//  - Oversize atomics (`__atomic_load`, `__atomic_store`, `__atomic_exchange`, `__atomic_compare_exchange`): rule 24's
//    single-thread collapse makes them the ordinary accesses: rule-22 copies of their size. A compare-exchange compares
//    the bytes and branches: a diamond, so this runs before the first taint.
//
// A body in the module wins over every name here (rule 18). Nothing else is recognised by name.
#include "LibCalls.h"

#include "cq/Common.h"

#include "llvm/ADT/StringMap.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Metadata.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"

using namespace llvm;

namespace cq::calls {

namespace {

constexpr const char *PatternKind = "cq.pattern";

// A fortified function: the plain name and the formals it does not have (ascending).
struct Fortified {
  const char *plain;
  unsigned params;
  SmallVector<unsigned, 2> drop;
};

const StringMap<Fortified> &fortifiedTable() {
  static const StringMap<Fortified> t = {
      {"__strcpy_chk", {"strcpy", 3, {2}}},
      {"__stpcpy_chk", {"stpcpy", 3, {2}}},
      {"__strcat_chk", {"strcat", 3, {2}}},
      {"__strncpy_chk", {"strncpy", 4, {3}}},
      {"__stpncpy_chk", {"stpncpy", 4, {3}}},
      {"__strncat_chk", {"strncat", 4, {3}}},
      {"__strlcpy_chk", {"strlcpy", 4, {3}}},
      {"__strlcat_chk", {"strlcat", 4, {3}}},
      {"__memccpy_chk", {"memccpy", 5, {4}}},
      {"__sprintf_chk", {"sprintf", 4, {1, 2}}},
      {"__snprintf_chk", {"snprintf", 5, {2, 3}}},
      {"__vsprintf_chk", {"vsprintf", 5, {1, 2}}},
      {"__vsnprintf_chk", {"vsnprintf", 6, {2, 3}}},
  };
  return t;
}

StringRef cName(const Function &F) {
  StringRef n = F.getName();
  return n.starts_with("\01_") ? n.drop_front(2) : n;
}

unsigned patternOf(StringRef n) {
  return n == "memset_pattern4" ? 4 : n == "memset_pattern8" ? 8 : n == "memset_pattern16" ? 16 : 0;
}

bool ptrAt(const FunctionType *FT, unsigned i) { return i < FT->getNumParams() && FT->getParamType(i)->isPointerTy(); }
bool intAt(const FunctionType *FT, unsigned i) { return i < FT->getNumParams() && FT->getParamType(i)->isIntegerTy(); }

void replaceAndErase(CallInst *CI, Value *result) {
  if (result && !CI->getType()->isVoidTy())
    CI->replaceAllUsesWith(result);
  CI->eraseFromParent();
}

bool rewriteFortifiedMem(CallInst *CI, StringRef n) {
  const FunctionType *FT = CI->getFunctionType();
  bool copy = n == "__memcpy_chk" || n == "__memmove_chk";
  if (!copy && n != "__memset_chk")
    return false;
  if (FT->getNumParams() != 4 || !ptrAt(FT, 0) || !intAt(FT, 2) || !intAt(FT, 3) || (copy ? !ptrAt(FT, 1) : !intAt(FT, 1)))
    return false;
  IRBuilder<> B(CI);
  Value *d = CI->getArgOperand(0), *x = CI->getArgOperand(1), *len = CI->getArgOperand(2);
  if (n == "__memcpy_chk")
    B.CreateMemCpy(d, MaybeAlign(), x, MaybeAlign(), len);
  else if (n == "__memmove_chk")
    B.CreateMemMove(d, MaybeAlign(), x, MaybeAlign(), len);
  else
    B.CreateMemSet(d, B.CreateTrunc(x, B.getInt8Ty()), len, MaybeAlign());
  replaceAndErase(CI, d);
  return true;
}

bool rewriteFortifiedCall(Module &M, CallInst *CI, const Fortified &f) {
  const FunctionType *FT = CI->getFunctionType();
  if (FT->getNumParams() != f.params)
    return false;
  SmallVector<Type *, 6> params;
  SmallVector<Value *, 8> args;
  for (unsigned i = 0; i < CI->arg_size(); ++i) {
    if (is_contained(f.drop, i))
      continue;
    args.push_back(CI->getArgOperand(i));
    if (i < FT->getNumParams())
      params.push_back(FT->getParamType(i));
  }
  FunctionType *Plain = FunctionType::get(FT->getReturnType(), params, FT->isVarArg());
  FunctionCallee G = M.getOrInsertFunction(f.plain, Plain);
  auto *N = CallInst::Create(Plain, G.getCallee(), args, "", CI->getIterator());
  N->setDebugLoc(CI->getDebugLoc());
  N->takeName(CI);
  replaceAndErase(CI, N);
  return true;
}

bool rewritePattern(CallInst *CI, unsigned period) {
  const FunctionType *FT = CI->getFunctionType();
  if (FT->getNumParams() != 3 || !ptrAt(FT, 0) || !ptrAt(FT, 1) || !intAt(FT, 2))
    return false;
  IRBuilder<> B(CI);
  CallInst *C = B.CreateMemCpy(CI->getArgOperand(0), MaybeAlign(), CI->getArgOperand(1), MaybeAlign(), CI->getArgOperand(2));
  C->setMetadata(PatternKind, MDNode::get(CI->getContext(), ConstantAsMetadata::get(B.getInt64(period))));
  replaceAndErase(CI, nullptr);
  return true;
}

// Rule 24: the ordinary accesses. The memory order is nothing.
bool rewriteAtomic(CallInst *CI, StringRef n) {
  const FunctionType *FT = CI->getFunctionType();
  unsigned np = FT->getNumParams();
  auto ptrs = [&](unsigned count) {
    for (unsigned i = 1; i <= count; ++i)
      if (!ptrAt(FT, i))
        return false;
    return intAt(FT, 0);
  };
  IRBuilder<> B(CI);
  Value *len = CI->arg_size() ? CI->getArgOperand(0) : nullptr;
  auto copy = [&](IRBuilder<> &At, Value *d, Value *s) { At.CreateMemCpy(d, MaybeAlign(), s, MaybeAlign(), len); };
  if (n == "__atomic_load" && np == 4 && ptrs(2)) {
    copy(B, CI->getArgOperand(2), CI->getArgOperand(1));
  } else if (n == "__atomic_store" && np == 4 && ptrs(2)) {
    copy(B, CI->getArgOperand(1), CI->getArgOperand(2));
  } else if (n == "__atomic_exchange" && np == 5 && ptrs(3)) {
    copy(B, CI->getArgOperand(3), CI->getArgOperand(1));
    copy(B, CI->getArgOperand(1), CI->getArgOperand(2));
  } else if (n == "__atomic_compare_exchange" && np == 6 && ptrs(3)) {
    auto *size = dyn_cast<ConstantInt>(len);
    if (!size) {
      noteUnbuilt("calls: __atomic_compare_exchange of a size that is not a constant (left the host call)", CI);
      return false;
    }
    Value *p = CI->getArgOperand(1), *e = CI->getArgOperand(2), *d = CI->getArgOperand(3);
    Value *eq = B.getTrue();
    for (uint64_t j = 0; j < size->getZExtValue(); ++j) {
      Value *a = B.CreateLoad(B.getInt8Ty(), B.CreateConstInBoundsGEP1_64(B.getInt8Ty(), p, j));
      Value *b = B.CreateLoad(B.getInt8Ty(), B.CreateConstInBoundsGEP1_64(B.getInt8Ty(), e, j));
      eq = B.CreateAnd(eq, B.CreateICmpEQ(a, b));
    }
    Value *result = CI->getType()->isVoidTy() ? nullptr : B.CreateZExtOrTrunc(eq, CI->getType());
    Instruction *Then = nullptr, *Else = nullptr;
    SplitBlockAndInsertIfThenElse(eq, CI->getIterator(), &Then, &Else);
    IRBuilder<> T(Then), E(Else);
    copy(T, p, d);
    copy(E, e, p);
    replaceAndErase(CI, result);
    return true;
  } else {
    return false;
  }
  replaceAndErase(CI, nullptr);
  return true;
}

} // namespace

bool canonicalizeLibCalls(Module &M) {
  SmallVector<CallInst *, 16> calls;
  for (Function &F : M)
    for (Instruction &I : instructions(F))
      if (auto *CI = dyn_cast<CallInst>(&I))
        if (const Function *G = CI->getCalledFunction(); G && G->isDeclaration() && !G->isIntrinsic())
          calls.push_back(CI);
  bool changed = false;
  SmallVector<Function *, 8> callees;
  for (CallInst *CI : calls) {
    Function *G = CI->getCalledFunction();
    StringRef n = cName(*G);
    bool done = false;
    if (unsigned period = patternOf(n))
      done = rewritePattern(CI, period);
    else if (n.starts_with("__atomic_"))
      done = rewriteAtomic(CI, n);
    else if (n.ends_with("_chk")) {
      const StringMap<Fortified> &t = fortifiedTable();
      auto it = t.find(n);
      done = it != t.end() ? rewriteFortifiedCall(M, CI, it->second) : rewriteFortifiedMem(CI, n);
    }
    if (done) {
      changed = true;
      if (!is_contained(callees, G))
        callees.push_back(G);
    }
  }
  for (Function *G : callees)
    if (G->use_empty())
      G->eraseFromParent();
  return changed;
}

unsigned patternPeriod(const CallBase &CB) {
  MDNode *md = CB.getMetadata(PatternKind);
  return md ? unsigned(mdconst::extract<ConstantInt>(md->getOperand(0))->getZExtValue()) : 0;
}

void restoreHostPatterns(Module &M) {
  // cq-i61ms: the scan below in module order only when some memcpy carries a pattern (a lowered module of millions of
  // instructions usually has none).
  bool any = false;
  for (Function &D : M)
    if (D.getIntrinsicID() == Intrinsic::memcpy || D.getIntrinsicID() == Intrinsic::memcpy_inline)
      for (User *U : D.users())
        if (auto *C = dyn_cast<MemCpyInst>(U); C && patternPeriod(*C))
          any = true;
  if (!any)
    return;
  SmallVector<MemCpyInst *, 4> tagged;
  for (Function &F : M)
    for (Instruction &I : instructions(F))
      if (auto *C = dyn_cast<MemCpyInst>(&I); C && patternPeriod(*C))
        tagged.push_back(C);
  for (MemCpyInst *C : tagged) {
    IRBuilder<> B(C);
    Type *Ptr = B.getPtrTy();
    FunctionType *FT = FunctionType::get(B.getVoidTy(), {Ptr, Ptr, B.getInt64Ty()}, false);
    FunctionCallee G = M.getOrInsertFunction(("memset_pattern" + Twine(patternPeriod(*C))).str(), FT);
    B.CreateCall(G, {C->getRawDest(), C->getRawSource(), B.CreateZExtOrTrunc(C->getLength(), B.getInt64Ty())});
    C->eraseFromParent();
  }
}

} // namespace cq::calls
