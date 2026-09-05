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

  // Which rotation stem `controlledRotationFn` spells. `Rz` (PRD §2.8) is the
  // diagonal phase rotation — what the RETIRED register-form `cq_phi` lowered
  // to. `Ry`
  // (control-in-place-PRD §5, bd test_C_libtooling-drbq Inc 0) is the
  // NON-diagonal superposition rotation — the lowered `cq_theta` — and is
  // the reason the whole family exists: a tainted-control Ry arm has NO
  // swap-route form (`Ry(θ)|0⟩ ≠ |0⟩` leaves the inactive work rail dirty
  // and entangled, Rules 6/8), so control-in-place is its mechanism.
  enum class RotStem { Ry, Rz };

  // Controlled rotation gate body: `void cqrt_<stem>_<W>_controlled[_inv]`
  // `(i32 ctrl, i32 handle, double angle)`. The width selects only the
  // symbol name; ctrl and handle are i32 and the angle double for every ABI
  // width. Null FunctionCallee for an unsupported width.
  //
  // `inverse` spells the `_controlled_inv` RESERVE family, and it is
  // meaningful for `Rz` ONLY. For `Ry` the `_controlled_inv` spelling names a
  // DIFFERENT, older symbol (the npu.6 MUX-EXCH prep-uncompute, 7 widths, no
  // f16/f80) that this resolver does not own, and the control-in-place
  // forward gate's adjoint is not that symbol at all: like every other
  // rotation in this compiler it inverts as the SAME symbol with a NEGATED
  // angle (`EmitInverse`). So `(Ry, inverse=true)` is refused with a null
  // callee rather than minting a name whose meaning is not the caller's.
  //
  // ⚠ `stem` HAS NO DEFAULT SINCE bd test_C_libtooling-3qlq Inc 1 part B, and
  // that is a deliberate compile-time fence rather than tidiness. It used to
  // default to `Rz`, and after this increment NOTHING in the pass mints a
  // controlled Rz at all: the register-free `cq_phi` is UNCONTROLLED
  // `cqrt_rz_i1` on a condition FLAG (kickback), so a `cqrt_rz_<W>_controlled`
  // is the TENSORED per-register gate PRD §1 records as the defect that made
  // every Grover golden the identity on `q`. A defaulted `Rz` would let a future
  // caller mint one by OMISSION — the exact "absence of a decision" failure mode
  // bd 3c6m.67 and bd big5 both document. Both live call sites pass
  // `RotStem::Ry` explicitly (`RotationLowering`, the drbq control-in-place
  // arm); make it three before you make it default again.
  llvm::FunctionCallee controlledRotationFn(llvm::StringRef abiWidth,
                                            RotStem stem,
                                            bool inverse = false) const;

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

  // CNOT gate primitive (3c6m.12 — the compound-condition OR network):
  // `void cqrt_cnot(i32 ctrl, i32 tgt)`. Width-agnostic — both operands are
  // i32 flag/ancilla handles. Self-inverse (an involution), so the LIFO
  // uncompute re-emits the same `cqrt_cnot` — no `_inv` twin. Together with
  // `toffoliFn` this realizes the header doctrine that multi-condition
  // control is built from single-control ops plus Toffoli flag conjunction:
  // `OR` on a |0> ancilla g is `cnot(l,g); cnot(r,g); toffoli(l,r,g)`
  // (g = l⊕r⊕lr = l∨r) — inputs are READ-ONLY, never X-bracketed.
  llvm::FunctionCallee cnotFn() const;

  // Toffoli / CCX gate primitive (3c6m.12 — the compound-condition AND node
  // and the OR completion): `void cqrt_toffoli(i32 c1, i32 c2, i32 tgt)`.
  // Width-agnostic (three i32 handles); self-inverse — no `_inv` twin.
  llvm::FunctionCallee toffoliFn() const;

  // Controlled reversible basis copy (Phase 4.4, PRD Part IV §16.3):
  // `void cqrt_copy_<W>_controlled(i32 ctrl, i32 src, i32 dst)` — the
  // tainted-`select` controlled-XOR copy merge primitive. Copies `src`
  // into the |0> `dst` rail iff the i32 control flag is set; the flag is
  // PREPENDED as arg 0 (PRD §1.2), so src/dst follow at args 1/2. The
  // width selects only the symbol name (all three args are i32 handles).
  // INTEGER widths only, and the null-on-fp fence is LOAD-BEARING beyond
  // this minter: for the 6.5 classical-call arm it IS the live fp/i128
  // classifier (DD-7 — `classifyClassicalCallArm` has no type gate of its
  // own and defers to this null; the minter-null-is-a-classifier hazard).
  // The fp SELECT merge therefore mints via the SEPARATE `copyControlledFpFn`
  // below (fp-data-select-PRD §4.2); this fence stays byte-identical so no
  // other consumer's accept surface can move by construction. f32/f64 (and
  // any unknown width) return a null FunctionCallee (caller declines),
  // guarded via the PUBLIC `WidthDispatch::llvmWidthType`.
  llvm::FunctionCallee copyControlledFn(llvm::StringRef abiWidth) const;

  // Controlled reversible basis copy, fp widths (fp-data-select-PRD §4.2,
  // issue test_C_libtooling-kjd1 — Option B): `void
  // cqrt_copy_f<W>_controlled(i32 ctrl, i32 src, i32 dst)` for
  // W ∈ {f16,f32,f64,f80}, gated by `abiWidthHasControlledFpCopy` (null for
  // f128 / unknown / anything non-fp). SELECT-LOCAL BY DESIGN: called ONLY
  // from `SelectMergeEmit`, where SelectClassify gate 3 has already proven
  // the fp value is DATA (not a rotation angle) and gate 5 that it carries
  // no phase — the §2 three-legged angle fence. Every other consumer of a
  // controlled copy keeps minting through `copyControlledFn` above so its
  // integer-only null keeps classifying for them. Same shape/involution
  // story as the integer family (all three args i32 handles, the fp width
  // tags the symbol name only — Rule 15; no `_controlled_inv` can exist).
  llvm::FunctionCallee copyControlledFpFn(llvm::StringRef abiWidth) const;

  // Controlled reversible I/O output-tape write (Phase 7.6 Increment 2,
  // PRD-7.6 §2.8 — the Tier-0 `if(q)printf` primitive):
  // `i32 cqrt_tape_write_<W>_controlled(i32 ctrl, i32 tape, i32 src)` appends
  // `src` to `tape` as a fresh kept |0> output rail whose CONTENT is committed
  // iff the i32 control flag `ctrl` is set; the flag is PREPENDED as arg 0
  // (PRD §1.2), so `tape`/`src` follow at args 1/2 and the kept out-handle is
  // RETURNED (unlike void `cqrt_copy_<W>_controlled`). The width selects only
  // the symbol name (all three args are i32 handles). Integer-only > 64
  // fence, matching `tapeWriteFn`: tape KEEPS integer-only even though the
  // select copy family gained fp twins (fp-data-select-PRD §4.1 — the two
  // fences legitimately diverge; a tainted fp printf arg has no
  // `cqrt_tape_write_f<W>` and still declines in IOSinkLowering). There is no
  // `cqrt_tape_write_i128_controlled` either, so an unsupported width returns
  // a null FunctionCallee (caller declines) rather than minting a phantom
  // extern that link-fails.
  llvm::FunctionCallee tapeWriteControlledFn(llvm::StringRef abiWidth) const;

private:
  llvm::Module &M;
  WidthDispatch &Wd;
};

}  // namespace cq

#endif  // CQ_IRPASS_CONTROLLED_SYMBOLS_H_
