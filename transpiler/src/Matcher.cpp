#include "Matcher.h"

#include "CastRewrite.h"
#include "DeclStmtRewrite.h"
#include "QuantumAttr.h"

#include <memory>
#include <optional>
#include <set>
#include <string>

#include <clang/AST/ASTConsumer.h>
#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/DeclGroup.h>
#include <clang/AST/Expr.h>
#include <clang/AST/Stmt.h>
#include <clang/ASTMatchers/ASTMatchFinder.h>
#include <clang/ASTMatchers/ASTMatchers.h>
#include <clang/Basic/SourceLocation.h>
#include <clang/Basic/SourceManager.h>
#include <clang/Frontend/CompilerInstance.h>
#include <clang/Rewrite/Core/Rewriter.h>
#include <llvm/Support/raw_ostream.h>

namespace qct {

namespace {

namespace m = clang::ast_matchers;

// Callback invoked by MatchFinder on every DeclStmt that has at least
// one VarDecl carrying an Annotate attribute. The matcher predicate
// matches *any* AnnotateAttr, so we re-check `hasQuantumAttr` inside
// each VarDecl via DeclStmtRewrite::buildRewrite (which already filters
// to "quantum").
//
// On a successful ReplaceText, the FileID containing the rewrite is
// recorded in the shared `rewritten_files` set so that the surrounding
// QuantumRewriteAction can insert a single `#include <CQ.h>` at the
// top of each rewritten translation unit (PLAN section 3.7).
class DeclStmtCallback : public m::MatchFinder::MatchCallback {
public:
    DeclStmtCallback(clang::Rewriter *rewriter,
                     std::set<clang::FileID> *rewrittenFiles)
        : rewriter_(rewriter), rewrittenFiles_(rewrittenFiles) {}

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

        // Record the FileID that just received a rewrite, so the
        // EndSourceFileAction can prepend `#include <CQ.h>` exactly
        // once per affected file. The rewrite range start is already an
        // expansion location, so getFileID returns the user's source
        // file rather than the macro expansion file.
        const clang::SourceManager &sm = result.Context->getSourceManager();
        clang::FileID fid = sm.getFileID(rewrite->range.getBegin());
        if (fid.isValid()) {
            rewrittenFiles_->insert(fid);
        }
    }

private:
    clang::Rewriter *rewriter_;
    std::set<clang::FileID> *rewrittenFiles_;
};

// Callback invoked by MatchFinder on every CStyleCastExpr whose
// subexpression (after paren/implicit-cast peeling) refers to a VarDecl
// carrying an Annotate attribute. The matcher predicate matches *any*
// AnnotateAttr; the "quantum" filter is enforced via hasQuantumAttr on
// the bound VarDecl (and again, defensively, inside buildCastRewrite —
// which re-derives the underlying decl through IgnoreParenImpCasts).
//
// On a successful ReplaceText, the FileID containing the rewrite is
// recorded in the shared `rewritten_files` set so the surrounding
// QuantumRewriteAction can insert a single `#include <CQ.h>` at the
// top of each rewritten translation unit (PLAN section 4.4.5).
class CastCallback : public m::MatchFinder::MatchCallback {
public:
    CastCallback(clang::Rewriter *rewriter,
                 std::set<clang::FileID> *rewrittenFiles)
        : rewriter_(rewriter), rewrittenFiles_(rewrittenFiles) {}

