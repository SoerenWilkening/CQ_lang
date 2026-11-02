// Module eff-conc (CR rule 24, 101): setjmp/longjmp.
//
// Rule 24: "longjmp under a quantum predicate is an escaped-flag result merged at the setjmp diamond".
// 101's header: a longjmp is a MULTI-FRAME PREDICATED EARLY RETURN; every intermediate frame returns its
// result beside an escaped flag (the OR of its callees' flags and its own longjmp arms), its continuation
// after each call predicated on not-escaped; setjmp's second return IS the escaped branch, its value
// longjmp's argument. The host setjmp and longjmp are not executed.
//
// The construction is that sentence made explicit control flow, as a CFG rewrite before the final taint
// (the scaffold runs explicitSetjmp after the preliminary taint, then fix-irreducible, then a fresh taint;
// nothing mutates the CFG after it). Every later construction then sees an ordinary program: the escaped
// flag is a returned value, each continuation an ordinary block under the predicates rules 8 and 9 give
// it, a cycle through a setjmp an ordinary loop (rule 14). The class is the rule's whole one: a longjmp
// at any call depth below its setjmp, any number of setjmps and longjmps, any jmp_buf (a pointer compared
// at run time), any value, any continuation shape.
//
//  - ESCAPING functions: a function with a body that calls longjmp/_longjmp/siglongjmp/__longjmp_chk, or
//    calls an escaping function directly. Per escaping function, the jmp_buf and value its escapes carry:
//    one constant each when every escape source (transitively) agrees, else a run-time value.
//  - REWRITTEN in place: every function the preliminary taint calls tainted that holds a setjmp (a
//    returns_twice call taking the jmp_buf pointer). Its signature is unchanged.
//  - ESCAPE CLONES: every escaping function a rewritten function or escape clone calls gets an internal
//    clone G' with the same parameters, returning {G's result fields..., escaped (i1), [jmp_buf (ptr)],
//    [value]}, the bracketed fields present only when not one constant. Its calls in rewritten functions
//    and clones call G' instead. An original left with no use is erased and G' takes its name.
//  - In a rewritten body, each escape point (a longjmp(jb, v); after each call of an escape clone, the
//    branch on its escaped field) jumps to one dispatch block with (jb, v). Each setjmp site s keeps, in
//    frame-local slots, the jmp_buf it was last called on and a stamp of its last execution (0: never).
//    The dispatch takes the matching site (same jmp_buf pointer) executed last: setjmp's second return
//    is the site's continuation run again, a copy of the site's block after the setjmp with the result
//    v != 0 ? v : 1 (C17 7.13.2.1p4), so `setjmp(jb) == 0` there is false. The first return is the
//    original block with the result 0. No matching site: an escape clone returns {poison..., true, jb,
//    v}; a rewritten function (its caller is outside the rewrite: a host frame, or a frame no taint
//    reaches) leaves the lowered program through the host longjmp(jb, v), which lowerLongjmp below
//    lowers: under a quantum predicate rule 16's noreturn arm, abort_i1(pred) (the program the shot
//    lowers ends there), classical the host call.
//  - Values defined in a site's continuation and read elsewhere, and any value whose definition no longer
//    dominates a use after the new edges, go through frame-local slots, promoted back to SSA (mem2reg);
//    the frame-local slots of the sites as well. The rewritten functions are then simplified (constant
//    folding, constant branches, unreachable blocks, single-edge merges): a setjmp that dominates its
//    escaping calls on one constant jmp_buf leaves a branch on the escaped flag alone (101).
//
// lowerSetjmp: a setjmp reaching the walker is a broken invariant (every tainted function holding one is
// rewritten). A returns_twice call taking no jmp_buf (vfork) is rule 16's side-effecting host call.
#include "Setjmp.h"

#include "cq/Common.h"
#include "cq/Effects.h"
#include "cq/Lowering.h"

#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/Analysis/InstructionSimplify.h"
#include "llvm/IR/AttributeMask.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"
#include "llvm/Transforms/Utils/ValueMapper.h"

using namespace llvm;

