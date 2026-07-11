// ControlledSymbols.cpp — Lazy minter for the Phase-4 controlled symbol
// surface. See header for the contract; PRD §2.8 for the naming grammar
// and §1.2 for the control-flag-as-arg-0 invariant. Every minted
// FunctionType byte-matches the C decls WP1 added to
// runtime/cq_templates.h and runtime/cq_runtime.h.

#include "ControlledSymbols.h"

#include "OpcodeSupport.h"  // abiWidthHasControlledFpCopy (the fp select fence)
#include "TemplateName.h"

#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Type.h"

using namespace llvm;

namespace cq {

FunctionCallee ControlledSymbols::controlledRotationFn(StringRef abiWidth,
                                                       bool inverse) const {
  // `void cqrt_rz_<W>_controlled[_inv](i32 ctrl, i32 handle, double angle)`.
  // The width only selects the symbol name; the llvmWidthType guard rejects
  // unknown widths (null callee so the caller diagnoses rather than minting
  // a garbage symbol).
  LLVMContext &Ctx = M.getContext();
  if (!Wd.llvmWidthType(abiWidth))
    return FunctionCallee();
  Type *I32 = Type::getInt32Ty(Ctx);
  StringRef Suffix = inverse ? "_controlled_inv" : "_controlled";
  return M.getOrInsertFunction(
      ("cqrt_rz_" + abiWidth + Suffix).str(),
      FunctionType::get(Type::getVoidTy(Ctx),
                        {I32, I32, Type::getDoubleTy(Ctx)}, false));
}

FunctionCallee ControlledSymbols::xFn() const {
  // `void cqrt_x(i32 q)`. Width-agnostic; the operand is an i32 flag handle.
  // X is an involution (its own inverse), so there is no `_inv` twin — the
  // De Morgan uncompute re-emits the same `cqrt_x`.
  LLVMContext &Ctx = M.getContext();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(
      "cqrt_x", FunctionType::get(Type::getVoidTy(Ctx), {I32}, false));
}

FunctionCallee ControlledSymbols::cswapFn() const {
  // `void cqrt_cswap(i32 ctrl, i32 a, i32 b)`. Width-agnostic; all three args
  // are i32 handles (the control flag, then the two registers to swap). SWAP is
  // an involution so the controlled-SWAP is its own inverse — no `_inv` twin.
  LLVMContext &Ctx = M.getContext();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(
      "cqrt_cswap", FunctionType::get(Type::getVoidTy(Ctx), {I32, I32, I32}, false));
}

FunctionCallee ControlledSymbols::cnotFn() const {
  // `void cqrt_cnot(i32 ctrl, i32 tgt)`. Width-agnostic; both operands are i32
  // flag/ancilla handles. CNOT is an involution (its own inverse), so the
  // compound-condition LIFO uncompute re-emits the same `cqrt_cnot` — no
  // `_inv` twin. Byte-matches the hand-written decl in runtime/cq_runtime.h
  // (§11.4 gate primitives).
  LLVMContext &Ctx = M.getContext();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(
      "cqrt_cnot", FunctionType::get(Type::getVoidTy(Ctx), {I32, I32}, false));
}

FunctionCallee ControlledSymbols::toffoliFn() const {
  // `void cqrt_toffoli(i32 c1, i32 c2, i32 tgt)`. Width-agnostic; three i32
  // handles (two read-only controls, one target). Self-inverse — no `_inv`
  // twin. Byte-matches runtime/cq_runtime.h (§11.4 gate primitives).
  LLVMContext &Ctx = M.getContext();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(
      "cqrt_toffoli",
      FunctionType::get(Type::getVoidTy(Ctx), {I32, I32, I32}, false));
}

FunctionCallee ControlledSymbols::copyControlledFn(StringRef abiWidth) const {
  // `void cqrt_copy_<W>_controlled(i32 ctrl, i32 src, i32 dst)`. Mirrors
  // cqrt_copy_<W>_controlled in runtime/cq_runtime.h (Phase 4.4 — the
  // tainted-`select` controlled-XOR copy merge). The control flag is
  // arg 0 (PRD §1.2); src/dst follow. The width only selects the symbol
  // name — all three args are i32 handles for every ABI width. INTEGER
  // widths only, and this null-on-fp fence is a LIVE CLASSIFIER, not
  // plumbing: the 6.5 classical-call arm's ONLY fp/i128 gate is this null
  // (DD-7, ClassicalCallArmEmit/ArmClassify defer to it — the
  // minter-null-is-a-classifier hazard). The fp SELECT merge mints through
  // `copyControlledFpFn` below instead (fp-data-select-PRD §4.2); keep this
  // fence byte-identical. Unknown widths return a null callee (caller
  // diagnoses) rather than minting dead ABI. The integer guard goes through
  // the PUBLIC `Wd.llvmWidthType` (WidthDispatch's file-local
  // `typeForAbiWidth` is unreachable here); the null check also covers an
  // unknown abiWidth.
  LLVMContext &Ctx = M.getContext();
  Type *Ty = Wd.llvmWidthType(abiWidth);
  // i128 no-clone fence (n0ui Tier-1): mirror copyFn — i128 is a recognized
  // integer width but has NO `cqrt_copy_i128_controlled` (intermediate-only),
  // so a tainted i128 controlled data-mux returns null and the caller declines,
  // never minting a phantom. Gate on width > 64 (not a name compare).
  if (!Ty || !Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return FunctionCallee();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(
      ("cqrt_copy_" + abiWidth + "_controlled").str(),
      FunctionType::get(Type::getVoidTy(Ctx), {I32, I32, I32}, false));
}

FunctionCallee
ControlledSymbols::copyControlledFpFn(StringRef abiWidth) const {
  // `void cqrt_copy_f<W>_controlled(i32 ctrl, i32 src, i32 dst)` for the fp
  // widths {f16,f32,f64,f80} (fp-data-select-PRD §4.2 — Option B; mirrors the
  // new decls in runtime/cq_runtime.h). SELECT-LOCAL: SelectMergeEmit is the
  // sole caller (see the header contract) — the shared integer minter above
  // keeps classifying for every other consumer. The fence is the pure
  // `abiWidthHasControlledFpCopy` predicate (OpcodeSupport), NOT a type-class
  // test: f128 (valid LLVM type, no sound c_type on this build) and any
  // unknown/integer width return null so the caller declines, never minting a
  // phantom extern that link-fails (the jvun class). Same symbol grammar and
  // all-i32-handle signature as the integer family (Rule 15).
  LLVMContext &Ctx = M.getContext();
  if (!abiWidthHasControlledFpCopy(abiWidth))
    return FunctionCallee();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(
      ("cqrt_copy_" + abiWidth + "_controlled").str(),
      FunctionType::get(Type::getVoidTy(Ctx), {I32, I32, I32}, false));
}

FunctionCallee ControlledSymbols::tapeWriteControlledFn(StringRef abiWidth) const {
  // `i32 cqrt_tape_write_<W>_controlled(i32 ctrl, i32 tape, i32 src)`. Mirrors
  // cqrt_tape_write_<W>_controlled in runtime/cq_runtime.h (Phase 7.6 Increment
  // 2 — the Tier-0 `if(q)printf` write). The control flag is arg 0 (PRD §1.2);
  // tape/src follow. UNLIKE the void `copyControlledFn`, this RETURNS an i32
  // (the kept out-rail handle), matching the uncontrolled `tapeWriteFn`. All
  // three args are i32 handles for every ABI width. Integer-only > 64 fence,
  // matching `tapeWriteFn`: tape KEEPS integer-only even though the select
  // copy family gained fp twins via `copyControlledFpFn` (fp-data-select-PRD
  // §4.1 — the fences legitimately diverge; no `cqrt_tape_write_f<W>` exists).
  // There is no `cqrt_tape_write_i128_controlled` either, so an unsupported
  // width returns null (caller declines) — never a phantom mint.
  LLVMContext &Ctx = M.getContext();
  Type *Ty = Wd.llvmWidthType(abiWidth);
  if (!Ty || !Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return FunctionCallee();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(
      ("cqrt_tape_write_" + abiWidth + "_controlled").str(),
      FunctionType::get(I32, {I32, I32, I32}, false));
}

}  // namespace cq
