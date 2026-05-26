#include "AssignRewrite.h"

#include "AssignCodegen.h"
#include "AssignMatcher.h"
#include "OperandClass.h"
#include "QuantumAttr.h"
#include "SourceText.h"
#include "UnaryCodegen.h"
#include "UnaryMatcher.h"

#include <algorithm>
#include <optional>
#include <string>
#include <vector>

#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/Expr.h>
#include <clang/AST/OperationKinds.h>
#include <clang/AST/RecursiveASTVisitor.h>
#include <clang/AST/Stmt.h>
#include <clang/Basic/LangOptions.h>
#include <clang/Basic/SourceLocation.h>
#include <clang/Basic/SourceManager.h>
#include <clang/Basic/TokenKinds.h>
#include <clang/Lex/Lexer.h>
#include <llvm/ADT/StringRef.h>

namespace qct {

namespace {

// Collect every DeclRefExpr referring to a quantum VarDecl inside an
// expression subtree. RecursiveASTVisitor descends freely so quantum
// decl-refs nested under binops/unaries/parens/casts all surface here
// in source order; we splice `.val` after each downstream.
class QuantumDeclRefCollector
    : public clang::RecursiveASTVisitor<QuantumDeclRefCollector> {
public:
    explicit QuantumDeclRefCollector(
        std::vector<const clang::DeclRefExpr *> *out)
        : out_(out) {}

    bool VisitDeclRefExpr(clang::DeclRefExpr *dre) {
        if (dre == nullptr) {
            return true;
        }
        const auto *vd = clang::dyn_cast<clang::VarDecl>(dre->getDecl());
        if (vd != nullptr && hasQuantumAttr(vd)) {
            out_->push_back(dre);
        }
        return true;
    }

private:
    std::vector<const clang::DeclRefExpr *> *out_;
};

// Compute the source-text byte offset (within the main file buffer)
// for a SourceLocation. Returns -1 on invalid loc.
int sourceOffset(clang::SourceLocation loc, const clang::SourceManager &sm) {
    if (loc.isInvalid()) {
        return -1;
    }
    auto decomp = sm.getDecomposedLoc(sm.getExpansionLoc(loc));
    return static_cast<int>(decomp.second);
}

// Return the source text of `e` with `.val` suffixed onto every quantum
// DeclRefExpr identifier inside it. Splices proceed end-to-start so
// earlier offsets don't shift. Empty string only when `e`'s source
// text is unrecoverable.
std::string decorateRhs(const clang::Expr *e,
                        const clang::SourceManager &sm,
                        const clang::LangOptions &lo) {
    if (e == nullptr) {
        return {};
    }
    std::string text = getExprText(e, sm, lo);
    if (text.empty()) {
        return text;
    }
    std::vector<const clang::DeclRefExpr *> qrefs;
    QuantumDeclRefCollector collector(&qrefs);
    collector.TraverseStmt(const_cast<clang::Expr *>(e));
    if (qrefs.empty()) {
        return text;
    }
    const int baseOffset = sourceOffset(e->getBeginLoc(), sm);
    if (baseOffset < 0) {
        return text;
    }
    // Each insertion is the position one-past the quantum-decl-ref
    // token's end inside `text`; Lexer::getLocForEndOfToken gives us
    // exactly that absolute offset.
    std::vector<int> insertions;
    insertions.reserve(qrefs.size());
    for (const clang::DeclRefExpr *dre : qrefs) {
        clang::SourceLocation endLoc =
            clang::Lexer::getLocForEndOfToken(dre->getEndLoc(),
                                              /*Offset=*/0, sm, lo);
        int absEnd = sourceOffset(endLoc, sm);
        if (absEnd < 0) {
            continue;
        }
        int rel = absEnd - baseOffset;
        if (rel < 0 || rel > static_cast<int>(text.size())) {
            // Macro-expansion edge case: end loc doesn't land inside
            // `e`'s source text. Skip rather than corrupt the splice.
            continue;
        }
        insertions.push_back(rel);
    }
    if (insertions.empty()) {
        return text;
    }
    // Descending splice order + dedup so duplicate qrefs at the same
    // range (rare) don't produce `a.val.val`.
    std::sort(insertions.begin(), insertions.end(),
              std::greater<int>());
    insertions.erase(std::unique(insertions.begin(), insertions.end()),
                     insertions.end());
    const std::string suffix = ".val";
    for (int pos : insertions) {
        text.insert(static_cast<size_t>(pos), suffix);
    }
    return text;
}

// Pull the bare identifier of the LHS quantum VarDecl from a matched
// AssignMatch's lhs OperandInfo. Returns the empty string if the
// underlying expr isn't a DeclRefExpr to a VarDecl (defensive — the
// matcher guarantees Quantum classification, but we still defend
// against odd AST shapes).
std::string lhsVarName(const OperandInfo &lhs) {
    if (lhs.expr == nullptr) {
        return {};
    }
    const auto *dre = clang::dyn_cast<clang::DeclRefExpr>(lhs.expr);
    if (dre == nullptr) {
        return {};
    }
    const auto *vd = clang::dyn_cast<clang::VarDecl>(dre->getDecl());
    if (vd == nullptr) {
        return {};
    }
    return vd->getNameAsString();
}

// Pull the RHS Expr from a BinaryOperator or CompoundAssignOperator.
// Both inherit from BinaryOperator and expose getRHS(), so a single
// dyn_cast covers both.
const clang::Expr *rhsOf(const clang::Stmt *s) {
    if (const auto *bo = clang::dyn_cast<clang::BinaryOperator>(s)) {
        return bo->getRHS();
    }
    return nullptr;
}

// Predicate: opcode is an inc/dec. Pure unaries (UO_Minus, UO_Not,
// UO_LNot) flow through `decorateRhs` so `b = -a;` becomes `b.val =
// -a.val;` byte-exact per PLAN §4.8.
bool isIncDecOpcode(clang::UnaryOperatorKind op) {
    switch (op) {
    case clang::UO_PreInc:
    case clang::UO_PostInc:
    case clang::UO_PreDec:
    case clang::UO_PostDec:
        return true;
    default:
        return false;
    }
}

// Recognise `b = ++a;` / `b = a++;` / `b = --a;` / `b = a--;` (both
// quantum). Returns a populated UnaryEmitInput with `destExpr =
// <lhsName>.val` for those shapes; otherwise std::nullopt so callers
// fall through to the normal RHS-decoration path. Gated on BO_Assign
// — inc/dec inside a compound-assign RHS isn't an acceptance shape.
std::optional<UnaryEmitInput>
recogniseAssignRhsIncDec(const clang::Stmt *s,
                         const std::string &lhsName,
                         const AssignMatch &m) {
    if (m.opcode != clang::BO_Assign) {
        return std::nullopt;
    }
    const auto *bo = clang::dyn_cast<clang::BinaryOperator>(s);
    if (bo == nullptr) {
        return std::nullopt;
    }
    const clang::Expr *rhs = bo->getRHS();
    if (rhs == nullptr) {
        return std::nullopt;
    }
    // Peel paren/cast wrappers — mirror `populateFromInit`'s shape.
    const clang::Expr *probe = rhs;
    for (;;) {
        if (const auto *pe = clang::dyn_cast<clang::ParenExpr>(probe)) {
            probe = pe->getSubExpr();
            continue;
        }
        if (const auto *ice =
                clang::dyn_cast<clang::ImplicitCastExpr>(probe)) {
            probe = ice->getSubExpr();
            continue;
        }
        break;
    }
    const auto *uo = clang::dyn_cast<clang::UnaryOperator>(probe);
    if (uo == nullptr) {
        return std::nullopt;
    }
    UnaryMatch um = matchUnary(uo);
    if (!um.matched || !isIncDecOpcode(um.opcode)) {
        return std::nullopt;
    }
    const auto *dre =
        clang::dyn_cast_or_null<clang::DeclRefExpr>(um.operand.expr);
    if (dre == nullptr) {
        return std::nullopt;
    }
    const auto *vd = clang::dyn_cast<clang::VarDecl>(dre->getDecl());
    if (vd == nullptr) {
        return std::nullopt;
    }
    UnaryEmitInput in{};
    in.opcode = um.opcode;
    in.operandName = vd->getNameAsString();
    in.destExpr = lhsName + ".val";
    return in;
}

}  // namespace

std::optional<AssignRewriteResult>
buildAssignRewrite(const clang::Stmt *s, const clang::ASTContext &ctx) {
    if (s == nullptr) {
        return std::nullopt;
    }
    AssignMatch m = matchAssign(s);
    if (!m.matched) {
        return std::nullopt;
    }
    const std::string lhs = lhsVarName(m.lhs);
    if (lhs.empty()) {
        return std::nullopt;
    }
    const clang::SourceManager &sm = ctx.getSourceManager();
    const clang::LangOptions &lo = ctx.getLangOpts();

    AssignRewriteResult out;

    // M8 round 2 — Pattern 9 inc/dec as RHS of an assignment:
    //   `b = ++a;` → `a.val += 1; b.val = a.val;`
    //   `b = a++;` → `b.val = a.val; a.val += 1;`
    // The match is gated on BO_Assign with a quantum LHS plus an
    // inc/dec UnaryOperator on a quantum operand on the RHS; pure
    // unaries on the RHS fall through to the normal RHS-decoration
    // path so `b = -a;` stays `b.val = -a.val;` byte-exact per PLAN
    // §4.8. UnaryCodegen owns the prefix/postfix ordering per PLAN §6.4.
    if (auto uin = recogniseAssignRhsIncDec(s, lhs, m)) {
        out.replacement = emitUnary(*uin);
    } else {
        const clang::Expr *rhs = rhsOf(s);
        if (rhs == nullptr) {
            return std::nullopt;
        }
        const std::string decoratedRhs = decorateRhs(rhs, sm, lo);
        if (decoratedRhs.empty()) {
            return std::nullopt;
        }
        AssignEmitInput in{};
        in.lhsName = lhs;
        in.rhsExpr = decoratedRhs;
        in.opcode = m.opcode;
        out.replacement = emitAssign(in);
    }
    // The BinaryOperator / CompoundAssignOperator node spans `a = 5` —
    // it does NOT include the trailing `;` (the semicolon belongs to
    // the enclosing ExprStmt). To replace the full statement including
    // its semicolon, we extend the end location past the next `;`
    // token via Lexer::findNextToken. Without this, the original `;`
    // remains in the source after our rewrite, producing `a.val = 5;;`.
    clang::SourceRange sr = s->getSourceRange();
    clang::SourceLocation beginExp = sm.getExpansionLoc(sr.getBegin());
    clang::SourceLocation endExp = sm.getExpansionLoc(sr.getEnd());
    auto nextTok = clang::Lexer::findNextToken(endExp, sm, lo);
    if (nextTok.has_value() &&
        nextTok->getKind() == clang::tok::semi) {
        endExp = nextTok->getLocation();
    }
    out.range = clang::SourceRange(beginExp, endExp);
    return out;
}

}  // namespace qct