namespace cq::conc {
namespace {

bool isLongjmpName(StringRef n) {
  return n == "longjmp" || n == "_longjmp" || n == "siglongjmp" || n == "__longjmp_chk";
}

bool isLongjmpCall(const CallBase &CB) {
  const Function *G = CB.getCalledFunction();
  return G && G->isDeclaration() && isLongjmpName(G->getName()) && CB.arg_size() == 2 &&
         CB.getArgOperand(0)->getType()->isPointerTy() && CB.getArgOperand(1)->getType()->isIntegerTy();
}

bool isReturnsTwice(const CallBase &CB) {
  const Function *G = CB.getCalledFunction();
  return CB.hasFnAttr(Attribute::ReturnsTwice) || (G && G->hasFnAttribute(Attribute::ReturnsTwice));
}

// setjmp, _setjmp, sigsetjmp, __sigsetjmp: returns_twice, the jmp_buf its first argument, an int result.
bool isSetjmpCall(const CallBase &CB) {
  return isReturnsTwice(CB) && !CB.isInlineAsm() && CB.arg_size() >= 1 &&
         CB.getArgOperand(0)->getType()->isPointerTy() && CB.getType()->isIntegerTy();
}

// One constant, or a run-time value (Many).
struct Lat {
  enum K { None, One, Many } k = None;
  Value *v = nullptr;
  bool join(Value *x) {
    if (k == Many)
      return false;
    if (!isa<Constant>(x)) {
      k = Many;
      return true;
    }
    if (k == None) {
      k = One;
      v = x;
      return true;
    }
    if (v == x)
      return false;
    k = Many;
    return true;
  }
  bool join(const Lat &o) {
    if (o.k == None)
      return false;
    if (o.k == Many) {
      bool c = k != Many;
      k = Many;
      return c;
    }
    return join(o.v);
  }
};
struct Esc {
  Lat jb, val;
};

struct Layout {
  Type *orig = nullptr;
  bool flat = false;      // orig is a struct whose elements lead the fields
  unsigned nOrig = 0, esc = 0;
  int jb = -1, val = -1;
  SmallVector<Type *, 6> fields;
  Type *ty = nullptr;     // the one field, or the struct of them
};

class Rewriter {
public:
  Rewriter(Module &M, const TaintInfo &T) : M(M), T(T), C(M.getContext()), DL(M.getDataLayout()) {}
  SmallVector<Function *, 8> run();

private:
  Module &M;
  const TaintInfo &T;
  LLVMContext &C;
  const DataLayout &DL;
  MapVector<Function *, Esc> esc;
  MapVector<Function *, Function *> clones;   // G -> G'
  DenseMap<Function *, Layout> layouts;       // by G'
  Type *valTy = nullptr;
  Function *hostLongjmp = nullptr;

  void findEscaping();
  Layout layoutOf(Function &G);
  Function *makeClone(Function &G, const Layout &L);
  void rewrite(Function &H, const Layout *L);
  void cleanup(Function &H, SmallVectorImpl<AllocaInst *> &allocas);
  Function *escapeTarget(const CallBase &CB) const {
    Function *G = CB.getCalledFunction();
    if (!G || G->isDeclaration() || CB.isInlineAsm())
      return nullptr;
    auto it = clones.find(G);
    return it == clones.end() ? nullptr : it->second;
  }
};

void Rewriter::findEscaping() {
  bool changed = true;
  while (changed) {
    changed = false;
    for (Function &F : M) {
      if (F.isDeclaration())
        continue;
      for (Instruction &I : instructions(F)) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB)
          continue;
        if (isLongjmpCall(*CB)) {
          auto [it, ins] = esc.insert({&F, Esc{}});
          changed |= ins;
          changed |= it->second.jb.join(CB->getArgOperand(0));
          changed |= it->second.val.join(CB->getArgOperand(1));
          if (!hostLongjmp) {
            hostLongjmp = CB->getCalledFunction();
            valTy = CB->getArgOperand(1)->getType();
          }
          continue;
        }
        Function *G = CB->getCalledFunction();
        if (!G || G->isDeclaration() || CB->isInlineAsm())
          continue;
        auto g = esc.find(G);
        if (g == esc.end())
          continue;
        Esc from = g->second;
        auto [it, ins] = esc.insert({&F, Esc{}});
        changed |= ins;
        changed |= it->second.jb.join(from.jb);
        changed |= it->second.val.join(from.val);
      }
    }
  }
}

