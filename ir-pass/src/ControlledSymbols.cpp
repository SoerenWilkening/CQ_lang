// ControlledSymbols.cpp — Lazy minter for the Phase-4 controlled symbol
// surface. See header for the contract; PRD §2.8 for the naming grammar
// and §1.2 for the control-flag-as-arg-0 invariant. Every minted
// FunctionType byte-matches the C decls WP1 added to
// runtime/cq_templates.h and runtime/cq_runtime.h.

#include "ControlledSymbols.h"

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

FunctionCallee ControlledSymbols::copyControlledFn(StringRef abiWidth) const {
  // `void cqrt_copy_<W>_controlled(i32 ctrl, i32 src, i32 dst)`. Mirrors
  // cqrt_copy_<W>_controlled in runtime/cq_runtime.h (Phase 4.4 — the
  // tainted-`select` controlled-XOR copy merge). The control flag is
  // arg 0 (PRD §1.2); src/dst follow. The width only selects the symbol
  // name — all three args are i32 handles for every ABI width. INTEGER
  // widths only: an FP merge phi under tainted control is categorically
  // an angle, never data (the f64 miscompile family), so f32/f64 — and
  // any unknown width — return a null callee (caller diagnoses) rather
  // than minting dead ABI. The integer guard goes through the PUBLIC
  // `Wd.llvmWidthType` (WidthDispatch's file-local `typeForAbiWidth` is
  // unreachable here); the null check also covers an unknown abiWidth.
  LLVMContext &Ctx = M.getContext();
  Type *Ty = Wd.llvmWidthType(abiWidth);
  if (!Ty || !Ty->isIntegerTy())
    return FunctionCallee();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(
      ("cqrt_copy_" + abiWidth + "_controlled").str(),
      FunctionType::get(Type::getVoidTy(Ctx), {I32, I32, I32}, false));
}

}  // namespace cq
