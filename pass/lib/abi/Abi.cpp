// Module abi (cq-w0-abi): Abi.h and the type helpers of Common.h.
//
// CR §1.1 handles and widths, §1.2 template grammar, §1.3 core gates, §1.4 clone names, rule 27's
// asm clone name. Signatures per BACKEND_ABI §1-§2 and the corpus declarations.
//
// Every name() validates its spec and calls cq::internalError on a spec that does not denote a
// canonical CR spelling (a non-canonical shape, an unknown op, a suffix the op does not take). Every
// parse*() returns std::nullopt on anything that is not exactly a canonical spelling, so for every
// accepted symbol name(parse(sym)) == sym. Declarations carry no signext/zeroext (CR §1.2 allows
// both; the backend reads only the low W bits of a narrow operand).
#include "cq/Abi.h"
#include "cq/Common.h"
#include "AbiLiteral.h"

#include <cctype>
#include <cstring>

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/SHA256.h"
#include "llvm/Support/raw_ostream.h"

using llvm::StringRef;

// ---------------------------------------------------------------------------------------------
// Common.h type helpers
// ---------------------------------------------------------------------------------------------
namespace cq {

RailType railTypeOf(llvm::Type *t) {
  if (auto *it = llvm::dyn_cast<llvm::IntegerType>(t))
    return {Kind::Int, it->getBitWidth()};
  if (t->isHalfTy())
    return {Kind::Fp, 16};
  if (t->isFloatTy())
    return {Kind::Fp, 32};
  if (t->isDoubleTy())
    return {Kind::Fp, 64};
  if (t->isX86_FP80Ty())
    return {Kind::Fp, 80};
  if (t->isBFloatTy())
    return {Kind::BFloat, 16}; // B1 (cq-dvj): bf16 is its own kind, bits always 16
  std::string s;
  llvm::raw_string_ostream os(s);
  t->print(os);
  // fp128 is unreachable from C on this target (CR §1.1, rule 25); ppc_fp128 is not x86-64.
  // Anything else (pointer, vector, aggregate, void) is no rail.
  if (t->isFloatingPointTy())
    internalError("abi: railTypeOf: IR the pinned pipeline cannot emit (CR §0, rule 25): an fp type with no CR §1.1 rail width: " + os.str());
  internalError("abi: railTypeOf: not a scalar rail type: " + os.str());
}

llvm::Type *irTypeOf(llvm::LLVMContext &C, RailType r) {
  if (r.kind == Kind::Int) {
    if (r.bits < 1 || r.bits > llvm::IntegerType::MAX_INT_BITS)
      internalError("abi: irTypeOf: integer width out of range: i" + std::to_string(r.bits));
    return llvm::IntegerType::get(C, r.bits);
  }
  if (r.kind == Kind::BFloat) {
    if (r.bits != 16)
      internalError("abi: irTypeOf: a BFloat rail is 16 bits, not " + std::to_string(r.bits));
    return llvm::Type::getBFloatTy(C);
  }
  switch (r.bits) {
  case 16: return llvm::Type::getHalfTy(C);
  case 32: return llvm::Type::getFloatTy(C);
  case 64: return llvm::Type::getDoubleTy(C);
  case 80: return llvm::Type::getX86_FP80Ty(C);
  default: internalError("abi: irTypeOf: no fp rail of width " + std::to_string(r.bits));
  }
}

llvm::IntegerType *handleTy(llvm::LLVMContext &C) { return llvm::Type::getInt32Ty(C); }

} // namespace cq

