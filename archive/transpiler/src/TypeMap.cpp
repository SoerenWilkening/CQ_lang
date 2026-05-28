#include "TypeMap.h"

#include <string>

#include <clang/Basic/TargetInfo.h>
#include <llvm/ADT/StringRef.h>

namespace qct {

namespace {

// Compose the intrinsic-name suffix from a bit width. Returns "" if
// the width is zero (TargetInfo should never report that for a real
// builtin, but stay defensive).
std::string suffixFromWidth(unsigned w) {
    if (w == 0) {
        return std::string();
    }
    return "i" + std::to_string(w);
}

// Resolve `qt` to its canonical BuiltinType, peeling typedefs and
// cv-qualifiers. Returns nullptr if `qt` is null or doesn't bottom out
// in a builtin (e.g. pointer, record, function type).
const clang::BuiltinType *asBuiltin(clang::QualType qt) {
    if (qt.isNull()) {
        return nullptr;
    }
    const clang::Type *t = qt.getCanonicalType().getTypePtrOrNull();
    if (t == nullptr) {
        return nullptr;
    }
    return t->getAs<clang::BuiltinType>();
}

}  // namespace

std::string irWidthSuffix(clang::QualType qt, const clang::TargetInfo &ti) {
    const clang::BuiltinType *bt = asBuiltin(qt);
    if (bt == nullptr) {
        return std::string();
    }
    using K = clang::BuiltinType;
    switch (bt->getKind()) {
    case K::Bool:
        // `_Bool`'s LLVM IR value type is always `i1`, even though its
        // ABI storage width on most targets (incl. x86_64-linux-gnu) is
        // 8. PLAN §4.4.1 pins the intrinsic suffix to `"i1"`, so we
        // hard-code it here rather than threading ti.getBoolWidth() —
        // that API reports storage width, not the IR value-type width
        // Clang would emit for a Bool rvalue.
        return "i1";
    case K::Char_S:
    case K::Char_U:
    case K::SChar:
    case K::UChar:
        return suffixFromWidth(ti.getCharWidth());
    case K::Short:
    case K::UShort:
        return suffixFromWidth(ti.getShortWidth());
    case K::Int:
    case K::UInt:
        return suffixFromWidth(ti.getIntWidth());
    case K::Long:
    case K::ULong:
        // Target-dependent: 64 on LP64 (x86_64-linux-gnu, aarch64-darwin),
        // 32 on LLP64 (Windows) and 32-bit targets. See PRD §"Target-
        // dependence of `long`".
        return suffixFromWidth(ti.getLongWidth());
    case K::LongLong:
    case K::ULongLong:
        return suffixFromWidth(ti.getLongLongWidth());
    case K::Float:
        // f32 / f64 width tags mirror IEEE 754 binary32 / binary64. The
        // IR pass uses these to route `fadd`/`fmul`/etc. to per-width
        // templates; signedness doesn't apply. `long double` is out of
        // Phase 2 scope (often 80-bit x87 on x86_64; no template).
        return "f32";
    case K::Double:
        return "f64";
    default:
        // LongDouble, wide-char variants (Char8/16/32, WChar_S/U), void,
        // Int128 / UInt128, fixed-point Accum/Fract, and dependent /
        // placeholder types all fall through to "unsupported in Phase 2".
        // Callers route the empty string into a diagnostic rather than
        // ever silently picking the wrong intrinsic width.
        return std::string();
    }
}

llvm::StringRef intrinsicSuffix(clang::QualType qt) {
    const clang::BuiltinType *bt = asBuiltin(qt);
    if (bt == nullptr) {
        return llvm::StringRef();
    }
    using K = clang::BuiltinType;
    switch (bt->getKind()) {
    // PRD §"Type map" verbatim. `char` is distinct from `signed char` /
    // `unsigned char` even when the target's plain-`char` representation
    // matches one of them — Clang reports this via the Char_S vs SChar /
    // Char_U vs UChar split, and we honor C's type-distinctness rule.
    case K::Bool:
        return "i1";
    case K::Char_S:
    case K::Char_U:
        return "c";
    case K::SChar:
        return "si8";
    case K::UChar:
        return "ui8";
    case K::Short:
        return "si16";
    case K::UShort:
        return "ui16";
    case K::Int:
        return "si32";
    case K::UInt:
        return "ui32";
    case K::Long:
        // Suffix is platform-stable (`sl` everywhere); only the width
        // form (`i64` on LP64 vs `i32` on LLP64) varies per target. See
        // PRD §"Target-dependence of `long`".
        return "sl";
    case K::ULong:
        return "ul";
    case K::LongLong:
        return "sll";
    case K::ULongLong:
        return "ull";
    case K::Float:
        return "f32";
    case K::Double:
        return "f64";
    default:
        return llvm::StringRef();
    }
}

llvm::StringRef midStructName(clang::QualType qt) {
    const clang::BuiltinType *bt = asBuiltin(qt);
    if (bt == nullptr) {
        return llvm::StringRef();
    }
    using K = clang::BuiltinType;
    switch (bt->getKind()) {
    // PRD §"Type map" mid-struct column. The 14 typedefs are declared in
    // include/cq_mid.h (cq-p2-m02); names below must match that header
    // verbatim or downstream rewrites emit unresolved typedef references.
    case K::Bool:
        return "qbool_mid_t";
    case K::Char_S:
    case K::Char_U:
        return "qchar_mid_t";
    case K::SChar:
        return "qschar_mid_t";
    case K::UChar:
        return "quchar_mid_t";
    case K::Short:
        return "qshort_mid_t";
    case K::UShort:
        return "qushort_mid_t";
    case K::Int:
        return "qint_mid_t";
    case K::UInt:
        return "quint_mid_t";
    case K::Long:
        return "qlong_mid_t";
    case K::ULong:
        return "qulong_mid_t";
    case K::LongLong:
        return "qlonglong_mid_t";
    case K::ULongLong:
        return "qulonglong_mid_t";
    case K::Float:
        return "qfloat_mid_t";
    case K::Double:
        return "qdouble_mid_t";
    default:
        return llvm::StringRef();
    }
}

// ---------------------------------------------------------------------------
// v1 legacy shims. The PRD bit-count table is hardcoded here verbatim
// (Bool=1, char=8, short/int=16, long=32, long long=64). These exist
// only so the still-v1 callers in DeclStmtRewrite/Codegen keep
// compiling until Phase 2 M9/M10/M11 migrate them onto the new
// suffix-driven accessors. See header for the deprecation note.
unsigned numBitsForBuiltin(clang::BuiltinType::Kind k) {
    using K = clang::BuiltinType;
    switch (k) {
    case K::Bool:
        return 1;
    case K::Char_S:
    case K::Char_U:
    case K::SChar:
    case K::UChar:
        return 8;
    case K::Short:
    case K::UShort:
    case K::Int:
    case K::UInt:
        return 16;
    case K::Long:
    case K::ULong:
        return 32;
    case K::LongLong:
    case K::ULongLong:
        return 64;
    default:
        return 0;
    }
}

unsigned numBitsForType(clang::QualType qt) {
    if (const auto *bt = asBuiltin(qt)) {
        return numBitsForBuiltin(bt->getKind());
    }
    return 0;
}

}  // namespace qct
