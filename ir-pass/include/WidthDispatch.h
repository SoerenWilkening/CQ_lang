// WidthDispatch.h — Symbol and type resolver for the cq-lowering pass.
//
// IR-pass parallel to the rewriter's TypeMap: knows the canonical
// 14-suffix table (PRD §"Type map"), the suffix → ABI-width collapse
// (PRD §"Width unification"), and how to spell every intrinsic /
// runtime / template symbol the lowering needs.
//
// Symbol policy:
//   * Front-end intrinsics (`@cq_init_<sfx>`, `@cq_measure_<sfx>`) are
//     looked up but never *created* — they come from the rewriter or
//     they don't exist (the passthrough_no_quantum fixture relies on
//     the latter).
//   * Runtime / template symbols (`@cqrt_alloc_<W>`, `@cqrt_measure_<W>`,
//     `@cq_template_add_<W>{,_hl}`) are lazy: declared on first call
//     via `M.getOrInsertFunction`. Preserves the invariant that
//     a quantum-free function leaks no runtime decls.
//
// Width unification: 14 suffixes collapse to 7 ABI widths {i1, i8, i16,
// i32, i64, f32, f64}. `sl`/`ul` are target-dependent (resolved from
// the Module's DataLayout at construction).

#ifndef CQ_IRPASS_WIDTH_DISPATCH_H_
#define CQ_IRPASS_WIDTH_DISPATCH_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Module.h"

#include <optional>

namespace cq {

class WidthDispatch {
public:
  explicit WidthDispatch(llvm::Module &M);

  // All known intrinsic suffixes, in canonical order (PRD §Type map).
  // 14 entries: int family {i1, c, si8, ui8, si16, ui16, si32, ui32,
  // sl, ul, sll, ull} then float family {f32, f64}.
  llvm::ArrayRef<llvm::StringRef> allSuffixes() const;

  // Suffix → ABI-width string ("si8" → "i8", "f32" → "f32"). Signedness
  // collapse per PRD §Width unification; `sl`/`ul` are target-dependent
  // and resolved against the Module's DataLayout at construction.
  // Returns "" for an unknown suffix.
  llvm::StringRef abiWidthFor(llvm::StringRef sfx) const;

  // Suffix → LLVM Type for the .val field's underlying scalar. Int
  // family returns an IntegerType of the ABI width (i1/i8/i16/i32/i64);
  // float family returns Float / Double. nullptr for an unknown suffix.
  llvm::Type *llvmTypeFor(llvm::StringRef sfx, llvm::LLVMContext &ctx) const;

  // Front-end intrinsic lookups (no insertion). Return nullptr if the
  // intrinsic is not declared — that's the cue to skip per-suffix work.
  llvm::Function *initFn(llvm::StringRef sfx) const;     // @cq_init_<sfx>
  llvm::Function *measureFn(llvm::StringRef sfx) const;  // @cq_measure_<sfx>

  // Runtime / template symbol resolvers. Each call is idempotent and
  // lazy: the decl is inserted on first call, reused thereafter.
  llvm::FunctionCallee allocFn(llvm::StringRef abiWidth) const;       // @cqrt_alloc_<W>
  llvm::FunctionCallee measureRtFn(llvm::StringRef abiWidth) const;   // @cqrt_measure_<W>

  // Template-symbol resolvers. `isQQ=true` selects the Q+Q symbol
  // (`@cq_template_add_<W>`); `isQQ=false` selects Q+C (`..._hl`).
  llvm::FunctionCallee addTemplate(llvm::StringRef abiWidth, bool isQQ) const;

  // Mid-struct recognition: name-keyed lookup over the 14 mid-struct
  // typedefs (suffix convention: docs/frontend.md §3.1). Returns the
  // matching suffix (e.g., `qint_mid_t` → "si32"); `std::nullopt` for
  // non-mid structs.
  std::optional<llvm::StringRef> midStructToSuffix(llvm::StructType *st) const;

  // Convenience accessors. `i32Ty()` is justified by PRD §"Width
  // unification": the handle is always i32 across every ABI width, so
  // measure lowering needs an i32 Type for the handle argument.
  llvm::Type *i32Ty() const { return llvm::Type::getInt32Ty(M.getContext()); }
  llvm::LLVMContext &context() const { return M.getContext(); }

  // Names of front-end intrinsic decls eligible for end-of-pass cleanup
  // (erased iff use-less). Returns the full per-suffix list — 28 names
  // (14 inits + 14 measures) — so the cleanup loop in CQLoweringPass
  // covers every suffix.
  llvm::ArrayRef<llvm::StringRef> frontEndIntrinsicNames() const;

private:
  llvm::Module &M;
  // ABI width to use for `sl`/`ul` on this target. Computed from the
  // Module's DataLayout at construction; "i64" on LP64, "i32" otherwise.
  llvm::StringRef LongAbiWidth;
};

}  // namespace cq

#endif  // CQ_IRPASS_WIDTH_DISPATCH_H_
