// The cq-lower and cq-verify passes (scaffold, cq-arch "Pass pipeline").
//
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes=cq-lower
//       [-cq-k=<fn>=<k>,...] [-cq-k-default=<k>] [-cq-roots=<file>] [-cq-dump-taint]
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes=cq-verify            (our output)
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes='cq-verify<reference>' (a reference)
//
// cq-lower: a preliminary taint, used only for isTainted(F) and by eff-conc's pre-taint rewrites (rule 24:
// atomic read-modify-writes through fat pointers and the thread calls collapsed, setjmp/longjmp made
// explicit control flow,
// Setjmp.h); FixIrreduciblePass on those
// functions; if any function changed, a fresh taint over the module with the preliminary result
// discarded; construct per specialization; calls::finalize; verifyLowered. Taint is computed once
// over the final CFG and nothing mutates the CFG after it (owner ruling on cq-5k5, option (a)).
// A module with no call to a CQ.h function and no -cq-roots is returned untouched before anything
// runs (owner ruling 2 on cq-arch: the condition is on calls, not declarations or other uses): the
// pass's identity (NORTHSTAR principle 1, kernel tier 1).
#include <functional>
#include <string>
#include <vector>

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Common.h"
#include "cq/Effects.h"
#include "cq/Lowering.h"
#include "cq/Loops.h"
#include "cq/Taint.h"
#include "cq/Verify.h"
#include "eff/conc/Setjmp.h"
#include "eff/invert/Split.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/FixIrreducible.h"

using namespace llvm;

