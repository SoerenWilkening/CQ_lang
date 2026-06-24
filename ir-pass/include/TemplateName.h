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
//   * Ternary{QQQ,QQL,QLQ,QLL} — the fma `a*b + c` family (wd2p). The product's
//             first slot is ALWAYS a handle (the recognizer canonicalizes the
//             commutative pair handle-before-literal); the second product slot
//             and the positional addend are each handle (`q`) or literal (`l`).
//             `QQQ` carries no shape suffix (bare base, like binary QQ); the
//             mixed forms spell `_qql`/`_qlq`/`_qll`. Data ops only — never
//             compares/casts.
enum class Shape {
  QQ,
  HL,
  LH,
  Unary,
  TernaryQQQ,
  TernaryQQL,
  TernaryQLQ,
  TernaryQLL,
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

// Cast op: `cq_template_<op>_<from>_to_<to>[_controlled][_inv]`. `op` is the
// cast opcode name ("sext"/"zext"/"trunc"/"fpext"/"fptrunc"/"sitofp"/
// "uitofp"/"fptosi"/"fptoui"). Casts are unary at the IR level → no shape
// suffix (PRD §2.3); the controlled/inverse tokens still trail last.
std::string castName(llvm::StringRef op, llvm::StringRef fromW,
                     llvm::StringRef toW, bool controlled = false,
                     bool inverse = false);

}  // namespace cq

#endif  // CQ_IRPASS_TEMPLATE_NAME_H_
