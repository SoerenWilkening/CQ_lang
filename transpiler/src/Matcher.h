// Matcher: libtooling integration. Defines an ASTFrontendAction that
//   - sets up a clang::Rewriter over the main file,
//   - registers two ASTMatchers:
//       1. DeclStmts containing at least one VarDecl with an AnnotateAttr
//          (filtered to "quantum" in the callback), wired to
//          qct::buildRewrite for the `quantum int ...;` patterns.
//       2. CStyleCastExprs whose subexpression (after paren/implicit-cast
//          peeling) is a DeclRefExpr to a VarDecl with an AnnotateAttr
//          (filtered to "quantum" in the callback), wired to
//          qct::buildCastRewrite for the measurement-as-cast pattern.
//   - on each match, calls the relevant builder and applies the result
//     via Rewriter::ReplaceText, recording the affected FileID,
//   - at EndSourceFileAction, prepends a single `#include <CQ.h>` to
//     the main file if it received any rewrites, then writes the
//     rewritten main-file buffer (or the untouched original if nothing
//     was rewritten) to llvm::outs().
//
// The qct::QuantumRewriteAction is plugged into ClangTool by the
// driver via newFrontendActionFactory<>.
#pragma once

#include <memory>
#include <set>

#include <clang/Basic/SourceLocation.h>
#include <clang/Frontend/FrontendAction.h>
#include <clang/Rewrite/Core/Rewriter.h>
#include <llvm/ADT/StringRef.h>

namespace clang {
class ASTConsumer;
class CompilerInstance;
}  // namespace clang

namespace qct {

class QuantumRewriteAction : public clang::ASTFrontendAction {
public:
    std::unique_ptr<clang::ASTConsumer>
    CreateASTConsumer(clang::CompilerInstance &ci,
                      llvm::StringRef file) override;

protected:
    void EndSourceFileAction() override;

private:
    clang::Rewriter rewriter_;
    // Set of FileIDs that received at least one rewrite, used to drive
    // the once-per-TU `#include <CQ.h>` insertion in
    // EndSourceFileAction. Populated by DeclStmtCallback and
    // CastCallback.
    std::set<clang::FileID> rewrittenFiles_;
};

}  // namespace qct
