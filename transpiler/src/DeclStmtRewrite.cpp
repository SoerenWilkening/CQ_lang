#include "DeclStmtRewrite.h"

#include "BinopMatcher.h"
#include "Codegen.h"
#include "OperandClass.h"
#include "QuantumAttr.h"
#include "SourceText.h"
#include "TypeMap.h"
#include "UnaryMatcher.h"

#include <string>
#include <vector>

#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/DeclGroup.h>
#include <clang/AST/Expr.h>
#include <clang/AST/ExprCXX.h>
#include <clang/AST/OperationKinds.h>
#include <clang/AST/Stmt.h>
#include <clang/AST/Type.h>
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

// If `init` (already paren/cast-stripped) is a DeclRefExpr to a quantum
// VarDecl whose canonical type matches `targetType`'s canonical type,
// return that VarDecl; otherwise nullptr. This is the Pattern 6 gate:
// `quantum T b = a;` where `a` is a `quantum T` of the same canonical
// type (PRD §"Rewriter patterns" row 6). Cross-type assignments —
// `quantum int b = q_long;` etc. — fall through to ClassicalInit, where
// they'll splice the implicit-conversion's source text into a
// cq_init_<sfx>() call (a documented soft-failure mode; see PRD
// §"Diagnostics baseline").
const clang::VarDecl *patternSixSource(const clang::Expr *init,
                                       clang::QualType targetType) {
    const auto *dre = clang::dyn_cast_or_null<clang::DeclRefExpr>(init);
    if (dre == nullptr) {
        return nullptr;
    }
    const auto *vd = clang::dyn_cast<clang::VarDecl>(dre->getDecl());
    if (vd == nullptr || !hasQuantumAttr(vd)) {
        return nullptr;
    }
    // Same-canonical-type check. `getCanonicalType()` peels typedefs +
    // cv-qualifiers, so `quantum int b = a;` matches Pattern 6 even
    // when `a` was declared `quantum int8_t` and `b` as plain
    // `quantum signed char` — both canonicalise to the same builtin.
    // Different-width assignments (`quantum int b = q_long;`) don't
    // match and route to ClassicalInit.
    if (vd->getType().getCanonicalType() != targetType.getCanonicalType()) {
        return nullptr;
    }
    return vd;
}

