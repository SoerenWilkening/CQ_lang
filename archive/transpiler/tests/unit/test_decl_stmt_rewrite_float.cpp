// Phase 2 M9 split — non-int unit tests for DeclStmtRewrite. Covers
// the three "non-int width" PRD §"Type map" entries: `_Bool`, `float`,
// `double`. `_Bool` is grouped with floats here (rather than with ints
// in test_decl_stmt_rewrite_int.cpp) because its recognition path —
// LLVM IR width is fixed at `i1` regardless of `TargetInfo::getBoolWidth()`
// — looks more like the floats' fixed `f32`/`f64` widths than like the
// target-dependent int widths. Helpers are duplicated from the int and
// pattern6 splits per PLAN §2.4 (shared header out of scope for M9).
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

// `<stdbool.h>` makes `bool` available as an alias for `_Bool`; the
// keyword cases below need this preamble even when the body uses
// `_Bool` directly so the include is present unconditionally.
std::optional<qct::StmtRewrite> rewriteDeclFor(const std::string &body,
                                               const std::string &name) {
    auto unit = parseC11(
        "#include <stdbool.h>\n"
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

// M9's scope is keyword recognition + Pattern 6 detection. The non-int
// Pattern 1/2 assertions below are substring-only against the cq_init
// suffix; M10 owns the full mid-struct-name threading through Codegen
// and adds byte-exact emission tests there.

// _Bool — recognized as the C99 builtin; intrinsic suffix `i1` (LLVM
// IR value-type width is always 1, regardless of
// `TargetInfo::getBoolWidth()` reporting 8 as ABI storage).

TEST(DeclStmtRewriteFloatTest, UninitBool) {
    auto r = rewriteDeclFor("    quantum _Bool x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_i1(0)"), std::string::npos);
}

TEST(DeclStmtRewriteFloatTest, LiteralInitBool) {
    auto r = rewriteDeclFor("    quantum _Bool x = 1;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_i1(1)"), std::string::npos);
}

// `bool` from <stdbool.h> resolves to `_Bool` post-preprocessing, so
// the rewriter sees the same VarDecl shape as the `_Bool` case above.
// PRD §"Open items" entry "<stdbool.h> interaction" — locked in here
// at the unit layer in addition to its e2e fixture.

TEST(DeclStmtRewriteFloatTest, UninitBoolKeyword) {
    auto r = rewriteDeclFor("    quantum bool x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_i1(0)"), std::string::npos);
}

// float — `f32` suffix per PRD §"Type map".

TEST(DeclStmtRewriteFloatTest, UninitFloat) {
    auto r = rewriteDeclFor("    quantum float x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_f32(0)"), std::string::npos);
}

TEST(DeclStmtRewriteFloatTest, LiteralInitFloat) {
    auto r = rewriteDeclFor("    quantum float x = 3.5f;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_f32(3.5f)"), std::string::npos);
}

// double — `f64` suffix.

TEST(DeclStmtRewriteFloatTest, UninitDouble) {
    auto r = rewriteDeclFor("    quantum double x;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_f64(0)"), std::string::npos);
}

TEST(DeclStmtRewriteFloatTest, LiteralInitDouble) {
    auto r = rewriteDeclFor("    quantum double x = 2.71828;", "x");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("cq_init_f64(2.71828)"), std::string::npos);
}

// Pattern 3 (Q+Q add) for floats — the .val arithmetic emission is
// type-agnostic so the suffix substring assertion proves the path
// works for floats. Full mid-struct-name assertion belongs to M10.

TEST(DeclStmtRewriteFloatTest, FloatQuantumPlusQuantum) {
    auto r = rewriteDeclFor(
        "    quantum float a = 1.0f;\n"
        "    quantum float b = 2.0f;\n"
        "    quantum float z = a + b;",
        "z");
    ASSERT_TRUE(r.has_value());
    EXPECT_NE(r->replacement.find("z.val = a.val + b.val;"),
              std::string::npos);
}
