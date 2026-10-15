// merge_selftest.cpp — cq-merge-selftest (bd test_C_libtooling-r2j3.32, R11
// round 1 items 1/5 and decision (b)): drives `dischargeMergeRails` — the
// window check and the carried-merge fence — DIRECTLY on hand-written LOWERED
// IR, which the full pass can never be handed: every shape these fixtures
// build (an alias of a stream register written inside the window; a
// non-diagonal gate after a loop on what a leaked carried rail records) is
// declined UPSTREAM on any source program (`condition predates a non-diagonal
// gate`, `routed base predates …`, `control flow under quantum control`, the
// taint-escape guards). Upstream masking is exactly why a fixture through the
// pass cannot pin an unsound LOOSENING of these checks; this driver can.
//
// TEST-ONLY. The production pass never reads the metadata below; only this
// binary does, so a forged tag in a user module changes nothing.
//
// Input: a lowered `.ll` module. Each function under test carries
//   "cq-selftest-expect"="kept" | "discharged" | "loud"
// (and, for "loud", "cq-selftest-message"="<diagnostic text>", compared
// character-for-character), and tags each merge rail it seeds into
// `ControlOwnedRails` with `!cq.selftest.merge`. Verdict: "loud" when a
// diagnostic was raised; otherwise "discharged" when every seeded rail is
// freed, else "kept". Exit 1 on any mismatch.
//
// WHICH CALL FIRED (bd r2j3.36 R11 round 1, F3): a "loud" function tags
// exactly ONE instruction with `!cq.selftest.fires` and gives it (and only it)
// a `!dbg` line; the diagnostic must carry that line. A loud verdict raised at
// any other gate fails. Every input FILE must hold at least one case (R17: a
// file the driver silently skips pins nothing).

#include "MergeRailDischarge.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/DiagnosticPrinter.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

#include <string>
#include <vector>

using namespace llvm;

int main(int argc, char **argv) {
  int Fails = 0, Cases = 0;
  for (int A = 1; A < argc; ++A) {
    LLVMContext Ctx;
    struct Diag {
      std::string Text;
      unsigned Line;
    };
    std::vector<Diag> Diags;
    Ctx.setDiagnosticHandlerCallBack(
        [](const DiagnosticInfo *DI, void *P) {
          std::string S;
          raw_string_ostream OS(S);
          DiagnosticPrinterRawOStream DP(OS);
          DI->print(DP);
          unsigned Line = 0;
          if (auto *WL = dyn_cast<DiagnosticInfoWithLocationBase>(DI);
              WL && WL->isLocationAvailable())
            Line = WL->getLine();
          static_cast<std::vector<Diag> *>(P)->push_back(
              {StringRef(OS.str()).rtrim().str(), Line});
        },
        &Diags);
    SMDiagnostic Err;
    std::unique_ptr<Module> M = parseIRFile(argv[A], Err, Ctx);
    if (!M) {
      Err.print(argv[0], errs());
      return 2;
    }
    cq::WidthDispatch wd(*M);
    int FileCases = 0;
    for (Function &F : *M) {
      if (F.isDeclaration() || !F.hasFnAttribute("cq-selftest-expect"))
        continue;
      ++Cases;
      ++FileCases;
      StringRef Want =
          F.getFnAttribute("cq-selftest-expect").getValueAsString();
      cq::TaintSet taint;
      std::vector<CallInst *> Seeded;
      for (BasicBlock &BB : F)
        for (Instruction &I : BB)
          if (auto *C = dyn_cast<CallInst>(&I);
              C && C->getMetadata("cq.selftest.merge")) {
            taint.ControlOwnedRails.insert(C);
            Seeded.push_back(C);
          }
      Diags.clear();
      cq::dischargeMergeRails(F, taint, wd);
      bool Freed = !Seeded.empty();
      for (CallInst *C : Seeded) {
        bool Any = false;
        for (User *U : C->users())
          if (auto *K = dyn_cast<CallInst>(U))
            if (Function *G = K->getCalledFunction();
                G && G->getName() == "cqrt_free")
              Any = true;
        Freed &= Any;
      }
      std::string Got = !Diags.empty() ? "loud" : Freed ? "discharged" : "kept";
      bool Ok = Got == Want;
      if (Ok && Got == "loud") {
        StringRef Msg =
            F.getFnAttribute("cq-selftest-message").getValueAsString();
        Ok = Diags.size() == 1 && !Msg.empty() &&
             StringRef(Diags[0].Text).ends_with(Msg);
        unsigned WantLine = 0, Tags = 0;
        for (BasicBlock &BB : F)
          for (Instruction &I : BB)
            if (I.getMetadata("cq.selftest.fires")) {
              ++Tags;
              if (const DebugLoc &DL = I.getDebugLoc())
                WantLine = DL.getLine();
            }
        if (Tags != 1 || !WantLine || (Ok && Diags[0].Line != WantLine)) {
          Ok = false;
          outs() << "  (fires-tag: " << Tags << " tag(s), want line " << WantLine
                 << ", got line " << (Diags.empty() ? 0 : Diags[0].Line)
                 << ")\n";
        }
      }
      if (Ok && verifyFunction(F, &errs()))
        Ok = false;
      outs() << (Ok ? "ok   " : "FAIL ") << F.getName() << ": want " << Want
             << ", got " << Got;
      for (const Diag &D : Diags)
        outs() << " [" << D.Text << "]";
      outs() << "\n";
      Fails += !Ok;
    }
    if (!FileCases) {
      outs() << "FAIL " << argv[A] << ": no case in this file\n";
      ++Fails;
    }
  }
  outs() << "cq-merge-selftest: " << Cases << " case(s), " << Fails
         << " failure(s)\n";
  return Fails || !Cases ? 1 : 0;
}
