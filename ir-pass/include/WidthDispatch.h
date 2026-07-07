// WidthDispatch.h — Symbol and type resolver for the cq-lowering pass.
//
// Knows the canonical 14-suffix table (PRD §"Type map"), the suffix → ABI-
// width collapse (PRD §"Width unification"), and how to spell every
// intrinsic / runtime / template symbol the lowering needs.
//
// Symbol policy:
//   * Front-end intrinsics (`@cq_theta_<sfx>`, `@cq_phi_<sfx>`,
//     `@cq_measure_<sfx>`) are looked up but never *created* — they come
//     from the frontend (`include/CQ.h`) or they don't exist (the
//     passthrough_no_quantum fixture relies on the latter).
//   * Runtime / template symbols (`@cqrt_alloc_<W>`, `@cqrt_ry_<W>`,
//     `@cqrt_rz_<W>`, `@cqrt_measure_<W>`, `@cq_template_add_<W>{,_hl}`)
//     are lazy: declared on first call via `M.getOrInsertFunction`.
//     Preserves the invariant that a quantum-free function leaks no
//     runtime decls.
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

#include "TemplateName.h"  // cq::Shape

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

  // Suffix → LLVM Type for the intrinsic's scalar operand/result. Int
  // family returns an IntegerType of the ABI width (i1/i8/i16/i32/i64);
  // float family returns Float / Double. nullptr for an unknown suffix.
  llvm::Type *llvmTypeFor(llvm::StringRef sfx, llvm::LLVMContext &ctx) const;

  // ABI-width string → the classical operand's LLVM type for an `_hl`/`_lh`
  // template (`i16`→i16, `f64`→double, …). nullptr for an unsupported
  // width. The handle stays i32; this is only the classical-operand type.
  // Public so ControlledSymbols (Phase 4) can mint the matching controlled
  // template signatures off the same table.
  llvm::Type *llvmWidthType(llvm::StringRef abiWidth) const;

  // Front-end intrinsic lookups (no insertion). Return nullptr if the
  // intrinsic is not declared — that's the cue to skip per-suffix work.
  llvm::Function *thetaFn(llvm::StringRef sfx) const;    // @cq_theta_<sfx>
  llvm::Function *phiFn(llvm::StringRef sfx) const;      // @cq_phi_<sfx>
  llvm::Function *measureFn(llvm::StringRef sfx) const;  // @cq_measure_<sfx>

  // Runtime / template symbol resolvers. Each call is idempotent and
  // lazy: the decl is inserted on first call, reused thereafter.
  llvm::FunctionCallee allocFn(llvm::StringRef abiWidth) const;       // @cqrt_alloc_<W>
  llvm::FunctionCallee measureRtFn(llvm::StringRef abiWidth) const;   // @cqrt_measure_<W>

  // Reversible-copy resolver (Phase 4.2, PRD Part II §8.1 — the design's
  // only new ABI). Signature `void(i32 src, i32 dst)` — handles are always
  // i32; the width only selects the symbol name. INTEGER ABI widths only
  // ({i1,i8,i16,i32,i64}): an FP merge phi under tainted control is
  // categorically an angle, never data (the f64 miscompile family), so
  // `f32`/`f64` return a null FunctionCallee (caller diagnoses) rather
  // than minting dead ABI. Emitted as the copy-out step of the value-arm
  // (method-B) swap-route lowering.
  llvm::FunctionCallee copyFn(llvm::StringRef abiWidth) const;        // @cqrt_copy_<W>

  // In-place reversible arithmetic — immediate operand (issue dtzb). Signature
  // `void cqrt_{addc,xorc}_<W>(i32 h, <iW> imm)`: the handle is i32 for every
  // width (Rule 15), the immediate carries the logical width type. INTEGER
  // widths only, gated EXACTLY as copyFn (non-integer / > 64-bit returns a null
  // FunctionCallee — caller declines). The in-place-gate twin of the
  // out-of-place data-template family, emitted only for a recognized loop-rail
  // self-update (LoopLowering.cpp).
  llvm::FunctionCallee addcFn(llvm::StringRef abiWidth) const;        // @cqrt_addc_<W>
  llvm::FunctionCallee xorcFn(llvm::StringRef abiWidth) const;        // @cqrt_xorc_<W>

  // Reversible I/O output-tape resolvers (Phase 7.6, PRD-7.6 §2.8 — FROZEN
  // core ABI). `tapeAllocFn` is width-agnostic `i32 cqrt_tape_alloc(void)`
  // (the tape handle is a classical resource token). `tapeWriteFn` is
  // `i32 cqrt_tape_write_<W>(i32 tape, i32 src)` — the kept output rail and
  // both inputs are i32 (the width only selects the symbol name), gated to
  // the INTEGER widths {i1,i8,i16,i32,i64} EXACTLY as `copyFn`: an fp arg is
  // an angle and there is no `cqrt_tape_write_i128`, so an unsupported width
  // returns a null callee (caller declines) rather than minting a phantom.
  llvm::FunctionCallee tapeAllocFn() const;                          // @cqrt_tape_alloc
  llvm::FunctionCallee tapeWriteFn(llvm::StringRef abiWidth) const;  // @cqrt_tape_write_<W>

  // QRAM tainted-index memory resolvers (Phase 7.5, PRD-7.5 §2.3 — FROZEN
  // core ABI). `qramAllocFn` is `i32 cqrt_qram_alloc_<W>(i32 count)` (the
  // array handle is a classical i32 resource token; the width selects only
  // the symbol). `qramLoadFn` is `i32 cqrt_qram_load_<W>(i32 arr, i32 idx)`
  // (Toffoli-copy-out; all handles i32). `qramLoadUncFn` is its void adjoint
  // `void cqrt_qram_load_<W>_unc(i32 out, i32 arr, i32 idx)` (out-first slot
  // convention, like `cq_template_*_unc`). All three are gated to the INTEGER
  // widths {i1,i8,i16,i32,i64} EXACTLY as `copyFn`/`tapeWriteFn` (the >64 /
  // non-integer fence): an fp cell is the angle hazard and there is no
  // `cqrt_qram_load_i128`, so an unsupported width returns a null callee
  // (caller declines) rather than minting a phantom extern.
  llvm::FunctionCallee qramAllocFn(llvm::StringRef abiWidth) const;    // @cqrt_qram_alloc_<W>
  llvm::FunctionCallee qramLoadFn(llvm::StringRef abiWidth) const;     // @cqrt_qram_load_<W>
  llvm::FunctionCallee qramLoadUncFn(llvm::StringRef abiWidth) const;  // @cqrt_qram_load_<W>_unc
  // Store path (Phase 7.5 Increment 2). `qramStoreFn` is the VOID in-place
  // mutator `void cqrt_qram_store_<W>(i32 arr, i32 idx, i32 val)` (arg-0 array
  // handle mutated; the backend owns the per-store tape). `qramStoreUncFn` is
  // its adjoint `void cqrt_qram_store_<W>_unc(i32 arr, i32 idx, i32 val)` —
  // SAME args (NOT out-first; a store mints no rail), `_unc` selects pop over
  // push. Same INTEGER-width fence as the load resolvers. NOTE: EmitInverse
  // mints the `_unc` decl inline from the forward store's own type; this
  // resolver exists for symmetry / direct callers and is byte-identical.
  llvm::FunctionCallee qramStoreFn(llvm::StringRef abiWidth) const;     // @cqrt_qram_store_<W>
  llvm::FunctionCallee qramStoreUncFn(llvm::StringRef abiWidth) const;  // @cqrt_qram_store_<W>_unc

  // iw81.7 — the path-predicate-GUARDED store + its adjoint. `void
  // cqrt_qram_store_<W>_controlled(i32 pred, i32 arr, i32 idx, i32 val)` (the
  // guard flag is arg 0, then the same arr/idx/val as the unguarded store); a
  // NO-OP on cell+tape when pred=0 (Bennett guarded shadow/MUX, backend-owned).
  // `_controlled_unc` is a DISTINCT symbol (store not self-inverse), gated by the
  // SAME pred, popped in strict LIFO reverse. Same INTEGER-width fence.
  llvm::FunctionCallee qramStoreControlledFn(llvm::StringRef abiWidth) const;     // @cqrt_qram_store_<W>_controlled
  llvm::FunctionCallee qramStoreControlledUncFn(llvm::StringRef abiWidth) const;  // @cqrt_qram_store_<W>_controlled_unc

  // Rotation runtime resolvers. Both signatures are `void(i32, double)`
  // (handle, angle) — the handle is always i32 across every ABI width
  // (PRD §"Width unification"). Names `@cqrt_ry_<W>` / `@cqrt_rz_<W>`.
  llvm::FunctionCallee ryRtFn(llvm::StringRef abiWidth) const;        // @cqrt_ry_<W>
  llvm::FunctionCallee rzRtFn(llvm::StringRef abiWidth) const;        // @cqrt_rz_<W>

  // General template-symbol resolvers (PRD §2.1). Each spells the symbol
  // via `TemplateName::*` and lazily mints the matching `FunctionType` via
  // `getOrInsertFunction`. The handle is always i32; the classical operand
  // of an `_hl`/`_lh` form is at its real LLVM width (`llvmWidthType`) so
  // the IR call matches the generated C signature. Return a null
  // FunctionCallee for an unsupported width (caller diagnoses).
  //
  //   * dataTemplateFn    — binary/unary data ops. Arity/types by Shape:
  //       QQ    (i32, i32) → i32     HL  (i32, W) → i32
  //       LH    (W, i32)   → i32     Unary (i32)  → i32   (fneg)
  //   * compareTemplateFn — icmp/fcmp; QQ (i32,i32)→i32, HL (i32,W)→i32;
  //                         result is an i32 flag handle (never i1).
  //   * castTemplateFn    — unary, always (i32) → i32 (the handle's ABI
  //                         width changes but the SSA type stays i32).
  //
  // `inverse=true` (Phase 5, PRD §2.3) selects the declared `_inv` twin — the
  // adjoint emitted at a tainted handle's last-use point (`EmitInverse`). The
  // `_inv` twin's `FunctionType` is byte-identical to the forward (only the
  // symbol name flips, via the already-inverse-aware `TemplateName::*`), so the
  // type fan-out below is shared. (Rotations have NO `_inv` symbol — their
  // inverse is the forward `cqrt_ry/rz_<W>` with a negated angle — so they are
  // not resolved here.)
  llvm::FunctionCallee dataTemplateFn(llvm::StringRef stem,
                                      llvm::StringRef abiWidth, Shape shape,
                                      bool inverse = false) const;
  llvm::FunctionCallee compareTemplateFn(llvm::StringRef op,
                                         llvm::StringRef pred,
                                         llvm::StringRef abiWidth, Shape shape,
                                         bool inverse = false) const;
  llvm::FunctionCallee castTemplateFn(llvm::StringRef op, llvm::StringRef fromW,
                                      llvm::StringRef toW,
                                      bool inverse = false) const;

  // Phase 5 (PRD §2.10). Width-agnostic deallocation: `void cqrt_free(i32)`.
  // Emitted by `Uncomputation` immediately after a tainted handle's whole-chain
  // adjoint, returning the freshly-zeroed handle to the runtime allocator. The
  // handle is always i32 (PRD §"Width unification"), so this takes no width.
  // Idempotent / lazy like the other runtime resolvers.
  llvm::FunctionCallee freeFn() const;  // @cqrt_free

  // Back-compat shim for the Phase-2 entry point. `isQQ=true` → Q+Q
  // (`cq_template_(add|fadd)_<W>`); `isQQ=false` → Q+C (`..._hl`). The
  // opcode stem is derived from the width prefix ('f' → fadd, else add) to
  // reproduce the original behavior exactly; delegates to dataTemplateFn.
  llvm::FunctionCallee addTemplate(llvm::StringRef abiWidth, bool isQQ) const;

  // Convenience accessors. `i32Ty()` is justified by PRD §"Width
  // unification": the handle is always i32 across every ABI width, so
  // rotation and measure lowering need an i32 Type for the handle argument.
  llvm::Type *i32Ty() const { return llvm::Type::getInt32Ty(M.getContext()); }
  llvm::LLVMContext &context() const { return M.getContext(); }

  // Names of front-end intrinsic decls eligible for end-of-pass cleanup
  // (erased iff use-less). Returns the full per-suffix list — 42 names
  // (14 thetas + 14 phis + 14 measures) — so the cleanup loop in
  // CQLoweringPass covers every suffix.
  llvm::ArrayRef<llvm::StringRef> frontEndIntrinsicNames() const;

private:
  llvm::Module &M;
  // ABI width to use for `sl`/`ul` on this target. Computed from the
  // Module's DataLayout at construction; "i64" on LP64, "i32" otherwise.
  llvm::StringRef LongAbiWidth;
};

}  // namespace cq

#endif  // CQ_IRPASS_WIDTH_DISPATCH_H_
