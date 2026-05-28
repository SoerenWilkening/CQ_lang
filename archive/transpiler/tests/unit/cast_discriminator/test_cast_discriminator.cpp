// Phase 3 M9 — Cast discriminator tests for Q→Q vs Q→C.
// Tests the four acceptance criteria from PLAN §4.9:
//   1. Q→C regression: `(int) q` still emits cq_measure_si32
//   2. Q→Q explicit: `quantum long b = (quantum long) q_int;` emits
//      stock cast on .val, no measurement
//   3. Q→Q implicit: `quantum long b = q_int;` same as explicit
//   4. Edge: `int x = (a == b);` (quantum expr → classical) left alone
//
// Tests 2-4 exercise DeclStmtRewrite (the DeclStmt owns the Q→Q
// decision); test 1 exercises CastRewrite directly.
#include <gtest/gtest.h>

#include <memory>
#include <optional>
#include <string>
#include <vector>

#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/Expr.h>
#include <clang/AST/Stmt.h>
#include <clang/Frontend/ASTUnit.h>
#include <clang/Tooling/Tooling.h>

#include "CastRewrite.h"
#include "DeclStmtRewrite.h"

namespace {

std::unique_ptr<clang::ASTUnit> parseC11(const std::string &code) {
    return clang::tooling::buildASTFromCodeWithArgs(
        code, /*Args=*/{"-std=c11"}, /*FileName=*/"input.c");
}

// --- CStyleCastExpr helpers (from test_cast_rewrite.cpp) ---

void collectCStyleCasts(const clang::Decl *d,
                        std::vector<const clang::CStyleCastExpr *> *out) {
    if (d == nullptr) return;
    const auto *fd = clang::dyn_cast<clang::FunctionDecl>(d);
    if (fd == nullptr || !fd->hasBody()) return;
    std::vector<const clang::Stmt *> work{fd->getBody()};
    while (!work.empty()) {
        const clang::Stmt *s = work.back();
        work.pop_back();
        if (s == nullptr) continue;
        if (const auto *ce = clang::dyn_cast<clang::CStyleCastExpr>(s))
            out->push_back(ce);
        for (const clang::Stmt *child : s->children())
            work.push_back(child);
    }
}

std::optional<qct::CastRewrite> firstCastRewrite(const std::string &body) {
    auto unit = parseC11(
        "#define quantum __attribute__((annotate(\"quantum\")))\n"
        "void f(void) {\n" +
        body + "\n}\n");
    if (unit == nullptr) return std::nullopt;
    std::vector<const clang::CStyleCastExpr *> casts;
    for (auto it = unit->top_level_begin(); it != unit->top_level_end(); ++it)
        collectCStyleCasts(*it, &casts);
    if (casts.empty()) return std::nullopt;
    return qct::buildCastRewrite(casts.back(), unit->getASTContext());
}

// --- DeclStmt helpers (from test_decl_stmt_rewrite_pattern6.cpp) ---

void collectDeclStmts(const clang::Decl *d,
                      std::vector<const clang::DeclStmt *> *out) {
    if (d == nullptr) return;
    const auto *fd = clang::dyn_cast<clang::FunctionDecl>(d);
    if (fd == nullptr || !fd->hasBody()) return;
    std::vector<const clang::Stmt *> work{fd->getBody()};
    while (!work.empty()) {
        const clang::Stmt *s = work.back();
        work.pop_back();
        if (s == nullptr) continue;
        if (const auto *ds = clang::dyn_cast<clang::DeclStmt>(s))
            out->push_back(ds);
        for (const clang::Stmt *child : s->children())
            work.push_back(child);
    }
}

bool firstDeclNamed(const clang::DeclStmt *ds, const std::string &name) {
    for (const clang::Decl *d : ds->decls()) {
        if (const auto *vd = clang::dyn_cast<clang::VarDecl>(d))
            return vd->getNameAsString() == name;
    }
    return false;
}

std::optional<qct::StmtRewrite> rewriteDeclFor(const std::string &body,
                                               const std::string &name) {
    auto unit = parseC11(
        "#define quantum __attribute__((annotate(\"quantum\")))\n"
        "void f(void) {\n" +
        body + "\n}\n");
    if (unit == nullptr) return std::nullopt;
    std::vector<const clang::DeclStmt *> stmts;
    for (auto it = unit->top_level_begin(); it != unit->top_level_end(); ++it)
        collectDeclStmts(*it, &stmts);
    for (const clang::DeclStmt *ds : stmts) {
        if (firstDeclNamed(ds, name))
            return qct::buildRewrite(ds, unit->getASTContext());
    }
    return std::nullopt;
}

}  // namespace

// Test 1: Q→C regression — `(int) q` still emits measurement.
TEST(CastDiscriminatorTest, QToCStillEmitsMeasure) {
    auto r = firstCastRewrite(
        "    quantum int q = 3;\n"
        "    int m = (int) q;");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "cq_measure_si32(q)");
}

// Test 2: Q→Q explicit — `quantum long b = (quantum long) q_int;`
// emits cross-copy with stock cast on .val, no measurement.
TEST(CastDiscriminatorTest, QToQExplicitCastEmitsCrossCopy) {
    auto r = rewriteDeclFor(
        "    quantum int q_int = 3;\n"
        "    quantum long b = (quantum long) q_int;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qlong_mid_t b; b.val = (long) q_int.val;");
    EXPECT_EQ(r->replacement.find("cq_measure"), std::string::npos);
}

// Test 3: Q→Q implicit — `quantum long b = q_int;` (no explicit cast)
// emits the same cross-copy form.
TEST(CastDiscriminatorTest, QToQImplicitEmitsCrossCopy) {
    auto r = rewriteDeclFor(
        "    quantum int q_int = 3;\n"
        "    quantum long b = q_int;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qlong_mid_t b; b.val = (long) q_int.val;");
    EXPECT_EQ(r->replacement.find("cq_measure"), std::string::npos);
}

// Test 4: Edge — quantum expression flowing to classical destination
// without explicit cast. The rewriter does NOT rewrite this; the IR
// pass produces the diagnostic.
TEST(CastDiscriminatorTest, QuantumExprToClassicalLeftAlone) {
    auto r = rewriteDeclFor(
        "    quantum int a = 3;\n"
        "    quantum int b = 5;\n"
        "    int x = (a == b);",
        "x");
    // `x` is not quantum → buildRewrite returns nullopt.
    EXPECT_FALSE(r.has_value());
}
