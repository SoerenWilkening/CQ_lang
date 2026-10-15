// cq_opt_main.cpp — PROTOTYPE purpose-built driver for the cq-lowering pass.
//
// Every one of the ~1090 `opt` invocations in this project runs the SAME
// pipeline: `-load-pass-plugin <so> -passes=cq-lowering -S <in> [-o <out>]`.
// A generic `opt` linked against the 140MB libLLVM.dylib pays ~0.345s of
// dynamic-loader + static-initializer cost per launch and then does ~0.02s of
// actual work. This driver does exactly that one pipeline and nothing else, so
// it can be linked against only the LLVM libraries the pass truly needs.
//
// Flag surface is deliberately opt-compatible so existing RUN lines and the
// e2e runners work unchanged:
//   -load-pass-plugin <path>   accepted and IGNORED (the pass is linked in)
//   -passes=cq-lowering        the ONLY accepted pipeline; anything else is a
//                              hard error rather than a silent no-op
//   -S                         accepted and ignored (output is always textual)
//   -o <path>                  default: stdout
//   -disable-output            parse+run+verify, print nothing
//
// One deliberate refusal: a module with a `target triple` but no `target
// datalayout` is a hard error (stock opt would infer the layout from a target
// backend cq-opt does not link; see main()).
//
// Semantics must match `opt` exactly, including that the module is VERIFIED
// after the pass and before printing (opt's default pipeline is
// CQLoweringPass -> VerifierPass -> PrintModulePass) and that a failure exits
// non-zero. The negative fixtures depend on the exact exit code and on
// diagnostics reaching stderr.

#include "CQLoweringPass.h"

#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

#include <string>

using namespace llvm;

int main(int argc, char **argv) {
  InitLLVM X(argc, argv);

  std::string InputFile, OutputFile;
  bool DisableOutput = false;
  bool SawPipeline = false;

  for (int i = 1; i < argc; ++i) {
    StringRef A(argv[i]);
    if (A == "-load-pass-plugin" || A == "--load-pass-plugin") {
      if (++i >= argc) { errs() << "cq-opt: -load-pass-plugin needs a value\n"; return 1; }
      continue;  // the pass is linked in; the plugin path is irrelevant
    }
    if (A.starts_with("-load-pass-plugin=") || A.starts_with("--load-pass-plugin="))
      continue;
    if (A.starts_with("-passes=") || A.starts_with("--passes=")) {
      StringRef P = A.substr(A.find('=') + 1);
      if (P != "cq-lowering") {
        errs() << "cq-opt: only -passes=cq-lowering is supported, got '" << P << "'\n";
        return 1;
      }
      SawPipeline = true;
      continue;
    }
    if (A == "-S" || A == "--S" || A == "-f") continue;
    if (A == "-disable-output" || A == "--disable-output") { DisableOutput = true; continue; }
    if (A == "-o" || A == "--o") {
      if (++i >= argc) { errs() << "cq-opt: -o needs a value\n"; return 1; }
      OutputFile = argv[i];
      continue;
    }
    if (A == "-") { InputFile = "-"; continue; }
    if (A.starts_with("-")) {
      errs() << "cq-opt: unrecognised flag '" << A << "'\n";
      return 1;
    }
    if (!InputFile.empty()) { errs() << "cq-opt: multiple inputs\n"; return 1; }
    InputFile = A.str();
  }

  if (!SawPipeline) { errs() << "cq-opt: missing -passes=cq-lowering\n"; return 1; }
  if (InputFile.empty()) InputFile = "-";

  LLVMContext Ctx;
  SMDiagnostic Err;
  std::unique_ptr<Module> M = parseIRFile(InputFile, Err, Ctx);
  if (!M) {
    Err.print("cq-opt", errs());
    return 1;
  }
  // A triple with no datalayout: stock opt (optMain's SetDataLayout callback)
  // INFERS the layout from the registered target's TargetMachine, runs the
  // pass under it and prints it. cq-opt links no target backends (linking every
  // target opt registers would bring back the static-initializer cost this
  // driver exists to avoid), so it would run under the DEFAULT DataLayout and
  // print none: a silent divergence the 2026-10-16 batch gate caught on two
  // fixtures. Refuse loudly instead. An explicit empty `target datalayout = ""`
  // is the same case (opt infers for it too).
  // Pinned by ir-pass/test/cq_opt_reject_triple_without_datalayout.ll.
  if (!M->getTargetTriple().empty() && M->getDataLayoutStr().empty()) {
    errs() << "cq-opt: module has a target triple ('" << M->getTargetTriple()
           << "') but no target datalayout; stock opt infers one from the "
              "target, cq-opt links no targets and cannot. Add an explicit "
              "'target datalayout' line.\n";
    return 1;
  }
  // opt verifies the INPUT module after parsing; mirror that.
  if (verifyModule(*M, &errs())) {
    errs() << "cq-opt: input module is broken\n";
    return 1;
  }

  PassBuilder PB;
  LoopAnalysisManager LAM;
  FunctionAnalysisManager FAM;
  CGSCCAnalysisManager CGAM;
  ModuleAnalysisManager MAM;
  PB.registerModuleAnalyses(MAM);
  PB.registerCGSCCAnalyses(CGAM);
  PB.registerFunctionAnalyses(FAM);
  PB.registerLoopAnalyses(LAM);
  PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);

  ModulePassManager MPM;
  MPM.addPass(cq::CQLoweringPass());
  MPM.addPass(VerifierPass());   // matches opt's default post-pipeline verify
  MPM.run(*M, MAM);

  if (DisableOutput) return 0;

  if (OutputFile.empty() || OutputFile == "-") {
    M->print(outs(), nullptr);
  } else {
    std::error_code EC;
    raw_fd_ostream OS(OutputFile, EC, sys::fs::OF_TextWithCRLF);
    if (EC) { errs() << "cq-opt: cannot open " << OutputFile << ": " << EC.message() << "\n"; return 1; }
    M->print(OS, nullptr);
  }
  return 0;
}
