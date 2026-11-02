// The cq-lower and cq-verify passes (scaffold, cq-arch "Pass pipeline").
//
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes=cq-lower
//       [-cq-k=<fn>=<k>,...] [-cq-k-default=<k>] [-cq-roots=<file>] [-cq-dump-taint]
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes=cq-verify            (our output)
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes='cq-verify<reference>' (a reference)
//
// cq-lower: a preliminary taint, used only for isTainted(F); FixIrreduciblePass on those
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

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/InstrTypes.h"
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

    // 1c. CR rule 24: setjmp/longjmp as explicit control flow (eff-conc, Setjmp.cpp), in the tainted
    // functions holding a setjmp and the escape clones it makes. Its CFG changes are final-taint input.
    SmallVector<Function *, 8> SJ = cq::conc::explicitSetjmp(M, T);
    if (!SJ.empty()) {
      trace("explicit-setjmp: changed");
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
