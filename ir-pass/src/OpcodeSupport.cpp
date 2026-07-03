// OpcodeSupport.cpp — supported-set + classification policy. See header
// for the surface. Hand-authored per PRD §2.1 (no generated table); the
// per-symbol LIT fixtures + link against the generated runtime header
// guard against drift from the yaml convention.

#include "OpcodeSupport.h"

#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/raw_ostream.h"

#include <string>

using namespace llvm;

namespace cq {

namespace {

// Integer ABI widths in bits, or 0 if `w` is not an in-scope int width.
unsigned intBits(StringRef w) {
  if (w == "i1")  return 1;
  if (w == "i8")  return 8;
  if (w == "i16") return 16;
  if (w == "i32") return 32;
  if (w == "i64") return 64;
  if (w == "i128") return 128;  // n0ui Tier-1 — INTERMEDIATE wide-int width
  return 0;
}

// Float ABI widths in bits, or 0 if `w` is not an in-scope fp width.
unsigned fpBits(StringRef w) {
  if (w == "f16") return 16;  // Phase 7.1 Increment D — half-precision
  if (w == "f32") return 32;
  if (w == "f64") return 64;
  if (w == "f80") return 80;    // bd 3c6m.4 — x86 extended (long double on x86-64)
  // f128 (IEEE quad) is NOT shipped: its only sound runtime c_type is a genuine
  // 128-bit fp, which this x86-64 build cannot compile (`_Float128`/`__float128`
  // unsupported here) — using `long double` (= fp80) would be an fp128-into-fp80
  // ABI silent miscompile. A tainted fp128 therefore DECLINES (abiWidthFromType
  // returns "" for it). f128==long double on AArch64 is a deferred, must-be-
  // built-on-AArch64 follow-up (Prime Directive: over-decline, never over-accept).
  return 0;
}

// Stringify an instruction's opcode + type for diagnostics, e.g.
// "sub i32" or "fadd half". Mirrors the original OpcodeLowering helper so
// the existing negative fixtures (lowering_sub_negative.ll) match the same
// substring. Casts/compares print their value type, which is enough for a
// recognizable FileCheck without depending on SSA names.
std::string describe(Instruction *I) {
  std::string s;
  raw_string_ostream os(s);
  os << I->getOpcodeName() << ' ';
  I->getType()->print(os);
  return os.str();
}

}  // namespace

StringRef binaryStem(unsigned opcode) {
  switch (opcode) {
  // int_arith
  case Instruction::Add:  return "add";
  case Instruction::Sub:  return "sub";
  case Instruction::Mul:  return "mul";
  case Instruction::SDiv: return "sdiv";
  case Instruction::UDiv: return "udiv";
  case Instruction::SRem: return "srem";
  case Instruction::URem: return "urem";
  // int_bitwise
  case Instruction::And:  return "and";
  case Instruction::Or:   return "or";
  case Instruction::Xor:  return "xor";
  case Instruction::Shl:  return "shl";
  case Instruction::LShr: return "lshr";
  case Instruction::AShr: return "ashr";
  // fp_arith
  case Instruction::FAdd: return "fadd";
  case Instruction::FSub: return "fsub";
  case Instruction::FMul: return "fmul";
  case Instruction::FDiv: return "fdiv";
  case Instruction::FRem: return "frem";
  default:
    return {};
  }
}

bool isCommutative(unsigned opcode) {
  switch (opcode) {
  case Instruction::Add:
  case Instruction::Mul:
  case Instruction::And:
  case Instruction::Or:
  case Instruction::Xor:
  case Instruction::FAdd:
  case Instruction::FMul:
    return true;
  default:
    return false;
  }
}

CmpInst::Predicate flipPredicate(CmpInst::Predicate pred) {
  // Swapped-operand predicate (a OP b  ==  b FLIP a). LLVM provides this
  // exactly via getSwappedPredicate; eq/ne/oeq/une are their own swap.
  // We route through it rather than a hand table so the mapping can never
  // drift from LLVM's own definition.
  return CmpInst::getSwappedPredicate(pred);
}

bool castInScope(StringRef op, StringRef fromW, StringRef toW) {
  const unsigned fi = intBits(fromW), ti = intBits(toW);
  const unsigned ff = fpBits(fromW),  tf = fpBits(toW);
  // Integer width casts.
  if (op == "sext" || op == "zext")
    return fi && ti && fi < ti;            // strict widen
  if (op == "trunc")
    return fi && ti && fi > ti;            // strict narrow
  // Floating-point width casts. The full fp-width grid {f16,f32,f64,f80,f128}
  // is shipped (opcode_table.yaml fpext/fptrunc pairs) — the generic width
  // compare admits every strict widen/narrow among them, and each admitted pair
  // has a template (bd 3c6m.4; the same "COMPLETE the grid so the generic
  // compare never mints a phantom" discipline the i128 int-width casts follow).
  if (op == "fpext")
    return ff && tf && ff < tf;
  if (op == "fptrunc")
    return ff && tf && ff > tf;
  // Cross-domain casts. sitofp/fptosi exclude i1 (no signed bool; Clang
  // uses uitofp/fptoui for _Bool); uitofp/fptoui include i1 (PRD §"Cross-
  // domain casts"). i128 is EXCLUDED from every cross-domain cast (n0ui Tier-1):
  // i128 ships the integer WIDTH casts (zext/sext/trunc) ONLY — i128<->fp is a
  // distinct, un-shipped feature (and fp-data is the angle hazard), so a tainted
  // `sitofp i128`/`fptoui ... to i128`/etc. must DECLINE, never mint a phantom
  // cq_template_sitofp_i128_* the YAML does not carry. (intBits now knows i128,
  // so without these guards the generic `fi && tf` would wrongly accept it.)
  // f80 (long double on x86-64) IS in scope for cross-domain since bd 3c6m.5:
  // the YAML now carries int<->f80 pairs ({i8,i16,i32,i64}<->f80 for the signed
  // forms, +i1 for the unsigned forms). Casts are arity-1 (i32 handle in/out,
  // Rule 15), so f80's `long double` c_type NEVER materializes in a cast body —
  // the f128 c_type hazard (long double != fp128 off-x86) categorically cannot
  // reach a cast. f128 itself is NOT in fpBits (abiWidthFromType returns "" =>
  // ff/tf are 0), so it can never reach these branches; the i128 guards keep
  // i128<->fp declining (i128 ships integer WIDTH casts only, n0ui Tier-1).
  if (op == "sitofp")
    return fi && tf && fromW != "i1" && fromW != "i128";
  if (op == "uitofp")
    return fi && tf && fromW != "i128";
  if (op == "fptosi")
    return ff && ti && toW != "i1" && toW != "i128";
  if (op == "fptoui")
    return ff && ti && toW != "i128";
  return false;
}

bool compareInScope(StringRef op, StringRef pred) {
  if (op == "icmp")
    // All 10 LLVM integer predicates are in scope (YAML `icmp` predicate set).
    return pred == "eq" || pred == "ne" || pred == "ugt" || pred == "uge" ||
           pred == "ult" || pred == "ule" || pred == "sgt" || pred == "sge" ||
           pred == "slt" || pred == "sle";
  if (op == "fcmp")
    // The full ordered/unordered comparison family (14 of LLVM's 16 fp
    // predicates; YAML `fcmp` predicate set — MUST mirror it character-for-
    // character, the ziov4 hazard). The 6 Clang emits from plain C
    // `== != < > <= >=` (`oeq,une,olt,ogt,ole,oge`) plus 8rvn's unordered twins
    // (`ueq,ugt,uge,ult,ule`) and the order-test trio (`one,ord,uno`). The
    // degenerate `true`/`false` (always-1/always-0; no comparison) stay OUT —
    // an out-of-set predicate has no generated template, so it must loud-decline
    // (`diagnoseNoTemplate`), never `getOrInsertFunction` a phantom symbol. The
    // unordered `u*` names overlap icmp's UNSIGNED predicates, but the `op`
    // family stem disambiguates the symbol (`cq_template_fcmp_ugt_*` vs
    // `cq_template_icmp_ugt_*`). `flipPredicate`/`getSwappedPredicate` keeps the
    // set CLOSED under operand-swap (ugt<->ult, uge<->ule; one/ord/uno/ueq and
    // oeq/une self-map) so the classical-on-left flip never moves an in-scope
    // predicate out of scope.
    return pred == "oeq" || pred == "une" || pred == "olt" || pred == "ogt" ||
           pred == "ole" || pred == "oge" || pred == "one" || pred == "ord" ||
           pred == "uno" || pred == "ueq" || pred == "ugt" || pred == "uge" ||
           pred == "ult" || pred == "ule";
  return false;
}

StringRef abiWidthFromType(Type *ty) {
  if (!ty)
    return {};
  if (auto *IT = dyn_cast<IntegerType>(ty)) {
    switch (IT->getBitWidth()) {
    case 1:  return "i1";
    case 8:  return "i8";
    case 16: return "i16";
    case 32: return "i32";
    case 64: return "i64";
    case 128: return "i128";  // n0ui Tier-1 — INTERMEDIATE wide-int width. NOT a
                              // theta/measure suffix (the C ABI shreds a __int128
                              // source/sink to {i64,i64} — Tier-2, deferred). The
                              // dependent fences (copyFn>64, CompareLowering icmp,
                              // castInScope cross-domain) keep i128 control-mux /
                              // compare / fp-cast declining despite this.
    default: return {};  // non-power-of-2 _BitInt(N) / i256+ decline here.
    }
  }
  if (ty->isHalfTy())     return "f16";  // Phase 7.1 Increment D — _Float16
  if (ty->isFloatTy())    return "f32";
  if (ty->isDoubleTy())   return "f64";
  if (ty->isX86_FP80Ty()) return "f80";   // bd 3c6m.4 — long double on x86-64
  // fp128 is intentionally NOT mapped (returns "" → tainted fp128 declines): the
  // only sound runtime c_type for it is a real 128-bit fp, which this x86-64
  // build cannot compile, so `long double` (fp80) would silently miscompile an
  // fp128 value. f128==long double on AArch64 is deferred (see fpBits).
  return {};
}

bool widthHasReversibleCopy(StringRef w) {
  // {i1,i8,i16,i32,i64} have a `cqrt_copy_<W>` / `_controlled`; i128 (now a
  // recognized INTERMEDIATE width) and any wider int do NOT (n0ui Tier-1). An
  // empty/unknown width (intBits 0) and the fp widths (intBits 0) also fail —
  // exactly the set a tainted data-mux must decline. (The fp SELECT accept
  // rides `abiWidthHasControlledFpCopy` below, never this predicate.)
  const unsigned b = intBits(w);
  return b >= 1 && b <= 64;
}

bool abiWidthHasControlledFpCopy(StringRef w) {
  // {f16,f32,f64,f80} have a `cqrt_copy_f<W>_controlled` (fp-data-select-PRD
  // §4.1/§4.3 — Option B, the select-merge's sole consumer). fp128 stays out
  // (abiWidthFromType already returns "" for it — no sound c_type on this
  // x86-64 build), as do all integer/empty/unknown widths. Select-local: see
  // the header note before widening the consumer set.
  return w == "f16" || w == "f32" || w == "f64" || w == "f80";
}

void diagnoseNoTemplate(Instruction *inst, StringRef detail) {
  // Loud failure on the same DiagnosticInfoUnsupported surface the rest of
  // the pass uses. `detail` lets a caller supply a precise "<op> <type>"
  // string; empty falls back to a derived description so any Instruction*
  // is diagnosable. Message text matches the original BinaryOperator-only
  // helper so existing negative fixtures still FileCheck.
  std::string Detail = detail.empty() ? describe(inst) : detail.str();
  std::string Msg =
      "no template for opcode '" + Detail + "' in tainted context";
  inst->getFunction()->getContext().diagnose(
      DiagnosticInfoUnsupported(*inst->getFunction(), Msg));
}

}  // namespace cq
