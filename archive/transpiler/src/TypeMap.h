// TypeMap: maps a C builtin type to the Phase 2 quantum-typed surface.
// Three accessors expose different slices of the per-type record:
//
//   - `irWidthSuffix`     -> width-only, e.g. "i32". Width comes from
//                            `clang::TargetInfo`, not hard-coded per
//                            kind. This is the form the IR pass uses;
//                            signedness is irrelevant past Stage 3
//                            (Clang has already baked it into the
//                            opcode — `sdiv` vs `udiv`, `sext` vs
//                            `zext`, etc.). See PRD §"IR pass changes —
//                            Width inference".
//   - `intrinsicSuffix`   -> signedness-bearing, e.g. "si32", "ui8",
//                            "sl", "f64". The rewriter uses this to
//                            build the `cq_init_<sfx>` / `cq_measure_<sfx>`
//                            symbol names per PRD §"Type map". `long`'s
//                            suffix (`sl`) is platform-stable; only the
//                            width form forks per target.
//   - `midStructName`     -> the C-source mid-struct typedef, e.g.
//                            "qint_mid_t", "qfloat_mid_t". The rewriter
//                            uses this to rewrite the C declarator
//                            (Pattern 1 / Pattern 6 in PRD §"Rewriter
//                            patterns").
//
// All three functions peel typedefs + cv-qualifiers via
// `getCanonicalType()` before classifying, so `<stdint.h>` typedefs
// (`int8_t`, `uint64_t`, …) and `const`-qualified types route to the
// same underlying entry as the plain C builtin.
//
// Pure logic apart from the Clang AST / TargetInfo handles passed in,
// so it can be unit-tested in isolation against an in-process AST. See
// phases/phase2/PLAN.md §4.8 for the API contract.
#pragma once
#include <string>

#include <clang/AST/Type.h>
#include <llvm/ADT/StringRef.h>

namespace clang {
class TargetInfo;
}  // namespace clang

namespace qct {

// Returns the LLVM-intrinsic width suffix for `qt` against `ti`:
//   - `_Bool`                        -> "i1"  (LLVM IR value-type width
//                                              for Bool is always 1, not
//                                              ti.getBoolWidth() which
//                                              reports ABI storage)
//   - char family (Char_S/U, SChar, UChar)
//                                    -> "i" + ti.getCharWidth() (8 on
//                                              all currently-supported
//                                              targets)
//   - short / unsigned short         -> "i" + ti.getShortWidth()
//   - int / unsigned int             -> "i" + ti.getIntWidth()
//   - long / unsigned long           -> "i" + ti.getLongWidth() (target-
//                                              dependent: 64 on
//                                              x86_64-linux-gnu, 32 on
//                                              Windows / 32-bit targets)
//   - long long / unsigned long long -> "i" + ti.getLongLongWidth()
//   - float                          -> "f32"
//   - double                         -> "f64"
//   - everything else (long double, wide-char variants, void, …)
//                                    -> "" (out of Phase 2 scope)
std::string irWidthSuffix(clang::QualType qt, const clang::TargetInfo &ti);

// Returns the signedness-bearing intrinsic suffix for `qt` per the PRD
// §"Type map" table. Values are stable C-string literals; the returned
// `StringRef` is valid for the program lifetime. Unsupported types
// (long double, wide chars, void, pointers, …) return an empty
// `StringRef`. A null `QualType` also returns empty.
//
// Mapping (PRD §"Type map", 14 entries):
//   `_Bool` / `bool`     -> "i1"
//   `char`               -> "c"
//   `signed char`        -> "si8"
//   `unsigned char`      -> "ui8"
//   `short`              -> "si16"
//   `unsigned short`     -> "ui16"
//   `int`                -> "si32"
//   `unsigned int`       -> "ui32"
//   `long`               -> "sl"
//   `unsigned long`      -> "ul"
//   `long long`          -> "sll"
//   `unsigned long long` -> "ull"
//   `float`              -> "f32"
//   `double`             -> "f64"
llvm::StringRef intrinsicSuffix(clang::QualType qt);

// Returns the mid-struct typedef name for `qt` per the PRD §"Type map"
// table (e.g. `int` -> "qint_mid_t", `float` -> "qfloat_mid_t"). Values
// are stable C-string literals. Same null / unsupported behavior as
// `intrinsicSuffix`.
llvm::StringRef midStructName(clang::QualType qt);

// ---------------------------------------------------------------------------
// v1 legacy shims — kept compiling until the Codegen / DeclStmtRewrite
// rewrites (Phase 2 M9/M10/M11) land. PLAN §4.4.1 ultimately removes
// these; today they're thin wrappers over hard-coded PRD bit-counts so
// downstream tests and the (still-v1) emission path don't break in
// this issue's commit. Do NOT take new callers — use `irWidthSuffix`.
unsigned numBitsForBuiltin(clang::BuiltinType::Kind k);
unsigned numBitsForType(clang::QualType qt);

}  // namespace qct
