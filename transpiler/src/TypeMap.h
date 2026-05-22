// TypeMap: maps a C builtin type to the LLVM-intrinsic width suffix
// (e.g. "i32") used by the Phase 1 emission path. The mapping is
// target-aware — widths come from `clang::TargetInfo`, not hard-coded
// per-kind constants — so a single `int` may legitimately resolve to
// `"i16"`, `"i32"`, or anything else the target reports. Pure logic
// (apart from the Clang AST / TargetInfo handles passed in), so it can
// be unit-tested in isolation against an in-process AST.
//
// See phases/phase1/PLAN.md §4.4.1 for the API contract and §6.6 for
// the width-family rationale (Phase 1 only ever emits `i32` against
// the test target, but the function is correct for the whole C int
// family so Phase 2 has no carry-forward debt).
#pragma once
#include <string>

#include <clang/AST/Type.h>

namespace clang {
class TargetInfo;
}  // namespace clang

namespace qct {

// Returns the LLVM intrinsic-name width suffix for `qt` against `ti`:
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
//   - long / unsigned long           -> "i" + ti.getLongWidth()
//   - long long / unsigned long long -> "i" + ti.getLongLongWidth()
//   - everything else (float, double, wide-char variants, void, …)
//                                    -> "" (unsupported in Phase 1)
//
// The function peels typedefs and qualifiers before classifying, so
// `typedef int my_int;` and `const int` both behave like plain `int`.
// Returns the empty string on a null QualType as a defensive default.
std::string irWidthSuffix(clang::QualType qt, const clang::TargetInfo &ti);

// ---------------------------------------------------------------------------
// v1 legacy shims — kept compiling until the Codegen / DeclStmtRewrite
// rewrites (issues -mit, -ldk) land. PLAN §4.4.1 ultimately removes
// these; today they're thin wrappers over hard-coded PRD bit-counts so
// downstream tests and the (still-v1) emission path don't break in
// this issue's commit. Do NOT take new callers — use `irWidthSuffix`.
unsigned numBitsForBuiltin(clang::BuiltinType::Kind k);
unsigned numBitsForType(clang::QualType qt);

}  // namespace qct
