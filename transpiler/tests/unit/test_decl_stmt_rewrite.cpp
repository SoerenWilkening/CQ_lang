// Unit tests for DeclStmtRewrite. Build a real in-process AST via
// `buildASTFromCodeWithArgs`, walk it to collect DeclStmts, then call
// `qct::buildRewrite` and assert the returned replacement string equals
// the byte-exact PRD output for the matching pattern.
//
// Per PLAN section 5.1: "one per e2e fixture, asserting replacement
// string from in-process AST." For P6 we cover the immediate path —
// pattern 1 (uninit) — plus the no-quantum-decls early-out and the
// multi-decl join (which is also exercised by fixture 07 in P9).
//
// The AST-walking helpers intentionally duplicate the ones in
// test_source_text.cpp and test_operand_class.cpp; factoring them
// into a shared header is its own change and explicitly out of scope.
#include <gtest/gtest.h>

#include <memory>
#include <optional>
#include <string>
#include <vector>

#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/Stmt.h>
#include <clang/Frontend/ASTUnit.h>
#include <clang/Tooling/Tooling.h>

#include "DeclStmtRewrite.h"

namespace {

std::unique_ptr<clang::ASTUnit> parseC11(const std::string &code) {
    return clang::tooling::buildASTFromCodeWithArgs(
        code, /*Args=*/{"-std=c11"}, /*FileName=*/"input.c");
}

// Collect every DeclStmt inside any function body in the TU, in source
// order. Top-level VarDecls are NOT wrapped in DeclStmts (they appear
// directly in the AST), so this helper only walks function bodies —
// which is fine because the quantum-VarDecl rewrite is targeted at
// statement-level decls.
void collectDeclStmts(const clang::Decl *d,
                      std::vector<const clang::DeclStmt *> *out) {
    if (d == nullptr) {
        return;
    }
    const auto *fd = clang::dyn_cast<clang::FunctionDecl>(d);
    if (fd == nullptr || !fd->hasBody()) {
        return;
    }
    std::vector<const clang::Stmt *> work{fd->getBody()};
    while (!work.empty()) {
        const clang::Stmt *s = work.back();
        work.pop_back();
        if (s == nullptr) {
            continue;
        }
        if (const auto *ds = clang::dyn_cast<clang::DeclStmt>(s)) {
            out->push_back(ds);
        }
        for (const clang::Stmt *child : s->children()) {
            work.push_back(child);
        }
    }
}

std::vector<const clang::DeclStmt *> allDeclStmts(clang::ASTUnit *unit) {
    std::vector<const clang::DeclStmt *> out;
    for (auto it = unit->top_level_begin(); it != unit->top_level_end(); ++it) {
        collectDeclStmts(*it, &out);
    }
    return out;
}

}  // namespace

// ---------------------------------------------------------------------------
// Pattern 1: uninitialized quantum int — the P6 acceptance case.
// ---------------------------------------------------------------------------

TEST(DeclStmtRewriteTest, UninitProducesPattern1) {
    // `quantum int x;` inside a function body. The DeclStmt for `x`
    // should rewrite to the canonical pattern-1 string. We do NOT
    // assert anything about the SourceRange — that's exercised by the
    // e2e fixture, which diffs the actual output of the Rewriter.
    auto unit = parseC11(
        "#define quantum __attribute__((annotate(\"quantum\")))\n"
        "void f(void) {\n"
        "    quantum int x;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);

    auto stmts = allDeclStmts(unit.get());
    ASSERT_EQ(stmts.size(), 1u);

    std::optional<qct::StmtRewrite> r =
        qct::buildRewrite(stmts[0], unit->getASTContext());
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_t x = init_qint(0, 16);");
}

// ---------------------------------------------------------------------------
// Non-quantum DeclStmt: buildRewrite should return nullopt so the
// caller leaves the statement untouched.
// ---------------------------------------------------------------------------

TEST(DeclStmtRewriteTest, NonQuantumDeclStmtReturnsNullopt) {
    // A plain `int x;` should never trigger a rewrite, even when
    // buildRewrite is called directly on its DeclStmt.
    auto unit = parseC11(
        "void f(void) {\n"
        "    int x;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);

    auto stmts = allDeclStmts(unit.get());
    ASSERT_EQ(stmts.size(), 1u);

    std::optional<qct::StmtRewrite> r =
        qct::buildRewrite(stmts[0], unit->getASTContext());
    EXPECT_FALSE(r.has_value());
}

// ---------------------------------------------------------------------------
// Multi-decl quantum statement: `quantum int a = 3, b = 2;` becomes
// two rewritten init_qint calls separated by a single space, matching
// the Codegen::renderDeclStmt join contract from PLAN section 3.5.
// This is also exercised by fixture 07 in P9 — covering it at unit
// level here keeps the join logic locked in before we wire up that
// fixture.
// ---------------------------------------------------------------------------

TEST(DeclStmtRewriteTest, MultiQuantumDeclStmt) {
    auto unit = parseC11(
        "#define quantum __attribute__((annotate(\"quantum\")))\n"
        "void f(void) {\n"
        "    quantum int a = 3, b = 2;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);

    auto stmts = allDeclStmts(unit.get());
    ASSERT_EQ(stmts.size(), 1u);

    std::optional<qct::StmtRewrite> r =
        qct::buildRewrite(stmts[0], unit->getASTContext());
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement,
              "qint_t a = init_qint(3, 16); qint_t b = init_qint(2, 16);");
}