Layout Rewriter::layoutOf(Function &G) {
  Layout L;
  L.orig = G.getReturnType();
  if (auto *st = dyn_cast<StructType>(L.orig)) {
    L.flat = true;
    L.fields.append(st->element_begin(), st->element_end());
  } else if (!L.orig->isVoidTy()) {
    L.fields.push_back(L.orig);
  }
  L.nOrig = L.fields.size();
  L.esc = L.fields.size();
  L.fields.push_back(Type::getInt1Ty(C));
  const Esc &E = esc.find(&G)->second;
  if (E.jb.k != Lat::One) {
    L.jb = L.fields.size();
    L.fields.push_back(PointerType::getUnqual(C));
  }
  if (E.val.k != Lat::One) {
    L.val = L.fields.size();
    L.fields.push_back(valTy);
  }
  L.ty = L.fields.size() == 1 ? L.fields[0] : StructType::get(C, L.fields);
  return L;
}

Function *Rewriter::makeClone(Function &G, const Layout &L) {
  ValueToValueMapTy VM;
  Function *C0 = CloneFunction(&G, VM);
  FunctionType *FT = FunctionType::get(L.ty, G.getFunctionType()->params(), G.isVarArg());
  Function *NF = Function::Create(FT, GlobalValue::InternalLinkage, G.getAddressSpace(), G.getName() + ".cq.esc", &M);
  NF->copyAttributesFrom(C0);
  NF->setLinkage(GlobalValue::InternalLinkage);
  NF->setVisibility(GlobalValue::DefaultVisibility);
  NF->setDLLStorageClass(GlobalValue::DefaultStorageClass);
  NF->setComdat(nullptr);
  AttributeList AL = NF->getAttributes();
  AL = AL.removeRetAttributes(C, AttributeMask(AL.getRetAttrs()));
  AL = AL.removeFnAttribute(C, Attribute::NoReturn);
  AL = AL.removeFnAttribute(C, Attribute::WillReturn);
  NF->setAttributes(AL);
  NF->splice(NF->end(), C0);
  for (unsigned i = 0; i < C0->arg_size(); ++i) {
    C0->getArg(i)->replaceAllUsesWith(NF->getArg(i));
    NF->getArg(i)->takeName(C0->getArg(i));
  }
  C0->eraseFromParent();
  return NF;
}

