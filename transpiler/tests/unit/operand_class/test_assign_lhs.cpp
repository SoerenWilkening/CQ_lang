// Unit tests for OperandClass extensions added in phase3-M6:
// `classifyAssignLHS` (Patterns 7 / 8 assignment LHS) and
// `classifyUnaryOperand` (Pattern 9 unary operand). Both share the
// peel-and-check predicate with the existing `classify`; these tests
// lock in their behaviour at the public-API boundary so a future
// divergence (e.g. unary-specific filtering) is caught.
//
// The AST-walking helpers (parseC11, collectVarDecls, allVarDecls,
// findVar) deliberately mirror test_operand_class.cpp — that is the
// established pattern in this directory and factoring the duplication
// into a shared header is its own change, out of scope for M6.
//
// Cases per helper:
//   (a) quantum VarDecl LHS / operand → Quantum
//   (b) classical VarDecl LHS / operand → Classical
//   (c) integer literal → Classical (cannot legally be an assign LHS
//       in C, but the helper is a pure predicate and must still
//       answer for any Expr* the call site hands it)
//   (d) nullptr → Classical with expr == nullptr
//
// AST extraction: for assignments we walk the function body for a
// BinaryOperator (BO_Assign) or CompoundAssignOperator and pull
// getLHS(); for unary operands we find a UnaryOperator and pull
// getSubExpr(). The literal/nullptr cases call the helpers directly
// with synthetic inputs.
#include <gtest/gtest.h>

#include <memory>
#include <string>
#include <vector>

#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/Expr.h>
#include <clang/AST/ExprCXX.h>
#include <clang/AST/OperationKinds.h>
#include <clang/AST/Stmt.h>
#include <clang/Frontend/ASTUnit.h>
#include <clang/Tooling/Tooling.h>

#include "OperandClass.h"

namespace {

// Parse `code` as C11; nullptr on failure.
std::unique_ptr<clang::ASTUnit> parseC11(const std::string &code) {
    return clang::tooling::buildASTFromCodeWithArgs(
        code, /*Args=*/{"-std=c11"}, /*FileName=*/"input.c");
}

// Walk a function body and return the first statement matching `pred`,
// or nullptr. Children are explored in depth-first source-order.
template <typename Pred>
const clang::Stmt *findFirstStmt(const clang::FunctionDecl *fd, Pred pred) {
    if (fd == nullptr || !fd->hasBody()) {
        return nullptr;
    }
    std::vector<const clang::Stmt *> work{fd->getBody()};
    while (!work.empty()) {
        const clang::Stmt *s = work.back();
        work.pop_back();
        if (s == nullptr) {
            continue;
        }
        if (pred(s)) {
            return s;
        }
        // Push children in reverse so depth-first walk matches source order.
        std::vector<const clang::Stmt *> kids(s->child_begin(), s->child_end());
        for (auto it = kids.rbegin(); it != kids.rend(); ++it) {
            work.push_back(*it);
        }
    }
    return nullptr;
}

// Locate the FunctionDecl named `name` at translation-unit scope.
const clang::FunctionDecl *findFunction(clang::ASTUnit *unit,
                                        const std::string &name) {
    for (auto it = unit->top_level_begin(); it != unit->top_level_end(); ++it) {
        const auto *fd = clang::dyn_cast<clang::FunctionDecl>(*it);
        if (fd != nullptr && fd->getNameAsString() == name) {
            return fd;
        }
    }
    return nullptr;
}

// Pull the LHS of the first BinaryOperator / CompoundAssignOperator in
// `fd`'s body. Returns nullptr if none is found.
const clang::Expr *firstAssignLHS(const clang::FunctionDecl *fd) {
    const clang::Stmt *s = findFirstStmt(fd, [](const clang::Stmt *st) {
        if (const auto *bo = clang::dyn_cast<clang::BinaryOperator>(st)) {
            return bo->getOpcode() == clang::BO_Assign;
        }
        return clang::isa<clang::CompoundAssignOperator>(st);
    });
    if (const auto *bo = clang::dyn_cast_or_null<clang::BinaryOperator>(s)) {
        return bo->getLHS();
    }
    return nullptr;
}

// Pull the sub-expression of the first UnaryOperator in `fd`'s body.
const clang::Expr *firstUnaryOperand(const clang::FunctionDecl *fd) {
    const clang::Stmt *s = findFirstStmt(fd, [](const clang::Stmt *st) {
        return clang::isa<clang::UnaryOperator>(st);
    });
    if (const auto *uo = clang::dyn_cast_or_null<clang::UnaryOperator>(s)) {
        return uo->getSubExpr();
    }
    return nullptr;
}

}  // namespace

// ---------------------------------------------------------------------------
// classifyAssignLHS
// ---------------------------------------------------------------------------

