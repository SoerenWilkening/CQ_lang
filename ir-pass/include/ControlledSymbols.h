// ControlledSymbols.h — Lazy minter for the Phase-4 controlled symbol
// surface (PRD §2.8). Sibling to `WidthDispatch`: where that resolver
// spells the base template / runtime symbols, this one spells the
// controlled forms — controlled data templates, the controlled Rz gate
// body, and the Toffoli flag-conjunction primitive.
//
// The controlled invariant (PRD §1.2): every controlled symbol takes
// EXACTLY ONE i32 control-flag handle, PREPENDED as argument 0. There is
// no doubly-controlled symbol; multi-condition control is built from
// single-control ops plus Toffoli flag conjunction.
//
// Symbol policy mirrors WidthDispatch: each resolver is idempotent and
// lazy — the decl is inserted on first call via `M.getOrInsertFunction`,
// reused thereafter, so a function that needs no controlled symbol leaks
// no decls. The minted `FunctionType`s byte-match the C declarations WP1
// added to `runtime/cq_templates.h` / `runtime/cq_runtime.h`, so Stage-3
// linking against `libcq_templates` / `libcq_runtime` resolves cleanly.
//
// The handle is always i32 across every ABI width (PRD §"Width
// unification"); only the classical operand of an `_hl`/`_lh` data
// template carries its real LLVM width, resolved via
// `WidthDispatch::llvmWidthType`.

#ifndef CQ_IRPASS_CONTROLLED_SYMBOLS_H_
#define CQ_IRPASS_CONTROLLED_SYMBOLS_H_

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Module.h"

#include "TemplateName.h"   // cq::Shape
#include "WidthDispatch.h"  // cq::WidthDispatch

namespace cq {

class ControlledSymbols {
public:
  // Bound to the module under transform and the shared width resolver.
  // Holds references only — both must outlive this object (they do: the
  // pass owns all three for the duration of a run).
  ControlledSymbols(llvm::Module &M, WidthDispatch &wd) : M(M), Wd(wd) {}

  // Controlled data template (PRD §2.8): `cq_template_<stem>_<W>[_hl|_lh]`
  // `_controlled[_inv]`, with an i32 control-flag handle PREPENDED as arg 0.
  // Operand fan-out by Shape, after the leading flag:
  //   QQ    (i32 flag, i32, i32)        → i32
  //   HL    (i32 flag, i32, W)          → i32
  //   LH    (i32 flag, W, i32)          → i32
  // where W is the classical operand's real LLVM width. Returns a null
  // FunctionCallee for an unsupported width or an unsupported shape
  // (`Shape::Unary` — fneg has no controlled binary form here).
  llvm::FunctionCallee controlledDataTemplateFn(llvm::StringRef stem,
                                                llvm::StringRef abiWidth,
                                                Shape shape,
                                                bool inverse = false) const;

  // Controlled Rz gate body (PRD §2.8): `void cqrt_rz_<W>_controlled[_inv]`
  // `(i32 ctrl, i32 handle, double angle)`. The width selects only the
  // symbol name; ctrl and handle are i32 and the angle double for every ABI
  // width. Null FunctionCallee for an unsupported width.
  llvm::FunctionCallee controlledRotationFn(llvm::StringRef abiWidth,
                                            bool inverse = false) const;

  // Controlled Ry INVERSE (npu.6): `void cqrt_ry_<W>_controlled_inv`
  // `(i32 ctrl, i32 handle, double angle)`. The controlled uncompute twin of
  // the Ry prep (`cqrt_ry_<W>`); same shape as `controlledRotationFn` but the
  // `ry` stem and there is only the inverse form (the prep is unconditional,
  // only its disentangle is controlled). Emitted by the gated-switch MUX-EXCH
  // lowering to return a non-selected source to |0>. Null callee for an
  // unsupported width.
  llvm::FunctionCallee controlledRyInvFn(llvm::StringRef abiWidth) const;

  // Toffoli flag conjunction (PRD §2.5/§2.7): `void cqrt_toffoli[_inv]`
  // `(i32 c1, i32 c2, i32 tgt)`. Width-agnostic — all three args are i32
  // flag handles. `inverse` selects the uncompute twin `cqrt_toffoli_inv`.
  llvm::FunctionCallee toffoliFn(bool inverse = false) const;

  // Pauli-X gate primitive (the De Morgan `||` bracket, PRD §2.5):
  // `void cqrt_x(i32 q)`. Width-agnostic — the operand is an i32 flag handle.
  // Its own inverse (X is an involution), so there is no `_inv` twin.
  llvm::FunctionCallee xFn() const;

  // Controlled-SWAP / Fredkin (npu.4/.5): `void cqrt_cswap(i32 ctrl, i32 a,
  // i32 b)` swaps registers a and b iff the i32 control flag is set. The
  // primitive for the distinct-per-case-handle gated-switch MUX-EXCH lowering —
  // `cqrt_cswap(f_q, regOut, q)` moves the selected source's state into the
  // muxed register and frees the source. Width-agnostic (all three args are
  // i32 handles). SWAP is an involution, so the controlled-SWAP is its own
  // inverse — no `_inv` twin.
  llvm::FunctionCallee cswapFn() const;

  // Controlled reversible basis copy (Phase 4.4, PRD Part IV §16.3):
  // `void cqrt_copy_<W>_controlled(i32 ctrl, i32 src, i32 dst)` — the
  // tainted-`select` controlled-XOR copy merge primitive. Copies `src`
  // into the |0> `dst` rail iff the i32 control flag is set; the flag is
  // PREPENDED as arg 0 (PRD §1.2), so src/dst follow at args 1/2. The
  // width selects only the symbol name (all three args are i32 handles).
  // INTEGER widths only — an FP merge phi under tainted control is
  // categorically an angle, never data (the f64 family) — so f32/f64 (and
  // any unknown width) return a null FunctionCallee (caller declines,
  // §16.4 staged), guarded via the PUBLIC `WidthDispatch::llvmWidthType`.
  llvm::FunctionCallee copyControlledFn(llvm::StringRef abiWidth) const;

private:
  llvm::Module &M;
  WidthDispatch &Wd;
};

}  // namespace cq

#endif  // CQ_IRPASS_CONTROLLED_SYMBOLS_H_