void Rewriter::rewrite(Function &H, const Layout *L) {
  SmallVector<CallBase *, 4> sites, ljs, calls;
  SmallVector<ReturnInst *, 4> rets;
  for (Instruction &I : instructions(H)) {
    if (auto *R = dyn_cast<ReturnInst>(&I))
      rets.push_back(R);
    auto *CB = dyn_cast<CallBase>(&I);
    if (!CB)
      continue;
    if (isSetjmpCall(*CB))
      sites.push_back(CB);
    else if (isLongjmpCall(*CB))
      ljs.push_back(CB);
    else if (escapeTarget(*CB))
      calls.push_back(CB);
  }
  Type *ptrTy = PointerType::getUnqual(C);
  Type *i64 = Type::getInt64Ty(C);
  SmallVector<AllocaInst *, 8> allocas;
  BasicBlock &entry = H.getEntryBlock();
  auto slot = [&](Type *ty, Value *init, const Twine &name) {
    IRBuilder<> b(&entry, entry.getFirstInsertionPt());
    AllocaInst *A = b.CreateAlloca(ty, nullptr, name);
    if (init)
      b.CreateStore(init, A);
    allocas.push_back(A);
    return A;
  };

  // The dispatch block: one per frame, (jb, v) its phis.
  BasicBlock *D = nullptr;
  PHINode *jbD = nullptr, *vD = nullptr;
  bool anyEscape = !ljs.empty() || !calls.empty();
  if (anyEscape) {
    if (!valTy)
      internalError("eff-conc: an escaping function in a module with no longjmp call");
    D = BasicBlock::Create(C, "cq.sj.escape", &H);
    IRBuilder<> b(D);
    jbD = b.CreatePHI(ptrTy, 2, "cq.sj.jb");
    vD = b.CreatePHI(valTy, 2, "cq.sj.val");
  }

  // longjmp(jb, v): the escape point itself.
  for (CallBase *LJ : ljs) {
    BasicBlock *B = LJ->getParent();
    IRBuilder<> b(LJ);
    Value *jb = LJ->getArgOperand(0);
    Value *v = b.CreateSExtOrTrunc(LJ->getArgOperand(1), valTy);
    SmallPtrSet<BasicBlock *, 4> succs(succ_begin(B), succ_end(B));
    for (BasicBlock *S : succs)
      S->removePredecessor(B);
    while (&B->back() != LJ) {
      Instruction &X = B->back();
      if (!X.getType()->isVoidTy())
        X.replaceAllUsesWith(PoisonValue::get(X.getType()));
      X.eraseFromParent();
    }
    LJ->eraseFromParent();
    BranchInst::Create(D, B);
    jbD->addIncoming(jb, B);
    vD->addIncoming(v, B);
  }

  // A call of an escaping function: its escape clone, then the branch on the escaped field.
  for (CallBase *CB : calls) {
    Function *G = CB->getCalledFunction();
    Function *NF = clones.find(G)->second;
    const Layout &CL = layouts.find(NF)->second;
    const Esc &E = esc.find(G)->second;
    auto *CI = dyn_cast<CallInst>(CB);
    if (!CI)
      internalError("eff-conc: an invoke or callbr of a function with a body (CR rule 25, §0: not an input)", CB);
    IRBuilder<> b(CI);
    SmallVector<Value *, 8> args(CI->args());
    SmallVector<OperandBundleDef, 2> bundles;
    CI->getOperandBundlesAsDefs(bundles);
    CallInst *N = b.CreateCall(NF->getFunctionType(), NF, args, bundles);
    N->setCallingConv(CI->getCallingConv());
    AttributeList AL = CI->getAttributes();
    AL = AL.removeRetAttributes(C, AttributeMask(AL.getRetAttrs()));
    AL = AL.removeFnAttribute(C, Attribute::NoReturn);
    N->setAttributes(AL);
    N->setDebugLoc(CI->getDebugLoc());
    auto field = [&](unsigned k) -> Value * { return CL.ty->isStructTy() ? b.CreateExtractValue(N, {k}) : N; };
    Value *e = field(CL.esc);
    Value *jb = CL.jb >= 0 ? field(CL.jb) : E.jb.v;
    Value *v = CL.val >= 0 ? field(CL.val) : b.CreateSExtOrTrunc(E.val.v, valTy);
    if (!CI->getType()->isVoidTy()) {
      Value *r;
      if (CL.flat) {
        r = PoisonValue::get(CI->getType());
        for (unsigned k = 0; k < CL.nOrig; ++k)
          r = b.CreateInsertValue(r, field(k), {k});
      } else {
        r = field(0);
      }
      CI->replaceAllUsesWith(r);
    }
    N->takeName(CI);
    Instruction *next = CI->getNextNode();
    CI->eraseFromParent();
    BasicBlock *B = N->getParent();
    BasicBlock *Cont = B->splitBasicBlock(next, B->getName() + ".cq.ret");
    B->getTerminator()->eraseFromParent();
    BranchInst::Create(D, Cont, e, B);
    jbD->addIncoming(jb, B);
    vD->addIncoming(v, B);
  }

  // The frame's exit for an escape no site of it catches.
  BasicBlock *Out = nullptr;
  if (L) {
    // An escape clone: one return block, {result fields..., escaped, [jb], [v]}.
    BasicBlock *R = BasicBlock::Create(C, "cq.sj.return", &H);
    IRBuilder<> rb(R);
    SmallVector<PHINode *, 6> ph;
    for (Type *t : L->fields)
      ph.push_back(rb.CreatePHI(t, 2));
    auto add = [&](BasicBlock *from, ArrayRef<Value *> vals) {
      for (unsigned k = 0; k < ph.size(); ++k)
        ph[k]->addIncoming(vals[k], from);
    };
    for (ReturnInst *Ret : rets) {
      BasicBlock *B = Ret->getParent();
      IRBuilder<> b(Ret);
      SmallVector<Value *, 6> vals;
      if (Value *X = Ret->getReturnValue()) {
        if (L->flat)
          for (unsigned k = 0; k < L->nOrig; ++k)
            vals.push_back(b.CreateExtractValue(X, {k}));
        else
          vals.push_back(X);
      }
      vals.push_back(ConstantInt::getFalse(C));
      if (L->jb >= 0)
        vals.push_back(PoisonValue::get(ptrTy));
      if (L->val >= 0)
        vals.push_back(PoisonValue::get(valTy));
      Ret->eraseFromParent();
      BranchInst::Create(R, B);
      add(B, vals);
    }
    if (D) {
      Out = BasicBlock::Create(C, "cq.sj.propagate", &H);
      SmallVector<Value *, 6> vals;
      for (unsigned k = 0; k < L->nOrig; ++k)
        vals.push_back(PoisonValue::get(L->fields[k]));
      vals.push_back(ConstantInt::getTrue(C));
      if (L->jb >= 0)
        vals.push_back(jbD);
      if (L->val >= 0)
        vals.push_back(vD);
      BranchInst::Create(R, Out);
      add(Out, vals);
    }
    Value *rv = nullptr;
    if (L->ty->isStructTy()) {
      rv = PoisonValue::get(L->ty);
      for (unsigned k = 0; k < ph.size(); ++k)
        rv = rb.CreateInsertValue(rv, ph[k], {k});
    } else {
      rv = ph[0];
    }
    rb.CreateRet(rv);
  } else if (D) {
    // A rewritten function: the host longjmp, out of the lowered program.
    Out = BasicBlock::Create(C, "cq.sj.leave", &H);
    IRBuilder<> b(Out);
    FunctionType *LT = hostLongjmp->getFunctionType();
    CallInst *lj = b.CreateCall(LT, hostLongjmp, {jbD, b.CreateSExtOrTrunc(vD, LT->getParamType(1))});
    lj->setDoesNotReturn();
    b.CreateUnreachable();
  }

  // The setjmp sites.
  AllocaInst *ctr = D && !sites.empty() ? slot(i64, ConstantInt::get(i64, 0), "cq.sj.clock") : nullptr;
  SmallVector<AllocaInst *, 4> stamps, bufs;
  SmallVector<BasicBlock *, 4> again;
  for (CallBase *SJ : sites) {
    BasicBlock *S = SJ->getParent();
    if (!D) {
      // No escape can reach this frame: setjmp returns once, 0.
      SJ->replaceAllUsesWith(ConstantInt::get(SJ->getType(), 0));
      SJ->eraseFromParent();
      continue;
    }
    // Values of the continuation (SJ and what follows it in S) read outside it go through slots: they
    // are defined both by the first return (S) and by the second (the copy below).
    auto outside = [&](const Use &U) {
      auto *I = cast<Instruction>(U.getUser());
      return I->getParent() != S || isa<PHINode>(I);
    };
    SmallVector<Instruction *, 8> defs;
    for (Instruction *I = SJ; I; I = I->getNextNode())
      if (!I->getType()->isVoidTy() && any_of(I->uses(), outside))
        defs.push_back(I);
    for (Instruction *I : defs) {
      AllocaInst *A = slot(I->getType(), nullptr, I->getName() + ".cq.sj");
      DenseMap<std::pair<PHINode *, BasicBlock *>, Value *> phiLoads;
      for (Use &U : make_early_inc_range(I->uses())) {
        if (!outside(U))
          continue;
        auto *User = cast<Instruction>(U.getUser());
        if (auto *P = dyn_cast<PHINode>(User)) {
          BasicBlock *in = P->getIncomingBlock(U);
          Value *&ld = phiLoads[{P, in}];
          if (!ld)
            ld = new LoadInst(I->getType(), A, I->getName() + ".cq.ld", in->getTerminator());
          U.set(ld);
        } else {
          U.set(new LoadInst(I->getType(), A, I->getName() + ".cq.ld", User));
        }
      }
      new StoreInst(I, A, I->getNextNode());
    }
    // setjmp's second return: the continuation again, the result v != 0 ? v : 1.
    BasicBlock *Again = BasicBlock::Create(C, "cq.sj.again", &H);
    IRBuilder<> cb(Again);
    Value *v = cb.CreateSelect(cb.CreateICmpEQ(vD, ConstantInt::get(valTy, 0)), ConstantInt::get(valTy, 1), vD);
    Value *r = cb.CreateSExtOrTrunc(v, SJ->getType());
    ValueToValueMapTy VM;
    VM[SJ] = r;
    for (Instruction *I = SJ->getNextNode(); I; I = I->getNextNode()) {
      Instruction *c = I->clone();
      c->insertInto(Again, Again->end());
      RemapInstruction(c, VM, RF_IgnoreMissingLocals | RF_NoModuleLevelChanges);
      if (!I->getName().empty())
        c->setName(I->getName() + ".again");
      VM[I] = c;
      // C17 7.13.2.1p4: the second return is never 0.
      if (auto *cmp = dyn_cast<ICmpInst>(c); cmp && cmp->isEquality()) {
        Value *a = cmp->getOperand(0), *z = cmp->getOperand(1);
        if (a != r)
          std::swap(a, z);
        if (a == r && match(z, PatternMatch::m_Zero())) {
          Constant *k = ConstantInt::getBool(C, cmp->getPredicate() == CmpInst::ICMP_NE);
          VM[I] = k;
          cmp->replaceAllUsesWith(k);
          cmp->eraseFromParent();
        }
      }
    }
    for (BasicBlock *X : SmallSetVector<BasicBlock *, 4>(succ_begin(S), succ_end(S)))
      for (PHINode &P : X->phis()) {
        SmallVector<Value *, 2> ins;
        for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
          if (P.getIncomingBlock(i) == S)
            ins.push_back(P.getIncomingValue(i));
        for (Value *in : ins) {
          auto it = VM.find(in);
          P.addIncoming(it != VM.end() ? static_cast<Value *>(it->second) : in, Again);
        }
      }
    // The first return: arm the site, the result 0.
    AllocaInst *stamp = slot(i64, ConstantInt::get(i64, 0), "cq.sj.stamp");
    AllocaInst *buf = slot(ptrTy, ConstantPointerNull::get(cast<PointerType>(ptrTy)), "cq.sj.buf");
    IRBuilder<> ab(SJ);
    Value *n = ab.CreateAdd(ab.CreateLoad(i64, ctr), ConstantInt::get(i64, 1));
    ab.CreateStore(n, ctr);
    ab.CreateStore(n, stamp);
    ab.CreateStore(SJ->getArgOperand(0), buf);
    SJ->replaceAllUsesWith(ConstantInt::get(SJ->getType(), 0));
    SJ->eraseFromParent();
    stamps.push_back(stamp);
    bufs.push_back(buf);
    again.push_back(Again);
  }

  // The dispatch: the matching site executed last, else out of the frame.
  if (D) {
    IRBuilder<> db(D);
    if (again.empty()) {
      db.CreateBr(Out);
    } else {
      Type *i32 = Type::getInt32Ty(C);
      Value *best = ConstantInt::get(i32, -1), *bestStamp = ConstantInt::get(i64, 0);
      for (unsigned k = 0; k < again.size(); ++k) {
        Value *st = db.CreateLoad(i64, stamps[k]);
        Value *bf = db.CreateLoad(ptrTy, bufs[k]);
        Value *take = db.CreateAnd(db.CreateICmpEQ(bf, jbD), db.CreateICmpUGT(st, bestStamp));
        best = db.CreateSelect(take, ConstantInt::get(i32, k), best);
        bestStamp = db.CreateSelect(take, st, bestStamp);
      }
      SwitchInst *sw = db.CreateSwitch(best, Out, again.size());
      for (unsigned k = 0; k < again.size(); ++k)
        sw->addCase(cast<ConstantInt>(ConstantInt::get(i32, k)), again[k]);
    }
  }
  cleanup(H, allocas);
}

