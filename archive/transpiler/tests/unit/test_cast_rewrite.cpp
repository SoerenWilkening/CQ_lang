// Unit tests for CastRewrite. Build a real in-process AST via
// `buildASTFromCodeWithArgs`, walk it to find CStyleCastExprs in
// function bodies, then call `qct::buildCastRewrite` and assert the
// returned replacement string for the measurement-as-cast pattern
// (PRD pattern #5: `(T) q` -> `cq_measure_<sfx>(q)`).
//
// M11 routes the cast's target-type QualType through
// `TypeMap::intrinsicSuffix`. Coverage: the four foundational Phase 1
// shapes; classical-cast / void-cast / null-input negatives; the
// 14-type PRD §"Type map" table; 2 typedef cases (`int32_t`,
// `uint64_t`); macro-boundary and source-location preservation
// invariants (carried through from Phase 1).
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

// Parse a function body wrapped with the `quantum` annotate macro,
// find the last CStyleCastExpr in source order (the TU walker is LIFO),
// and return its rewrite. Tests only assert on `replacement` because
// the returned `range` references storage owned by the destroyed
// ASTUnit.
std::optional<qct::CastRewrite> firstCastRewrite(const std::string &body) {
    auto unit = parseC11(
        "#define quantum __attribute__((annotate(\"quantum\")))\n"
        "void f(void) {\n" +
        body + "\n}\n");
    if (unit == nullptr) {
        return std::nullopt;
    }
    auto casts = allCStyleCasts(unit.get());
    if (casts.empty()) {
        return std::nullopt;
    }
    return qct::buildCastRewrite(casts.back(), unit->getASTContext());
}

}  // namespace

// `(int) q` where q is quantum -> `cq_measure_si32(q)`. Canonical
// measurement-as-cast pattern from PRD pattern #5.
TEST(CastRewriteTest, IntCastOfQuantumVar) {
    auto r = firstCastRewrite(
        "    quantum int q = 3;\n"
        "    int m = (int) q;");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "cq_measure_si32(q)");
}

// `(int) (q)` -> `cq_measure_si32(q)`. Operand parens stripped before
// extracting <argText> (PLAN §4.4.4 acceptance).
TEST(CastRewriteTest, IntCastOfParenthesisedQuantumVar) {
    auto r = firstCastRewrite(
        "    quantum int q = 3;\n"
        "    int m = (int) (q);");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "cq_measure_si32(q)");
}

// Classical cast `(int) c` where c is non-quantum -> nullopt.
TEST(CastRewriteTest, ClassicalCastReturnsNullopt) {
    auto r = firstCastRewrite(
        "    int c = 3;\n"
        "    int m = (int) c;");
    EXPECT_FALSE(r.has_value());
}

// `(int) q + 1`: the CStyleCastExpr's SourceRange covers only the
// `(int) q` text, so the replacement is exactly `cq_measure_si32(q)`
// — the surrounding arithmetic is left untouched by the rewriter.
TEST(CastRewriteTest, CastInsideExpressionContextRewritesOnlyTheCast) {
    auto r = firstCastRewrite(
        "    quantum int q = 3;\n"
        "    int r = (int) q + 1;");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "cq_measure_si32(q)");
}

// `(void) q;` is the unused-warning C idiom — must NOT rewrite. The
// e2e fixtures rely on this so `(void) q;` stays a no-op.
TEST(CastRewriteTest, VoidCastOfQuantumVarReturnsNullopt) {
    auto r = firstCastRewrite(
        "    quantum int q = 3;\n"
        "    (void) q;");
    EXPECT_FALSE(r.has_value());
}

// Null CStyleCastExpr* must report nullopt rather than crash.
TEST(CastRewriteTest, NullInputReturnsNullopt) {
    auto unit = parseC11("int f(void) { return 0; }\n");
    ASSERT_NE(unit, nullptr);
    EXPECT_FALSE(
        qct::buildCastRewrite(nullptr, unit->getASTContext()).has_value());
}

