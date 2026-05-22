#include "CastRewrite.h"

#include "QuantumAttr.h"
#include "SourceText.h"

#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/Expr.h>
#include <clang/Basic/LangOptions.h>
#include <clang/Basic/SourceManager.h>

namespace qct {

std::optional<CastRewrite> buildCastRewrite(const clang::CStyleCastExpr *ce,
                                            const clang::ASTContext &ctx) {
    if (ce == nullptr) {
        return std::nullopt;
    }
    const clang::Expr *sub = ce->getSubExpr();
    if (sub == nullptr) {
        return std::nullopt;
    }

    // Peel ParenExpr / ImplicitCastExpr layers so the underlying
    // DeclRefExpr (if any) is visible, mirroring QuantumAttr's helper.
    // We deliberately use IgnoreParenImpCasts here rather than
    // IgnoreCasts: explicit casts under our explicit cast should not
    // be peeled — `(int)(short)q` is two distinct cast layers and
    // only the outermost one is the measurement we want to lower.
    const clang::Expr *probe = sub->IgnoreParenImpCasts();
    const auto *dre = clang::dyn_cast<clang::DeclRefExpr>(probe);
    if (dre == nullptr) {
        return std::nullopt;
    }
    const auto *vd = clang::dyn_cast<clang::VarDecl>(dre->getDecl());
    if (!hasQuantumAttr(vd)) {
        return std::nullopt;
    }

    // <argText> is the bare DeclRefExpr's source text — i.e. the
    // variable name, with any operand-side parens stripped per PLAN
    // §4.4.4 acceptance test ("(int)(q) -> cq_measure_i32(q)"). Using
    // the peeled `probe` rather than the raw `sub` produces exactly
    // that emission.
    const clang::SourceManager &sm = ctx.getSourceManager();
    const clang::LangOptions &lo = ctx.getLangOpts();
    std::string argText = getExprText(probe, sm, lo);
    if (argText.empty()) {
        // Defensive: if we somehow can't recover the operand text
        // (e.g. compiler-synthesized expression with no on-disk
        // location), don't emit a broken rewrite.
        return std::nullopt;
    }

    CastRewrite out;
    out.replacement = "cq_measure_i32(" + argText + ")";

    // Hand back the CStyleCastExpr's token range. The cast's begin
    // location is the opening `(` of the cast's type parenthesis and
    // its end location is the last token of the subexpression — so
    // the range covers exactly the `(int)q` text. Map both endpoints
    // through getExpansionLoc to keep the rewriter happy in case the
    // cast appears inside a macro expansion (matches DeclStmtRewrite's
    // treatment of macro-spanning ranges).
    clang::SourceRange sr = ce->getSourceRange();
    out.range = clang::SourceRange(sm.getExpansionLoc(sr.getBegin()),
                                   sm.getExpansionLoc(sr.getEnd()));
    return out;
}

}  // namespace qct
