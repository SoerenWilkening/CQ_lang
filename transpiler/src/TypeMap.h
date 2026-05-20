// TypeMap: maps a C builtin type to its `num_bits` per the PRD bit-width
// table. Pure logic — no dependency on a live CompilerInstance — so it
// can be unit-tested in isolation.
#pragma once

#include <clang/AST/Type.h>

namespace qct {

// Returns num_bits for the PRD bit-width table; 0 if the kind is
// unsupported in v1 (e.g. floats, wide-char variants, void, etc.).
unsigned numBitsForBuiltin(clang::BuiltinType::Kind k);

// Convenience: peels typedefs/qualifiers off `qt`, then dispatches to
// numBitsForBuiltin. Returns 0 if the underlying type isn't a
// BuiltinType.
unsigned numBitsForType(clang::QualType qt);

}  // namespace qct
