// TemplateName.h — Pure symbol-string builder for the frozen template
// naming convention (PRD §2.1). No LLVM beyond `StringRef`; no IR, no
// type construction (that is `WidthDispatch`'s job). This TU owns the
// *string* only.
//
// The convention (Phase 4 adds the trailing `[_controlled][_inv]` axis;
// both default off so forward, uncontrolled output is unchanged):
//
//   cq_template_<op>[_<pred>]_<W>[_<from>_to_<to>][_hl|_lh][_controlled][_inv]
//
//   * data    : cq_template_<op>_<W>[_hl|_lh]
//                 add i32 Q+Q     → cq_template_add_i32
//                 add i32 Q+C     → cq_template_add_i32_hl
//                 sub i32 C+Q     → cq_template_sub_i32_lh
//   * compare : cq_template_<op>_<pred>_<W>[_hl]   (QQ or HL only — no _lh)
//                 icmp slt i32 QQ → cq_template_icmp_slt_i32
//                 fcmp une f32 HL → cq_template_fcmp_une_f32_hl
//   * cast    : cq_template_<op>_<from>_to_<to>     (unary — no shape suffix)
//                 sext i1→i32     → cq_template_sext_i1_to_i32
//   * unary   : cq_template_<op>_<W>                (fneg — no shape suffix)
//                 fneg f32        → cq_template_fneg_f32
//
// The stem (`add`/`sub`/`fadd`/`shl`/…), the predicate
// (`slt`/`une`/`oeq`/…), and the op name (`icmp`/`fcmp`/`sext`/…) are the
// exact strings LLVM hands us via `Instruction::getOpcodeName()` /
// `CmpInst::getPredicateName()`; this builder only concatenates, it does
// not invent names. Per PRD §2.1 the convention is mirrored here, not
// copied from a generated table; drift is caught by per-symbol LIT
// FileCheck and by linking against the generated runtime header.

#ifndef CQ_IRPASS_TEMPLATE_NAME_H_
#define CQ_IRPASS_TEMPLATE_NAME_H_

#include "llvm/ADT/StringRef.h"

#include <string>

