#include "TypeMap.h"

#include <string>

#include <clang/Basic/TargetInfo.h>

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

}  // namespace

std::string irWidthSuffix(clang::QualType qt, const clang::TargetInfo &ti) {
    if (qt.isNull()) {
        return std::string();
    }
    // Peel typedefs / cv-qualifiers so e.g. `typedef int my_int;` and
    // `const int` route to the same builtin classification as plain
    // `int`.
    const clang::Type *t = qt.getCanonicalType().getTypePtrOrNull();
    if (t == nullptr) {
        return std::string();
    }
    const auto *bt = t->getAs<clang::BuiltinType>();
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
        return suffixFromWidth(ti.getLongWidth());
    case K::LongLong:
    case K::ULongLong:
        return suffixFromWidth(ti.getLongLongWidth());
    default:
        // Float, Double, LongDouble, wide-char variants, void, and
        // anything else fall through to "unsupported in Phase 1".
        // Callers route the empty string into a diagnostic rather than
        // ever silently picking the wrong intrinsic width.
        return std::string();
    }
}

// ---------------------------------------------------------------------------
// v1 legacy shims. The PRD bit-count table is hardcoded here verbatim
// (Bool=1, char=8, short/int=16, long=32, long long=64). These exist
// only so the still-v1 callers in DeclStmtRewrite/Codegen keep
// compiling until issues -mit and -ldk migrate them onto
// `irWidthSuffix`. See header for the deprecation note.
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
    if (qt.isNull()) {
        return 0;
    }
    const clang::Type *t = qt.getCanonicalType().getTypePtrOrNull();
    if (t == nullptr) {
        return 0;
    }
    if (const auto *bt = t->getAs<clang::BuiltinType>()) {
        return numBitsForBuiltin(bt->getKind());
    }
    return 0;
}

}  // namespace qct
