// RuntimeNarrowABI.h — bd test_C_libtooling-r2j3.20 (etj3): the C ABI of a
// narrow runtime parameter.
//
// Every `cqrt_*` / `cq_template_*` C prototype spells an `i1` as `bool`, an `i8`
// as `int8_t` and an `i16` as `int16_t` (runtime/cq_runtime.h, the generated
// runtime/cq_templates.h and runtime/cq_intrinsic_templates.h; width-only ABI,
// R13). clang passes those `zeroext` / `signext` / `signext`, and a clang-built
// callee relies on the caller's extension. The pass declared them bare, so a
// negative narrow literal reached the C template unextended (etj3: `i16 -9`
// printed 65527). This sweep gives every runtime DECLARATION the attribute its
// prototype implies, on parameters and return; codegen reads a call's extension
// from its callee's declaration (`CallBase::paramHasAttr`).

#ifndef CQ_IRPASS_RUNTIME_NARROW_ABI_H_
#define CQ_IRPASS_RUNTIME_NARROW_ABI_H_

namespace llvm {
class Module;
}  // namespace llvm

namespace cq {

// Idempotent; touches only declarations named `cqrt_*` / `cq_template_*`.
void annotateRuntimeNarrowABI(llvm::Module &M);

// Runs `annotateRuntimeNarrowABI` when the pass returns, on every exit path.
class RuntimeNarrowABIOnExit {
public:
  explicit RuntimeNarrowABIOnExit(llvm::Module &M) : M(M) {}
  ~RuntimeNarrowABIOnExit() { annotateRuntimeNarrowABI(M); }
  RuntimeNarrowABIOnExit(const RuntimeNarrowABIOnExit &) = delete;
  RuntimeNarrowABIOnExit &operator=(const RuntimeNarrowABIOnExit &) = delete;

private:
  llvm::Module &M;
};

}  // namespace cq

#endif  // CQ_IRPASS_RUNTIME_NARROW_ABI_H_
