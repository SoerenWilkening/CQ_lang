// CastRewrite: bridges the Clang AST to the rewriter's measurement-cast
// emission. Given a `CStyleCastExpr` whose subexpression refers (after
// paren/implicit-cast peeling) to a quantum-annotated VarDecl, this
// module:
//   - confirms the cast's operand is a quantum DeclRefExpr,
//   - extracts the bare DeclRefExpr's source text via SourceText,
//   - builds the replacement `cq_measure_i32(<argText>)`,
//   - returns the SourceRange of the original CStyleCastExpr so the
//     caller substitutes only the cast (the surrounding expression
//     context, e.g. `+ 1`, is left untouched).
//
// Per PLAN §4.4.4 + the issue's explicit note, ALL target widths use
// the same `cq_measure_i32` intrinsic — width truncation for narrower
// casts (e.g. `(short) q`) is done by the surrounding C classically.
// Phase 2 will introduce per-width siblings; Phase 1 hardcodes i32.
//
// Returns std::nullopt when the cast's operand (after peeling) is not
// a DeclRefExpr to a quantum-annotated VarDecl — classical casts are
// left alone.
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