TEST(ClassifyAssignLHSTest, QuantumLHSIsQuantum) {
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int q = 0;\n"
        "void f(void) {\n"
        "    q = 1;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Expr *lhs = firstAssignLHS(findFunction(unit.get(), "f"));
    ASSERT_NE(lhs, nullptr);

    qct::OperandInfo info = qct::classifyAssignLHS(lhs);
    EXPECT_EQ(info.kind, qct::OperandKind::Quantum);
    EXPECT_NE(info.expr, nullptr);
}

TEST(ClassifyAssignLHSTest, ClassicalLHSIsClassical) {
    auto unit = parseC11(
        "int c = 0;\n"
        "void f(void) {\n"
        "    c = 1;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Expr *lhs = firstAssignLHS(findFunction(unit.get(), "f"));
    ASSERT_NE(lhs, nullptr);

    qct::OperandInfo info = qct::classifyAssignLHS(lhs);
    EXPECT_EQ(info.kind, qct::OperandKind::Classical);
    EXPECT_NE(info.expr, nullptr);
}

TEST(ClassifyAssignLHSTest, IntegerLiteralIsClassical) {
    // A literal is not a legal LHS in C, but the helper is a pure
    // predicate: anything that does not bottom out at a quantum
    // DeclRefExpr must be Classical. We extract a literal from a
    // synthetic initializer and pass it straight in.
    auto unit = parseC11(
        "void f(void) {\n"
        "    int r = 5;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);

    // Grab the initializer of `r` — that's a (possibly-cast-wrapped)
    // IntegerLiteral, which after peeling is non-DeclRefExpr.
    const clang::FunctionDecl *fd = findFunction(unit.get(), "f");
    ASSERT_NE(fd, nullptr);
    const clang::Expr *literal_init = nullptr;
    for (const clang::Stmt *st : fd->getBody()->children()) {
        if (const auto *ds = clang::dyn_cast<clang::DeclStmt>(st)) {
            for (const clang::Decl *d : ds->decls()) {
                if (const auto *vd = clang::dyn_cast<clang::VarDecl>(d)) {
                    if (vd->getNameAsString() == "r") {
                        literal_init = vd->getInit();
                    }
                }
            }
        }
    }
    ASSERT_NE(literal_init, nullptr);

    qct::OperandInfo info = qct::classifyAssignLHS(literal_init);
    EXPECT_EQ(info.kind, qct::OperandKind::Classical);
    EXPECT_NE(info.expr, nullptr);
}

TEST(ClassifyAssignLHSTest, NullIsClassical) {
    qct::OperandInfo info = qct::classifyAssignLHS(nullptr);
    EXPECT_EQ(info.kind, qct::OperandKind::Classical);
    EXPECT_EQ(info.expr, nullptr);
}

// ---------------------------------------------------------------------------
// classifyUnaryOperand
// ---------------------------------------------------------------------------

TEST(ClassifyUnaryOperandTest, QuantumOperandIsQuantum) {
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int q = 0;\n"
        "void f(void) {\n"
        "    int r = -q;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Expr *opnd = firstUnaryOperand(findFunction(unit.get(), "f"));
    ASSERT_NE(opnd, nullptr);

    qct::OperandInfo info = qct::classifyUnaryOperand(opnd);
    EXPECT_EQ(info.kind, qct::OperandKind::Quantum);
    EXPECT_NE(info.expr, nullptr);
}

TEST(ClassifyUnaryOperandTest, ClassicalOperandIsClassical) {
    auto unit = parseC11(
        "int c = 0;\n"
        "void f(void) {\n"
        "    int r = -c;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Expr *opnd = firstUnaryOperand(findFunction(unit.get(), "f"));
    ASSERT_NE(opnd, nullptr);

    qct::OperandInfo info = qct::classifyUnaryOperand(opnd);
    EXPECT_EQ(info.kind, qct::OperandKind::Classical);
    EXPECT_NE(info.expr, nullptr);
}

TEST(ClassifyUnaryOperandTest, IntegerLiteralIsClassical) {
    // `-5` produces a UnaryOperator whose operand is an IntegerLiteral
    // (possibly through implicit casts). After peeling, the operand is
    // not a DeclRefExpr — must be Classical.
    auto unit = parseC11(
        "void f(void) {\n"
        "    int r = -5;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Expr *opnd = firstUnaryOperand(findFunction(unit.get(), "f"));
    ASSERT_NE(opnd, nullptr);

    qct::OperandInfo info = qct::classifyUnaryOperand(opnd);
    EXPECT_EQ(info.kind, qct::OperandKind::Classical);
    EXPECT_NE(info.expr, nullptr);
}

TEST(ClassifyUnaryOperandTest, NullIsClassical) {
    qct::OperandInfo info = qct::classifyUnaryOperand(nullptr);
    EXPECT_EQ(info.kind, qct::OperandKind::Classical);
    EXPECT_EQ(info.expr, nullptr);
}
