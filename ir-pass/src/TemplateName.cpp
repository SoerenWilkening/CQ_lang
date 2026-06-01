// TemplateName.cpp — Pure symbol-string builder (PRD §2.1). See header
// for the full convention. This TU touches no LLVM IR; it only spells
// names. `WidthDispatch` owns the matching `FunctionType` / lazy decl.

#include "TemplateName.h"

#include "llvm/ADT/Twine.h"

using namespace llvm;

namespace cq {

namespace {

// The `_hl`/`_lh` shape suffix for data/compare ops. QQ and Unary carry
// no shape suffix (the base symbol). LH is valid only for data ops; the
// compare builder never passes it (asserted by the caller's invariants —
// compares canonicalize a left literal by predicate flip, not `_lh`).
StringRef shapeSuffix(Shape shape) {
  switch (shape) {
  case Shape::HL: return "_hl";
  case Shape::LH: return "_lh";
  case Shape::QQ:
  case Shape::Unary:
    break;
  }
  return "";
}

// The trailing `[_controlled][_inv]` axis (Phase 4, PRD §2.8). Appended
// after the shape suffix in a fixed order: `_controlled` first (when
// controlled), then `_inv` (when inverse). With both false the result is
// the empty string, so the no-control forward symbol is byte-identical to
// the Phase-3 names.
StringRef ctrlInvSuffix(bool controlled, bool inverse) {
  if (controlled)
    return inverse ? "_controlled_inv" : "_controlled";
  return inverse ? "_inv" : "";
}

}  // namespace

std::string dataName(StringRef stem, StringRef width, Shape shape,
                     bool controlled, bool inverse) {
  // cq_template_<stem>_<W>[_hl|_lh][_controlled][_inv]. With the default
  // (uncontrolled, forward) axis this matches the existing
  // `cq_template_add_i32` / `cq_template_add_i32_hl` /
  // `cq_template_sub_i32_lh` symbols byte-for-byte.
  return ("cq_template_" + stem + "_" + width + shapeSuffix(shape) +
          ctrlInvSuffix(controlled, inverse))
      .str();
}

std::string compareName(StringRef op, StringRef pred, StringRef width,
                        Shape shape, bool controlled, bool inverse) {
  // cq_template_<op>_<pred>_<W>[_hl][_controlled][_inv]. Compares insert the
  // predicate token between the op name and the width; no `_lh` form exists.
  return ("cq_template_" + op + "_" + pred + "_" + width + shapeSuffix(shape) +
          ctrlInvSuffix(controlled, inverse))
      .str();
}

std::string castName(StringRef op, StringRef fromW, StringRef toW,
                     bool controlled, bool inverse) {
  // cq_template_<op>_<from>_to_<to>[_controlled][_inv]. Unary at the IR
  // level — no shape suffix. The width pair keys the symbol (and changes the
  // handle's ABI width); both widths are captured before RAUW (PRD §2.3).
  return ("cq_template_" + op + "_" + fromW + "_to_" + toW +
          ctrlInvSuffix(controlled, inverse))
      .str();
}

}  // namespace cq
