#include "TypeMap.h"

namespace qct {

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
        // Float, Double, LongDouble, wide-char variants, and anything
        // else are unsupported in v1.
        return 0;
    }
}

unsigned numBitsForType(clang::QualType qt) {
    if (qt.isNull()) {
        return 0;
    }
    // Peel typedefs and qualifiers so e.g. `typedef int my_int;` and
    // `const int` map to the same kind as plain `int`.
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
