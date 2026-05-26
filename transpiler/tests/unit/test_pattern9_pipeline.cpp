// Phase 3 M8 round 2 — full-pipeline (AST → rewriter → text) tests for
// Pattern 9 (PRD §"Rewriter patterns" Pattern 9 + PLAN §4.8 / §6.4).
//
// The codegen-only unit tests under tests/unit/codegen/ exercise the
// emitter functions in isolation (we hand them a populated
// UnaryEmitInput / VarRewriteInput). Those tests don't cover the AST
// wiring — i.e. they don't catch defects like "DeclStmtRewrite doesn't
// route a UnaryOperator initializer through UnaryCodegen". This file
// closes that gap by parsing C source through libtooling, invoking
// `buildRewrite` / `buildAssignRewrite`, and asserting the byte-exact
// emission listed in PLAN §4.8.
//
// Cases covered:
//   `quantum int b = -a;`  → `qint_mid_t b; b.val = -a.val;`
//   `quantum int b = ~a;`  → `qint_mid_t b; b.val = ~a.val;`
//   `quantum int b = !a;`  → `qint_mid_t b; b.val = !a.val;`
//   `quantum int b = ++a;` → `qint_mid_t b; a.val += 1; b.val = a.val;`
//   `quantum int b = a++;` → `qint_mid_t b; b.val = a.val; a.val += 1;`
//   `quantum int b = --a;` → `qint_mid_t b; a.val -= 1; b.val = a.val;`
//   `quantum int b = a--;` → `qint_mid_t b; b.val = a.val; a.val -= 1;`
//   `b = ++a;` (existing decls) → `a.val += 1; b.val = a.val;`
//   `b = a++;`                  → `b.val = a.val; a.val += 1;`
//   `b = --a;`                  → `a.val -= 1; b.val = a.val;`
//   `b = a--;`                  → `b.val = a.val; a.val -= 1;`
//   `b = -a;` (regression — pure unary still uses RHS decoration)
//                               → `b.val = -a.val;`
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

#include "AssignRewrite.h"
#include "DeclStmtRewrite.h"

namespace {

std::unique_ptr<clang::ASTUnit> parseC11(const std::string &code) {
    return clang::tooling::buildASTFromCodeWithArgs(
        code, /*Args=*/{"-std=c11"}, /*FileName=*/"input.c");
}

// Walk every function body in the TU collecting Stmt pointers in
// reverse-source order. We want both DeclStmts (for the declaration-
// init pipeline) and BinaryOperator nodes (for the assignment-RHS
// pipeline); the test helpers below pick the kind they need.
void collectStmts(const clang::Decl *d,
                  std::vector<const clang::Stmt *> *out) {
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
        out->push_back(s);
        for (const clang::Stmt *child : s->children()) {
            work.push_back(child);
        }
    }
}

std::vector<const clang::Stmt *> allStmts(clang::ASTUnit *unit) {
    std::vector<const clang::Stmt *> out;
    for (auto it = unit->top_level_begin(); it != unit->top_level_end();
         ++it) {
        collectStmts(*it, &out);
    }
    return out;
}

// Parse `body` wrapped in `void f(void) { ... }` (with `quantum`
// pre-defined), find the DeclStmt whose first VarDecl is named `name`,
// and return its rewrite. Mirrors `rewriteDeclFor` in
// test_decl_stmt_rewrite_int.cpp.
std::optional<qct::StmtRewrite> rewriteDeclFor(const std::string &body,
                                               const std::string &name) {
    auto unit = parseC11(
        "#define quantum __attribute__((annotate(\"quantum\")))\n"
        "void f(void) {\n" +
        body + "\n}\n");
    if (unit == nullptr) {
        return std::nullopt;
    }
    for (const clang::Stmt *s : allStmts(unit.get())) {
        const auto *ds = clang::dyn_cast<clang::DeclStmt>(s);
        if (ds == nullptr) {
            continue;
        }
        for (const clang::Decl *d : ds->decls()) {
            if (const auto *vd = clang::dyn_cast<clang::VarDecl>(d)) {
                if (vd->getNameAsString() == name) {
                    return qct::buildRewrite(ds, unit->getASTContext());
                }
            }
        }
    }
    return std::nullopt;
}

// Parse `body` and find the first BinaryOperator (assignment) whose
// LHS is a DeclRefExpr to a VarDecl named `name`. Returns the
// `buildAssignRewrite` result for that node.
std::optional<qct::AssignRewriteResult>
rewriteAssignFor(const std::string &body, const std::string &lhsName) {
    auto unit = parseC11(
        "#define quantum __attribute__((annotate(\"quantum\")))\n"
        "void f(void) {\n" +
        body + "\n}\n");
    if (unit == nullptr) {
        return std::nullopt;
    }
    for (const clang::Stmt *s : allStmts(unit.get())) {
        const auto *bo = clang::dyn_cast<clang::BinaryOperator>(s);
        if (bo == nullptr || !bo->isAssignmentOp()) {
            continue;
        }
        const auto *dre = clang::dyn_cast<clang::DeclRefExpr>(
            bo->getLHS()->IgnoreParenImpCasts());
        if (dre == nullptr) {
            continue;
        }
        const auto *vd = clang::dyn_cast<clang::VarDecl>(dre->getDecl());
        if (vd == nullptr || vd->getNameAsString() != lhsName) {
            continue;
        }
        return qct::buildAssignRewrite(bo, unit->getASTContext());
    }
    return std::nullopt;
}

}  // namespace

