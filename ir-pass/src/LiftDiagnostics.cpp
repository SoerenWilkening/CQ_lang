// LiftDiagnostics.cpp — see LiftDiagnostics.h (bd test_C_libtooling-3c6m.82).

#include "LiftDiagnostics.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticHandler.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"

#include <memory>
#include <string>
#include <utility>

using namespace llvm;

namespace cq {

namespace {

struct SiteRecord {
  const Function *Caller;
  DebugLoc Loc;
  std::string Callee;
};

// The specializer runs single-threaded within one pass run; the stack is empty
// between runs (every `LiftSite` is scoped). Scopes may nest (`runOnFunction`
// inside `run`): only the outermost clears the stack (review round 2).
SmallVector<SiteRecord, 4> &siteStack() {
  static SmallVector<SiteRecord, 4> Stack;
  return Stack;
}
unsigned ScopeDepth = 0;

// The math.h spelling of a bound bundle body or a clone of one, else the name.
std::string userCalleeName(StringRef N) {
  N.consume_front("__cq_q_");
  N.consume_front("__cq_libm_");
  return N.str();
}

class NotingHandler final : public DiagnosticHandler {
public:
  NotingHandler(LLVMContext &Ctx, std::unique_ptr<DiagnosticHandler> Inner)
      : Ctx(Ctx), Inner(std::move(Inner)) {}

  // `LLVMContext::diagnose` sets `HasErrors` on the INSTALLED handler (this
  // one); hand it back so the restored handler still reports the errors.
  std::unique_ptr<DiagnosticHandler> release() {
    if (HasErrors && Inner)
      Inner->HasErrors = true;
    return std::move(Inner);
  }

  bool handleDiagnostics(const DiagnosticInfo &DI) override {
    if (DI.getSeverity() == DS_Error && !siteStack().empty()) {
      const SiteRecord &S = siteStack().front();
      const auto *U = dyn_cast<DiagnosticInfoUnsupported>(&DI);
      // An error already located in the user's function needs no pointer back.
      // The note goes FIRST: `opt` exits on the error (bd br4a).
      if (S.Caller && (!U || &U->getFunction() != S.Caller))
        Ctx.diagnose(DiagnosticInfoUnsupported(
            *S.Caller,
            "cq specialization: the error below is inside the quantum call to '" +
                S.Callee + "' lifted from here",
            S.Loc, DS_Note));
    }
    return Inner && Inner->handleDiagnostics(DI);
  }

  bool isAnalysisRemarkEnabled(StringRef PassName) const override {
    return Inner && Inner->isAnalysisRemarkEnabled(PassName);
  }
  bool isMissedOptRemarkEnabled(StringRef PassName) const override {
    return Inner && Inner->isMissedOptRemarkEnabled(PassName);
  }
  bool isPassedOptRemarkEnabled(StringRef PassName) const override {
    return Inner && Inner->isPassedOptRemarkEnabled(PassName);
  }
  bool isAnyRemarkEnabled() const override {
    return Inner && Inner->isAnyRemarkEnabled();
  }

private:
  LLVMContext &Ctx;
  std::unique_ptr<DiagnosticHandler> Inner;
};

}  // namespace

// ⚠ `setDiagnosticHandler` resets the context's RespectDiagnosticFilters to its
// default (false) on install and on restore; LLVM 19 has no getter to keep it.
// No CQ host (opt, cq-opt, cqc) sets it.
// Only the OUTERMOST scope installs a handler: a nested one would wrap it and
// print every note twice (review round 3).
LiftDiagnosticScope::LiftDiagnosticScope(LLVMContext &Ctx)
    : Ctx(Ctx), Installed(nullptr) {
  if (ScopeDepth++ != 0)
    return;
  auto H = std::make_unique<NotingHandler>(Ctx, Ctx.getDiagnosticHandler());
  Installed = H.get();
  Ctx.setDiagnosticHandler(std::move(H));
}

LiftDiagnosticScope::~LiftDiagnosticScope() {
  if (Installed) {
    std::unique_ptr<DiagnosticHandler> Current = Ctx.getDiagnosticHandler();
    // Restore the wrapped handler only if ours is still the installed one.
    if (Current.get() == Installed)
      Ctx.setDiagnosticHandler(
          static_cast<NotingHandler *>(Current.get())->release());
    else
      Ctx.setDiagnosticHandler(std::move(Current));
  }
  if (--ScopeDepth == 0)
    siteStack().clear();
}

LiftSite::LiftSite(const CallInst *Site) {
  const Function *Callee = Site ? Site->getCalledFunction() : nullptr;
  siteStack().push_back(
      SiteRecord{Site ? Site->getFunction() : nullptr,
                 Site ? Site->getDebugLoc() : DebugLoc(),
                 Callee ? userCalleeName(Callee->getName()) : std::string()});
}

LiftSite::~LiftSite() {
  if (!siteStack().empty())
    siteStack().pop_back();
}

}  // namespace cq
