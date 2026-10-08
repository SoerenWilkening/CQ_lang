// LiftDiagnostics.h — bd test_C_libtooling-3c6m.82: a failure inside a lifted
// body names the user's call.
//
// A quantum call to a library function lifts the function's body (the cqc
// bundle, or any visible callee), and a construct the compiler does not lower
// yet fails loudly at the offending instruction INSIDE that body: openlibm's
// source line, or `<unknown>:0:0` when the bundle has no debug info. Measured on
// the e0af16ed census: of 105 cqc declines, none named the user's call site.
// R1 asks for a failure the user can locate, so while the specializer works on a
// call site from user code, every error raised in another function is preceded
// by a note at that call site.

#ifndef CQ_IRPASS_LIFT_DIAGNOSTICS_H_
#define CQ_IRPASS_LIFT_DIAGNOSTICS_H_

namespace llvm {
class CallInst;
class LLVMContext;
}  // namespace llvm

namespace cq {

// For one pass run: wraps the context's diagnostic handler and restores it.
class LiftDiagnosticScope {
public:
  explicit LiftDiagnosticScope(llvm::LLVMContext &Ctx);
  ~LiftDiagnosticScope();
  LiftDiagnosticScope(const LiftDiagnosticScope &) = delete;
  LiftDiagnosticScope &operator=(const LiftDiagnosticScope &) = delete;

private:
  llvm::LLVMContext &Ctx;
  const void *Installed;  // the wrapper this scope installed
};

// While alive, `Site` is a call the specializer is classifying or lifting. Only
// the OUTERMOST site is noted: inner sites live in lifted bodies themselves. The
// site's function, location and callee name are copied, so a site the
// specializer rebuilds or erases meanwhile is never read again.
class LiftSite {
public:
  explicit LiftSite(const llvm::CallInst *Site);
  ~LiftSite();
  LiftSite(const LiftSite &) = delete;
  LiftSite &operator=(const LiftSite &) = delete;
};

}  // namespace cq

#endif  // CQ_IRPASS_LIFT_DIAGNOSTICS_H_
