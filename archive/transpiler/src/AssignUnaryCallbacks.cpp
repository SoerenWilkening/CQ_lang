#include "AssignUnaryCallbacks.h"

#include "AssignRewrite.h"
#include "QuantumAttr.h"
#include "UnaryRewrite.h"

#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/Expr.h>
#include <clang/AST/Stmt.h>
#include <clang/Basic/SourceManager.h>

namespace qct {

namespace m = clang::ast_matchers;

namespace {

// Record the FileID a rewrite landed in so EndSourceFileAction can
// prepend `#include <CQ.h>` once per affected TU. The rewrite range's
// begin loc is already mapped to an expansion location by the build*
// helpers, so getFileID returns the user's source file (not the macro
// expansion file).
template <typename Rewrite>
void registerFile(const Rewrite &rewrite,
                  const clang::ASTContext &ctx,
                  std::set<clang::FileID> *rewrittenFiles) {
    const clang::SourceManager &sm = ctx.getSourceManager();
    clang::FileID fid = sm.getFileID(rewrite.range.getBegin());
    if (fid.isValid()) {
        rewrittenFiles->insert(fid);
    }
}

}  // namespace

AssignCallback::AssignCallback(clang::Rewriter *rewriter,
                               std::set<clang::FileID> *rewrittenFiles)
    : rewriter_(rewriter), rewrittenFiles_(rewrittenFiles) {}

void AssignCallback::run(const m::MatchFinder::MatchResult &result) {
    const auto *bo = result.Nodes.getNodeAs<clang::BinaryOperator>("assign");
    if (bo == nullptr || result.Context == nullptr) {
        return;
    }
    const auto *vd = result.Nodes.getNodeAs<clang::VarDecl>("assignlhs");
    if (!hasQuantumAttr(vd)) {
        return;
    }
    auto rewrite = buildAssignRewrite(bo, *result.Context);
    if (!rewrite.has_value()) {
        return;
    }
    auto range = clang::CharSourceRange::getTokenRange(rewrite->range);
    rewriter_->ReplaceText(range, rewrite->replacement);
    registerFile(*rewrite, *result.Context, rewrittenFiles_);
}

UnaryCallback::UnaryCallback(clang::Rewriter *rewriter,
                             std::set<clang::FileID> *rewrittenFiles)
    : rewriter_(rewriter), rewrittenFiles_(rewrittenFiles) {}

void UnaryCallback::run(const m::MatchFinder::MatchResult &result) {
    const auto *uo = result.Nodes.getNodeAs<clang::UnaryOperator>("unary");
    if (uo == nullptr || result.Context == nullptr) {
        return;
    }
    const auto *vd = result.Nodes.getNodeAs<clang::VarDecl>("unaryvar");
    if (!hasQuantumAttr(vd)) {
        return;
    }
    auto rewrite = buildUnaryRewrite(uo, *result.Context);
    if (!rewrite.has_value()) {
        return;
    }
    auto range = clang::CharSourceRange::getTokenRange(rewrite->range);
    rewriter_->ReplaceText(range, rewrite->replacement);
    registerFile(*rewrite, *result.Context, rewrittenFiles_);
}

}  // namespace qct