// ---------------------------------------------------------------------------------------------
// Shared lexical helpers
// ---------------------------------------------------------------------------------------------
namespace {
using namespace cq;
using cq::abi::CloneSpec;
using cq::abi::Core;
using cq::abi::CoreSpec;
using cq::abi::TemplateSpec;

bool allDigits(StringRef s) {
  return !s.empty() && llvm::all_of(s, [](char c) { return c >= '0' && c <= '9'; });
}
// Decimal with no leading zero ("0" itself allowed when allowZero).
bool canonicalDecimal(StringRef s, bool allowZero) {
  if (!allDigits(s))
    return false;
  if (s.size() > 1 && s[0] == '0')
    return false;
  return allowZero || s != "0";
}

bool validRail(RailType r) {
  switch (r.kind) {
  case Kind::Int: return r.bits >= 1 && r.bits <= llvm::IntegerType::MAX_INT_BITS;
  case Kind::Fp: return r.bits == 16 || r.bits == 32 || r.bits == 64 || r.bits == 80;
  case Kind::BFloat: return r.bits == 16;
  }
  return false;
}

// The CR §1.1 width prefix: i, f, or bf (bf16 is the only BFloat width).
const char *widthPrefix(Kind k) {
  switch (k) {
  case Kind::Int: return "i";
  case Kind::Fp: return "f";
  case Kind::BFloat: return "bf";
  }
  return "?";
}

std::string widthToken(RailType r) {
  if (!validRail(r))
    internalError("abi: invalid rail width " + std::string(widthPrefix(r.kind)) + std::to_string(r.bits));
  return widthPrefix(r.kind) + std::to_string(r.bits);
}

// True for the fp kinds (IEEE half/float/double/x86_fp80 and bf16): CR §1.1 gives bf16 the same
// rounding and NaN rules, so every fp template, cast and _rm/_exc accepts it.
bool isFpKind(Kind k) { return k == Kind::Fp || k == Kind::BFloat; }

std::optional<RailType> parseWidth(StringRef s) {
  if (s == "bf16")
    return RailType{Kind::BFloat, 16};
  if (s.size() < 2 || (s[0] != 'i' && s[0] != 'f'))
    return std::nullopt;
  StringRef d = s.drop_front();
  if (!canonicalDecimal(d, false) || d.size() > 9)
    return std::nullopt;
  RailType r{s[0] == 'i' ? Kind::Int : Kind::Fp, 0};
  d.getAsInteger(10, r.bits);
  if (!validRail(r))
    return std::nullopt;
  return r;
}

llvm::SmallVector<StringRef, 8> splitUnderscore(StringRef s) {
  llvm::SmallVector<StringRef, 8> t;
  s.split(t, '_', -1, /*KeepEmpty=*/true);
  return t;
}

llvm::FunctionCallee declareChecked(llvm::Module &M, StringRef name, llvm::FunctionType *ft) {
  if (llvm::Function *f = M.getFunction(name)) {
    if (f->getFunctionType() != ft) {
      std::string s;
      llvm::raw_string_ostream os(s);
      os << "abi: " << name << " already in the module with type " << *f->getFunctionType()
         << ", ABI type is " << *ft;
      internalError(os.str());
    }
    return {ft, f};
  }
  return M.getOrInsertFunction(name, ft);
}

// ---------------------------------------------------------------------------------------------
// Templates (CR §1.2)
// ---------------------------------------------------------------------------------------------
enum class Arity : uint8_t { Unary, Binary, Select, Ternary, Qrom };
enum class Dom : uint8_t { Int, Fp, Any, CastII, CastFF, CastIF, CastFI, Bitcast, TruncEither };
enum class Comm : uint8_t { No, Int, Fp, Cmp, FmaProduct };

struct OpInfo {
  const char *name;
  Arity arity;
  Dom dom;
  Comm comm;
  bool hasPred;
};

// The op set of CR §1.2. "qrom_load_s" is spelled qrom_load_<W>_s (TemplateSpec::strided), so it is
// not an op name of its own here.
const OpInfo kOps[] = {
    {"add", Arity::Binary, Dom::Int, Comm::Int, false},
    {"sub", Arity::Binary, Dom::Int, Comm::No, false},
    {"mul", Arity::Binary, Dom::Int, Comm::Int, false},
    {"udiv", Arity::Binary, Dom::Int, Comm::No, false},
    {"sdiv", Arity::Binary, Dom::Int, Comm::No, false},
    {"urem", Arity::Binary, Dom::Int, Comm::No, false},
    {"srem", Arity::Binary, Dom::Int, Comm::No, false},
    {"and", Arity::Binary, Dom::Int, Comm::Int, false},
    {"or", Arity::Binary, Dom::Int, Comm::Int, false},
    {"xor", Arity::Binary, Dom::Int, Comm::Int, false},
    {"shl", Arity::Binary, Dom::Int, Comm::No, false},
    {"lshr", Arity::Binary, Dom::Int, Comm::No, false},
    {"ashr", Arity::Binary, Dom::Int, Comm::No, false},
    {"fadd", Arity::Binary, Dom::Fp, Comm::Fp, false},
    {"fsub", Arity::Binary, Dom::Fp, Comm::No, false},
    {"fmul", Arity::Binary, Dom::Fp, Comm::Fp, false},
    {"fdiv", Arity::Binary, Dom::Fp, Comm::No, false},
    {"frem", Arity::Binary, Dom::Fp, Comm::No, false},
    {"fneg", Arity::Unary, Dom::Fp, Comm::No, false},
    {"icmp", Arity::Binary, Dom::Int, Comm::Cmp, true},
    {"fcmp", Arity::Binary, Dom::Fp, Comm::Cmp, true},
    {"fcmps", Arity::Binary, Dom::Fp, Comm::Cmp, true},
    {"select", Arity::Select, Dom::Any, Comm::No, false},
    {"zext", Arity::Unary, Dom::CastII, Comm::No, false},
    {"sext", Arity::Unary, Dom::CastII, Comm::No, false},
    {"trunc", Arity::Unary, Dom::TruncEither, Comm::No, false},
    {"fpext", Arity::Unary, Dom::CastFF, Comm::No, false},
    {"fptrunc", Arity::Unary, Dom::CastFF, Comm::No, false},
    {"sitofp", Arity::Unary, Dom::CastIF, Comm::No, false},
    {"uitofp", Arity::Unary, Dom::CastIF, Comm::No, false},
    {"fptosi", Arity::Unary, Dom::CastFI, Comm::No, false},
    {"fptoui", Arity::Unary, Dom::CastFI, Comm::No, false},
    {"bitcast", Arity::Unary, Dom::Bitcast, Comm::No, false},
    {"fma", Arity::Ternary, Dom::Fp, Comm::FmaProduct, false},
    {"fshl", Arity::Ternary, Dom::Int, Comm::No, false},
    {"fshr", Arity::Ternary, Dom::Int, Comm::No, false},
    {"abs", Arity::Unary, Dom::Int, Comm::No, false},
    {"ctlz", Arity::Unary, Dom::Int, Comm::No, false},
    {"cttz", Arity::Unary, Dom::Int, Comm::No, false},
    {"ctpop", Arity::Unary, Dom::Int, Comm::No, false},
    {"bswap", Arity::Unary, Dom::Int, Comm::No, false},
    {"smax", Arity::Binary, Dom::Int, Comm::Int, false},
    {"smin", Arity::Binary, Dom::Int, Comm::Int, false},
    {"umax", Arity::Binary, Dom::Int, Comm::Int, false},
    {"umin", Arity::Binary, Dom::Int, Comm::Int, false},
    {"uadd_sat", Arity::Binary, Dom::Int, Comm::Int, false},
    {"usub_sat", Arity::Binary, Dom::Int, Comm::No, false},
    {"sadd_sat", Arity::Binary, Dom::Int, Comm::Int, false},
    {"ssub_sat", Arity::Binary, Dom::Int, Comm::No, false},
    {"uadd_overflow", Arity::Binary, Dom::Int, Comm::Int, false},
    {"sadd_overflow", Arity::Binary, Dom::Int, Comm::Int, false},
    {"umul_overflow", Arity::Binary, Dom::Int, Comm::Int, false},
    {"smul_overflow", Arity::Binary, Dom::Int, Comm::Int, false},
    {"usub_overflow", Arity::Binary, Dom::Int, Comm::No, false},
    {"ssub_overflow", Arity::Binary, Dom::Int, Comm::No, false},
    // fmax/fmin are not commutative under CR §2 (equal values give the first operand).
    {"fabs", Arity::Unary, Dom::Fp, Comm::No, false},
    {"copysign", Arity::Binary, Dom::Fp, Comm::No, false},
    {"fmax", Arity::Binary, Dom::Fp, Comm::No, false},
    {"fmin", Arity::Binary, Dom::Fp, Comm::No, false},
    {"floor", Arity::Unary, Dom::Fp, Comm::No, false},
    {"ceil", Arity::Unary, Dom::Fp, Comm::No, false},
    {"rint", Arity::Unary, Dom::Fp, Comm::No, false},
    {"round", Arity::Unary, Dom::Fp, Comm::No, false},
    {"sqrt", Arity::Unary, Dom::Fp, Comm::No, false},
    {"is_fpclass", Arity::Binary, Dom::Fp, Comm::No, false},
    {"qrom_load", Arity::Qrom, Dom::Any, Comm::No, false},
};

const OpInfo *findOp(StringRef op) {
  for (const OpInfo &o : kOps)
    if (op == o.name)
      return &o;
  return nullptr;
}

const char *kIcmpPreds[] = {"eq", "ne", "ugt", "uge", "ult", "ule", "sgt", "sge", "slt", "sle"};
const char *kFcmpPreds[] = {"false", "oeq", "ogt", "oge", "olt", "ole", "one", "ord",
                            "ueq",   "ugt", "uge", "ult", "ule", "une", "uno", "true"};

template <size_t N> bool inList(StringRef s, const char *(&list)[N]) {
  for (const char *p : list)
    if (s == p)
      return true;
  return false;
}

unsigned dataOperands(Arity a) {
  switch (a) {
  case Arity::Unary: return 1;
  case Arity::Binary: return 2;
  case Arity::Select: return 2; // the two arms; the condition is always a handle
  case Arity::Ternary: return 3;
  case Arity::Qrom: return 0;
  }
  return 0;
}

// Empty string when the spec is a canonical CR §1.2 spelling, else the reason it is not.
std::string checkTemplate(const TemplateSpec &s) {
  const OpInfo *o = findOp(s.op);
  if (!o)
    return "unknown template op '" + s.op + "'";
  if (!validRail(s.w))
    return "invalid width";
  if (s.to && !validRail(*s.to))
    return "invalid _to_ width";

  // Predicate.
  if (o->hasPred) {
    bool ok = s.op == "icmp" ? inList(StringRef(s.pred), kIcmpPreds) : inList(StringRef(s.pred), kFcmpPreds);
    if (!ok)
      return "invalid predicate '" + s.pred + "' for " + s.op;
  } else if (!s.pred.empty()) {
    return s.op + " takes no predicate";
  }

  // Domain and the cast's target.
  Kind wk = s.w.kind;
  auto needTo = [&](bool want) -> std::string {
    if (want && !s.to)
      return s.op + " needs _to_";
    if (!want && s.to)
      return s.op + " takes no _to_";
    return "";
  };
  std::string e;
  switch (o->dom) {
  case Dom::Int:
    if (!(e = needTo(false)).empty()) return e;
    if (wk != Kind::Int) return s.op + " needs an integer width";
    break;
  case Dom::Fp:
    if (!(e = needTo(false)).empty()) return e;
    if (!isFpKind(wk)) return s.op + " needs an fp width";
    break;
  case Dom::Any:
    if (!(e = needTo(false)).empty()) return e;
    break;
  case Dom::TruncEither:
    if (s.to) {
      if (wk != Kind::Int || s.to->kind != Kind::Int || s.to->bits >= s.w.bits)
        return "trunc_<W>_to_<W2> needs integers with W2 < W";
    } else if (!isFpKind(wk)) {
      return "trunc without _to_ is the fp rounding op and needs an fp width";
    }
    break;
  case Dom::CastII:
    if (!(e = needTo(true)).empty()) return e;
    if (wk != Kind::Int || s.to->kind != Kind::Int || s.to->bits <= s.w.bits)
      return s.op + " needs integers with W2 > W";
    break;
  case Dom::CastFF:
    if (!(e = needTo(true)).empty()) return e;
    if (!isFpKind(wk) || !isFpKind(s.to->kind))
      return s.op + " needs fp widths";
    // fpext/fptrunc between half and bfloat (equal widths) is rejected by LLVM 19's parser and out
    // of scope (CR §2); the strict direction test below rejects it.
    if (s.op == "fpext" ? s.to->bits <= s.w.bits : s.to->bits >= s.w.bits)
      return s.op + ": wrong direction";
    break;
  case Dom::CastIF:
    if (!(e = needTo(true)).empty()) return e;
    if (wk != Kind::Int || !isFpKind(s.to->kind)) return s.op + " needs int to fp";
    break;
  case Dom::CastFI:
    if (!(e = needTo(true)).empty()) return e;
    if (!isFpKind(wk) || s.to->kind != Kind::Int) return s.op + " needs fp to int";
    break;
  case Dom::Bitcast:
    if (!(e = needTo(true)).empty()) return e;
    if (s.to->bits != s.w.bits || s.to->kind == wk)
      return "bitcast needs equal widths of different kinds";
    break;
  }
  if (s.op == "bswap" && s.w.bits % 16 != 0)
    return "bswap needs a width that is a multiple of 16";

  // Strided QROM.
  if (s.strided && o->arity != Arity::Qrom)
    return "_s is qrom_load only";

  // Rounding mode and exception bits: only where an fp value is involved.
  bool fp = isFpKind(wk) || (s.to && isFpKind(s.to->kind));
  if ((s.rm != TemplateSpec::NoRm || s.exc) && !fp)
    return "_rm/_rmq/_exc need an fp operand or result";
  if (o->arity == Arity::Qrom && (s.rm != TemplateSpec::NoRm || s.exc))
    return "qrom_load takes no _rm/_rmq/_exc";

  // Shape.
  const std::string &sh = s.shape;
  unsigned n = dataOperands(o->arity);
  if (s.op == "is_fpclass" && sh != "hl")
    return "is_fpclass is spelled _hl (the class mask is an immediate)";
  if (sh.empty())
    return "";
  if (n == 0)
    return s.op + " takes no shape";
  if (sh.size() != n)
    return "shape '" + sh + "' needs " + std::to_string(n) + " letters";
  char handle = o->arity == Arity::Ternary ? 'q' : 'h';
  bool anyHandle = false;
  for (char c : sh) {
    if (c != handle && c != 'l')
      return "shape '" + sh + "': letters are " + std::string(1, handle) + "/l for " + s.op;
    anyHandle |= c == handle;
  }
  if (sh == std::string(n, handle))
    return "an all-handle shape is spelled bare";
  // No handle among the data operands: only the condition (select) or the _rmq mode is quantum.
  if (!anyHandle && o->arity != Arity::Select && s.rm != TemplateSpec::RmRail)
    return "shape '" + sh + "' has no quantum operand (needs _rmq)";
  if (o->arity == Arity::Binary && sh == "lh") {
    switch (o->comm) {
    case Comm::Int: return s.op + " is commutative: the handle goes first (_hl)";
    case Comm::Cmp: return "compares never take _lh (flip the predicate)";
    default: break; // Comm::Fp: _lh is the NaN-literal spelling
    }
  }
  // fma lqq/lql are the NaN-literal spellings (CR §1.2, 3aaafe1), as _lh is for a commutative fp
  // binary op: the name does not carry the literal, so the literal's NaN-ness is checked on the call
  // (checkFpLiteralPosition). fshl/fshr keep every mixed shape.
  return "";
}

void requireTemplate(const TemplateSpec &s) {
  std::string why = checkTemplate(s);
  if (!why.empty())
    internalError("abi: template spec: " + why);
}

std::string templateName(const TemplateSpec &s, bool unc) {
  std::string n = "cq_template_" + s.op;
  if (!s.pred.empty())
    n += "_" + s.pred;
  n += "_" + widthToken(s.w);
  if (s.to)
    n += "_to_" + widthToken(*s.to);
  if (!s.shape.empty())
    n += "_" + s.shape;
  if (s.strided)
    n += "_s";
  if (s.rm == TemplateSpec::RmLit)
    n += "_rm";
  else if (s.rm == TemplateSpec::RmRail)
    n += "_rmq";
  if (s.exc)
    n += "_exc";
  if (unc)
    n += "_unc";
  return n;
}

// ---------------------------------------------------------------------------------------------
// Core gates (CR §1.3)
// ---------------------------------------------------------------------------------------------
enum class WidthUse : uint8_t { None, FixedI1, Any };

struct CoreInfo {
  Core op;
  const char *stem;  // spelling before the width token (or the whole fixed name)
  WidthUse width;
  bool ctlAllowed, ctlRequired, hlAllowed, uncAllowed;
};

// The order of entries only matters for the parser's stem match (longer stems first where one is a
// prefix of another: "tape_write_str_lit" before "tape_write").
const CoreInfo kCores[] = {
    {Core::Alloc, "alloc", WidthUse::Any, false, false, false, false},
    {Core::Free, "free", WidthUse::None, false, false, false, false},
    {Core::Measure, "measure", WidthUse::Any, false, false, false, false},
    {Core::Ry, "ry", WidthUse::Any, true, false, false, false},
    {Core::RyQAngle, "ry", WidthUse::Any, true, false, false, false}, // ry_<W>_qangle
    {Core::RzI1, "rz_i1", WidthUse::FixedI1, false, false, false, false},
    {Core::RzQAngle, "rz_qangle", WidthUse::None, true, false, false, false},
    {Core::NotI1, "not_i1", WidthUse::FixedI1, false, false, false, false},
    {Core::AndI1, "and_i1", WidthUse::FixedI1, false, false, false, false},
    {Core::OrI1, "or_i1", WidthUse::FixedI1, false, false, false, false},
    {Core::XorI1, "xor_i1", WidthUse::FixedI1, false, false, false, false},
    {Core::Copy, "copy", WidthUse::Any, true, false, false, false},
    {Core::Xorc, "xorc", WidthUse::Any, true, false, false, false},
    {Core::QramAlloc, "qram_alloc", WidthUse::Any, false, false, false, false},
    {Core::QramRealloc, "qram_realloc", WidthUse::Any, false, false, false, true},
    {Core::QramStore, "qram_store", WidthUse::Any, true, false, true, true},
    {Core::QramLoad, "qram_load", WidthUse::Any, true, false, true, true},
    {Core::QramFree, "qram_free", WidthUse::None, false, false, false, false},
    {Core::QramSize, "qram_size", WidthUse::None, false, false, false, false},
    {Core::TapeAlloc, "tape_alloc", WidthUse::None, false, false, false, false},
    {Core::TapeFmt, "tape_fmt", WidthUse::None, true, false, false, false},
    {Core::TapeEffect, "tape_effect", WidthUse::None, true, true, false, false},
    {Core::TapeWriteStrLit, "tape_write_str_lit", WidthUse::None, false, false, false, false},
    {Core::TapeStrBegin, "tape_str_begin", WidthUse::None, false, false, false, false},
    {Core::TapeStrEnd, "tape_str_end", WidthUse::None, false, false, false, false},
    {Core::TapeWrite, "tape_write", WidthUse::Any, true, false, false, false},
    {Core::TapeWriteLit, "tape_write", WidthUse::Any, false, false, false, false}, // tape_write_<W>_lit
    {Core::AbortI1, "abort_i1", WidthUse::FixedI1, false, false, false, false},
    {Core::Push, "push", WidthUse::None, false, false, false, false},
    {Core::Pop, "pop", WidthUse::None, false, false, false, false},
    {Core::InvertBegin, "invert_begin", WidthUse::None, false, false, false, false},
    {Core::InvertEnd, "invert_end", WidthUse::None, false, false, false, false},
};

const CoreInfo &coreInfo(Core op) {
  for (const CoreInfo &c : kCores)
    if (c.op == op)
      return c;
  internalError("abi: unknown core op " + std::to_string(unsigned(op)));
}

std::string checkCore(const CoreSpec &s) {
  const CoreInfo &c = coreInfo(s.op);
  switch (c.width) {
  case WidthUse::Any:
    if (!validRail(s.w))
      return std::string("cqrt_") + c.stem + " needs a valid width";
    break;
  case WidthUse::FixedI1:
    if (!(s.w.kind == Kind::Int && (s.w.bits == 0 || s.w.bits == 1)))
      return std::string("cqrt_") + c.stem + " is i1 only";
    break;
  case WidthUse::None:
    if (!(s.w.kind == Kind::Int && s.w.bits == 0))
      return std::string("cqrt_") + c.stem + " takes no width";
    break;
  }
  if (s.ctl && !c.ctlAllowed)
    return std::string("cqrt_") + c.stem + " has no _controlled form";
  if (!s.ctl && c.ctlRequired)
    return std::string("cqrt_") + c.stem + " exists only as _controlled";
  if (s.hl && !c.hlAllowed)
    return std::string("cqrt_") + c.stem + " has no _hl form";
  if (s.unc && !c.uncAllowed)
    return std::string("cqrt_") + c.stem + " has no _unc spelling (an involution is its own _unc)";
  return "";
}

void requireCore(const CoreSpec &s) {
  std::string why = checkCore(s);
  if (!why.empty())
    internalError("abi: core spec: " + why);
}

std::string coreName(const CoreSpec &s) {
  const CoreInfo &c = coreInfo(s.op);
  std::string n = std::string("cqrt_") + c.stem;
  if (c.width == WidthUse::Any)
    n += "_" + widthToken(s.w);
  if (s.op == Core::RyQAngle)
    n += "_qangle";
  if (s.op == Core::TapeWriteLit)
    n += "_lit";
  if (s.hl)
    n += "_hl";
  if (s.ctl)
    n += "_controlled";
  if (s.unc)
    n += "_unc";
  return n;
}

// ---------------------------------------------------------------------------------------------
// Clones (CR §1.4)
// ---------------------------------------------------------------------------------------------
bool isMask(StringRef s) {
  return llvm::all_of(s, [](char c) { return c == '0' || c == '1'; });
}

std::string cloneName(const CloneSpec &s) {
  std::string n = "__cq_q_" + s.fn + "_" + s.mask;
  for (size_t i = 0; i < s.bounds.size(); ++i)
    n += (i == 0 ? "_b" : "_") + std::to_string(s.bounds[i]);
  if (s.ctl)
    n += "_ctl";
  if (s.pure)
    n += "_pure";
  if (s.depth)
    n += "_d" + std::to_string(s.depth);
  for (size_t i = 0; i < s.inv.size(); ++i)
    n += (i == 0 ? "_inv" : "_") + std::to_string(s.inv[i]);
  if (s.unc)
    n += "_unc";
  return n;
}

std::optional<CloneSpec> parseCloneImpl(StringRef sym) {
  if (!sym.consume_front("__cq_q_"))
    return std::nullopt;
  llvm::SmallVector<StringRef, 8> t = splitUnderscore(sym);
  CloneSpec s;
  size_t n = t.size();
  // Suffixes, right to left, in the reverse of their fixed order.
  if (n && t[n - 1] == "unc") { s.unc = true; --n; }
  // cq-xivx: "_inv" cell { "_" cell }: trailing decimal tokens back to an "inv<N>" token. A reading that
  // leaves no mask is not this suffix (a fn or mask token that merely looks like one).
  {
    size_t k = n;
    while (k > 0 && allDigits(t[k - 1]))
      --k;
    if (k > 1 && t[k - 1].size() > 3 && t[k - 1].starts_with("inv") && allDigits(t[k - 1].drop_front(3))) {
      std::vector<unsigned> cells;
      bool ok = true;
      for (size_t i = k - 1; i < n && ok; ++i) {
        StringRef c = i == k - 1 ? t[i].drop_front(3) : t[i];
        unsigned v;
        ok = canonicalDecimal(c, true) && !c.getAsInteger(10, v);
        if (ok)
          cells.push_back(v);
      }
      bool maskLeft = false;
      for (size_t i = 0; i + 1 < k; ++i)
        maskLeft |= isMask(t[i]);
      if (ok && maskLeft) {
        s.inv = std::move(cells);
        n = k - 1;
      }
    }
  }
  if (n && t[n - 1].size() > 1 && t[n - 1][0] == 'd' && canonicalDecimal(t[n - 1].drop_front(), false)) {
    if (t[n - 1].drop_front().getAsInteger(10, s.depth))
      return std::nullopt;
    --n;
  }
  if (n && t[n - 1] == "pure") { s.pure = true; --n; }
  if (n && t[n - 1] == "ctl") { s.ctl = true; --n; }
  if (n == 0)
    return std::nullopt;
  // Bounds: "<mask>_b<N>{_<N>}". Walk back over all-digit tokens to a "b<N>" token preceded by a mask.
  size_t k = n;
  while (k > 0 && allDigits(t[k - 1]))
    --k;
  size_t maskAt = n - 1;
  if (k > 0 && t[k - 1].size() > 1 && t[k - 1][0] == 'b' && allDigits(t[k - 1].drop_front()) && k >= 2 &&
      isMask(t[k - 2])) {
    llvm::SmallVector<StringRef, 4> bs;
    bs.push_back(t[k - 1].drop_front());
    for (size_t i = k; i < n; ++i)
      bs.push_back(t[i]);
    for (StringRef b : bs) {
      uint64_t v;
      if (!canonicalDecimal(b, true) || b.getAsInteger(10, v))
        return std::nullopt;
      s.bounds.push_back(v);
    }
    maskAt = k - 2;
  }
  if (!isMask(t[maskAt]))
    return std::nullopt;
  s.mask = t[maskAt].str();
  std::string fn;
  for (size_t i = 0; i < maskAt; ++i)
    fn += (i ? "_" : "") + t[i].str();
  if (fn.empty())
    return std::nullopt;
  s.fn = fn;
  return s;
}

} // namespace

