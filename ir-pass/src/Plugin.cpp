// Plugin.cpp — LLVM pass-plugin entry point for libCQPass.so.
//
// Registers only the cq-lowering pass. The prototype's other three passes
// (cq-uncompute, cq-specialize, cq-control) stay in prototype/cq_pass.cpp
// and are NOT productionized.
//
// Standard out-of-tree pass-plugin shape (Polly / Enzyme / sanitizer
// runtimes use the same pattern): we expose llvmGetPassPluginInfo() as a
// weak C symbol that opt/clang resolves on dlopen.

#include "CQLoweringPass.h"

#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

using namespace llvm;

namespace {

PassPluginLibraryInfo getCQPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "cq-lowering", LLVM_VERSION_STRING,
          [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef Name, ModulePassManager &MPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "cq-lowering") {
                    MPM.addPass(cq::CQLoweringPass());
                    return true;
                  }
                  return false;
                });
          }};
}

}  // namespace

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return getCQPluginInfo();
}
