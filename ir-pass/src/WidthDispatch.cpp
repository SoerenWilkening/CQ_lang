// WidthDispatch.cpp — Suffix → ABI width tables + symbol resolvers.
// See header for contract; PRD §Type map / §Width unification for table.

#include "WidthDispatch.h"

#include "TemplateName.h"

#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Type.h"

using namespace llvm;

namespace cq {

namespace {

// Canonical 14-suffix table — PRD §Type map. Int family first, then
// floats. Same order is reused by allSuffixes() and the front-end
// intrinsic name table; the per-suffix taint walk and the per-suffix
// measure walk both rely on this order being canonical.
//
// AbiWidth = "" marks the target-dependent rows (sl, ul); they resolve
// to LongAbiWidth — set from the Module's DataLayout at construction.
struct SuffixRow {
  StringRef Sfx;
  StringRef AbiWidth;
};

// Phase 7.1 Increment D adds the f16 fp suffix; bd 3c6m.4 adds the long-double
// suffix f80 (x86_fp80 == `long double` on x86-64). f128 (IEEE quad, == long
// double on AArch64) is NOT shipped in this x86-64 build — its only sound
// runtime c_type is a real 128-bit fp this host cannot compile, so it is deferred
// (a tainted fp128 declines; see OpcodeSupport fpBits/abiWidthFromType). i128 is
// deferred as a theta/measure suffix (its C ABI shreds __int128 to {i64,i64}), so
// no si128/ui128 rows here (16 rows).
constexpr SuffixRow kRows[] = {
    {"i1",   "i1"},  {"c",    "i8"},  {"si8",  "i8"},  {"ui8",  "i8"},
    {"si16", "i16"}, {"ui16", "i16"}, {"si32", "i32"}, {"ui32", "i32"},
    {"sl",   ""},    {"ul",   ""},    {"sll",  "i64"}, {"ull",  "i64"},
    {"f16",  "f16"}, {"f32",  "f32"}, {"f64",  "f64"}, {"f80",  "f80"},
};

// ABI-width string → LLVM Type. The 7 supported widths cover the entire
// surface; any other string returns nullptr and the caller is
// expected to bail with a FunctionCallee(). Used by llvmTypeFor() and
// by the lazy-decl resolvers (allocFn, copyFn, measureRtFn, ryRtFn,
// rzRtFn, addTemplate).
Type *typeForAbiWidth(StringRef W, LLVMContext &Ctx) {
  if (W == "i1")  return Type::getInt1Ty(Ctx);
  if (W == "i8")  return Type::getInt8Ty(Ctx);
  if (W == "i16") return Type::getInt16Ty(Ctx);
  if (W == "i32") return Type::getInt32Ty(Ctx);
  if (W == "i64") return Type::getInt64Ty(Ctx);
  if (W == "i128") return Type::getInt128Ty(Ctx);  // n0ui Tier-1 — wide-int width
  if (W == "f16") return Type::getHalfTy(Ctx);   // Phase 7.1 Increment D — _Float16
  if (W == "f32") return Type::getFloatTy(Ctx);
  if (W == "f64") return Type::getDoubleTy(Ctx);
  if (W == "f80") return Type::getX86_FP80Ty(Ctx);  // bd 3c6m.4 — long double (x86-64)
  // f128 deferred (not shipped in this x86-64 build; see OpcodeSupport).
  return nullptr;
}

}  // namespace

WidthDispatch::WidthDispatch(Module &mod) : M(mod) {
  // Long is target-dependent. Approximate `long` width with the pointer
  // size: LP64 (Linux/macOS 64-bit) → i64; ILP32 / LLP64 (Win64) → i32.
  // PRD §Width unification line 149 mandates this be derived from the
  // DataLayout. Pointer size is the cheapest reliable proxy and matches
  // how the frontend's suffix scheme resolves `long`.
  LongAbiWidth =
      mod.getDataLayout().getPointerSizeInBits() == 64 ? "i64" : "i32";
}

ArrayRef<StringRef> WidthDispatch::allSuffixes() const {
  // Static StringRef array built once from the kRows table. The
  // backing string literals have static storage; StringRef wraps them
  // without copying.
  static const StringRef Names[] = {
      kRows[0].Sfx,  kRows[1].Sfx,  kRows[2].Sfx,  kRows[3].Sfx,
      kRows[4].Sfx,  kRows[5].Sfx,  kRows[6].Sfx,  kRows[7].Sfx,
      kRows[8].Sfx,  kRows[9].Sfx,  kRows[10].Sfx, kRows[11].Sfx,
      kRows[12].Sfx, kRows[13].Sfx, kRows[14].Sfx, kRows[15].Sfx,
  };
  return Names;
}

StringRef WidthDispatch::abiWidthFor(StringRef sfx) const {
  for (const SuffixRow &R : kRows) {
    if (R.Sfx != sfx)
      continue;
    // Empty AbiWidth marks target-dependent rows (sl, ul): resolve
    // against the construction-time pointer width.
    return R.AbiWidth.empty() ? LongAbiWidth : R.AbiWidth;
  }
  return {};
}

Type *WidthDispatch::llvmTypeFor(StringRef sfx, LLVMContext &ctx) const {
  StringRef W = abiWidthFor(sfx);
  return W.empty() ? nullptr : typeForAbiWidth(W, ctx);
}

Function *WidthDispatch::thetaFn(StringRef sfx) const {
  return M.getFunction(("cq_theta_" + sfx).str());
}

Function *WidthDispatch::phiFn(StringRef sfx) const {
  return M.getFunction(("cq_phi_" + sfx).str());
}

Function *WidthDispatch::measureFn(StringRef sfx) const {
  return M.getFunction(("cq_measure_" + sfx).str());
}

FunctionCallee WidthDispatch::allocFn(StringRef abiWidth) const {
  // Signature: takes a value of the ABI-width type, returns i32 handle.
  // Mirrors cqrt_alloc_<W> in runtime/cq_runtime.h.
  LLVMContext &Ctx = M.getContext();
  Type *ArgTy = typeForAbiWidth(abiWidth, Ctx);
  if (!ArgTy)
    return FunctionCallee();
  return M.getOrInsertFunction(
      ("cqrt_alloc_" + abiWidth).str(),
      FunctionType::get(Type::getInt32Ty(Ctx), {ArgTy}, false));
}

FunctionCallee WidthDispatch::copyFn(StringRef abiWidth) const {
  // Signature: void(i32 src, i32 dst). Mirrors cqrt_copy_<W> in
  // runtime/cq_runtime.h (Phase 4.2, PRD Part II §8.1 — the design's only
  // new ABI). The width only selects the symbol name — both handles are
  // i32 for every ABI width. INTEGER widths only: an FP merge phi under
  // tainted control is categorically an angle, never data (the f64
  // miscompile family), so f32/f64 — and any unknown width — return a
  // null callee (caller diagnoses) rather than minting dead ABI.
  LLVMContext &Ctx = M.getContext();
  Type *Ty = typeForAbiWidth(abiWidth, Ctx);
  // i128 no-clone fence (n0ui Tier-1): i128 is now a recognized template width,
  // so `Ty` is a valid integer type — but there is NO `cqrt_copy_i128` (i128 is
  // an INTERMEDIATE-only width; source/sink stay i64). A tainted i128 value-mux /
  // select / switch / merge therefore has no reversible copy and must DECLINE
  // (the control classifiers null-check this callee), never mint a phantom
  // `cqrt_copy_i128`. Gate on bit-width > 64 (not a name compare) so any future
  // >64-bit width inherits the fence. Generalizes the f16-angle fence: fp widths
  // (and now wide ints) have no data-copy under tainted control.
  if (!Ty || !Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return FunctionCallee();
  return M.getOrInsertFunction(
      ("cqrt_copy_" + abiWidth).str(),
      FunctionType::get(Type::getVoidTy(Ctx),
                        {Type::getInt32Ty(Ctx), Type::getInt32Ty(Ctx)},
                        false));
}

FunctionCallee WidthDispatch::addcFn(StringRef abiWidth) const {
  // Signature: void(i32 h, <iW> imm) — in-place add of a classical immediate
  // (issue dtzb). The handle is i32 for every width (Rule 15); the immediate
  // carries the logical width type `Ty` (so the trace prints it at width, and
  // the FunctionType matches the hand-written cqrt_addc_<W> in cq_runtime.h).
  // INTEGER widths only, gated EXACTLY as copyFn (the > 64 / non-integer fence:
  // no in-place arithmetic on an fp angle / intermediate-only i128).
  LLVMContext &Ctx = M.getContext();
  Type *Ty = typeForAbiWidth(abiWidth, Ctx);
  if (!Ty || !Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return FunctionCallee();
  return M.getOrInsertFunction(
      ("cqrt_addc_" + abiWidth).str(),
      FunctionType::get(Type::getVoidTy(Ctx), {Type::getInt32Ty(Ctx), Ty},
                        false));
}

FunctionCallee WidthDispatch::xorcFn(StringRef abiWidth) const {
  // Signature: void(i32 h, <iW> imm) — in-place xor of a classical immediate
  // (issue dtzb), self-inverse. Same i32-handle / width-typed-immediate /
  // integer-only-fence contract as addcFn above.
  LLVMContext &Ctx = M.getContext();
  Type *Ty = typeForAbiWidth(abiWidth, Ctx);
  if (!Ty || !Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return FunctionCallee();
  return M.getOrInsertFunction(
      ("cqrt_xorc_" + abiWidth).str(),
      FunctionType::get(Type::getVoidTy(Ctx), {Type::getInt32Ty(Ctx), Ty},
                        false));
}

FunctionCallee WidthDispatch::tapeAllocFn() const {
  // Width-agnostic `i32 cqrt_tape_alloc(void)` (Phase 7.6, PRD-7.6 §2.8).
  // Returns a tape handle (a classical resource token); takes no width and
  // no args. Idempotent / lazy like the other runtime resolvers.
  LLVMContext &Ctx = M.getContext();
  return M.getOrInsertFunction(
      "cqrt_tape_alloc",
      FunctionType::get(Type::getInt32Ty(Ctx), {}, false));
}

FunctionCallee WidthDispatch::tapeWriteFn(StringRef abiWidth) const {
  // Signature: i32(i32 tape, i32 src) — the kept output-rail handle and both
  // inputs are i32 (the width only selects the symbol name). Mirrors
  // cqrt_tape_write_<W> in runtime/cq_runtime.h (Phase 7.6). INTEGER widths
  // only, gated EXACTLY as copyFn (the > 64 / non-integer fence): an fp arg
  // in a rail is the f64/angle miscompile family, and there is NO
  // cqrt_tape_write_i128 (i128 is an intermediate-only width, n0ui Tier-1),
  // so an unsupported width returns a null callee (caller diagnoses) rather
  // than minting a phantom extern that link-fails.
  LLVMContext &Ctx = M.getContext();
  Type *Ty = typeForAbiWidth(abiWidth, Ctx);
  if (!Ty || !Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return FunctionCallee();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(("cqrt_tape_write_" + abiWidth).str(),
                               FunctionType::get(I32, {I32, I32}, false));
}

FunctionCallee WidthDispatch::qramAllocFn(StringRef abiWidth) const {
  // Signature: i32(i32 count) — the array handle and the count are both i32
  // (the width only selects the symbol name). Mirrors cqrt_qram_alloc_<W> in
  // runtime/cq_runtime.h (Phase 7.5, PRD-7.5 §2.3). INTEGER cell widths only,
  // gated EXACTLY as copyFn/tapeWriteFn (the >64 / non-integer fence): an fp
  // cell is the f64/angle miscompile family and there is no
  // cqrt_qram_alloc_i128, so an unsupported width returns a null callee
  // (caller declines) rather than minting a phantom.
  LLVMContext &Ctx = M.getContext();
  Type *Ty = typeForAbiWidth(abiWidth, Ctx);
  if (!Ty || !Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return FunctionCallee();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(("cqrt_qram_alloc_" + abiWidth).str(),
                               FunctionType::get(I32, {I32}, false));
}

FunctionCallee WidthDispatch::qramLoadFn(StringRef abiWidth) const {
  // Signature: i32(i32 arr, i32 idx) — array handle, index handle, and the
  // fresh loaded-value handle are all i32. Mirrors cqrt_qram_load_<W> in
  // runtime/cq_runtime.h. Same INTEGER-width fence as qramAllocFn.
  LLVMContext &Ctx = M.getContext();
  Type *Ty = typeForAbiWidth(abiWidth, Ctx);
  if (!Ty || !Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return FunctionCallee();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(("cqrt_qram_load_" + abiWidth).str(),
                               FunctionType::get(I32, {I32, I32}, false));
}

FunctionCallee WidthDispatch::qramLoadUncFn(StringRef abiWidth) const {
  // Signature: void(i32 out, i32 arr, i32 idx) — the adjoint of a load. The
  // out-first slot convention mirrors cq_template_*_unc (EmitInverse). Mirrors
  // cqrt_qram_load_<W>_unc in runtime/cq_runtime.h. Same INTEGER-width fence.
  // NOTE: EmitInverse mints this `_unc` decl inline (out-first) from the
  // forward call's own type; this resolver exists for symmetry / direct callers
  // and produces a byte-identical FunctionType so the two never diverge.
  LLVMContext &Ctx = M.getContext();
  Type *Ty = typeForAbiWidth(abiWidth, Ctx);
  if (!Ty || !Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return FunctionCallee();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(("cqrt_qram_load_" + abiWidth + "_unc").str(),
                               FunctionType::get(Type::getVoidTy(Ctx),
                                                 {I32, I32, I32}, false));
}

FunctionCallee WidthDispatch::qramStoreFn(StringRef abiWidth) const {
  // Signature: void(i32 arr, i32 idx, i32 val) — the VOID in-place store
  // mutator (Phase 7.5 Inc 2). All three are i32 handles; the array handle is
  // arg 0 (mutated in place), the index and the value handles are borrowed
  // (preserved) inputs. Mirrors cqrt_qram_store_<W> in runtime/cq_runtime.h.
  // Same INTEGER-width fence as qramAllocFn/qramLoadFn.
  LLVMContext &Ctx = M.getContext();
  Type *Ty = typeForAbiWidth(abiWidth, Ctx);
  if (!Ty || !Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return FunctionCallee();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(
      ("cqrt_qram_store_" + abiWidth).str(),
      FunctionType::get(Type::getVoidTy(Ctx), {I32, I32, I32}, false));
}

FunctionCallee WidthDispatch::qramStoreUncFn(StringRef abiWidth) const {
  // Signature: void(i32 arr, i32 idx, i32 val) — the adjoint of a store, with
  // the SAME args as the forward store (NOT out-first; a store mints no rail
  // to zero). `_unc` pops the backend's tape, restoring the cell's old value.
  // Mirrors cqrt_qram_store_<W>_unc in runtime/cq_runtime.h. NOTE: EmitInverse
  // mints this `_unc` decl inline from the forward store's own type; this
  // resolver exists for symmetry and produces a byte-identical FunctionType so
  // the two never diverge. Same INTEGER-width fence.
  LLVMContext &Ctx = M.getContext();
  Type *Ty = typeForAbiWidth(abiWidth, Ctx);
  if (!Ty || !Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return FunctionCallee();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(
      ("cqrt_qram_store_" + abiWidth + "_unc").str(),
      FunctionType::get(Type::getVoidTy(Ctx), {I32, I32, I32}, false));
}

FunctionCallee WidthDispatch::qramStoreControlledFn(StringRef abiWidth) const {
  // iw81.7 — the path-predicate-GUARDED store. Signature:
  // void(i32 pred, i32 arr, i32 idx, i32 val) — the guard flag is arg 0, then
  // the SAME (arr, idx, val) as the unguarded store (all i32 handles). Realizes
  // the Bennett guarded shadow/MUX store in the deferred backend; a NO-OP on
  // cell+tape when pred=0. Mirrors cqrt_qram_store_<W>_controlled in
  // runtime/cq_runtime.h. Same INTEGER-width fence as qramStoreFn.
  LLVMContext &Ctx = M.getContext();
  Type *Ty = typeForAbiWidth(abiWidth, Ctx);
  if (!Ty || !Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return FunctionCallee();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(
      ("cqrt_qram_store_" + abiWidth + "_controlled").str(),
      FunctionType::get(Type::getVoidTy(Ctx), {I32, I32, I32, I32}, false));
}

FunctionCallee WidthDispatch::qramStoreControlledUncFn(StringRef abiWidth) const {
  // iw81.7 — adjoint of the guarded store. SAME args as the forward guarded
  // store (pred, arr, idx, val); `_controlled_unc` pops the backend tape ONLY on
  // the branch where the forward store pushed, gated by the SAME pred. A DISTINCT
  // symbol (the store is not self-inverse) — EmitInverse cannot reuse the
  // re-emit-under-flag involution trick. Mirrors cqrt_qram_store_<W>_controlled_unc
  // in runtime/cq_runtime.h. Same INTEGER-width fence.
  LLVMContext &Ctx = M.getContext();
  Type *Ty = typeForAbiWidth(abiWidth, Ctx);
  if (!Ty || !Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return FunctionCallee();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(
      ("cqrt_qram_store_" + abiWidth + "_controlled_unc").str(),
      FunctionType::get(Type::getVoidTy(Ctx), {I32, I32, I32, I32}, false));
}

FunctionCallee WidthDispatch::measureRtFn(StringRef abiWidth) const {
  // Signature: takes an i32 handle, returns a value of the ABI-width
  // type. Mirrors cqrt_measure_<W> in runtime/cq_runtime.h.
  LLVMContext &Ctx = M.getContext();
  Type *Ret = typeForAbiWidth(abiWidth, Ctx);
  if (!Ret)
    return FunctionCallee();
  return M.getOrInsertFunction(
      ("cqrt_measure_" + abiWidth).str(),
      FunctionType::get(Ret, {Type::getInt32Ty(Ctx)}, false));
}

FunctionCallee WidthDispatch::ryRtFn(StringRef abiWidth) const {
  // Signature: void(i32 handle, double angle). Mirrors cqrt_ry_<W> in
  // runtime/cq_runtime.h. The width only selects the symbol name — the
  // handle is i32 and the angle double for every ABI width. The
  // typeForAbiWidth guard rejects unknown widths (returns a null callee
  // so the caller diagnoses rather than minting a garbage symbol).
  LLVMContext &Ctx = M.getContext();
  if (!typeForAbiWidth(abiWidth, Ctx))
    return FunctionCallee();
  return M.getOrInsertFunction(
      ("cqrt_ry_" + abiWidth).str(),
      FunctionType::get(Type::getVoidTy(Ctx),
                        {Type::getInt32Ty(Ctx), Type::getDoubleTy(Ctx)},
                        false));
}

FunctionCallee WidthDispatch::rzRtFn(StringRef abiWidth) const {
  // Signature: void(i32 handle, double angle). Mirrors cqrt_rz_<W> in
  // runtime/cq_runtime.h. Same shape as ryRtFn.
  LLVMContext &Ctx = M.getContext();
  if (!typeForAbiWidth(abiWidth, Ctx))
    return FunctionCallee();
  return M.getOrInsertFunction(
      ("cqrt_rz_" + abiWidth).str(),
      FunctionType::get(Type::getVoidTy(Ctx),
                        {Type::getInt32Ty(Ctx), Type::getDoubleTy(Ctx)},
                        false));
}

Type *WidthDispatch::llvmWidthType(StringRef abiWidth) const {
  // The classical operand of an `_hl`/`_lh` template at its real LLVM
  // width. Reuses the shared ABI-width → Type table; nullptr for any
  // unsupported width.
  return typeForAbiWidth(abiWidth, M.getContext());
}

FunctionCallee WidthDispatch::dataTemplateFn(StringRef stem, StringRef abiWidth,
                                             Shape shape, bool inverse) const {
  // Binary/unary data op. Handle is i32; the classical operand of an
  // `_hl`/`_lh` form is at its real LLVM width so the call matches the
  // generated C signature. Symbol via TemplateName::dataName. `inverse` selects
  // the `_inv` twin (Phase 5, PRD §2.3) — same FunctionType, name flipped.
  LLVMContext &Ctx = M.getContext();
  Type *Handle = Type::getInt32Ty(Ctx);
  // Phantom-mint fence (n0ui Tier-1): QQ/Unary mint unconditionally via
  // getOrInsertFunction, so a width with NO generated template would create an
  // UNRESOLVED extern (verify-clean, exit 0, LINK-FAILS). Gate on a known ABI
  // type: a width `typeForAbiWidth` does not recognize returns null and the
  // caller declines loudly. HL/LH already guard below via `llvmWidthType`; this
  // covers QQ/Unary symmetrically (belt-and-suspenders behind the upstream
  // `abiWidthFromType().empty()` gate — converts any stray unsupported-width
  // call from a silent phantom mint to a loud null-callee decline).
  if (!typeForAbiWidth(abiWidth, Ctx))
    return FunctionCallee();
  std::string Name = dataName(stem, abiWidth, shape, /*controlled=*/false,
                              inverse);
  switch (shape) {
  case Shape::QQ:
    return M.getOrInsertFunction(
        Name, FunctionType::get(Handle, {Handle, Handle}, false));
  case Shape::Unary:
    return M.getOrInsertFunction(
        Name, FunctionType::get(Handle, {Handle}, false));
  case Shape::HL:
  case Shape::LH: {
    Type *Classical = llvmWidthType(abiWidth);
    if (!Classical)
      return FunctionCallee();
    // HL: (handle, classical); LH: (classical, handle). Operand order is
    // observable — it is the whole point of the distinct `_lh` symbol.
    if (shape == Shape::HL)
      return M.getOrInsertFunction(
          Name, FunctionType::get(Handle, {Handle, Classical}, false));
    return M.getOrInsertFunction(
        Name, FunctionType::get(Handle, {Classical, Handle}, false));
  }
  case Shape::TernaryQQQ:
    // fma a*b+c, all-handle: (i32, i32, i32) -> i32.
    return M.getOrInsertFunction(
        Name, FunctionType::get(Handle, {Handle, Handle, Handle}, false));
  case Shape::TernaryQQL:
  case Shape::TernaryQLQ:
  case Shape::TernaryQLL: {
    // fma mixed handle/literal. The first slot is always a handle; the second
    // product slot (QLQ/QLL) and/or the addend (QQL/QLL) are classical scalars at
    // the real fp width, so the IR call matches the generated C signature.
    Type *Classical = llvmWidthType(abiWidth);
    if (!Classical)
      return FunctionCallee();
    Type *B = (shape == Shape::TernaryQQL) ? Handle : Classical;
    Type *C = (shape == Shape::TernaryQLQ) ? Handle : Classical;
    return M.getOrInsertFunction(
        Name, FunctionType::get(Handle, {Handle, B, C}, false));
  }
  }
  return FunctionCallee();
}

FunctionCallee WidthDispatch::compareTemplateFn(StringRef op, StringRef pred,
                                                StringRef abiWidth, Shape shape,
                                                bool inverse) const {
  // icmp/fcmp → an i32 flag handle (never i1). QQ (i32,i32)→i32; HL
  // (i32, classical)→i32. No `_lh` compares (a left literal is handled by
  // predicate flip upstream). Symbol via TemplateName::compareName. `inverse`
  // selects the `_inv` twin (Phase 5, PRD §2.3) — same FunctionType.
  LLVMContext &Ctx = M.getContext();
  Type *Handle = Type::getInt32Ty(Ctx);
  std::string Name = compareName(op, pred, abiWidth, shape,
                                 /*controlled=*/false, inverse);
  if (shape == Shape::QQ)
    return M.getOrInsertFunction(
        Name, FunctionType::get(Handle, {Handle, Handle}, false));
  // HL — the only other valid compare shape.
  Type *Classical = llvmWidthType(abiWidth);
  if (!Classical)
    return FunctionCallee();
  return M.getOrInsertFunction(
      Name, FunctionType::get(Handle, {Handle, Classical}, false));
}

FunctionCallee WidthDispatch::castTemplateFn(StringRef op, StringRef fromW,
                                             StringRef toW,
                                             bool inverse) const {
  // Casts are unary at the IR level: (i32 handle) → i32 handle. The width
  // pair only selects the symbol (and, semantically, the handle's ABI
  // width); the SSA type is i32 on both sides. Symbol via
  // TemplateName::castName. `inverse` selects the `_inv` twin (Phase 5,
  // PRD §2.3) — same FunctionType.
  LLVMContext &Ctx = M.getContext();
  Type *Handle = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(
      castName(op, fromW, toW, /*controlled=*/false, inverse),
      FunctionType::get(Handle, {Handle}, false));
}

FunctionCallee WidthDispatch::freeFn() const {
  // Width-agnostic `void cqrt_free(i32)` (PRD §2.10). The handle is always i32,
  // so this takes no width. Idempotent / lazy like the other runtime resolvers.
  LLVMContext &Ctx = M.getContext();
  return M.getOrInsertFunction(
      "cqrt_free",
      FunctionType::get(Type::getVoidTy(Ctx), {Type::getInt32Ty(Ctx)}, false));
}

FunctionCallee WidthDispatch::addTemplate(StringRef abiWidth,
                                          bool isQQ) const {
  // Phase-2 entry point, now a shim over dataTemplateFn. The opcode stem
  // is derived from the width prefix ('f' → fadd, else add) — the exact
  // rule the old hardcoded path used — and Q+Q/Q+C map to Shape::QQ/HL.
  // Output is byte-identical to the pre-refactor symbol/type, which the
  // existing lowering_add_* fixtures pin.
  StringRef Stem = abiWidth.starts_with("f") ? "fadd" : "add";
  return dataTemplateFn(Stem, abiWidth, isQQ ? Shape::QQ : Shape::HL);
}

ArrayRef<StringRef> WidthDispatch::frontEndIntrinsicNames() const {
  // 48 entries: cq_theta_<sfx>, then cq_phi_<sfx>, then cq_measure_<sfx>
  // for all 16 suffixes in canonical order (Phase 7.1 Increment D adds the
  // f16 triple; bd 3c6m.4 adds the f80 long-double triple — f128 is deferred,
  // not shipped). Used by CQLoweringPass's end-of-pass dead-decl sweep; decl-only
  // entries (use_empty()) get erased so a quantum-touched module leaves no
  // front-end intrinsic decls behind.
  static const StringRef Names[] = {
      "cq_theta_i1",     "cq_theta_c",      "cq_theta_si8",
      "cq_theta_ui8",    "cq_theta_si16",   "cq_theta_ui16",
      "cq_theta_si32",   "cq_theta_ui32",   "cq_theta_sl",
      "cq_theta_ul",     "cq_theta_sll",    "cq_theta_ull",
      "cq_theta_f16",    "cq_theta_f32",    "cq_theta_f64",
      "cq_theta_f80",
      "cq_phi_i1",       "cq_phi_c",        "cq_phi_si8",
      "cq_phi_ui8",      "cq_phi_si16",     "cq_phi_ui16",
      "cq_phi_si32",     "cq_phi_ui32",     "cq_phi_sl",
      "cq_phi_ul",       "cq_phi_sll",      "cq_phi_ull",
      "cq_phi_f16",      "cq_phi_f32",      "cq_phi_f64",
      "cq_phi_f80",
      "cq_measure_i1",   "cq_measure_c",    "cq_measure_si8",
      "cq_measure_ui8",  "cq_measure_si16", "cq_measure_ui16",
      "cq_measure_si32", "cq_measure_ui32", "cq_measure_sl",
      "cq_measure_ul",   "cq_measure_sll",  "cq_measure_ull",
      "cq_measure_f16",  "cq_measure_f32",  "cq_measure_f64",
      "cq_measure_f80",
  };
  return Names;
}

}  // namespace cq