namespace {

cl::list<std::string> KPerFunction("cq-k", cl::CommaSeparated, cl::value_desc("fn=k"),
                                   cl::desc("cq: per-function loop cutoff K, e.g. -cq-k=fmod=2046,sin=53"));
cl::opt<unsigned> KDefault("cq-k-default", cl::value_desc("k"),
                           cl::desc("cq: global loop cutoff K (built-in default 4)"));
cl::opt<std::string> RootsFile("cq-roots", cl::value_desc("file"),
                               cl::desc("cq: library-build roots, one clone name (CR §1.4) per line"));
cl::opt<bool> DumpTaint("cq-dump-taint", cl::desc("cq: print the taint result to stderr"));
// Private to scaffold (Plugin.cpp and tests/scaffold): one stderr line per pipeline step, so a test
// can see that the taint the constructions read is the one computed over the final CFG.
cl::opt<bool> TracePipeline("cq-trace-pipeline", cl::Hidden,
                            cl::desc("cq: print each cq-lower pipeline step to stderr"));

// Private to eff-conc's tests: the module after the rule-24 setjmp rewrite, on stderr.
cl::opt<bool> DumpSetjmp("cq-dump-setjmp", cl::Hidden,
                         cl::desc("cq: print the module after the rule 24 setjmp rewrite to stderr"));

void trace(const Twine &step) {
  if (TracePipeline)
    errs() << "cq-lower: " << step << "\n";
}

[[noreturn]] void usageError(const Twine &msg) {
  report_fatal_error("cq: " + msg, /*gen_crash_diag=*/false);
}

// -cq-k and -cq-k-default. The precedence (flag, CQ_K, global, default 4) is loops::resolveK's.
cq::loops::KOptions readKOptions() {
  cq::loops::KOptions K;
  for (const std::string &item : KPerFunction) {
    auto [fn, k] = StringRef(item).split('=');
    unsigned v = 0;
    if (fn.empty() || k.empty() || k.getAsInteger(10, v) || v == 0)
      usageError("-cq-k: expected <fn>=<k> with k >= 1, got '" + item + "'");
    K.perFunction[fn.str()] = v;
  }
  if (KDefault.getNumOccurrences()) {
    if (KDefault == 0)
      usageError("-cq-k-default: expected k >= 1");
    K.global = KDefault;
  }
  return K;
}

cq::TaintOptions readTaintOptions() {
  cq::TaintOptions TO;
  if (RootsFile.empty())
    return TO;
  auto buf = MemoryBuffer::getFile(RootsFile);
  if (!buf)
    usageError("-cq-roots: cannot read '" + RootsFile + "': " + buf.getError().message());
  SmallVector<StringRef, 64> lines;
  (*buf)->getBuffer().split(lines, '\n', -1, /*KeepEmpty=*/false);
  for (StringRef line : lines) {
    line = line.trim();
    if (line.empty())
      continue;
    std::optional<cq::abi::CloneSpec> spec = cq::abi::parseClone(line);
    if (!spec)
      usageError("-cq-roots: not a clone name: '" + line + "'");
    TO.roots.push_back(std::move(*spec));
  }
  return TO;
}

// The CQ.h surface: cq_theta_*, cq_measure_*, cq_phi, __cq_invert_begin, __cq_invert_end.
// cq-jkq8: one return block per tainted function, the same kind of rewrite as fix-irreducible (CR rule 14:
// a semantics-preserving CFG rewrite before the final taint; §6 compares semantics, never CFG shape). Each
// return becomes a branch to one block returning the phi of their values, so a return under a quantum
// predicate is the function's only return (the paths outside its predicate never return: they abort or never
// end, rules 14 and 16) and returns on several quantum paths merge by rule 9 at that phi. A musttail call
// (clang's [[clang::musttail]]) becomes an ordinary tail call: the lowering calls clones of other signatures
// anyway, and C semantics do not depend on the frame being reused.
bool unifyReturns(Function &F) {
  SmallVector<ReturnInst *, 4> rets;
  for (BasicBlock &BB : F)
    if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
      rets.push_back(R);
  if (rets.size() < 2)
    return false;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (auto *CI = dyn_cast<CallInst>(&I); CI && CI->isMustTailCall())
        CI->setTailCallKind(CallInst::TCK_Tail);
  LLVMContext &C = F.getContext();
  BasicBlock *U = BasicBlock::Create(C, "cq.ret", &F);
  PHINode *PN = nullptr;
  if (!F.getReturnType()->isVoidTy()) {
    PN = PHINode::Create(F.getReturnType(), unsigned(rets.size()), "cq.retval");
    PN->insertInto(U, U->end());
  }
  ReturnInst::Create(C, PN, U);
  for (ReturnInst *R : rets) {
    BasicBlock *BB = R->getParent();
    if (PN)
      PN->addIncoming(R->getReturnValue(), BB);
    R->eraseFromParent();
    BranchInst::Create(U, BB);
  }
  return true;
}

// cq-jkq8 (CR rule 23): llvm.get.rounding (C's FLT_ROUNDS) and llvm.set.rounding read and write the rounding
// mode, the environment's mode part, which C17 §7.6 reads and writes by fegetround / fesetround. In a tainted
// function each becomes that call with x86-64's encoding change around it (FLT_ROUNDS 0 toward zero, 1 nearest,
// 2 upward, 3 downward; FE_* the rounding-control bits << 10), so rule 23's fenv construction lowers it, a
// quantum mode included (the encoding change is ordinary arithmetic on the mode). An argument of set.rounding
// outside 0..3 has no defined effect (LangRef), outside the domain.
bool rewriteRoundingIntrinsics(Function &F) {
  SmallVector<IntrinsicInst *, 4> work;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (auto *II = dyn_cast<IntrinsicInst>(&I);
          II && (II->getIntrinsicID() == Intrinsic::get_rounding || II->getIntrinsicID() == Intrinsic::set_rounding))
        work.push_back(II);
  if (work.empty())
    return false;
  Module &M = *F.getParent();
  Type *i32 = Type::getInt32Ty(M.getContext());
  for (IntrinsicInst *II : work) {
    IRBuilder<> B(II);
    if (II->getIntrinsicID() == Intrinsic::get_rounding) {
      FunctionCallee get = M.getOrInsertFunction("fegetround", FunctionType::get(i32, false));
      Value *m = B.CreateCall(get);
      // FLT_ROUNDS = (0x2d >> ((m >> 9) & 6)) & 3 for m one of 0, 0x400, 0x800, 0xc00.
      Value *s = B.CreateAnd(B.CreateLShr(m, 9), 6);
      Value *r = B.CreateAnd(B.CreateLShr(ConstantInt::get(i32, 0x2d), s), 3);
      if (r->getType() != II->getType())
        r = B.CreateZExtOrTrunc(r, II->getType());
      II->replaceAllUsesWith(r);
    } else {
      FunctionCallee set = M.getOrInsertFunction("fesetround", FunctionType::get(i32, {i32}, false));
      // FE_* = ((0x63 >> 2r) & 3) << 10: r = 0, 1, 2, 3 to 0xc00, 0, 0x800, 0x400.
      Value *r = B.CreateZExtOrTrunc(II->getArgOperand(0), i32);
      Value *rc = B.CreateAnd(B.CreateLShr(ConstantInt::get(i32, 0x63), B.CreateShl(r, 1)), 3);
      B.CreateCall(set, {B.CreateShl(rc, 10)});
    }
    II->eraseFromParent();
  }
  return true;
}

bool isCqSurface(StringRef name) {
  return name.starts_with("cq_theta_") || name.starts_with("cq_measure_") || name == "cq_phi" ||
         name == "__cq_invert_begin" || name == "__cq_invert_end";
}

// True iff some call site calls a CQ.h surface function directly (owner ruling 2 on cq-arch). Only
// a CallBase whose callee operand is the function counts: a declaration, a store of the address, an
// @llvm.used entry, a constant expression or the function passed as a call argument does not.
// cq_phi alone counts (rule 12 deletes it; the deletion is the pass's to make).
bool callsCqSurface(const Module &M) {
  for (const Function &F : M) {
    if (!isCqSurface(F.getName()))
      continue;
    for (const Use &U : F.uses())
      if (const auto *CB = dyn_cast<CallBase>(U.getUser()); CB && CB->isCallee(&U))
        return true;
  }
  return false;
}

// cq-i9wk (CR rule 19): an in-place callee (reached with no quantum argument) is constructed before its
// callers, which read whether its quantum results are frozen (spine::entryReturn). Otherwise taint's
// order; a cycle of in-place calls keeps it.
std::vector<const cq::Specialization *> constructionOrder(const cq::TaintInfo &T) {
  llvm::ArrayRef<cq::Specialization> all = T.specializations();
  std::vector<const cq::Specialization *> order;
  llvm::DenseMap<const cq::Specialization *, int> state;   // 1 in progress, 2 done
  std::function<void(const cq::Specialization &)> visit = [&](const cq::Specialization &S) {
    int &st = state[&S];
    if (st)
      return;
    st = 1;
    if (!S.F->isDeclaration() && !S.pure)
      for (BasicBlock &BB : *S.F)
        for (Instruction &I : BB)
          if (auto *CB = dyn_cast<CallBase>(&I);
              CB && CB->getCalledFunction() && !CB->getCalledFunction()->isDeclaration() && !CB->isInlineAsm())
            if (const cq::Specialization *C = T.calleeSpecialization(*CB, S); C && C != &S && C->isEntry())
              visit(*C);
    state[&S] = 2;
    order.push_back(&S);
  };
  for (const cq::Specialization &S : all)
    visit(S);
  return order;
}

struct CQLowerPass : PassInfoMixin<CQLowerPass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &MAM) {
    cq::TaintOptions TO = readTaintOptions();
    // Read before the identity exit so a malformed flag fails on every module.
    cq::loops::KOptions KO = readKOptions();
    if (TO.roots.empty() && !callsCqSurface(M))
      return PreservedAnalyses::all();