// Populate `out` (assumed pre-filled with name + widthSuffix) by
// analyzing the VarDecl's initializer. `sm` and `lo` are needed only
// for the getExprText fallback paths. Under taint propagation the
// QQ/QC/CQ distinction collapses (PLAN §4.4.2 / architecture §5.2): any
// add with at least one quantum operand is a single QuantumAdd form;
// the quantum operand is decorated with ".val" here so Codegen can stay
// Clang-free.
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

    // The initializer we care about may be wrapped in implicit casts /
    // parens — `quantum int x = a + 5;` where `+` returns int and
    // there's no extra cast usually has no wrapper, but `quantum int b
    // = a;` where `a` is itself a quantum-typed value typically does
    // (LValueToRValue). Strip those layers before pattern dispatch.
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

    // Pattern 6 (M9): `quantum T b = a;` where `a` is a quantum VarDecl
    // of the same canonical type. Tried before the binop dispatch so a
    // bare DeclRefExpr doesn't fall through to ClassicalInit's
    // verbatim-splice path. If the canonical types don't match, this
    // returns null and we proceed to the binop/classical dispatch
    // below — letting cross-type cases route through ClassicalInit (a
    // documented soft-failure mode for Phase 2; see PRD
    // §"Diagnostics baseline").
    if (const clang::VarDecl *src =
            patternSixSource(probe, vd->getType())) {
        out->form = VarRewriteInput::Form::QuantumCopy;
        out->sourceName = src->getNameAsString();
        return;
    }

    // Pattern 9 declaration-init (M8 round 2): `quantum T b = -a;` (or
    // ~a, !a, ++a, a++, --a, a--) on a quantum operand. PLAN §4.8
    // acceptance lists the shapes; PLAN §6.4 fixes the prefix/postfix
    // ordering. UnaryMatcher gates on the seven Phase 3 unary opcodes
    // plus a Quantum operand classification (paren/cast wrappers
    // already peeled). Codegen pairs the result with the declaration
    // prefix via the QuantumUnaryInit form.
    if (const auto *uo = clang::dyn_cast<clang::UnaryOperator>(probe)) {
        UnaryMatch um = matchUnary(uo);
        if (um.matched) {
            std::string opnd = quantumOperandName(um.operand.expr);
            if (!opnd.empty()) {
                out->form = VarRewriteInput::Form::QuantumUnaryInit;
                out->sourceName = std::move(opnd);
                out->unaryOpcode = um.opcode;
                return;
            }
            // Operand wasn't a DeclRef though UnaryMatch said Quantum
            // — defensive; drop to ClassicalInit fallback below.
        }
    }

    // Delegate the binop recognition to BinopMatcher (Phase 3 M7
    // split): the matcher is opcode-aware and reports the operand
    // classification through OperandInfo. We still gate on BO_Add
    // here because Phase 2 only emits one arithmetic opcode through
    // the rewriter; Phase 3 M11 widens the IR-pass dispatch but the
    // rewriter remains add-only until M8 wires the rest. Any
    // non-quantum binop (including non-Add quantum binops, which
    // don't exist yet) falls through to ClassicalInit, which splices
    // the user's original source text verbatim — preserving the
    // Phase 2 contract byte-exact.
    BinopMatch bm = matchBinop(probe);
    if (!bm.matched || bm.opcode != clang::BO_Add) {
        fallbackClassical();
        return;
    }

    OperandInfo lhs = bm.lhs;
    OperandInfo rhs = bm.rhs;
    const bool lhsQ = (lhs.kind == OperandKind::Quantum);
    const bool rhsQ = (rhs.kind == OperandKind::Quantum);

    // At least one side is quantum: emit QuantumAdd. Each side is
    // decorated here — quantum operands become "<name>.val", classical
    // operands keep their raw source text — and Codegen splices both
    // verbatim. If we cannot recover a quantum operand's VarDecl name
    // (defensive — shouldn't happen for v1 inputs), fall back to the
    // classical splice so we still produce parseable C.
    auto decorateQuantum = [](const std::string &name) {
        return name + ".val";
    };

    std::string lhsExpr;
    if (lhsQ) {
        std::string n = quantumOperandName(lhs.expr);
        if (n.empty()) {
            fallbackClassical();
            return;
        }
        lhsExpr = decorateQuantum(n);
    } else {
        lhsExpr = getExprText(lhs.expr, sm, lo);
    }

    std::string rhsExpr;
    if (rhsQ) {
        std::string n = quantumOperandName(rhs.expr);
        if (n.empty()) {
            fallbackClassical();
            return;
        }
        rhsExpr = decorateQuantum(n);
    } else {
        rhsExpr = getExprText(rhs.expr, sm, lo);
    }

    out->form = VarRewriteInput::Form::QuantumAdd;
    out->lhsExpr = std::move(lhsExpr);
    out->rhsExpr = std::move(rhsExpr);
}

}  // namespace

std::optional<StmtRewrite> buildRewrite(const clang::DeclStmt *ds,
                                        const clang::ASTContext &ctx) {
    if (ds == nullptr) {
        return std::nullopt;
    }
    const clang::SourceManager &sm = ctx.getSourceManager();
    const clang::LangOptions &lo = ctx.getLangOpts();
    // ctx.getTargetInfo() was needed only for the Phase-1 v1 `irWidthSuffix`
    // splice; M9 routes through `intrinsicSuffix` which is target-stable
    // for all 14 PRD types, so the TargetInfo handle is no longer used.

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
        // Phase 2 M9: keyword recognition runs entirely through
        // TypeMap. `intrinsicSuffix` returns "" for any type that
        // isn't one of the 14 PRD §"Type map" entries (long double,
        // wide chars, void, pointers, ...), and we treat that as
        // "skip — Phase 2 doesn't support this type". Typedef'd
        // integers from <stdint.h> fall out for free because
        // TypeMap peels typedefs via `getCanonicalType()` before
        // matching, so `quantum int8_t` routes to the same entry
        // as `quantum signed char`.
        llvm::StringRef sfx = intrinsicSuffix(vd->getType());
        if (sfx.empty()) {
            continue;
        }
        VarRewriteInput in{};
        in.name = vd->getNameAsString();
        in.widthSuffix = sfx.str();
        in.midStructName = midStructName(vd->getType()).str();
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
