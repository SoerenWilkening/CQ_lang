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

FunctionCallee
ControlledSymbols::controlledDataTemplateFn(StringRef stem, StringRef abiWidth,
                                            Shape shape, bool inverse) const {
  // `cq_template_<stem>_<W>[_hl|_lh]_controlled[_inv]`. The i32 control flag
  // is argument 0 (PRD §1.2); the remaining operands follow the base data
  // template's by-Shape layout. Handle is always i32; the classical operand
  // of an `_hl`/`_lh` form is at its real LLVM width so the IR call matches
  // the generated C signature.
  LLVMContext &Ctx = M.getContext();
  Type *Handle = Type::getInt32Ty(Ctx);
  Type *Flag = Handle;  // the control flag is itself an i32 handle.
  std::string Name = dataName(stem, abiWidth, shape, /*controlled=*/true,
                              inverse);
  switch (shape) {
  case Shape::QQ:
    return M.getOrInsertFunction(
        Name, FunctionType::get(Handle, {Flag, Handle, Handle}, false));
  case Shape::HL:
  case Shape::LH: {
    Type *Classical = Wd.llvmWidthType(abiWidth);
    if (!Classical)
      return FunctionCallee();
    // HL: (flag, handle, classical); LH: (flag, classical, handle). Operand
    // order after the flag is observable — it is the whole point of the
    // distinct `_lh` symbol.
    if (shape == Shape::HL)
      return M.getOrInsertFunction(
          Name, FunctionType::get(Handle, {Flag, Handle, Classical}, false));
    return M.getOrInsertFunction(
        Name, FunctionType::get(Handle, {Flag, Classical, Handle}, false));
  }
  case Shape::Unary:
    // fneg has no controlled binary surface here; caller diagnoses.
    break;
  }
  return FunctionCallee();
}

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

FunctionCallee ControlledSymbols::toffoliFn(bool inverse) const {
  // `void cqrt_toffoli[_inv](i32 c1, i32 c2, i32 tgt)`. Width-agnostic; all
  // three args are i32 flag handles.
  LLVMContext &Ctx = M.getContext();
  Type *I32 = Type::getInt32Ty(Ctx);
  return M.getOrInsertFunction(
      inverse ? "cqrt_toffoli_inv" : "cqrt_toffoli",
      FunctionType::get(Type::getVoidTy(Ctx), {I32, I32, I32}, false));
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

}  // namespace cq