    FunctionAnalysisManager &FAM = MAM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();

    // 1. Preliminary taint. Read only for isTainted(F): which functions step 2 may touch.
    trace("taint: preliminary");
    cq::TaintInfo T = cq::computeTaint(M, TO);
    SmallVector<Function *, 16> Tainted;
    for (Function &F : M)
      if (!F.isDeclaration() && T.isTainted(F))
        Tainted.push_back(&F);

    // 1b. Rule 16: a deferred host call's result the program reads is the library's formatting body on a
    // null buffer (cq-a63l). No CFG change; the taint below is recomputed when it rewrote anything.
    bool CFGChanged = cq::tape::rewriteDeferredResults(M, T);
    if (CFGChanged) {
      T = cq::TaintInfo();
      T = cq::computeTaint(M, TO);
      Tainted.clear();
      for (Function &F : M)
        if (!F.isDeclaration() && T.isTainted(F))
          Tainted.push_back(&F);
    }

    // 1c. CR rule 24 (eff-conc, Setjmp.h), in tainted functions: atomic read-modify-writes through fat
    // pointers as the plain load + op + store, the thread calls as the sequential schedule, then (it may
    // erase originals, so T is read before) setjmp/longjmp as explicit control flow with its escape clones.
    // Their CFG changes are final-taint input.
    SmallPtrSet<Function *, 8> changed;
    for (Function *F : cq::conc::collapseFatAtomics(M, T))
      changed.insert(F);
    for (Function *F : cq::conc::collapseThreads(M, T))
      changed.insert(F);
    for (Function *F : cq::conc::explicitSetjmp(M, T))   // may erase originals: compared, never read
      changed.insert(F);
    SmallVector<Function *, 8> SJ;
    for (Function &F : M)
      if (changed.count(&F))
        SJ.push_back(&F);
    if (!SJ.empty()) {
      trace("rule 24 rewrites: changed");
      if (DumpSetjmp)
        M.print(errs(), nullptr);
      CFGChanged = true;
      Tainted.clear();
      for (Function &F : M)
        if (!F.isDeclaration() && (T.isTainted(F) || is_contained(SJ, &F)))
          Tainted.push_back(&F);
      for (Function *F : SJ)
        FAM.invalidate(*F, PreservedAnalyses::none());
    }