// ---------------------------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------------------------
namespace cq::abi {

std::string name(const TemplateSpec &s, bool unc) {
  requireTemplate(s);
  return templateName(s, unc);
}

llvm::FunctionCallee declare(llvm::Module &M, const TemplateSpec &s, bool unc) {
  requireTemplate(s);
  llvm::LLVMContext &C = M.getContext();
  const OpInfo *o = findOp(s.op);
  llvm::Type *h = handleTy(C);
  llvm::SmallVector<llvm::Type *, 6> args;
  if (unc)
    args.push_back(h); // out
  if (o->arity == Arity::Qrom) {
    args.push_back(llvm::PointerType::getUnqual(C));
    args.push_back(llvm::Type::getInt64Ty(C));
    if (s.strided)
      args.push_back(llvm::Type::getInt64Ty(C));
    args.push_back(h); // idx
  } else {
    if (o->arity == Arity::Select)
      args.push_back(h); // condition
    unsigned n = dataOperands(o->arity);
    for (unsigned i = 0; i < n; ++i) {
      bool lit = !s.shape.empty() && s.shape[i] == 'l';
      if (!lit)
        args.push_back(h);
      else if (s.op == "is_fpclass" && i == 1)
        args.push_back(llvm::Type::getInt32Ty(C)); // the class mask
      else
        args.push_back(irTypeOf(C, s.w));
    }
  }
  if (s.rm != TemplateSpec::NoRm)
    args.push_back(llvm::Type::getInt32Ty(C)); // FE_* literal (_rm) or mode rail (_rmq)
  llvm::Type *ret = unc ? llvm::Type::getVoidTy(C) : static_cast<llvm::Type *>(h);
  return declareChecked(M, templateName(s, unc), llvm::FunctionType::get(ret, args, false));
}

std::optional<TemplateSpec> parseTemplate(llvm::StringRef sym, bool *unc) {
  StringRef rest = sym;
  if (!rest.consume_front("cq_template_"))
    return std::nullopt;
  // Longest op that is followed by '_'.
  const OpInfo *op = nullptr;
  for (const OpInfo &o : kOps) {
    StringRef on(o.name);
    if (rest.size() > on.size() && rest.starts_with(on) && rest[on.size()] == '_' &&
        (!op || on.size() > std::strlen(op->name)))
      op = &o;
  }
  if (!op)
    return std::nullopt;
  TemplateSpec s;
  s.op = op->name;
  llvm::SmallVector<StringRef, 8> t = splitUnderscore(rest.drop_front(std::strlen(op->name) + 1));
  size_t i = 0, n = t.size();
  auto at = [&](StringRef v) { return i < n && t[i] == v; };
  if (op->hasPred) {
    if (i >= n)
      return std::nullopt;
    s.pred = t[i++].str();
  }
  if (i >= n)
    return std::nullopt;
  auto w = parseWidth(t[i++]);
  if (!w)
    return std::nullopt;
  s.w = *w;
  if (at("to")) {
    ++i;
    if (i >= n)
      return std::nullopt;
    auto w2 = parseWidth(t[i++]);
    if (!w2)
      return std::nullopt;
    s.to = *w2;
  }
  if (i < n && !t[i].empty() && llvm::all_of(t[i], [](char c) { return c == 'h' || c == 'q' || c == 'l'; }))
    s.shape = t[i++].str();
  if (at("s")) { s.strided = true; ++i; }
  if (at("rm")) { s.rm = TemplateSpec::RmLit; ++i; }
  else if (at("rmq")) { s.rm = TemplateSpec::RmRail; ++i; }
  if (at("exc")) { s.exc = true; ++i; }
  bool u = false;
  if (at("unc")) { u = true; ++i; }
  if (i != n)
    return std::nullopt;
  if (!checkTemplate(s).empty())
    return std::nullopt;
  if (templateName(s, u) != sym)
    return std::nullopt;
  if (unc)
    *unc = u;
  return s;
}

std::string name(const CoreSpec &s) {
  requireCore(s);
  return coreName(s);
}

llvm::FunctionCallee declare(llvm::Module &M, const CoreSpec &s) {
  requireCore(s);
  llvm::LLVMContext &C = M.getContext();
  llvm::Type *h = handleTy(C);
  llvm::Type *v = llvm::Type::getVoidTy(C);
  llvm::Type *d = llvm::Type::getDoubleTy(C);
  llvm::Type *p = llvm::PointerType::getUnqual(C);
  llvm::Type *i32 = llvm::Type::getInt32Ty(C);
  auto T = [&]() { return irTypeOf(C, s.w); };
  llvm::SmallVector<llvm::Type *, 5> a;
  llvm::Type *ret = v;
  if (s.ctl)
    a.push_back(h); // the control flag is argument 0 of every _controlled form
  switch (s.op) {
  case Core::Alloc: ret = h; a.push_back(T()); break;
  case Core::Free: a.push_back(h); break;
  case Core::Measure: ret = T(); a.push_back(h); break;
  case Core::Ry: a.append({h, d}); break;
  case Core::RyQAngle: a.append({h, h}); break;
  case Core::RzI1: a.append({h, d}); break;
  case Core::RzQAngle: a.push_back(h); break;
  case Core::NotI1: a.push_back(h); break;
  case Core::AndI1:
  case Core::OrI1: a.append({h, h, h}); break;
  case Core::XorI1: a.append({h, h}); break;
  case Core::Copy: a.append({h, h}); break;
  case Core::Xorc: a.append({h, T()}); break;
  case Core::QramAlloc: ret = h; a.push_back(i32); break;
  case Core::QramRealloc:
    // forward (a, n) -> a'; _unc (a', n_old)
    ret = s.unc ? v : h;
    a.append({h, i32});
    break;
  case Core::QramStore: a.append({h, s.hl ? i32 : h, h}); break; // (a, idx | j, v); _unc same
  case Core::QramLoad:
    if (s.unc) {
      a.insert(a.begin(), h); // _unc(h, [c,] a, idx | j)
    } else {
      ret = h;
    }
    a.append({h, s.hl ? i32 : h});
    break;
  case Core::QramFree: a.push_back(h); break;
  case Core::QramSize: ret = i32; a.push_back(h); break;
  case Core::TapeAlloc: ret = h; break;
  case Core::TapeFmt: a.append({h, p}); break;
  case Core::TapeEffect: a.append({h, p}); break;
  case Core::TapeWrite: ret = h; a.append({h, h}); break;
  case Core::TapeWriteLit: a.append({h, T()}); break;
  case Core::TapeWriteStrLit: a.append({h, p}); break;
  case Core::TapeStrBegin: case Core::TapeStrEnd: a.push_back(h); break;
  case Core::AbortI1: a.push_back(h); break;
  case Core::Push: a.push_back(i32); break;
  case Core::Pop: ret = i32; break;
  case Core::InvertBegin:
  case Core::InvertEnd: break;
  }
  return declareChecked(M, coreName(s), llvm::FunctionType::get(ret, a, false));
}

std::optional<CoreSpec> parseCore(llvm::StringRef sym) {
  StringRef rest = sym;
  if (!rest.consume_front("cqrt_"))
    return std::nullopt;
  for (const CoreInfo &c : kCores) {
    StringRef r = rest;
    if (!r.consume_front(c.stem))
      continue;
    CoreSpec s;
    s.op = c.op;
    if (c.width == WidthUse::FixedI1)
      s.w = {Kind::Int, 1};
    llvm::SmallVector<StringRef, 6> t;
    if (!r.empty()) {
      if (r[0] != '_')
        continue;
      t = splitUnderscore(r.drop_front());
    }
    size_t i = 0, n = t.size();
    auto at = [&](StringRef v) { return i < n && t[i] == v; };
    if (c.width == WidthUse::Any) {
      if (i >= n)
        continue;
      auto w = parseWidth(t[i++]);
      if (!w)
        continue;
      s.w = *w;
    }
    if (c.op == Core::RyQAngle) {
      if (!at("qangle"))
        continue;
      ++i;
    }
    if (c.op == Core::TapeWriteLit) {
      if (!at("lit"))
        continue;
      ++i;
    }
    if (at("hl")) { s.hl = true; ++i; }
    if (at("controlled")) { s.ctl = true; ++i; }
    if (at("unc")) { s.unc = true; ++i; }
    if (i != n)
      continue;
    if (!checkCore(s).empty())
      continue;
    if (coreName(s) != sym)
      continue;
    return s;
  }
  return std::nullopt;
}

// The §1.4 grammar is not injective for every fn (one ending in "_<mask>_b<N>"), and that is the
// spec (ruling 2026-10-27, cq-lmf): a name with bounds is internal to its module, the compiler binds
// clones by CloneSpec fields, never by re-reading a name, and the module that creates the function
// uniquifies a colliding symbol. So name() spells any well-formed spec without an ambiguity check.
std::string name(const CloneSpec &s) {
  if (s.fn.empty())
    internalError("abi: clone spec: empty function name");
  if (!isMask(s.mask))
    internalError("abi: clone spec: mask '" + s.mask + "' is not binary digits");
  return cloneName(s);
}

// The normative right-to-left reading (CR §1.4): suffix words, then the _b bounds, then the mask as
// the rightmost binary token; fn is the rest. Its consumers are rule-27 symbols, which carry no bounds.
std::optional<CloneSpec> parseClone(llvm::StringRef symbol) {
  auto s = parseCloneImpl(symbol);
  if (!s || cloneName(*s) != symbol)
    return std::nullopt;
  return s;
}

// Rule 27 (3aaafe1): SHA-256 over the asm string as LLVM spells it ($N operands), one NUL byte, then
// the constraint string; the first 16 lowercase hex digits.
std::string asmCloneFn(const llvm::InlineAsm &ia) {
  std::string data = ia.getAsmString();
  data.push_back('\0');
  data += ia.getConstraintString();
  std::array<uint8_t, 32> h = llvm::SHA256::hash(
      llvm::ArrayRef<uint8_t>(reinterpret_cast<const uint8_t *>(data.data()), data.size()));
  return "asm_" + llvm::toHex(h, /*LowerCase=*/true).substr(0, 16);
}

} // namespace cq::abi

