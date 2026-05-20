// Matcher: libtooling integration. Defines an ASTFrontendAction that
//   - sets up a clang::Rewriter over the main file,
//   - registers an ASTMatcher binding DeclStmts that contain at least
//     one VarDecl with an AnnotateAttr (filtered to "quantum" in the
//     callback),
//   - on each match, calls qct::buildRewrite and applies the result via
//     Rewriter::ReplaceText,
//   - at EndSourceFileAction, writes the rewritten main-file buffer (or
//     the untouched original if nothing was rewritten) to llvm::outs().
//
// The qct::QuantumRewriteAction is plugged into ClangTool by the
// driver via newFrontendActionFactory<>.
//
// NOTE: P6 deliberately does NOT insert `#include "qint.h"` — that's
// scheduled for PLAN phase P10.
#pragma once

#include <memory>

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
};

}  // namespace qct