void Rewriter::cleanup(Function &H, SmallVectorImpl<AllocaInst *> &allocas) {
  // Definitions that no longer dominate a use (a value of the setjmp's frame read on its second return,
  // reached now from an escape point it does not dominate) go through slots as well.
  for (;;) {
    DominatorTree DT(H);
    SmallVector<Instruction *, 8> bad;
    for (Instruction &I : instructions(H)) {
      if (isa<AllocaInst>(I) || I.getType()->isVoidTy())
        continue;
      for (const Use &U : I.uses())
        if (!DT.dominates(&I, U)) {
          bad.push_back(&I);
          break;
        }
    }
    if (bad.empty())
      break;
    for (Instruction *I : bad)
      allocas.push_back(DemoteRegToStack(*I));
  }
  {
    DominatorTree DT(H);
    SmallVector<AllocaInst *, 8> prom;
    for (AllocaInst *A : allocas)
      if (isAllocaPromotable(A))
        prom.push_back(A);
      else
        internalError("eff-conc: a frame-local slot of the setjmp rewrite that mem2reg cannot promote", A);
    if (!prom.empty())
      PromoteMemToReg(prom, DT);
  }
  SimplifyQuery Q(DL);
  for (bool again = true; again;) {
    again = false;
    for (BasicBlock &BB : H)
      for (Instruction &I : make_early_inc_range(BB)) {
        if (Value *V = simplifyInstruction(&I, Q); V && V != &I) {
          I.replaceAllUsesWith(V);
          again = true;
        }
        if (isInstructionTriviallyDead(&I)) {
          I.eraseFromParent();
          again = true;
        }
      }
    for (BasicBlock &BB : H)
      again |= ConstantFoldTerminator(&BB, /*DeleteDeadConditions=*/true);
    again |= removeUnreachableBlocks(H);
  }
  SmallVector<BasicBlock *, 16> blocks;
  for (BasicBlock &BB : H)
    blocks.push_back(&BB);
  for (BasicBlock *BB : blocks)
    if (BB != &H.getEntryBlock())
      MergeBlockIntoPredecessor(BB);
}

