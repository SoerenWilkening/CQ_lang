// WidthDispatch.cpp — Suffix → ABI width tables + symbol resolvers.
// See header for contract; PRD §Type map / §Width unification for table.

#include "WidthDispatch.h"

#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Type.h"

using namespace llvm;

namespace cq {

namespace {

// Canonical 14-suffix table — PRD §Type map. Int family first, then
// floats. Same order is reused by allSuffixes() and the front-end
// intrinsic name table; the per-suffix taint walk and the per-suffix
// measure walk both rely on this order being canonical.
//
// AbiWidth = "" marks the target-dependent rows (sl, ul); they resolve
// to LongAbiWidth — set from the Module's DataLayout at construction.
struct SuffixRow {
  StringRef Sfx;
  StringRef AbiWidth;
};

constexpr SuffixRow kRows[] = {
    {"i1",   "i1"},  {"c",    "i8"},  {"si8",  "i8"},  {"ui8",  "i8"},
    {"si16", "i16"}, {"ui16", "i16"}, {"si32", "i32"}, {"ui32", "i32"},
    {"sl",   ""},    {"ul",   ""},    {"sll",  "i64"}, {"ull",  "i64"},
    {"f32",  "f32"}, {"f64",  "f64"},
};

// Mid-struct typedef name → suffix. The 14 names come straight from
// include/cq_mid.h; identified-struct comparison is what the rewriter
// + Clang emit, so a literal/anonymous struct never matches
// (intentional).
struct MidRow {
  StringRef Name;
  StringRef Sfx;
};

constexpr MidRow kMidRows[] = {
    {"qbool_mid_t",      "i1"},   {"qchar_mid_t",      "c"},
    {"qschar_mid_t",     "si8"},  {"quchar_mid_t",     "ui8"},
    {"qshort_mid_t",     "si16"}, {"qushort_mid_t",    "ui16"},
    {"qint_mid_t",       "si32"}, {"quint_mid_t",      "ui32"},
    {"qlong_mid_t",      "sl"},   {"qulong_mid_t",     "ul"},
    {"qlonglong_mid_t",  "sll"},  {"qulonglong_mid_t", "ull"},
    {"qfloat_mid_t",     "f32"},  {"qdouble_mid_t",    "f64"},
};

// ABI-width string → LLVM Type. The 7 supported widths cover the entire
// surface; any other string returns nullptr and the caller is
// expected to bail with a FunctionCallee(). Used by llvmTypeFor() and
// by the three lazy-decl resolvers (allocFn, measureRtFn, addTemplate).
Type *typeForAbiWidth(StringRef W, LLVMContext &Ctx) {
  if (W == "i1")  return Type::getInt1Ty(Ctx);
  if (W == "i8")  return Type::getInt8Ty(Ctx);
  if (W == "i16") return Type::getInt16Ty(Ctx);
  if (W == "i32") return Type::getInt32Ty(Ctx);
  if (W == "i64") return Type::getInt64Ty(Ctx);
  if (W == "f32") return Type::getFloatTy(Ctx);
  if (W == "f64") return Type::getDoubleTy(Ctx);
  return nullptr;
}

}  // namespace

WidthDispatch::WidthDispatch(Module &mod) : M(mod) {
  // Long is target-dependent. Approximate `long` width with the pointer
  // size: LP64 (Linux/macOS 64-bit) → i64; ILP32 / LLP64 (Win64) → i32.
  // PRD §Width unification line 149 mandates this be derived from the
  // DataLayout. Pointer size is the cheapest reliable proxy and matches
  // how the rewriter's TypeMap resolves `long` via TargetInfo.
  LongAbiWidth =
      mod.getDataLayout().getPointerSizeInBits() == 64 ? "i64" : "i32";
}

ArrayRef<StringRef> WidthDispatch::allSuffixes() const {
  // Static StringRef array built once from the kRows table. The
  // backing string literals have static storage; StringRef wraps them
  // without copying.
  static const StringRef Names[] = {
      kRows[0].Sfx,  kRows[1].Sfx,  kRows[2].Sfx,  kRows[3].Sfx,
      kRows[4].Sfx,  kRows[5].Sfx,  kRows[6].Sfx,  kRows[7].Sfx,
      kRows[8].Sfx,  kRows[9].Sfx,  kRows[10].Sfx, kRows[11].Sfx,
      kRows[12].Sfx, kRows[13].Sfx,
  };
  return Names;
}

StringRef WidthDispatch::abiWidthFor(StringRef sfx) const {
  for (const SuffixRow &R : kRows) {
    if (R.Sfx != sfx)
      continue;
    // Empty AbiWidth marks target-dependent rows (sl, ul): resolve
    // against the construction-time pointer width.
    return R.AbiWidth.empty() ? LongAbiWidth : R.AbiWidth;
  }
  return {};
}

Type *WidthDispatch::llvmTypeFor(StringRef sfx, LLVMContext &ctx) const {
  StringRef W = abiWidthFor(sfx);
  return W.empty() ? nullptr : typeForAbiWidth(W, ctx);
}

Function *WidthDispatch::initFn(StringRef sfx) const {
  return M.getFunction(("cq_init_" + sfx).str());
}

Function *WidthDispatch::measureFn(StringRef sfx) const {
  return M.getFunction(("cq_measure_" + sfx).str());
}

FunctionCallee WidthDispatch::allocFn(StringRef abiWidth) const {
  // Signature: takes a value of the ABI-width type, returns i32 handle.
  // Mirrors cqrt_alloc_<W> in runtime/cq_runtime.h.
  LLVMContext &Ctx = M.getContext();
  Type *ArgTy = typeForAbiWidth(abiWidth, Ctx);
  if (!ArgTy)
    return FunctionCallee();
  return M.getOrInsertFunction(
      ("cqrt_alloc_" + abiWidth).str(),
      FunctionType::get(Type::getInt32Ty(Ctx), {ArgTy}, false));
}

FunctionCallee WidthDispatch::measureRtFn(StringRef abiWidth) const {
  // Signature: takes an i32 handle, returns a value of the ABI-width
  // type. Mirrors cqrt_measure_<W> in runtime/cq_runtime.h.
  LLVMContext &Ctx = M.getContext();
  Type *Ret = typeForAbiWidth(abiWidth, Ctx);
  if (!Ret)
    return FunctionCallee();
  return M.getOrInsertFunction(
      ("cqrt_measure_" + abiWidth).str(),
      FunctionType::get(Ret, {Type::getInt32Ty(Ctx)}, false));
}

FunctionCallee WidthDispatch::addTemplate(StringRef abiWidth,
                                          bool isQQ) const {
  // Q+Q (`cq_template_(add|fadd)_<W>`) and Q+C (`..._hl`) are distinct C
  // symbols (C lacks overloading). Q+Q: (handle, handle) → handle.
  // Q+C: (handle, classical-of-width-W) → handle. Both return i32
  // handle; the rhs type is what distinguishes them at the call site.
  // Matches cq_templates.h declarations exactly. The int and float
  // opcode roots are split to follow LLVM IR convention: integer
  // widths land on `cq_template_add_i*`, float widths on
  // `cq_template_fadd_f*`. The opcode root is selected by the abiWidth
  // prefix ('f' → fadd, otherwise → add).
  LLVMContext &Ctx = M.getContext();
  Type *ClassicalTy = typeForAbiWidth(abiWidth, Ctx);
  if (!ClassicalTy)
    return FunctionCallee();
  Type *Handle = Type::getInt32Ty(Ctx);
  StringRef OpcodeRoot = abiWidth.starts_with("f") ? "fadd_" : "add_";
  std::string Name = ("cq_template_" + OpcodeRoot + abiWidth).str();
  if (!isQQ)
    Name += "_hl";
  Type *RhsTy = isQQ ? Handle : ClassicalTy;
  return M.getOrInsertFunction(
      Name, FunctionType::get(Handle, {Handle, RhsTy}, false));
}

std::optional<StringRef>
WidthDispatch::midStructToSuffix(StructType *ST) const {
  if (!ST || !ST->hasName())
    return std::nullopt;
  // LLVM may version-suffix identified structs (e.g. `qint_mid_t.0`)
  // when a TU links against another that already declared the type.
  // Strip everything past the first '.' for robust matching.
  StringRef N = ST->getName();
  size_t Dot = N.find('.');
  if (Dot != StringRef::npos)
    N = N.substr(0, Dot);
  for (const MidRow &R : kMidRows)
    if (R.Name == N)
      return R.Sfx;
  return std::nullopt;
}

ArrayRef<StringRef> WidthDispatch::frontEndIntrinsicNames() const {
  // 28 entries: cq_init_<sfx> then cq_measure_<sfx> for all 14 suffixes
  // in canonical order. Used by CQLoweringPass's end-of-pass dead-decl
  // sweep; decl-only entries (use_empty()) get erased so a passthrough-
  // quantum-touch module leaves no front-end intrinsic decls behind.
  static const StringRef Names[] = {
      "cq_init_i1",      "cq_init_c",       "cq_init_si8",
      "cq_init_ui8",     "cq_init_si16",    "cq_init_ui16",
      "cq_init_si32",    "cq_init_ui32",    "cq_init_sl",
      "cq_init_ul",      "cq_init_sll",     "cq_init_ull",
      "cq_init_f32",     "cq_init_f64",
      "cq_measure_i1",   "cq_measure_c",    "cq_measure_si8",
      "cq_measure_ui8",  "cq_measure_si16", "cq_measure_ui16",
      "cq_measure_si32", "cq_measure_ui32", "cq_measure_sl",
      "cq_measure_ul",   "cq_measure_sll",  "cq_measure_ull",
      "cq_measure_f32",  "cq_measure_f64",
  };
  return Names;
}

}  // namespace cq
