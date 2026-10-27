// The cq-lower and cq-verify passes (scaffold, cq-arch "Pass pipeline").
//
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes=cq-lower
//       [-cq-k=<fn>=<k>,...] [-cq-k-default=<k>] [-cq-roots=<file>] [-cq-dump-taint]
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes=cq-verify            (our output)
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes='cq-verify<reference>' (a reference)
//
// cq-lower: taint; FixIrreduciblePass on tainted functions only; construct per specialization;
// calls::finalize; verifyLowered. A module that uses no CQ.h function and has no -cq-roots has no
// taint source (rule 3: taint starts at cq_theta results), so it is returned untouched before
// anything runs: the pass's identity (NORTHSTAR principle 1, kernel tier 1).
#include <string>

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Common.h"
#include "cq/Lowering.h"
#include "cq/Loops.h"
#include "cq/Taint.h"
#include "cq/Verify.h"

#include "llvm/ADT/StringRef.h"
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

bool usesCqSurface(const Module &M) {
  for (const Function &F : M)
    if (isCqSurface(F.getName()) && !F.use_empty())
      return true;
  return false;
}

struct CQLowerPass : PassInfoMixin<CQLowerPass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &MAM) {
    cq::TaintOptions TO = readTaintOptions();
    // Read now so a malformed flag fails on every module. It reaches no module yet: construct() and
    // LoweringContext have no K channel in cq-arch (see the scaffold report).
    (void)readKOptions();
    if (TO.roots.empty() && !usesCqSurface(M))
      return PreservedAnalyses::all();

    // 1. Taint.
    cq::TaintInfo T = cq::computeTaint(M, TO);
    if (DumpTaint)
      T.print(errs());

    // 2. Reducible control flow, on tainted functions only.
    FunctionAnalysisManager &FAM = MAM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();
    for (Function &F : M) {
      if (F.isDeclaration() || !T.isTainted(F))
        continue;
      PreservedAnalyses PA = FixIrreduciblePass().run(F, FAM);
      FAM.invalidate(F, PA);
    }

    // 3. The general construction, once per specialization.
    for (const cq::Specialization &S : T.specializations())
      cq::construct(M, T, S);

    // 4. Drop originals with no classical caller (rule 18).
    cq::calls::finalize(M);

    // 5. The structural verifier, on every run.
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