namespace cq {

// Operand shape of a lowered op. Drives the `_hl`/`_lh` suffix (data and
// compare) and the operand-type fan-out in `WidthDispatch`.
//   * QQ    — both operands are quantum handles (no suffix).
//   * HL    — handle on the left, classical literal on the right (`_hl`).
//   * LH    — classical literal on the left, handle on the right (`_lh`).
//             Non-commutative binary ops only; never compares.
//   * Unary — single operand (fneg / casts). No shape suffix.
//   * Ternary{QQQ,QQL,QLQ,QLL} — the fma `a*b + c` family (wd2p). When the
//             product holds a handle, its first slot is ALWAYS a handle (the
//             recognizer canonicalizes the commutative pair handle-before-literal);
//             the second product slot and the positional addend are each handle
//             (`q`) or literal (`l`). `QQQ` carries no shape suffix (bare base,
//             like binary QQ); the mixed forms spell `_qql`/`_qlq`/`_qll`.
//   * TernaryLLQ — the fma with an all-classical product and a quantum addend
//             (bd 3c6m.73): `_llq` (literal, literal, handle), product order kept.
//             Data ops only — never compares/casts.
enum class Shape {
  QQ,
  HL,
  LH,
  Unary,
  TernaryQQQ,
  TernaryQQL,
  TernaryQLQ,
  TernaryQLL,
  TernaryLLQ,
};

// Controlled / inverse axis (Phase 4, PRD §2.8). Both default to the
// no-control forward form, so every existing caller stays byte-identical.
// The grammar appends, after the shape suffix: `_controlled` when
// `controlled`, then `_inv` when `inverse` — in that fixed order. E.g.
// data add i32 HL controlled → `cq_template_add_i32_hl_controlled`;
// controlled_inv → `cq_template_add_i32_hl_controlled_inv`; QQ controlled
// → `cq_template_add_i32_controlled`. (An `_inv`-only form — `inverse`
// without `controlled` — spells `..._inv`, matching the generated
// uncontrolled inverse templates.)

// Binary/unary data op: `cq_template_<stem>_<W>[_hl|_lh][_controlled][_inv]`.
// `Shape::Unary` (fneg) and `Shape::QQ` get no shape suffix; `HL`→`_hl`,
// `LH`→`_lh`. `_controlled`/`_inv` follow the shape suffix (see above).
std::string dataName(llvm::StringRef stem, llvm::StringRef width, Shape shape,
                     bool controlled = false, bool inverse = false);

// Compare op: `cq_template_<op>_<pred>_<W>[_hl][_controlled][_inv]`. `op` is
// "icmp"/"fcmp", `pred` the LLVM predicate name. Only `Shape::QQ` (no
// suffix) and `Shape::HL` (`_hl`) are valid — compares have no `_lh` form (a
// literal-on-left compare canonicalizes by predicate flip; PRD §2.4).
std::string compareName(llvm::StringRef op, llvm::StringRef pred,
                        llvm::StringRef width, Shape shape,
                        bool controlled = false, bool inverse = false);

// Is argument slot `argIdx` of the `cq_template_*` symbol `symbol` a QUANTUM
// HANDLE slot, as opposed to a classical LITERAL one? (bd
// test_C_libtooling-4p7j Rule-13 round, finding F5.)
//
// THE INVERSE OF `shapeSuffix`, and deliberately the same table read the other
// way (Rule 14): `_hl` → slot 0, `_lh` → slot 1, `_qql` → {0,1}, `_qlq` → {0,2},
// `_qll` → {0}, `_llq` → {2}; NO shape suffix (QQ / Unary / cast / TernaryQQQ) → every slot.
// FORWARD, UNCONTROLLED SYMBOLS ONLY: a `_controlled` form prepends a flag and an
// `_inv`/`_unc` twin takes the rail out-first, so both SHIFT the slots and both
// answer `false` here rather than confidently and wrongly.
//
// WHY THE SYMBOL AND NOT THE TYPE: an `_hl` template at width i32 has the
// FunctionType `(i32, i32) -> i32` — the classical operand is `llvmWidthType`,
// which for i32 IS the handle type — so no operand type distinguishes the slots
// and only the name does.
//
// FAILS CLOSED: `false` for anything that is not a `cq_template_*` symbol, for
// an out-of-range index, and for any name whose shape token this cannot read.
// A caller asking "may this value appear here?" therefore refuses on doubt,
// which is the Prime Directive's direction.
bool isHandleSlot(llvm::StringRef symbol, unsigned argIdx);

// The SAME question for the void OUT-FIRST adjoint twin `f_unc(out, operands…)`
// that `EmitInverse` mints: is argument slot `argIdx` of the `_unc` symbol a
// QUANTUM HANDLE slot? (bd test_C_libtooling-160a, M-B Increment 6.)
//
// SLOT 0 IS THE WRITTEN RAIL and answers `false` — deliberately. The caller
// (`ChainWalk::isInteriorConsumer`, gated on `TaintSet::DischargedFlagGates`)
// asks "did this call merely READ my rail?", and slot 0 is the register the
// `_unc` ZEROES. For a Phase-4 flag strip that slot is the control flag, a rail
// Phase 4 owns and frees on the next line; admitting it as a read would let the
// interior partition discharge a rail another owner is still tearing down.
//
// Every other slot SHIFTS BY ONE and is answered by `isHandleSlot` on the base
// symbol — one table, read in one direction, exactly as the forward form is
// (Rule 14). `_unc` is the only trailing token this accepts: a `_controlled_unc`
// prepends a flag ON TOP of the out-first rail, which is a THIRD layout nobody
// has needed, so it fails closed rather than guessing a double shift.
bool isUncHandleSlot(llvm::StringRef symbol, unsigned argIdx);

// Cast op: `cq_template_<op>_<from>_to_<to>[_controlled][_inv]`. `op` is the
// cast opcode name ("sext"/"zext"/"trunc"/"fpext"/"fptrunc"/"sitofp"/
// "uitofp"/"fptosi"/"fptoui"). Casts are unary at the IR level → no shape
// suffix (PRD §2.3); the controlled/inverse tokens still trail last.
std::string castName(llvm::StringRef op, llvm::StringRef fromW,
                     llvm::StringRef toW, bool controlled = false,
                     bool inverse = false);

}  // namespace cq

#endif  // CQ_IRPASS_TEMPLATE_NAME_H_