    // 1d. CR rule 17 (2026-11-02, cq-asfn): a cq_invert marker in a quantum arm whose match is outside the
    // arm: the tail is split per region depth (eff-invert Split.h). Its CFG changes are final-taint input.
    for (Function *F : cq::invert::splitMarkerPaths(M, T)) {
      trace("rule 17 marker paths: changed @" + F->getName());
      CFGChanged = true;
      FAM.invalidate(*F, PreservedAnalyses::none());
    }

    // 2. Reducible control flow, on tainted functions only (NORTHSTAR principle 1). The pass
    // returns PreservedAnalyses::all() exactly when it left the function unchanged.
    for (Function *F : Tainted) {
      PreservedAnalyses PA = FixIrreduciblePass().run(*F, FAM);
      if (PA.areAllPreserved())
        continue;
      trace("fix-irreducible: changed @" + F->getName());
      CFGChanged = true;
      FAM.invalidate(*F, PA);
    }
    // 2b. One return block per tainted function (unifyReturns), and the rounding intrinsics as the C17 calls
    // (rewriteRoundingIntrinsics), cq-jkq8.
    for (Function *F : Tainted) {
      if (!rewriteRoundingIntrinsics(*F))
        continue;
      trace("rounding intrinsics: changed @" + F->getName());
      CFGChanged = true;
      FAM.invalidate(*F, PreservedAnalyses::none());
    }
    for (Function *F : Tainted) {
      if (!unifyReturns(*F))
        continue;
      trace("unify-returns: changed @" + F->getName());
      CFGChanged = true;
      FAM.invalidate(*F, PreservedAnalyses::none());
    }

    // 3. Taint over the final CFG. Step 2 added blocks, phis and branches the preliminary result
    // has no answer for, so it is released first and replaced by a fresh analysis; no handle to
    // it survives. Unchanged CFG: the preliminary result already is the taint of the final CFG.
    if (CFGChanged) {
      T = cq::TaintInfo();
      trace("taint: final (fresh, CFG changed)");
      T = cq::computeTaint(M, TO);
    } else {
      trace("taint: final (preliminary, CFG unchanged)");
    }
    const cq::TaintInfo &Final = T;
    if (DumpTaint)
      Final.print(errs());

    // 4. The general construction, once per specialization. The CFG is final from here on.
    trace("construct");
    for (const cq::Specialization *S : constructionOrder(Final))
      cq::construct(M, Final, *S, KO);

    // 5. Drop originals with no classical caller (rule 18).
    cq::calls::finalize(M);

    // CR rule 13 (b137e75): a lowered computed goto compares its address with blockaddress constants, which a
    // clone (or another lowered function) may take of another function's block. The textual IR names such a
    // block only by name (an unnamed block cannot be referenced from a function printed after its own), so a
    // block whose address is taken outside its own function gets one.
    for (Function &F : M)
      for (BasicBlock &BB : F)
        if (BB.hasAddressTaken() && !BB.hasName())
          if (BlockAddress *BA = BlockAddress::lookup(&BB))
            for (const User *U : BA->users())
              if (auto *CE = dyn_cast<ConstantExpr>(U); CE ? any_of(CE->users(), [&](const User *V) {
                    auto *I = dyn_cast<Instruction>(V);
                    return I && I->getFunction() != &F;
                  })
                                                            : isa<Instruction>(U) &&
                                                                  cast<Instruction>(U)->getFunction() != &F) {
                BB.setName("cq.addr");
                break;
              }

    // 6. The structural verifier, on every run.
    cq::verifyLowered(M);
    return PreservedAnalyses::none();
  }
  static bool isRequired() { return true; }
};

struct CQVerifyPass : PassInfoMixin<CQVerifyPass> {
  cq::VerifyOptions Opts;
  explicit CQVerifyPass(cq::VerifyOptions O) : Opts(O) {}
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    cq::verifyLowered(M, Opts);
    return PreservedAnalyses::all();
  }
  static bool isRequired() { return true; }
};

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "CQLower", "0", [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
                  if (name == "cq-lower") {
                    MPM.addPass(CQLowerPass());
                    return true;
                  }
                  if (name == "cq-verify") {
                    MPM.addPass(CQVerifyPass(cq::VerifyOptions{}));
                    return true;
                  }
                  if (name == "cq-verify<reference>") {
                    cq::VerifyOptions O;
                    O.reference = true;
                    MPM.addPass(CQVerifyPass(O));
                    return true;
                  }
                  return false;
                });
          }};
}