namespace cq::abi::detail {

std::string checkFpLiteralPosition(const llvm::CallBase &call) {
  const llvm::Function *f = call.getCalledFunction();
  if (!f)
    return "not a direct call";
  bool unc = false;
  std::optional<TemplateSpec> s = parseTemplate(f->getName(), &unc);
  if (!s)
    return "@" + f->getName().str() + " is not a canonical cq_template_*";
  const OpInfo *o = findOp(s->op);
  bool kept = (o->comm == Comm::Fp && s->shape == "lh") ||
              (o->comm == Comm::FmaProduct && (s->shape == "lqq" || s->shape == "lql"));
  if (!kept)
    return "";
  unsigned at = unc ? 1 : 0; // the _unc forms take `out` first
  if (call.arg_size() <= at)
    return "@" + f->getName().str() + " called with too few arguments";
  // CR §1.2 (ruling cq-5iy, CQ_spec 8b52487): only a compile-time NaN constant keeps its position.
  // A non-NaN constant and a run-time classical operand both commute behind the handle.
  const llvm::Value *lit = call.getArgOperand(at);
  if (auto *c = llvm::dyn_cast<llvm::ConstantFP>(lit))
    if (c->isNaN())
      return "";
  std::string v;
  llvm::raw_string_ostream os(v);
  lit->printAsOperand(os, false);
  std::string swapped = s->shape == "lh" ? "hl" : s->shape == "lqq" ? "qlq" : "qll";
  return "@" + f->getName().str() + ": classical operand " + os.str() +
         " is not a compile-time NaN constant, so it commutes behind the handle (CR §1.2: _" + swapped + ")";
}

} // namespace cq::abi::detail
