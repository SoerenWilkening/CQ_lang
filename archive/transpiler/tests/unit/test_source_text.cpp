// Unit tests for QuantumAttr and SourceText. Both modules touch the
// Clang AST, so we build a real in-process AST via
// `buildASTFromCodeWithArgs` and walk the resulting translation unit
// to grab the specific Decls/Exprs we want to assert on.
//
// Per PLAN section 5.1, one test file covers both modules.
#include <gtest/gtest.h>

#include <memory>
#include <string>
#include <vector>

#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/DeclGroup.h>
#include <clang/AST/Expr.h>
#include <clang/AST/Stmt.h>
#include <clang/Frontend/ASTUnit.h>
#include <clang/Tooling/Tooling.h>

#include "QuantumAttr.h"
#include "SourceText.h"

namespace {

// Parse `code` as C11 with no extra arguments. Returns nullptr on failure.
std::unique_ptr<clang::ASTUnit> parseC11(const std::string &code) {
    return clang::tooling::buildASTFromCodeWithArgs(
        code, /*Args=*/{"-std=c11"}, /*FileName=*/"input.c");
}

// Recursively find every VarDecl reachable from a Decl: top-level
// VarDecls, plus VarDecls inside function bodies (DeclStmt-wrapped).
// Order matches source order, which is what the tests rely on.
void collectVarDecls(const clang::Decl *d,
                     std::vector<const clang::VarDecl *> *out) {
    if (d == nullptr) {
        return;
    }
    if (const auto *vd = clang::dyn_cast<clang::VarDecl>(d)) {
        out->push_back(vd);
    }
    if (const auto *fd = clang::dyn_cast<clang::FunctionDecl>(d)) {
        if (fd->hasBody()) {
            // Walk the function body looking for DeclStmts.
            const clang::Stmt *body = fd->getBody();
            std::vector<const clang::Stmt *> work{body};
            while (!work.empty()) {
                const clang::Stmt *s = work.back();
                work.pop_back();
                if (s == nullptr) {
                    continue;
                }
                if (const auto *ds = clang::dyn_cast<clang::DeclStmt>(s)) {
                    for (const clang::Decl *inner : ds->decls()) {
                        collectVarDecls(inner, out);
                    }
                }
                for (const clang::Stmt *child : s->children()) {
                    work.push_back(child);
                }
            }
        }
    }
}

std::vector<const clang::VarDecl *> allVarDecls(clang::ASTUnit *unit) {
    std::vector<const clang::VarDecl *> out;
    for (auto it = unit->top_level_begin(); it != unit->top_level_end(); ++it) {
        collectVarDecls(*it, &out);
    }
    return out;
}

}  // namespace

// ---------------------------------------------------------------------------
// QuantumAttr coverage
// ---------------------------------------------------------------------------

TEST(QuantumAttrTest, DetectsAnnotatedVarDecl) {
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int x;\n"
        "int y;\n");
    ASSERT_NE(unit, nullptr);

    auto vars = allVarDecls(unit.get());
    ASSERT_EQ(vars.size(), 2u);
    EXPECT_EQ(vars[0]->getNameAsString(), "x");
    EXPECT_EQ(vars[1]->getNameAsString(), "y");

    EXPECT_TRUE(qct::hasQuantumAttr(vars[0]));
    EXPECT_FALSE(qct::hasQuantumAttr(vars[1]));
}

TEST(QuantumAttrTest, HasQuantumAttrHandlesNull) {
    // Defensive: a null VarDecl* must report false, not crash.
    EXPECT_FALSE(qct::hasQuantumAttr(nullptr));
}

