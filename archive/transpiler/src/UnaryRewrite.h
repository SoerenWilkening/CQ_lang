// UnaryRewrite: bridges the Clang AST to UnaryCodegen's emission for
// PRD Pattern 9 (unary on quantum operand) in the standalone-statement
// form. Given a Stmt that contains a UnaryOperator with a quantum
// operand at statement scope (e.g. `++a;`, `a--;`), this module:
//   - runs UnaryMatcher to extract the opcode + operand VarDecl name,
//   - calls UnaryCodegen::emitUnary to assemble the replacement
//     statement,
//   - returns the SourceRange of the original statement.
//
// Scope (Phase 3 M8 wiring):
//
// - Standalone inc/dec statements (`++a;`, `--a;`, `a++;`, `a--;`)
//   where the value is discarded: emit just the modification statement
//   (`a.val += 1;` / `a.val -= 1;`).
//
// - Pure-unary expressions (`-a`, `~a`, `!a`) embedded inside a larger
//   context (an assignment RHS, an initializer): these are handled
//   transparently by AssignRewrite's RHS decoration — the quantum
//   DeclRefExpr inside the unary gets `.val` appended in place, so
//   `b = -a;` decorates to `b = -a.val;`. UnaryRewrite is NOT involved
//   in that path.
//
// - Inc/dec used as the value of an assignment (`b = ++a;` etc.) is
//   the multi-statement expansion documented in PLAN §6.4. This case
//   requires lifting the modification statement out of the enclosing
//   statement and is structurally non-trivial in the existing rewriter
//   framework — see M8's worker report.
//
// Returns std::nullopt when the Stmt is not a recognised
// standalone-inc/dec form on a quantum operand.
#pragma once

#include <optional>
#include <string>

#include <clang/Basic/SourceLocation.h>

namespace clang {
class ASTContext;
class Stmt;
}  // namespace clang

namespace qct {

struct UnaryRewriteResult {
    clang::SourceRange range;
    std::string replacement;
};

// Inspect `s` and build a replacement for a standalone Pattern 9
// inc/dec statement on a quantum operand. Returns std::nullopt if the
// Stmt is not such a form.
std::optional<UnaryRewriteResult>
buildUnaryRewrite(const clang::Stmt *s, const clang::ASTContext &ctx);

}  // namespace qct
