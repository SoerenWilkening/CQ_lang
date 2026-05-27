// Phase 2 M9 split — Pattern-6 detection tests for DeclStmtRewrite.
// PRD §"Rewriter patterns" row 6: `quantum T b = a;` (a quantum
// VarDecl of the same canonical type) lowers to `qT_mid_t b; b.val =
// a.val;` — no `cq_copy_<sfx>` intrinsic (PRD §"On assignment and
// surviving operations"). Negative cases: cross-type assignment and
// classical-source assignment both fall back to ClassicalInit.
// Helpers duplicated from the int/float splits per PLAN §2.4.
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

bool firstDeclNamed(const clang::DeclStmt *ds, const std::string &name) {
    for (const clang::Decl *d : ds->decls()) {
        if (const auto *vd = clang::dyn_cast<clang::VarDecl>(d)) {
            return vd->getNameAsString() == name;
        }
    }
    return false;
}

std::optional<qct::StmtRewrite> rewriteDeclFor(const std::string &body,
                                               const std::string &name) {
    auto unit = parseC11(
        "#include <stdint.h>\n"
        "#define quantum __attribute__((annotate(\"quantum\")))\n"
        "void f(void) {\n" +
        body + "\n}\n");
    if (unit == nullptr) {
        return std::nullopt;
    }
    auto stmts = allDeclStmts(unit.get());
    for (const clang::DeclStmt *ds : stmts) {
        if (firstDeclNamed(ds, name)) {
            return qct::buildRewrite(ds, unit->getASTContext());
        }
    }
    return std::nullopt;
}

}  // namespace

// Positive: `quantum int b = a;` lowers to the QuantumCopy split form.
// `a` must itself be a quantum-annotated VarDecl of the same canonical
// type; the rewriter checks both gates and the renderer threads the
// mid-struct name from TypeMap.

TEST(DeclStmtRewritePattern6Test, IntCopy) {
    auto r = rewriteDeclFor(
        "    quantum int a = 3;\n"
        "    quantum int b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t b; b.val = a.val;");
}

// Positive across the other 13 mid-struct types. One per type — the
// recognition path is uniform (intrinsicSuffix + midStructName lookup),
// so a smaller sample is enough to catch keyword/typedef regressions.

TEST(DeclStmtRewritePattern6Test, BoolCopy) {
    auto r = rewriteDeclFor(
        "    quantum _Bool a = 1;\n"
        "    quantum _Bool b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qbool_mid_t b; b.val = a.val;");
}

TEST(DeclStmtRewritePattern6Test, CharCopy) {
    auto r = rewriteDeclFor(
        "    quantum char a = 7;\n"
        "    quantum char b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qchar_mid_t b; b.val = a.val;");
}

TEST(DeclStmtRewritePattern6Test, SignedCharCopy) {
    auto r = rewriteDeclFor(
        "    quantum signed char a = 7;\n"
        "    quantum signed char b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qschar_mid_t b; b.val = a.val;");
}

TEST(DeclStmtRewritePattern6Test, UnsignedCharCopy) {
    auto r = rewriteDeclFor(
        "    quantum unsigned char a = 7;\n"
        "    quantum unsigned char b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "quchar_mid_t b; b.val = a.val;");
}

TEST(DeclStmtRewritePattern6Test, ShortCopy) {
    auto r = rewriteDeclFor(
        "    quantum short a = 7;\n"
        "    quantum short b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qshort_mid_t b; b.val = a.val;");
}

TEST(DeclStmtRewritePattern6Test, UnsignedShortCopy) {
    auto r = rewriteDeclFor(
        "    quantum unsigned short a = 7;\n"
        "    quantum unsigned short b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qushort_mid_t b; b.val = a.val;");
}

TEST(DeclStmtRewritePattern6Test, UnsignedIntCopy) {
    auto r = rewriteDeclFor(
        "    quantum unsigned int a = 7;\n"
        "    quantum unsigned int b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "quint_mid_t b; b.val = a.val;");
}

TEST(DeclStmtRewritePattern6Test, LongCopy) {
    auto r = rewriteDeclFor(
        "    quantum long a = 7;\n"
        "    quantum long b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qlong_mid_t b; b.val = a.val;");
}

TEST(DeclStmtRewritePattern6Test, UnsignedLongCopy) {
    auto r = rewriteDeclFor(
        "    quantum unsigned long a = 7;\n"
        "    quantum unsigned long b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qulong_mid_t b; b.val = a.val;");
}

TEST(DeclStmtRewritePattern6Test, LongLongCopy) {
    auto r = rewriteDeclFor(
        "    quantum long long a = 7;\n"
        "    quantum long long b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qlonglong_mid_t b; b.val = a.val;");
}

TEST(DeclStmtRewritePattern6Test, FloatCopy) {
    auto r = rewriteDeclFor(
        "    quantum float a = 3.5f;\n"
        "    quantum float b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qfloat_mid_t b; b.val = a.val;");
}

TEST(DeclStmtRewritePattern6Test, DoubleCopy) {
    auto r = rewriteDeclFor(
        "    quantum double a = 2.7;\n"
        "    quantum double b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qdouble_mid_t b; b.val = a.val;");
}

// Typedef positive: `quantum int8_t b = a;` where `a` is `quantum
// signed char` (both canonicalise to `signed char`). Confirms the
// canonical-type comparison rather than spelling-equality drives
// Pattern-6 detection.

TEST(DeclStmtRewritePattern6Test, TypedefCanonicalMatch) {
    auto r = rewriteDeclFor(
        "    quantum signed char a = 7;\n"
        "    quantum int8_t b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qschar_mid_t b; b.val = a.val;");
}

// Cross-type Q→Q: Pattern 11 (Phase 3 M9). `quantum int b = a;` where
// `a` is `quantum long` emits a cross-copy with a narrowing cast on
// `.val`. Phase 2 routed this to ClassicalInit; Phase 3 handles it.

TEST(DeclStmtRewritePattern6Test, CrossTypeEmitsQuantumCrossCopy) {
    auto r = rewriteDeclFor(
        "    quantum long a = 7;\n"
        "    quantum int b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t b; b.val = (int) a.val;");
}

// Negative: assigning from a classical (non-quantum) variable does
// NOT match Pattern 6 even when the types match. The source must
// itself be quantum-annotated.

TEST(DeclStmtRewritePattern6Test, ClassicalSourceFallsToClassicalInit) {
    auto r = rewriteDeclFor(
        "    int a = 7;\n"
        "    quantum int b = a;",
        "b");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t b = cq_init_si32(a);");
}

// Multi-decl: `quantum int a, b = 0;` should still produce two
// classical inits — `a` is uninit (Pattern 1) and `b` is a classical
// literal (Pattern 2). Neither matches Pattern 6 because the only
// DeclRefExpr-from-quantum candidate is `a`, and `b`'s initializer is
// the literal `0`. PLAN §4.9 lists this as a required carry-forward.

TEST(DeclStmtRewritePattern6Test, MultiDeclClassicalInitsUnchanged) {
    auto r = rewriteDeclFor("    quantum int a, b = 0;", "a");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement,
              "qint_mid_t a = cq_init_si32(0); qint_mid_t b = cq_init_si32(0);");
}
