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
  // Ternary fma (wd2p): the all-handle QQQ form is the bare base symbol (no
  // suffix, like binary QQ); the mixed forms carry a 3-letter shape token.
  case Shape::TernaryQQL: return "_qql";
  case Shape::TernaryQLQ: return "_qlq";
  case Shape::TernaryQLL: return "_qll";
  case Shape::QQ:
  case Shape::Unary:
  case Shape::TernaryQQQ:
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

bool isHandleSlot(StringRef symbol, unsigned argIdx) {
  // A NEW `Shape` ENUMERATOR MUST BE ADDED TO THE TABLE BELOW. The suffix half
  // is inverted from `shapeSuffix` itself (so a renamed token cannot drift),
  // but the SLOT LAYOUT is spelled here and in `WidthDispatch::dataTemplateFn`'s
  // FunctionType construction, which are the only two places that know it. This
  // assert is what stops a third shape being added to one and not the other.
  static_assert(static_cast<int>(Shape::TernaryQLL) == 7,
                "new Shape added — extend the handle-slot table below");
  if (!symbol.starts_with("cq_template_"))
    return false;  // the `cqrt_*` core ABI is not this grammar — fail closed.
  if (argIdx > 2)
    return false;  // no template arity exceeds 3 (the fma family).
  // THE FORWARD UNCONTROLLED FORM ONLY. Every symbol on the trailing
  // `[_controlled][_inv]` / `_unc` axis SHIFTS the slots relative to its base —
  // the void `_unc` twin `EmitInverse` mints takes the rail OUT-FIRST
  // (`f_unc(out, operands…)`), and a `_controlled` form prepends a flag — so
  // stripping the token and reading the base mask would answer confidently and
  // WRONGLY. Refuse instead: `false` for every slot, which is "not proven a
  // handle slot", the leak direction for the one caller
  // (`ChainWalk::isInteriorConsumer`, whose `isTemplateProducer` gate already
  // excludes all three families, so this is defence in depth rather than a live
  // path).
  StringRef N = symbol;
  if (N.ends_with("_unc") || N.ends_with("_inv") || N.contains("_controlled"))
    return false;
  // The handle-slot bitmask per shape, bit i = "slot i is a handle".
  //   HL  (handle, literal)                  → 0b001
  //   LH  (literal, handle)                  → 0b010
  //   QQL (handle, handle, literal)          → 0b011
  //   QLQ (handle, literal, handle)          → 0b101
  //   QLL (handle, literal, literal)         → 0b001
  // (the fma first slot is always a handle — see the `Shape` doc comment).
  static const struct {
    Shape S;
    unsigned Mask;
  } Table[] = {
      {Shape::HL, 0b001},         {Shape::LH, 0b010},
      {Shape::TernaryQQL, 0b011}, {Shape::TernaryQLQ, 0b101},
      {Shape::TernaryQLL, 0b001},
  };
  for (const auto &Row : Table)
    if (N.ends_with(shapeSuffix(Row.S)))
      return (Row.Mask >> argIdx) & 1u;
  // No shape token: `Shape::QQ`, `Shape::Unary`, `Shape::TernaryQQQ` and every
  // cast symbol — all of whose operands are handles.
  return true;
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
