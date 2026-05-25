// CastRewrite: bridges the Clang AST to the rewriter's measurement-cast
// emission. Given a `CStyleCastExpr` whose subexpression refers (after
// paren/implicit-cast peeling) to a quantum-annotated VarDecl, this
// module:
//   - confirms the cast's operand is a quantum DeclRefExpr,
//   - extracts the bare DeclRefExpr's source text via SourceText,
//   - resolves the cast's target type to its intrinsic suffix via
//     `TypeMap::intrinsicSuffix(T)` (PRD §"Type map" — `si32`, `ui8`,
//     `sl`, `f64`, …),
//   - builds the replacement `cq_measure_<sfx>(<argText>)`,
//   - returns the SourceRange of the original CStyleCastExpr so the
//     caller substitutes only the cast (the surrounding expression
//     context, e.g. `+ 1`, is left untouched).
//
// Per PRD §"Rewriter patterns" pattern #5, `(T) q` (q quantum T) lowers
// to `cq_measure_<sfx>(q)`. The cast's target-type QualType picks the
// intrinsic — typedefs and cv-qualifiers peel through `getCanonicalType()`
// inside `TypeMap`, so `(int32_t) q` and `(int) q` route to the same
// `_si32` emission.
//
// Returns std::nullopt when the cast's operand (after peeling) is not
// a DeclRefExpr to a quantum-annotated VarDecl (classical casts are
// left alone), the operand text can't be recovered, or the target type
// is out of Phase 2 scope (long double, wide chars, pointers, …) and
// has no intrinsic suffix.
#pragma once

#include <optional>
#include <string>

#include <clang/Basic/SourceLocation.h>

namespace clang {
class ASTContext;
class CStyleCastExpr;
}  // namespace clang

namespace qct {

struct CastRewrite {
    // The token range covering the whole CStyleCastExpr (i.e. the
    // `(int)q` text including the parenthesised type). Callers apply
    // this with Rewriter::ReplaceText via
    // CharSourceRange::getTokenRange so the trailing token of the
    // subexpression is included in full.
    clang::SourceRange range;
    std::string replacement;
};

// Inspect `ce` and build a replacement for a measurement-cast pattern.
// Returns std::nullopt if `ce` is null, has no subexpression, or the
// subexpression (after stripping ParenExpr / ImplicitCastExpr layers)
// is not a DeclRefExpr to a quantum-annotated VarDecl.
std::optional<CastRewrite> buildCastRewrite(const clang::CStyleCastExpr *ce,
                                            const clang::ASTContext &ctx);

}  // namespace qct