    void run(const m::MatchFinder::MatchResult &result) override {
        const auto *ce =
            result.Nodes.getNodeAs<clang::CStyleCastExpr>("cast");
        if (ce == nullptr || result.Context == nullptr) {
            return;
        }

        // Defensive early-out: the bound VarDecl must actually carry the
        // "quantum" annotation, not just any AnnotateAttr the matcher's
        // hasAttr() predicate would accept. Mirrors DeclStmtCallback's
        // anyQuantum check above. buildCastRewrite re-checks this too
        // via its own IgnoreParenImpCasts peeling, but doing it here
        // first keeps the hot path short for unrelated casts.
        const auto *vd = result.Nodes.getNodeAs<clang::VarDecl>("castvar");
        if (!hasQuantumAttr(vd)) {
            return;
        }

        std::optional<CastRewrite> rewrite =
            buildCastRewrite(ce, *result.Context);
        if (!rewrite.has_value()) {
            return;
        }
        // getTokenRange expands the end location to include the last
        // token of the CStyleCastExpr in full, so the rewritten text
        // wholly replaces the cast (the surrounding expression context,
        // e.g. `+ 1`, is left untouched). The range endpoints are
        // already mapped to expansion locations inside buildCastRewrite
        // so Rewriter accepts them even when the cast appears inside a
        // macro expansion.
        auto range = clang::CharSourceRange::getTokenRange(rewrite->range);
        rewriter_->ReplaceText(range, rewrite->replacement);

        // Record the FileID that just received a rewrite, so the
        // EndSourceFileAction can prepend `#include <CQ.h>` exactly
        // once per affected file. Mirrors DeclStmtCallback's bookkeeping.
        const clang::SourceManager &sm = result.Context->getSourceManager();
        clang::FileID fid = sm.getFileID(rewrite->range.getBegin());
        if (fid.isValid()) {
            rewrittenFiles_->insert(fid);
        }
    }

private:
    clang::Rewriter *rewriter_;
    std::set<clang::FileID> *rewrittenFiles_;
};

// Holds the MatchFinder + callbacks for the lifetime of one TU. The
// MatchFinder owns the registered matchers; we own the callbacks and
// keep them alive as long as the consumer is alive.
class QuantumConsumer : public clang::ASTConsumer {
public:
    QuantumConsumer(clang::Rewriter *rewriter,
                    std::set<clang::FileID> *rewrittenFiles)
        : declStmtCallback_(rewriter, rewrittenFiles),
          castCallback_(rewriter, rewrittenFiles) {
        // Match every DeclStmt that contains at least one VarDecl with
        // an Annotate attribute. The hasQuantumAttr filter is applied
        // in the callback (and inside buildRewrite) because the matcher
        // predicate hasAttr() can't pin to a specific annotation
        // string.
        auto declStmtMatcher = m::declStmt(
                                   m::has(m::varDecl(
                                       m::hasAttr(clang::attr::Annotate))))
                                   .bind("ds");
        finder_.addMatcher(declStmtMatcher, &declStmtCallback_);

        // Match every CStyleCastExpr whose source expression (after
        // peeling paren / implicit-cast layers) is a DeclRefExpr to a
        // VarDecl with an Annotate attribute. The cast and the VarDecl
        // are both bound so the callback can filter to "quantum" via
        // hasQuantumAttr without re-walking the AST. Mirrors the
        // peeling buildCastRewrite performs via IgnoreParenImpCasts.
        auto castMatcher = m::cStyleCastExpr(
                               m::hasSourceExpression(
                                   m::ignoringParenImpCasts(
                                       m::declRefExpr(m::to(
                                           m::varDecl(m::hasAttr(
                                                          clang::attr::Annotate))
                                               .bind("castvar"))))))
                               .bind("cast");
        finder_.addMatcher(castMatcher, &castCallback_);
    }

    void HandleTranslationUnit(clang::ASTContext &ctx) override {
        finder_.matchAST(ctx);
    }

private:
    DeclStmtCallback declStmtCallback_;
    CastCallback castCallback_;
    m::MatchFinder finder_;
};

}  // namespace

std::unique_ptr<clang::ASTConsumer>
QuantumRewriteAction::CreateASTConsumer(clang::CompilerInstance &ci,
                                        llvm::StringRef /*file*/) {
    rewriter_.setSourceMgr(ci.getSourceManager(), ci.getLangOpts());
    rewrittenFiles_.clear();
    return std::make_unique<QuantumConsumer>(&rewriter_, &rewrittenFiles_);
}

void QuantumRewriteAction::EndSourceFileAction() {
    clang::SourceManager &sm = rewriter_.getSourceMgr();
    clang::FileID mainId = sm.getMainFileID();

    // If the main file received at least one rewrite, prepend a single
    // `#include <CQ.h>` at its start so the rewritten output picks up
    // the Phase-1 user-facing header (the `quantum` macro and, via the
    // transpiled-C ABI in cq_mid.h that cqc threads in, the per-width
    // intrinsics like cq_init_i32 / cq_measure_i32). Angle-bracket form
    // per PLAN §4.4.5 — the include is system-style so it resolves
    // through -I include/ from the driver. We use InsertText with
    // InsertAfter=true (a no-op here since this is the only insertion
    // at SOF) and indentNewLines=false (the inserted line already ends
    // in '\n').
    if (rewrittenFiles_.count(mainId) > 0) {
        clang::SourceLocation sof = sm.getLocForStartOfFile(mainId);
        rewriter_.InsertText(sof, "#include <CQ.h>\n",
                             /*InsertAfter=*/true,
                             /*indentNewLines=*/false);
    }

    const auto *rb = rewriter_.getRewriteBufferFor(mainId);
    if (rb != nullptr) {
        // We rewrote at least one DeclStmt (and/or inserted the
        // include): emit the modified buffer.
        llvm::outs() << std::string(rb->begin(), rb->end());
    } else {
        // No rewrites — pass the original source through unchanged so
        // the tool's stdout is still a complete C translation unit.
        llvm::outs() << sm.getBufferData(mainId);
    }
}

}  // namespace qct
