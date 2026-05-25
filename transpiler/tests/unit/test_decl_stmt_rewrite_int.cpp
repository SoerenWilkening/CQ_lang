// Phase 2 M9 split — int-family unit tests for DeclStmtRewrite.
// Carries forward all Phase 1 cases and extends them with per-type
// recognition of Patterns 1–2 across the 12 int-family mid-structs in
// PRD §"Type map" plus the `<stdint.h>` typedef cases. Pattern 6 lives
// in test_decl_stmt_rewrite_pattern6.cpp; _Bool / float / double live
// in test_decl_stmt_rewrite_float.cpp. Helpers are duplicated across
// the three files (PLAN §2.4: shared header is its own change).
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
// order. Top-level VarDecls are not wrapped in DeclStmts (they appear
// directly in the AST), so this helper walks function bodies only.
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

// Parse `body` wrapped in `void f(void) { ... }` (with `quantum`
// pre-defined and <stdint.h> available for typedef cases), find the
// DeclStmt whose first VarDecl is named `name`, and return its rewrite.
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

// Phase 1 carry-forward: Patterns 1–4 for `quantum int`, plus
// multi-decl and non-quantum cases. PLAN §4.9 acceptance gate requires
// these to be byte-identical after the M3 intrinsic rename.

TEST(DeclStmtRewriteIntTest, UninitProducesPattern1) {
    auto r = rewriteDeclFor("    quantum int x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t x = cq_init_si32(0);");
}

TEST(DeclStmtRewriteIntTest, ClassicalLiteralInit) {
    auto r = rewriteDeclFor("    quantum int x = 7;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t x = cq_init_si32(7);");
}

TEST(DeclStmtRewriteIntTest, ClassicalVarInit) {
    auto r = rewriteDeclFor(
        "    int c = 3;\n"
        "    quantum int x = c;",
        "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t x = cq_init_si32(c);");
}

TEST(DeclStmtRewriteIntTest, QuantumPlusQuantum) {
    auto r = rewriteDeclFor(
        "    quantum int a = 3;\n"
        "    quantum int b = 2;\n"
        "    quantum int z = a + b;",
        "z");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t z; z.val = a.val + b.val;");
}

TEST(DeclStmtRewriteIntTest, QuantumPlusClassical) {
    auto r = rewriteDeclFor(
        "    quantum int a = 3;\n"
        "    quantum int z = a + 5;",
        "z");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t z; z.val = a.val + 5;");
}

TEST(DeclStmtRewriteIntTest, ClassicalPlusQuantumCommuted) {
    auto r = rewriteDeclFor(
        "    quantum int a = 3;\n"
        "    quantum int z = 5 + a;",
        "z");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement, "qint_mid_t z; z.val = 5 + a.val;");
}

TEST(DeclStmtRewriteIntTest, MultiQuantumDeclStmt) {
    auto r = rewriteDeclFor("    quantum int a = 3, b = 2;", "a");
    ASSERT_TRUE(r.has_value());
    EXPECT_EQ(r->replacement,
              "qint_mid_t a = cq_init_si32(3); qint_mid_t b = cq_init_si32(2);");
}

TEST(DeclStmtRewriteIntTest, NonQuantumDeclStmtReturnsNullopt) {
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

// Per-int-type Pattern 1 (uninit). M9's scope is keyword recognition —
// confirm that each C spelling produces a non-empty rewrite carrying
// the right intrinsic suffix. M10 takes over the full mid-struct-name
// threading through Codegen and adds byte-exact emission tests there.
// Plain `char` is distinct from `signed char` / `unsigned char` even
// when they share representation (C's rule, honored by TypeMap).

TEST(DeclStmtRewriteIntTest, UninitChar) {
    auto r = rewriteDeclFor("    quantum char x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_c(0)"), std::string::npos);
}

TEST(DeclStmtRewriteIntTest, UninitSignedChar) {
    auto r = rewriteDeclFor("    quantum signed char x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_si8(0)"), std::string::npos);
}

TEST(DeclStmtRewriteIntTest, UninitUnsignedChar) {
    auto r = rewriteDeclFor("    quantum unsigned char x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_ui8(0)"), std::string::npos);
}

TEST(DeclStmtRewriteIntTest, UninitShort) {
    auto r = rewriteDeclFor("    quantum short x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_si16(0)"), std::string::npos);
}

TEST(DeclStmtRewriteIntTest, UninitUnsignedShort) {
    auto r = rewriteDeclFor("    quantum unsigned short x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_ui16(0)"), std::string::npos);
}

TEST(DeclStmtRewriteIntTest, UninitUnsignedInt) {
    auto r = rewriteDeclFor("    quantum unsigned int x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_ui32(0)"), std::string::npos);
}

TEST(DeclStmtRewriteIntTest, UninitLong) {
    auto r = rewriteDeclFor("    quantum long x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_sl(0)"), std::string::npos);
}

TEST(DeclStmtRewriteIntTest, UninitUnsignedLong) {
    auto r = rewriteDeclFor("    quantum unsigned long x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_ul(0)"), std::string::npos);
}

TEST(DeclStmtRewriteIntTest, UninitLongLong) {
    auto r = rewriteDeclFor("    quantum long long x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_sll(0)"), std::string::npos);
}

TEST(DeclStmtRewriteIntTest, UninitUnsignedLongLong) {
    auto r = rewriteDeclFor("    quantum unsigned long long x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_ull(0)"), std::string::npos);
}

// Per-int-type Pattern 2 (classical literal init). Covers one type per
// signedness slot — the Uninit cases above already prove the keyword
// recognition; these confirm the classical-init path also threads the
// correct suffix.

TEST(DeclStmtRewriteIntTest, LiteralInitUnsignedChar) {
    auto r = rewriteDeclFor("    quantum unsigned char x = 7;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_ui8(7)"), std::string::npos);
}

TEST(DeclStmtRewriteIntTest, LiteralInitLong) {
    auto r = rewriteDeclFor("    quantum long x = 42;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_sl(42)"), std::string::npos);
}

TEST(DeclStmtRewriteIntTest, LiteralInitLongLong) {
    auto r = rewriteDeclFor("    quantum long long x = 99;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_sll(99)"), std::string::npos);
}

// <stdint.h> typedef cases: Clang's `getCanonicalType()` peels the
// typedef so `quantum int8_t` routes to the same entry as `quantum
// signed char` — no recognizer-level enumeration needed.

TEST(DeclStmtRewriteIntTest, UninitInt8Typedef) {
    auto r = rewriteDeclFor("    quantum int8_t x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_si8(0)"), std::string::npos);
}

TEST(DeclStmtRewriteIntTest, UninitUint32Typedef) {
    auto r = rewriteDeclFor("    quantum uint32_t x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_ui32(0)"), std::string::npos);
}