TEST(QuantumAttrTest, RefersToQuantumVarUnwrapsParensAndCasts) {
    // r1: ParenExpr around quantum DeclRefExpr  -> true
    // r2: ParenExpr around classical DeclRefExpr -> false
    // r3: bare quantum DeclRefExpr (with implicit lvalue-to-rvalue cast) -> true
    // r4: bare classical DeclRefExpr -> false
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int q = 0;\n"
        "int c = 0;\n"
        "void f(void) {\n"
        "    int r1 = (q);\n"
        "    int r2 = (c);\n"
        "    int r3 = q;\n"
        "    int r4 = c;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);

    auto vars = allVarDecls(unit.get());
    // Expect: q, c, r1, r2, r3, r4.
    ASSERT_GE(vars.size(), 6u);

    auto findByName = [&](const std::string &name) -> const clang::VarDecl * {
        for (const auto *vd : vars) {
            if (vd->getNameAsString() == name) {
                return vd;
            }
        }
        return nullptr;
    };

    const clang::VarDecl *r1 = findByName("r1");
    const clang::VarDecl *r2 = findByName("r2");
    const clang::VarDecl *r3 = findByName("r3");
    const clang::VarDecl *r4 = findByName("r4");
    ASSERT_NE(r1, nullptr);
    ASSERT_NE(r2, nullptr);
    ASSERT_NE(r3, nullptr);
    ASSERT_NE(r4, nullptr);

    EXPECT_TRUE(qct::refersToQuantumVar(r1->getInit()));
    EXPECT_FALSE(qct::refersToQuantumVar(r2->getInit()));
    EXPECT_TRUE(qct::refersToQuantumVar(r3->getInit()));
    EXPECT_FALSE(qct::refersToQuantumVar(r4->getInit()));
}

TEST(QuantumAttrTest, RefersToQuantumVarHandlesNullAndNonRef) {
    // Null is false; a non-DeclRefExpr initializer (a literal) is false.
    EXPECT_FALSE(qct::refersToQuantumVar(nullptr));

    auto unit = parseC11("int k = 7;\n");
    ASSERT_NE(unit, nullptr);
    auto vars = allVarDecls(unit.get());
    ASSERT_EQ(vars.size(), 1u);
    EXPECT_FALSE(qct::refersToQuantumVar(vars[0]->getInit()));
}

// ---------------------------------------------------------------------------
// SourceText coverage
// ---------------------------------------------------------------------------

TEST(SourceTextTest, LiteralInitializer) {
    auto unit = parseC11("int z = 1 + 2;\n");
    ASSERT_NE(unit, nullptr);
    auto vars = allVarDecls(unit.get());
    ASSERT_EQ(vars.size(), 1u);

    const auto &sm = unit->getSourceManager();
    const auto &lo = unit->getLangOpts();
    EXPECT_EQ(qct::getExprText(vars[0]->getInit(), sm, lo), "1 + 2");
}

TEST(SourceTextTest, ParenInitializer) {
    auto unit = parseC11("int y = (3);\n");
    ASSERT_NE(unit, nullptr);
    auto vars = allVarDecls(unit.get());
    ASSERT_EQ(vars.size(), 1u);

    const auto &sm = unit->getSourceManager();
    const auto &lo = unit->getLangOpts();
    EXPECT_EQ(qct::getExprText(vars[0]->getInit(), sm, lo), "(3)");
}

TEST(SourceTextTest, BinopWithCallInitializer) {
    // Place inside a function body so `5 + foo()` is a valid local
    // initializer (C disallows non-constant initializers at file scope).
    auto unit = parseC11(
        "int foo(void);\n"
        "void g(void) {\n"
        "    int x = 5 + foo();\n"
        "}\n");
    ASSERT_NE(unit, nullptr);

    auto vars = allVarDecls(unit.get());
    ASSERT_EQ(vars.size(), 1u);
    EXPECT_EQ(vars[0]->getNameAsString(), "x");

    const auto &sm = unit->getSourceManager();
    const auto &lo = unit->getLangOpts();
    EXPECT_EQ(qct::getExprText(vars[0]->getInit(), sm, lo), "5 + foo()");
}

TEST(SourceTextTest, MultiLineInitializer) {
    // Multi-line expression: exact whitespace not asserted, but both
    // boundary tokens must be present so we know the full range was
    // captured rather than truncated at the first line.
    auto unit = parseC11("int w = 1\n  + 2;\n");
    ASSERT_NE(unit, nullptr);
    auto vars = allVarDecls(unit.get());
    ASSERT_EQ(vars.size(), 1u);

    const auto &sm = unit->getSourceManager();
    const auto &lo = unit->getLangOpts();
    std::string text = qct::getExprText(vars[0]->getInit(), sm, lo);
    EXPECT_FALSE(text.empty());
    EXPECT_NE(text.find('1'), std::string::npos);
    EXPECT_NE(text.find('2'), std::string::npos);
}

TEST(SourceTextTest, NullExprReturnsEmpty) {
    auto unit = parseC11("int q = 0;\n");
    ASSERT_NE(unit, nullptr);
    const auto &sm = unit->getSourceManager();
    const auto &lo = unit->getLangOpts();
    EXPECT_EQ(qct::getExprText(nullptr, sm, lo), "");
}
