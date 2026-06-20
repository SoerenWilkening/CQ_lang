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
  return 0;
}

// Float ABI widths in bits, or 0 if `w` is not an in-scope fp width.
unsigned fpBits(StringRef w) {
  if (w == "f16") return 16;  // Phase 7.1 Increment D — half-precision
  if (w == "f32") return 32;
  if (w == "f64") return 64;
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
  // Floating-point width casts.
  if (op == "fpext")
    return ff && tf && ff < tf;
  if (op == "fptrunc")
    return ff && tf && ff > tf;
  // Cross-domain casts. sitofp/fptosi exclude i1 (no signed bool; Clang
  // uses uitofp/fptoui for _Bool); uitofp/fptoui include i1 (PRD §"Cross-
  // domain casts").
  if (op == "sitofp")
    return fi && tf && fromW != "i1";
  if (op == "uitofp")
    return fi && tf;
  if (op == "fptosi")
    return ff && ti && toW != "i1";
  if (op == "fptoui")
    return ff && ti;
  return false;
}

bool compareInScope(StringRef op, StringRef pred) {
  if (op == "icmp")
    // All 10 LLVM integer predicates are in scope (YAML `icmp` predicate set).
    return pred == "eq" || pred == "ne" || pred == "ugt" || pred == "uge" ||
           pred == "ult" || pred == "ule" || pred == "sgt" || pred == "sge" ||
           pred == "slt" || pred == "sle";
  if (op == "fcmp")
    // Only the 6 predicates Clang emits for C float `== != < > <= >=`
    // (`oeq, une, olt, ogt, ole, oge`); every other fcmp predicate
    // (`one`/`ord`/`uno`/`ueq`/unordered `u*`/`true`/`false`) is out of scope.
    return pred == "oeq" || pred == "une" || pred == "olt" || pred == "ogt" ||
           pred == "ole" || pred == "oge";
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
    default: return {};  // i128 deferred (its C ABI shreds __int128 to
                         // {i64,i64}); non-power-of-2 _BitInt(N) declines here.
    }
  }
  if (ty->isHalfTy())   return "f16";  // Phase 7.1 Increment D — _Float16
  if (ty->isFloatTy())  return "f32";
  if (ty->isDoubleTy()) return "f64";
  return {};
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
