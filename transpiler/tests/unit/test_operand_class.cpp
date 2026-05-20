// Unit tests for OperandClass. Builds a real in-process AST via
// `buildASTFromCodeWithArgs` and walks the resulting translation unit
// to grab the initializer expression we want to classify.
//
// Per PLAN section 5.1: cover quantum var, classical var, literal,
// paren-wrapped quantum, implicit cast. We also assert null-safety and
// a binop case to lock in the "anything not a DeclRefExpr-to-quantum
// is Classical" contract.
//
// The AST-walking helpers (parseC11, collectVarDecls, allVarDecls,
// findVar) intentionally duplicate the ones in test_source_text.cpp.
// Factoring them into a shared header is its own change and explicitly
// out of scope for P4.
#include <gtest/gtest.h>

#include <memory>
#include <string>
#include <vector>

#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/Expr.h>
#include <clang/AST/Stmt.h>
#include <clang/Frontend/ASTUnit.h>
#include <clang/Tooling/Tooling.h>

#include "OperandClass.h"

namespace {

// Parse `code` as C11 with no extra arguments. Returns nullptr on failure.
std::unique_ptr<clang::ASTUnit> parseC11(const std::string &code) {
    return clang::tooling::buildASTFromCodeWithArgs(
        code, /*Args=*/{"-std=c11"}, /*FileName=*/"input.c");
}

// Recursively collect every VarDecl reachable from `d`: top-level
// VarDecls plus VarDecls inside function bodies (DeclStmt-wrapped).
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
            std::vector<const clang::Stmt *> work{fd->getBody()};
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

const clang::VarDecl *findVar(const std::vector<const clang::VarDecl *> &vars,
                              const std::string &name) {
    for (const auto *vd : vars) {
        if (vd->getNameAsString() == name) {
            return vd;
        }
    }
    return nullptr;
}

}  // namespace

// ---------------------------------------------------------------------------
// OperandClass coverage
// ---------------------------------------------------------------------------

TEST(OperandClassTest, QuantumVarIsQuantum) {
    // A bare reference to a quantum-annotated var: even though the AST
    // wraps the DeclRefExpr in an implicit lvalue-to-rvalue cast,
    // classify() must peel it off and report Quantum.
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int q = 0;\n"
        "void f(void) {\n"
        "    int r = q;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);

    auto vars = allVarDecls(unit.get());
    const clang::VarDecl *r = findVar(vars, "r");
    ASSERT_NE(r, nullptr);

    qct::OperandInfo info = qct::classify(r->getInit());
    EXPECT_EQ(info.kind, qct::OperandKind::Quantum);
    EXPECT_NE(info.expr, nullptr);
}

TEST(OperandClassTest, ClassicalVarIsClassical) {
    auto unit = parseC11(
        "int c = 0;\n"
        "void f(void) {\n"
        "    int r = c;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);

    auto vars = allVarDecls(unit.get());
    const clang::VarDecl *r = findVar(vars, "r");
    ASSERT_NE(r, nullptr);

    qct::OperandInfo info = qct::classify(r->getInit());
    EXPECT_EQ(info.kind, qct::OperandKind::Classical);
    EXPECT_NE(info.expr, nullptr);
}

TEST(OperandClassTest, LiteralIsClassical) {
    auto unit = parseC11(
        "void f(void) {\n"
        "    int r = 5;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);

    auto vars = allVarDecls(unit.get());
    const clang::VarDecl *r = findVar(vars, "r");
    ASSERT_NE(r, nullptr);

    qct::OperandInfo info = qct::classify(r->getInit());
    EXPECT_EQ(info.kind, qct::OperandKind::Classical);
    EXPECT_NE(info.expr, nullptr);
}

TEST(OperandClassTest, ParenWrappedQuantumIsQuantum) {
    // `(q)` wraps the quantum DeclRefExpr in a ParenExpr (and Clang adds
    // an implicit lvalue-to-rvalue cast either inside or outside the
    // paren). classify() must peel all layers and report Quantum, AND
    // info.expr must point at the unwrapped node — i.e. not equal to
    // the original initializer expression.
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int q = 0;\n"
        "void f(void) {\n"
        "    int r = (q);\n"
        "}\n");
    ASSERT_NE(unit, nullptr);

    auto vars = allVarDecls(unit.get());
    const clang::VarDecl *r = findVar(vars, "r");
    ASSERT_NE(r, nullptr);

    const clang::Expr *raw_init = r->getInit();
    qct::OperandInfo info = qct::classify(raw_init);
    EXPECT_EQ(info.kind, qct::OperandKind::Quantum);
    // Should have unwrapped at least one layer.
    EXPECT_NE(info.expr, raw_init);
    EXPECT_NE(info.expr, nullptr);
}

TEST(OperandClassTest, ImplicitCastUnwrap) {
    // Same as QuantumVarIsQuantum but asserts that the implicit
    // lvalue-to-rvalue cast Clang inserts around `q` is peeled — the
    // returned info.expr is not the cast node, it is the inner
    // DeclRefExpr (i.e. not the original initializer).
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int q = 0;\n"
        "void f(void) {\n"
        "    int r = q;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);

    auto vars = allVarDecls(unit.get());
    const clang::VarDecl *r = findVar(vars, "r");
    ASSERT_NE(r, nullptr);

    const clang::Expr *raw_init = r->getInit();
    qct::OperandInfo info = qct::classify(raw_init);
    EXPECT_EQ(info.kind, qct::OperandKind::Quantum);
    // The bare `q` reference is wrapped in an ImplicitCastExpr; classify
    // must unwrap it, so info.expr should not equal the original
    // initializer.
    EXPECT_NE(info.expr, raw_init);
}

TEST(OperandClassTest, NullExprIsClassical) {
    qct::OperandInfo info = qct::classify(nullptr);
    EXPECT_EQ(info.kind, qct::OperandKind::Classical);
    EXPECT_EQ(info.expr, nullptr);
}

TEST(OperandClassTest, BinopIsClassical) {
    // A binary operator never bottoms out at a DeclRefExpr after the
    // unwrap loop (which only peels Paren/ImplicitCast), so it must be
    // Classical regardless of operand kinds.
    auto unit = parseC11(
        "void f(void) {\n"
        "    int r = 1 + 2;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);

    auto vars = allVarDecls(unit.get());
    const clang::VarDecl *r = findVar(vars, "r");
    ASSERT_NE(r, nullptr);

    qct::OperandInfo info = qct::classify(r->getInit());
    EXPECT_EQ(info.kind, qct::OperandKind::Classical);
    EXPECT_NE(info.expr, nullptr);
}