SmallVector<Function *, 8> Rewriter::run() {
  SmallVector<Function *, 8> out;
  SmallVector<Function *, 4> inPlace;
  for (Function &F : M)
    if (!F.isDeclaration() && T.isTainted(F))
      for (Instruction &I : instructions(F))
        if (auto *CB = dyn_cast<CallBase>(&I); CB && isSetjmpCall(*CB)) {
          inPlace.push_back(&F);
          break;
        }
  if (inPlace.empty())
    return out;
  findEscaping();

  // The escape clones: closure over direct calls of escaping functions.
  SetVector<Function *> need;
  SmallVector<Function *, 8> work(inPlace.begin(), inPlace.end());
  SmallPtrSet<Function *, 8> seen(inPlace.begin(), inPlace.end());
  while (!work.empty()) {
    Function *F = work.pop_back_val();
    for (Instruction &I : instructions(*F))
      if (auto *CB = dyn_cast<CallBase>(&I))
        if (Function *G = CB->getCalledFunction(); G && !G->isDeclaration() && !CB->isInlineAsm() &&
                                                   esc.count(G) && need.insert(G) && seen.insert(G).second)
          work.push_back(G);
  }
  // Clones from the original bodies, before any body is rewritten.
  for (Function *G : need) {
    Layout L = layoutOf(*G);
    Function *NF = makeClone(*G, L);
    clones.insert({G, NF});
    layouts.insert({NF, L});
  }
  for (auto &[G, NF] : clones) {
    rewrite(*NF, &layouts.find(NF)->second);
    out.push_back(NF);
  }
  for (Function *F : inPlace) {
    rewrite(*F, nullptr);
    out.push_back(F);
  }
  // An original no call reaches any more is dropped; its clone takes its name.
  for (auto &[G, NF] : clones)
    if (G->use_empty() && G->hasLocalLinkage() && !is_contained(inPlace, G)) {
      std::string name = G->getName().str();
      G->eraseFromParent();
      NF->setName(name);
    }
  return out;
}

} // namespace

SmallVector<Function *, 8> explicitSetjmp(Module &M, const TaintInfo &T) { return Rewriter(M, T).run(); }

void lowerSetjmp(LoweringContext &ctx, CallBase &CB) {
  if (isSetjmpCall(CB))
    internalError("eff-conc: a setjmp in a lowered function (rule 24: conc::explicitSetjmp rewrites every tainted "
                  "function that holds one before the final taint)",
                  &CB);
  // A returns_twice call that takes no jmp_buf (vfork): rule 16's side-effecting host call.
  tape::lowerHostEffect(ctx, CB);
}

void lowerLongjmp(LoweringContext &ctx, CallBase &CB) {
  // Rule 24 after explicitSetjmp: a longjmp left in a lowered function escapes to a setjmp in no lowered
  // frame (a host frame): the program the shot lowers ends there, rule 16's noreturn arm.
  tape::lowerNoreturn(ctx, CB);
}

} // namespace cq::conc
