// WidthDispatch.h — Symbol and type resolver for the cq-lowering pass.
//
// In Phase 2 M12 this is intentionally a thin, i32/si32-only surface:
// every accessor below knows exactly one suffix (`si32`) and one ABI
// width (`i32`). M13 (`cq-p2-m13`) replaces the bodies with the full
// 14-suffix table; the API exposed here is the contract that M14–M17
// consume so M13 can land without touching the consumers.
//
// Symbol-resolution policy mirrors the pre-split monolith:
//   * Front-end intrinsics (`@cq_init_si32`, `@cq_measure_si32`) are
//     looked up but never *created* — they come in from the rewriter or
//     they don't exist (the passthrough_no_quantum fixture relies on
//     the latter).
//   * Runtime / template symbols (`@cqrt_alloc_i32`, `@cqrt_measure_i32`,
//     `@cq_template_add_i32{,_hl}`) are *lazy*: declared on first call
//     via `M.getOrInsertFunction`. This preserves Phase 1's invariant
//     that a function with no quantum work leaks no runtime decls.
//
// Spec: phases/phase2/PLAN.md §4.12 (M12 split contract), §4.13 (M13
// generalization).

#ifndef CQ_IRPASS_WIDTH_DISPATCH_H_
#define CQ_IRPASS_WIDTH_DISPATCH_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Module.h"

namespace cq {

class WidthDispatch {
public:
  explicit WidthDispatch(llvm::Module &M);

  // Front-end intrinsic lookups (no insertion). Return nullptr if the
  // intrinsic is not declared in the module — that's the cue to skip
  // any per-width work for this suffix.
  llvm::Function *initFn() const;     // @cq_init_si32
  llvm::Function *measureFn() const;  // @cq_measure_si32

  // Runtime / template symbol resolvers. Each call is idempotent and
  // lazy: the decl is inserted on first call, reused thereafter. M13
  // will add a suffix parameter; M12 keeps the surface minimal.
  llvm::FunctionCallee allocFn() const;       // @cqrt_alloc_i32
  llvm::FunctionCallee measureRtFn() const;   // @cqrt_measure_i32
  llvm::FunctionCallee addTemplate(bool isHL) const;  // @cq_template_add_i32{,_hl}

  // Mid-struct recognition for taint propagation and rebind. M12 only
  // knows about `qint_mid_t`; M15 (`cq-p2-m15`) generalizes to the
  // full 14-struct table. nullptr/false on no match.
  bool isMidStruct(llvm::StructType *ST) const;

  // Type accessors.
  llvm::Type *i32Ty() const { return I32; }
  llvm::LLVMContext &context() const { return M.getContext(); }
  llvm::Module &module() const { return M; }

  // Names of front-end intrinsic decls eligible for end-of-pass cleanup
  // (erased iff use-less). M13 replaces this with the per-suffix list.
  llvm::ArrayRef<llvm::StringRef> frontEndIntrinsicNames() const;

private:
  llvm::Module &M;
  llvm::Type *I32;
};

}  // namespace cq

#endif  // CQ_IRPASS_WIDTH_DISPATCH_H_
