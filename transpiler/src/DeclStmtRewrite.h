// DeclStmtRewrite: bridges the Clang AST to the pure-string Codegen
// module. Given a `DeclStmt` whose VarDecls were matched by the
// Matcher's `hasAttr(annotate("quantum"))` predicate, this module:
//   - filters down to the quantum-annotated VarDecls,
//   - decides the rewrite Form for each (Uninit / ClassicalInit /
//     QuantumPlusQuantum / QuantumPlusClassical / ClassicalPlusQuantum),
//     populating the VarRewriteInput fields accordingly,
//   - calls Codegen::renderDeclStmt to assemble the replacement text,
//   - returns the SourceRange of the original DeclStmt (including its
//     trailing semicolon — the caller is expected to apply the rewrite
//     via Rewriter::ReplaceText with CharSourceRange::getTokenRange so
//     the last token, i.e. the `;`, is included in full).
//
// Returns std::nullopt if the DeclStmt has no quantum VarDecls — that
// signals the caller to leave the source untouched.
#pragma once

#include <optional>
#include <string>

#include <clang/Basic/SourceLocation.h>

namespace clang {
class ASTContext;
class DeclStmt;
}  // namespace clang

namespace qct {

struct StmtRewrite {
    // The token range of the original DeclStmt. The caller should pass
    // this to Rewriter::ReplaceText via CharSourceRange::getTokenRange,
    // which expands the end location to include the last token (the
    // `;`) in full.
    clang::SourceRange range;
    std::string replacement;
};

// Inspect `ds` and build a replacement for every quantum-annotated
// VarDecl in it. Returns std::nullopt if no VarDecl in the DeclStmt
// carries the `quantum` AnnotateAttr (i.e. the matcher matched a
// DeclStmt that happens to contain another annotation we don't care
// about — defensive, shouldn't happen for v1 inputs).
std::optional<StmtRewrite> buildRewrite(const clang::DeclStmt *ds,
                                        const clang::ASTContext &ctx);

}  // namespace qct
