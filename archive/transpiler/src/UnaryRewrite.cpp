#include "UnaryRewrite.h"

#include "OperandClass.h"
#include "QuantumAttr.h"
#include "UnaryCodegen.h"
#include "UnaryMatcher.h"

#include <optional>
#include <string>

#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/Expr.h>
#include <clang/AST/OperationKinds.h>
#include <clang/AST/Stmt.h>
#include <clang/Basic/LangOptions.h>
#include <clang/Basic/SourceLocation.h>
#include <clang/Basic/SourceManager.h>
#include <clang/Basic/TokenKinds.h>
#include <clang/Lex/Lexer.h>

namespace qct {

namespace {

// Predicate: opcode is an inc/dec (i.e. has a side effect). Pure
// unaries with no side effect (UO_Minus, UO_Not, UO_LNot) are handled
// inside AssignRewrite's RHS decoration, not here.
bool isIncDec(clang::UnaryOperatorKind op) {
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

// Pull the operand's quantum VarDecl name. Returns the empty string if
// the operand can't be resolved to a VarDecl (defensive — the matcher
// guarantees a Quantum classification of the operand, but the unwrap
// may still expose a non-DeclRef in odd AST shapes).
std::string operandName(const OperandInfo &opnd) {
    if (opnd.expr == nullptr) {
        return {};
    }
    const auto *dre = clang::dyn_cast<clang::DeclRefExpr>(opnd.expr);
    if (dre == nullptr) {
        return {};
    }
    const auto *vd = clang::dyn_cast<clang::VarDecl>(dre->getDecl());
    if (vd == nullptr) {
        return {};
    }
    return vd->getNameAsString();
}

}  // namespace

std::optional<UnaryRewriteResult>
buildUnaryRewrite(const clang::Stmt *s, const clang::ASTContext &ctx) {
    if (s == nullptr) {
        return std::nullopt;
    }
    UnaryMatch m = matchUnary(s);
    if (!m.matched) {
        return std::nullopt;
    }
    // For Phase 3 M8 only the standalone inc/dec statement form is
    // wired here. Pure-unary expressions are handled by AssignRewrite's
    // RHS decoration. Inc/dec as the value of an enclosing assignment
    // requires multi-statement lifting — deferred (see header).
    if (!isIncDec(m.opcode)) {
        return std::nullopt;
    }
    const std::string opnd = operandName(m.operand);
    if (opnd.empty()) {
        return std::nullopt;
    }

    UnaryEmitInput in{};
    in.opcode = m.opcode;
    in.operandName = opnd;
    // Standalone form — no value consumer.
    in.destExpr.clear();
    UnaryRewriteResult out;
    out.replacement = emitUnary(in);

    const clang::SourceManager &sm = ctx.getSourceManager();
    const clang::LangOptions &lo = ctx.getLangOpts();
    clang::SourceRange sr = s->getSourceRange();
    clang::SourceLocation beginExp = sm.getExpansionLoc(sr.getBegin());
    clang::SourceLocation endExp = sm.getExpansionLoc(sr.getEnd());
    // Extend past the trailing `;` of the enclosing ExprStmt — same
    // rationale as AssignRewrite.cpp: the UnaryOperator node's source
    // range stops at the operand identifier (or the postfix `++` /
    // `--` token), not the statement-terminating semicolon.
    auto nextTok = clang::Lexer::findNextToken(endExp, sm, lo);
    if (nextTok.has_value() &&
        nextTok->getKind() == clang::tok::semi) {
        endExp = nextTok->getLocation();
    }
    out.range = clang::SourceRange(beginExp, endExp);
    return out;
}

}  // namespace qct
