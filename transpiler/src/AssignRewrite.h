// AssignRewrite: bridges the Clang AST to AssignCodegen's emission for
// PRD Patterns 7 (plain assign with quantum LHS) and 8 (compound assign
// with quantum LHS). Given a Stmt that AssignMatcher recognises, this
// module:
//   - re-runs the matcher to extract the opcode + LHS-quantum-VarDecl,
//   - walks the RHS expression tree to produce decorated text where
//     every quantum DeclRefExpr inside is suffixed with `.val`,
//   - calls AssignCodegen::emitAssign to assemble the replacement,
//   - returns the SourceRange of the original assignment statement so
//     the caller can substitute via Rewriter::ReplaceText.
//
// Returns std::nullopt when the Stmt is not a recognised assignment to
// a quantum VarDecl (i.e. AssignMatcher returns matched=false) or when
// the rewriter can't produce a valid replacement (e.g. unrecoverable
// source text). The wider rewriter framework treats nullopt as "leave
// the source untouched".
#pragma once

#include <optional>
#include <string>

#include <clang/Basic/SourceLocation.h>

namespace clang {
class ASTContext;
class Stmt;
}  // namespace clang

namespace qct {

struct AssignRewriteResult {
    // Token range covering the whole assignment statement (including
    // its trailing `;`). Callers apply this with Rewriter::ReplaceText
    // via CharSourceRange::getTokenRange so the semicolon is included.
    clang::SourceRange range;
    std::string replacement;
};

// Inspect `s` and build a replacement for a Pattern 7 / Pattern 8
// assignment. Returns std::nullopt if the Stmt is not a recognised
// quantum-LHS assignment.
std::optional<AssignRewriteResult>
buildAssignRewrite(const clang::Stmt *s, const clang::ASTContext &ctx);

}  // namespace qct
