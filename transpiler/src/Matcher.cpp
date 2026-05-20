#include "Matcher.h"

#include "DeclStmtRewrite.h"
#include "QuantumAttr.h"

#include <memory>
#include <optional>
#include <string>

#include <clang/AST/ASTConsumer.h>
#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/DeclGroup.h>
#include <clang/AST/Stmt.h>
#include <clang/ASTMatchers/ASTMatchFinder.h>
#include <clang/ASTMatchers/ASTMatchers.h>
#include <clang/Basic/SourceManager.h>
#include <clang/Frontend/CompilerInstance.h>
#include <clang/Rewrite/Core/RewriteBuffer.h>
#include <llvm/Support/raw_ostream.h>

namespace qct {

namespace {

namespace m = clang::ast_matchers;

// Callback invoked by MatchFinder on every DeclStmt that has at least
// one VarDecl carrying an Annotate attribute. The matcher predicate
// matches *any* AnnotateAttr, so we re-check `hasQuantumAttr` inside
// each VarDecl via DeclStmtRewrite::buildRewrite (which already filters
// to "quantum").
class DeclStmtCallback : public m::MatchFinder::MatchCallback {
public:
    explicit DeclStmtCallback(clang::Rewriter *rewriter) : rewriter_(rewriter) {}

    void run(const m::MatchFinder::MatchResult &result) override {
        const auto *ds = result.Nodes.getNodeAs<clang::DeclStmt>("ds");
        if (ds == nullptr || result.Context == nullptr) {
            return;
        }

        // Defensive: confirm at least one of the contained VarDecls is
        // quantum. buildRewrite already enforces this and returns
        // nullopt otherwise — this is just an early-out.
        bool anyQuantum = false;
        for (const clang::Decl *d : ds->decls()) {
            const auto *vd = clang::dyn_cast<clang::VarDecl>(d);
            if (vd != nullptr && hasQuantumAttr(vd)) {
                anyQuantum = true;
                break;
            }
        }
        if (!anyQuantum) {
            return;
        }

        std::optional<StmtRewrite> rewrite =
            buildRewrite(ds, *result.Context);
        if (!rewrite.has_value()) {
            return;
        }
        // getTokenRange expands the end location to include the last
        // token of the DeclStmt (the `;`) in full, so the rewritten
        // text wholly replaces the original statement. The range
        // endpoints are already mapped to expansion locations inside
        // buildRewrite so Rewriter accepts them even when the DeclStmt
        // starts inside the `quantum` macro expansion.
        auto range = clang::CharSourceRange::getTokenRange(rewrite->range);
        rewriter_->ReplaceText(range, rewrite->replacement);
    }

private:
    clang::Rewriter *rewriter_;
};

// Holds the MatchFinder + callback for the lifetime of one TU. The
// MatchFinder owns the registered matchers; we own the callback and
// keep it alive as long as the consumer is alive.
class QuantumConsumer : public clang::ASTConsumer {
public:
    explicit QuantumConsumer(clang::Rewriter *rewriter)
        : callback_(rewriter) {
        // Match every DeclStmt that contains at least one VarDecl with
        // an Annotate attribute. The hasQuantumAttr filter is applied
        // in the callback (and inside buildRewrite) because the matcher
        // predicate hasAttr() can't pin to a specific annotation
        // string.
        auto matcher = m::declStmt(
                           m::has(m::varDecl(
                               m::hasAttr(clang::attr::Annotate))))
                           .bind("ds");
        finder_.addMatcher(matcher, &callback_);
    }

    void HandleTranslationUnit(clang::ASTContext &ctx) override {
        finder_.matchAST(ctx);
    }

private:
    DeclStmtCallback callback_;
    m::MatchFinder finder_;
};

}  // namespace

std::unique_ptr<clang::ASTConsumer>
QuantumRewriteAction::CreateASTConsumer(clang::CompilerInstance &ci,
                                        llvm::StringRef /*file*/) {
    rewriter_.setSourceMgr(ci.getSourceManager(), ci.getLangOpts());
    return std::make_unique<QuantumConsumer>(&rewriter_);
}

void QuantumRewriteAction::EndSourceFileAction() {
    const clang::SourceManager &sm = rewriter_.getSourceMgr();
    clang::FileID mainId = sm.getMainFileID();
    const clang::RewriteBuffer *rb = rewriter_.getRewriteBufferFor(mainId);
    if (rb != nullptr) {
        // We rewrote at least one DeclStmt: emit the modified buffer.
        llvm::outs() << std::string(rb->begin(), rb->end());
    } else {
        // No rewrites — pass the original source through unchanged so
        // the tool's stdout is still a complete C translation unit.
        llvm::outs() << sm.getBufferData(mainId);
    }
}

}  // namespace qct