// ---------------------------------------------------------------------------
// Pattern 9 declaration-init pipeline. Each `quantum int b = <unary>;`
// shape must produce the canonical PLAN §4.8 emission — the AST→rewriter
// wiring is what's under test here; UnaryCodegen's per-opcode output is
// covered separately by the codegen unit tests.
// ---------------------------------------------------------------------------

TEST(Pattern9PipelineDeclInitTest, NegateInitProducesSplitForm) {
    auto r = rewriteDeclFor(
        "    quantum int a = 5;\n"
        "    quantum int b = -a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t b; b.val = -a.val;");
}

TEST(Pattern9PipelineDeclInitTest, BitwiseNotInitProducesSplitForm) {
    auto r = rewriteDeclFor(
        "    quantum int a = 5;\n"
        "    quantum int b = ~a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t b; b.val = ~a.val;");
}

TEST(Pattern9PipelineDeclInitTest, LogicalNotInitProducesSplitForm) {
    auto r = rewriteDeclFor(
        "    quantum int a = 5;\n"
        "    quantum int b = !a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t b; b.val = !a.val;");
}

TEST(Pattern9PipelineDeclInitTest, PreIncInitProducesModifyThenPropagate) {
    auto r = rewriteDeclFor(
        "    quantum int a = 5;\n"
        "    quantum int b = ++a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement,
              "qint_mid_t b; a.val += 1; b.val = a.val;");
}

TEST(Pattern9PipelineDeclInitTest, PostIncInitProducesPropagateThenModify) {
    auto r = rewriteDeclFor(
        "    quantum int a = 5;\n"
        "    quantum int b = a++;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement,
              "qint_mid_t b; b.val = a.val; a.val += 1;");
}

TEST(Pattern9PipelineDeclInitTest, PreDecInitProducesModifyThenPropagate) {
    auto r = rewriteDeclFor(
        "    quantum int a = 5;\n"
        "    quantum int b = --a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement,
              "qint_mid_t b; a.val -= 1; b.val = a.val;");
}

TEST(Pattern9PipelineDeclInitTest, PostDecInitProducesPropagateThenModify) {
    auto r = rewriteDeclFor(
        "    quantum int a = 5;\n"
        "    quantum int b = a--;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement,
              "qint_mid_t b; b.val = a.val; a.val -= 1;");
}

// ---------------------------------------------------------------------------
// Pattern 9 assignment-RHS pipeline. `b = ++a;` and friends must lift
// the inc/dec out of the RHS into the multi-statement form per PLAN
// §6.4 — replacing the whole enclosing ExprStmt (semicolon included).
// Pure unaries (`b = -a;`) must still go through the RHS-decoration
// path, producing `b.val = -a.val;` byte-exact per PLAN §4.8.
// ---------------------------------------------------------------------------

TEST(Pattern9PipelineAssignRhsTest, PreIncRhsLiftsToMultiStmt) {
    auto r = rewriteAssignFor(
        "    quantum int a = 5;\n"
        "    quantum int b = 0;\n"
        "    b = ++a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "a.val += 1; b.val = a.val;");
}

TEST(Pattern9PipelineAssignRhsTest, PostIncRhsLiftsToMultiStmt) {
    auto r = rewriteAssignFor(
        "    quantum int a = 5;\n"
        "    quantum int b = 0;\n"
        "    b = a++;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "b.val = a.val; a.val += 1;");
}

TEST(Pattern9PipelineAssignRhsTest, PreDecRhsLiftsToMultiStmt) {
    auto r = rewriteAssignFor(
        "    quantum int a = 5;\n"
        "    quantum int b = 0;\n"
        "    b = --a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "a.val -= 1; b.val = a.val;");
}

TEST(Pattern9PipelineAssignRhsTest, PostDecRhsLiftsToMultiStmt) {
    auto r = rewriteAssignFor(
        "    quantum int a = 5;\n"
        "    quantum int b = 0;\n"
        "    b = a--;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "b.val = a.val; a.val -= 1;");
}

TEST(Pattern9PipelineAssignRhsTest, PureUnaryRhsStillUsesValDecoration) {
    // Regression guard: the inc/dec lift must NOT engulf pure unaries.
    // `b = -a;` is a Pattern 7-shape statement with a unary in its RHS;
    // the decorator should only append `.val` to `a`.
    auto r = rewriteAssignFor(
        "    quantum int a = 5;\n"
        "    quantum int b = 0;\n"
        "    b = -a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "b.val = -a.val;");
}

TEST(Pattern9PipelineAssignRhsTest, BitwiseNotRhsStillUsesValDecoration) {
    auto r = rewriteAssignFor(
        "    quantum int a = 5;\n"
        "    quantum int b = 0;\n"
        "    b = ~a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "b.val = ~a.val;");
}
