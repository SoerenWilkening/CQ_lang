// Unit tests for CastRewrite. Build a real in-process AST via
// `buildASTFromCodeWithArgs`, walk it to find CStyleCastExprs in
// function bodies, then call `qct::buildCastRewrite` and assert the
// returned replacement string is the byte-exact Phase 1 emission for
// the measurement-as-cast pattern (PRD pattern #5).
//
// Per PLAN §4.4.4 the cases covered below are:
//
//   - `(int) q`   where q is quantum            -> "cq_measure_i32(q)"
//   - `(int) (q)` (paren stripped around q)     -> "cq_measure_i32(q)"
//   - `(int) c`   where c is non-quantum        -> nullopt
//   - cast in expr context (`(int) q + 1`)      -> rewrites only the cast
//
// All target widths use cq_measure_i32 (the issue is explicit; surrounding
// C does any truncation classically). The AST-walking helpers intentionally
// duplicate the ones in test_decl_stmt_rewrite.cpp; factoring them into a
// shared header is its own change and explicitly out of scope.
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

namespace {

std::unique_ptr<clang::ASTUnit> parseC11(const std::string &code) {
    return clang::tooling::buildASTFromCodeWithArgs(
        code, /*Args=*/{"-std=c11"}, /*FileName=*/"input.c");
}

// Walk every statement reachable from any function body and collect
// the CStyleCastExprs in source order. Top-level Decls don't contain
// expressions, so we only walk function bodies — adequate for the
// measurement-cast pattern which is always inside a function body.
void collectCStyleCasts(const clang::Decl *d,
                        std::vector<const clang::CStyleCastExpr *> *out) {
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
        if (const auto *ce = clang::dyn_cast<clang::CStyleCastExpr>(s)) {
            out->push_back(ce);
        }
        for (const clang::Stmt *child : s->children()) {
            work.push_back(child);
        }
    }
}

std::vector<const clang::CStyleCastExpr *>
allCStyleCasts(clang::ASTUnit *unit) {
    std::vector<const clang::CStyleCastExpr *> out;
    for (auto it = unit->top_level_begin(); it != unit->top_level_end(); ++it) {
        collectCStyleCasts(*it, &out);
    }
    return out;
}

// Parse a function body that uses `quantum` (predefined as the annotate
// macro), find the first CStyleCastExpr in source order, and return its
// rewrite. Returns nullopt if no cast is found or buildCastRewrite
// declines to rewrite it.
//
// The returned CastRewrite's `range` references SourceLocations owned by
// the ASTUnit which is destroyed when this helper returns — so tests
// only assert on `replacement` (a std::string that owns its storage).
std::optional<qct::CastRewrite> firstCastRewrite(const std::string &body) {
    auto unit = parseC11(
        "#define quantum __attribute__((annotate(\"quantum\")))\n"
        "void f(void) {\n" +
        body + "\n}\n");
    if (unit == nullptr) {
        return std::nullopt;
    }
    auto casts = allCStyleCasts(unit.get());
    // The TU walker is LIFO so `casts` is in reverse source order.
    // For the measurement-cast pattern, every test below has at most
    // one CStyleCastExpr anyway, so order doesn't matter for them; we
    // pick the last element to honour source order if multiple ever
    // appear.
    if (casts.empty()) {
        return std::nullopt;
    }
    const clang::CStyleCastExpr *target = casts.back();
    return qct::buildCastRewrite(target, unit->getASTContext());
}

}  // namespace

// ---------------------------------------------------------------------------
// `(int) q` where q is quantum -> `cq_measure_i32(q)`.
// The canonical measurement-as-cast pattern from PRD pattern #5.
// ---------------------------------------------------------------------------

TEST(CastRewriteTest, IntCastOfQuantumVar) {
    auto r = firstCastRewrite(
        "    quantum int q = 3;\n"
        "    int m = (int) q;");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "cq_measure_i32(q)");
}

// ---------------------------------------------------------------------------
// `(int) (q)` -> `cq_measure_i32(q)`. Operand parens are stripped before
// extracting <argText>; the test pins the PLAN §4.4.4 acceptance contract
// for paren-wrapped operands.
// ---------------------------------------------------------------------------

TEST(CastRewriteTest, IntCastOfParenthesisedQuantumVar) {
    auto r = firstCastRewrite(
        "    quantum int q = 3;\n"
        "    int m = (int) (q);");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "cq_measure_i32(q)");
}

// ---------------------------------------------------------------------------
// Classical cast: `(int) c` where c is non-quantum -> nullopt.
// Defends against accidentally rewriting plain C casts.
// ---------------------------------------------------------------------------

TEST(CastRewriteTest, ClassicalCastReturnsNullopt) {
    auto r = firstCastRewrite(
        "    int c = 3;\n"
        "    int m = (int) c;");
    EXPECT_FALSE(r.has_value());
}

// ---------------------------------------------------------------------------
// Cast inside a larger expression: `(int) q + 1`. The CStyleCastExpr's
// SourceRange must cover only the `(int) q` text — not the surrounding
// `+ 1` — so Rewriter::ReplaceText leaves the trailing arithmetic
// untouched. We can't easily assert on the SourceRange directly (it
// references storage owned by the destroyed ASTUnit), but we *can*
// assert that the replacement string is exactly `cq_measure_i32(q)`
// — without the `+ 1` — which is the externally-observable
// contract that matters.
// ---------------------------------------------------------------------------

TEST(CastRewriteTest, CastInsideExpressionContextRewritesOnlyTheCast) {
    auto r = firstCastRewrite(
        "    quantum int q = 3;\n"
        "    int r = (int) q + 1;");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "cq_measure_i32(q)");
}

// ---------------------------------------------------------------------------
// Defensive: null CStyleCastExpr* must report nullopt rather than crash.
// ---------------------------------------------------------------------------

TEST(CastRewriteTest, NullInputReturnsNullopt) {
    auto unit = parseC11("int f(void) { return 0; }\n");
    ASSERT_NE(unit, nullptr);
    EXPECT_FALSE(
        qct::buildCastRewrite(nullptr, unit->getASTContext()).has_value());
}

// ---------------------------------------------------------------------------
// Narrower target type: `(short) q` where q is `quantum int`. Per the
// issue + PLAN §4.4.4 paragraph "Width-narrower casts", ALL target
// widths use `cq_measure_i32` — the surrounding C does any truncation
// classically. This pins that policy at the unit level so a future
// width-discriminated change can't sneak through unit-test-green.
// ---------------------------------------------------------------------------

TEST(CastRewriteTest, NarrowerTargetTypeStillUsesI32) {
    auto r = firstCastRewrite(
        "    quantum int q = 3;\n"
        "    short s = (short) q;");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "cq_measure_i32(q)");
}
