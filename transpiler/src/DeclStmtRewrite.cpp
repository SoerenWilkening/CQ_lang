#include "DeclStmtRewrite.h"

#include "Codegen.h"
#include "OperandClass.h"
#include "QuantumAttr.h"
#include "SourceText.h"
#include "TypeMap.h"

#include <vector>

#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/DeclGroup.h>
#include <clang/AST/Expr.h>
#include <clang/AST/ExprCXX.h>
#include <clang/AST/OperationKinds.h>
#include <clang/AST/Stmt.h>
#include <clang/Basic/LangOptions.h>
#include <clang/Basic/SourceManager.h>

namespace qct {

namespace {

// Given an already-unwrapped Expr (Paren/ImplicitCast stripped — i.e.
// the .expr field of an OperandInfo with kind == Quantum), pull out the
// referenced VarDecl's name. Returns the empty string if `e` isn't a
// DeclRefExpr to a VarDecl (shouldn't happen given OperandClass's
// contract, but defending against it costs ~3 lines and lets us fall
// back to a ClassicalInit rather than crashing).
std::string quantumOperandName(const clang::Expr *e) {
    const auto *dre = clang::dyn_cast_or_null<clang::DeclRefExpr>(e);
    if (dre == nullptr) {
        return {};
    }
    const auto *vd = clang::dyn_cast<clang::VarDecl>(dre->getDecl());
    if (vd == nullptr) {
        return {};
    }
    return vd->getNameAsString();
}

// Populate `out` (assumed pre-filled with name + numBits) by analyzing
// the VarDecl's initializer. `sm` and `lo` are needed only for the
// getExprText fallback paths.
void populateFromInit(const clang::VarDecl *vd,
                      const clang::SourceManager &sm,
                      const clang::LangOptions &lo,
                      VarRewriteInput *out) {
    const clang::Expr *init = vd->getInit();
    if (init == nullptr) {
        out->form = VarRewriteInput::Form::Uninit;
        return;
    }

    // Default: any non-binop initializer is a ClassicalInit with the
    // user's original expression spliced verbatim.
    auto fallbackClassical = [&]() {
        out->form = VarRewriteInput::Form::ClassicalInit;
        out->initText = getExprText(init, sm, lo);
    };

    // The BinaryOperator we care about may be wrapped in implicit
    // casts (e.g. `quantum int x = a + 5;` where `+` returns int and
    // there's no extra cast — usually no wrapper, but defensively we
    // walk through paren/cast layers before dispatching).
    const clang::Expr *probe = init;
    for (;;) {
        if (const auto *pe = clang::dyn_cast<clang::ParenExpr>(probe)) {
            probe = pe->getSubExpr();
            continue;
        }
        if (const auto *ice = clang::dyn_cast<clang::ImplicitCastExpr>(probe)) {
            probe = ice->getSubExpr();
            continue;
        }
        break;
    }

    const auto *bo = clang::dyn_cast<clang::BinaryOperator>(probe);
    if (bo == nullptr || bo->getOpcode() != clang::BO_Add) {
        fallbackClassical();
        return;
    }

    OperandInfo lhs = classify(bo->getLHS());
    OperandInfo rhs = classify(bo->getRHS());
    const bool lhsQ = (lhs.kind == OperandKind::Quantum);
    const bool rhsQ = (rhs.kind == OperandKind::Quantum);

    if (lhsQ && rhsQ) {
        std::string lhsName = quantumOperandName(lhs.expr);
        std::string rhsName = quantumOperandName(rhs.expr);
        if (lhsName.empty() || rhsName.empty()) {
            // Defensive: should not happen for v1 inputs.
            fallbackClassical();
            return;
        }
        out->form = VarRewriteInput::Form::QuantumPlusQuantum;
        out->lhsName = std::move(lhsName);
        out->rhsName = std::move(rhsName);
        return;
    }
    if (lhsQ && !rhsQ) {
        std::string lhsName = quantumOperandName(lhs.expr);
        if (lhsName.empty()) {
            fallbackClassical();
            return;
        }
        out->form = VarRewriteInput::Form::QuantumPlusClassical;
        out->lhsName = std::move(lhsName);
        out->rhsText = getExprText(rhs.expr, sm, lo);
        return;
    }
    if (!lhsQ && rhsQ) {
        std::string rhsName = quantumOperandName(rhs.expr);
        if (rhsName.empty()) {
            fallbackClassical();
            return;
        }
        out->form = VarRewriteInput::Form::ClassicalPlusQuantum;
        out->lhsText = getExprText(lhs.expr, sm, lo);
        out->rhsName = std::move(rhsName);
        return;
    }
    // C + C: a "quantum int x = 1 + 2;" — both sides are classical, so
    // the whole binop is a classical expression. Splice the entire
    // binop verbatim into init_qint(...).
    fallbackClassical();
}

}  // namespace

std::optional<StmtRewrite> buildRewrite(const clang::DeclStmt *ds,
                                        const clang::ASTContext &ctx) {
    if (ds == nullptr) {
        return std::nullopt;
    }
    const clang::SourceManager &sm = ctx.getSourceManager();
    const clang::LangOptions &lo = ctx.getLangOpts();

    std::vector<VarRewriteInput> vars;
    vars.reserve(4);
    for (const clang::Decl *d : ds->decls()) {
        const auto *vd = clang::dyn_cast<clang::VarDecl>(d);
        if (vd == nullptr) {
            continue;
        }
        if (!hasQuantumAttr(vd)) {
            // Non-quantum VarDecl inside a matched DeclStmt would be
            // unusual (the matcher should only fire on DeclStmts that
            // contain at least one quantum VarDecl), but we still skip
            // it rather than rewriting a non-quantum decl by accident.
            continue;
        }
        VarRewriteInput in{};
        in.name = vd->getNameAsString();
        in.numBits = numBitsForType(vd->getType());
        populateFromInit(vd, sm, lo, &in);
        vars.push_back(std::move(in));
    }

    if (vars.empty()) {
        return std::nullopt;
    }

    StmtRewrite out;
    out.replacement = renderDeclStmt(vars);
    // Hand back the DeclStmt's token range — callers apply this with
    // Rewriter::ReplaceText(CharSourceRange::getTokenRange(range), ...),
    // which expands the end loc to cover the last token (the trailing
    // `;`) in full. This is the simplest reliable way to overwrite the
    // semicolon without manual offset arithmetic.
    //
    // The DeclStmt's begin location is inside the `quantum` macro
    // expansion (since `quantum` expands to `__attribute__((annotate
    // ("quantum")))`). Rewriter::ReplaceText refuses macro-ID
    // locations, so we map both endpoints to their expansion (i.e.
    // user-source) locations. The result is that the rewrite overwrites
    // the entire `quantum int x;` text in the user's file rather than
    // trying to reach inside the macro.
    clang::SourceRange sr = ds->getSourceRange();
    out.range = clang::SourceRange(sm.getExpansionLoc(sr.getBegin()),
                                   sm.getExpansionLoc(sr.getEnd()));
    return out;
}

}  // namespace qct