// 14-type table — PRD §"Type map" entry per row. Casts `quantum T q` to
// `(T)` and pins the resulting `cq_measure_<sfx>(q)`. The target type
// drives the suffix; PRD pattern #5: `(T) q` (q quantum T).

namespace {

struct TypeCase {
    const char *type;        // e.g. "signed char"
    const char *expectedSfx; // e.g. "si8"
};

// All 14 PRD §"Type map" entries. `_Bool` rather than `bool` to avoid
// the <stdbool.h> dependency.
const TypeCase kTypeMap[] = {
    {"_Bool",              "i1"},
    {"char",               "c"},
    {"signed char",        "si8"},
    {"unsigned char",      "ui8"},
    {"short",              "si16"},
    {"unsigned short",     "ui16"},
    {"int",                "si32"},
    {"unsigned int",       "ui32"},
    {"long",               "sl"},
    {"unsigned long",      "ul"},
    {"long long",          "sll"},
    {"unsigned long long", "ull"},
    {"float",              "f32"},
    {"double",             "f64"},
};

}  // namespace

TEST(CastRewriteTest, AllFourteenTypesRouteThroughIntrinsicSuffix) {
    for (const TypeCase &tc : kTypeMap) {
        const std::string body =
            std::string("    quantum ") + tc.type + " q;\n" +
            "    " + tc.type + " m = (" + tc.type + ") q;";
        auto r = firstCastRewrite(body);
        ASSERT_TRUE(r.has_value()) << "type = " << tc.type;
        EXPECT_EQ(r->replacement,
                  std::string("cq_measure_") + tc.expectedSfx + "(q)")
            << "type = " << tc.type;
    }
}

// `<stdint.h>` typedefs peel through `getCanonicalType()` inside
// TypeMap, so a cast to `int32_t` / `uint64_t` routes to the underlying
// builtin's suffix. Typedefs declared locally to avoid the system
// header dependency.

TEST(CastRewriteTest, Int32TypedefRoutesToSI32) {
    auto r = firstCastRewrite(
        "    typedef int int32_t;\n"
        "    quantum int32_t q;\n"
        "    int32_t m = (int32_t) q;");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "cq_measure_si32(q)");
}

// LP64 host: `unsigned long` is 64-bit; `uint64_t` typedefs to it and
// the intrinsic suffix is the platform-stable `ul`.
TEST(CastRewriteTest, Uint64TypedefRoutesToUL) {
    auto r = firstCastRewrite(
        "    typedef unsigned long uint64_t;\n"
        "    quantum uint64_t q;\n"
        "    uint64_t m = (uint64_t) q;");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "cq_measure_ul(q)");
}

// Macro-boundary preservation (Phase 1 invariant): a cast inside a
// macro expansion still recognizes through to its quantum operand and
// emits a usable replacement via `sm.getExpansionLoc(...)` mapping in
// buildCastRewrite.
TEST(CastRewriteTest, CastThroughMacroBoundaryStillRewrites) {
    auto r = firstCastRewrite(
        "#define MEASURE(x) ((int)(x))\n"
        "    quantum int q = 3;\n"
        "    int m = MEASURE(q);");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "cq_measure_si32(q)");
}

// Source-location preservation (Phase 1 invariant): the rewrite's
// SourceRange endpoints are valid SourceLocations. Asserted while the
// ASTUnit is still alive (range storage is owned by the unit).
TEST(CastRewriteTest, SourceLocationPreservedForRewrittenCast) {
    auto unit = parseC11(
        "#define quantum __attribute__((annotate(\"quantum\")))\n"
        "void f(void) {\n"
        "    quantum int q = 3;\n"
        "    int m = (int) q;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    auto casts = allCStyleCasts(unit.get());
    ASSERT_FALSE(casts.empty());
    auto r =
        qct::buildCastRewrite(casts.back(), unit->getASTContext());
    ASSERT_TRUE(r.has_value());
    EXPECT_TRUE(r->range.getBegin().isValid());
    EXPECT_TRUE(r->range.getEnd().isValid());
}
