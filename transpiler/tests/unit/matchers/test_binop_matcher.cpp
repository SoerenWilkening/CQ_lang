// Unit tests for BinopMatcher (Phase 3 M7). The matcher is the
// extracted Phase 2 binop recognition layer: given an already-unwrapped
// Expr, it returns whether the Expr is a binary operator with at least
// one quantum operand, along with the opcode and operand
// classifications. DeclStmtRewrite delegates to this matcher in Phase 2
// regression mode; M8 wires the Codegen split into it.
//
// Test coverage:
//   - Quantum + Classical add (`q + 1`) → matched, BO_Add, lhs=Quantum
//   - Quantum + Quantum add (`q + q2`) → matched, BO_Add, both Quantum
//   - Classical + Classical add (`1 + 2`) → not matched
//   - Plain assignment (`q = 1`) is excluded (AssignMatcher's job)
//   - Compound assignment (`q += 1`) is excluded (AssignMatcher's job)
//   - Null Expr → not matched
//
// AST extraction mirrors operand_class/test_assign_lhs.cpp.
#include <gtest/gtest.h>

#include <memory>
#include <string>
#include <vector>

#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/Expr.h>
#include <clang/AST/OperationKinds.h>
#include <clang/AST/Stmt.h>
#include <clang/Frontend/ASTUnit.h>
#include <clang/Tooling/Tooling.h>

#include "BinopMatcher.h"
#include "OperandClass.h"

namespace {

std::unique_ptr<clang::ASTUnit> parseC11(const std::string &code) {
    return clang::tooling::buildASTFromCodeWithArgs(
        code, /*Args=*/{"-std=c11"}, /*FileName=*/"input.c");
}

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

// Strip ParenExpr/ImplicitCastExpr layers in order to expose the
// underlying binop / assignment / unary node. Mirrors the unwrap loop
// in DeclStmtRewrite::populateFromInit so the matcher inputs we test
// look like what the production caller passes in.
const clang::Expr *unwrap(const clang::Expr *e) {
    if (e == nullptr) {
        return nullptr;
    }
    for (;;) {
        if (const auto *pe = clang::dyn_cast<clang::ParenExpr>(e)) {
            e = pe->getSubExpr();
            continue;
        }
        if (const auto *ice = clang::dyn_cast<clang::ImplicitCastExpr>(e)) {
            e = ice->getSubExpr();
            continue;
        }
        break;
    }
    return e;
}

// Pull the initializer of the VarDecl named `name` from `fd`'s body,
// already unwrapped. Returns nullptr if not found.
const clang::Expr *findVarInit(const clang::FunctionDecl *fd,
                               const std::string &name) {
    if (fd == nullptr || !fd->hasBody()) {
        return nullptr;
    }
    std::vector<const clang::Stmt *> work{fd->getBody()};
    while (!work.empty()) {
        const clang::Stmt *s = work.back();
        work.pop_back();
        if (s == nullptr) continue;
        if (const auto *ds = clang::dyn_cast<clang::DeclStmt>(s)) {
            for (const clang::Decl *d : ds->decls()) {
                if (const auto *vd = clang::dyn_cast<clang::VarDecl>(d)) {
                    if (vd->getNameAsString() == name) {
                        return unwrap(vd->getInit());
                    }
                }
            }
        }
        for (const clang::Stmt *c : s->children()) {
            work.push_back(c);
        }
    }
    return nullptr;
}

// Pull the first statement matching `pred` from `fd`'s body.
template <typename Pred>
const clang::Stmt *findFirstStmt(const clang::FunctionDecl *fd, Pred pred) {
    if (fd == nullptr || !fd->hasBody()) return nullptr;
    std::vector<const clang::Stmt *> work{fd->getBody()};
    while (!work.empty()) {
        const clang::Stmt *s = work.back();
        work.pop_back();
        if (s == nullptr) continue;
        if (pred(s)) return s;
        std::vector<const clang::Stmt *> kids(s->child_begin(), s->child_end());
        for (auto it = kids.rbegin(); it != kids.rend(); ++it) {
            work.push_back(*it);
        }
    }
    return nullptr;
}

}  // namespace

TEST(BinopMatcherTest, QuantumPlusClassicalIsMatched) {
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int q = 0;\n"
        "void f(void) {\n"
        "    int r = q + 1;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Expr *init = findVarInit(findFunction(unit.get(), "f"), "r");
    ASSERT_NE(init, nullptr);

    qct::BinopMatch m = qct::matchBinop(init);
    EXPECT_TRUE(m.matched);
    EXPECT_EQ(m.opcode, clang::BO_Add);
    EXPECT_EQ(m.lhs.kind, qct::OperandKind::Quantum);
    EXPECT_EQ(m.rhs.kind, qct::OperandKind::Classical);
}

TEST(BinopMatcherTest, QuantumPlusQuantumIsMatched) {
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int a = 0;\n"
        "__attribute__((annotate(\"quantum\"))) int b = 0;\n"
        "void f(void) {\n"
        "    int r = a + b;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Expr *init = findVarInit(findFunction(unit.get(), "f"), "r");
    ASSERT_NE(init, nullptr);

    qct::BinopMatch m = qct::matchBinop(init);
    EXPECT_TRUE(m.matched);
    EXPECT_EQ(m.opcode, clang::BO_Add);
    EXPECT_EQ(m.lhs.kind, qct::OperandKind::Quantum);
    EXPECT_EQ(m.rhs.kind, qct::OperandKind::Quantum);
}

TEST(BinopMatcherTest, ClassicalPlusClassicalIsNotMatched) {
    auto unit = parseC11(
        "void f(void) {\n"
        "    int r = 1 + 2;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Expr *init = findVarInit(findFunction(unit.get(), "f"), "r");
    ASSERT_NE(init, nullptr);

    qct::BinopMatch m = qct::matchBinop(init);
    EXPECT_FALSE(m.matched);
}

TEST(BinopMatcherTest, PlainAssignIsExcluded) {
    // `q = 1` is a BinaryOperator with BO_Assign — it must NOT be
    // matched by BinopMatcher. AssignMatcher owns that case (Pattern 7).
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int q = 0;\n"
        "void f(void) {\n"
        "    q = 1;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Stmt *assign = findFirstStmt(
        findFunction(unit.get(), "f"),
        [](const clang::Stmt *st) {
            const auto *bo = clang::dyn_cast<clang::BinaryOperator>(st);
            return bo != nullptr && bo->getOpcode() == clang::BO_Assign;
        });
    ASSERT_NE(assign, nullptr);

    qct::BinopMatch m = qct::matchBinop(clang::dyn_cast<clang::Expr>(assign));
    EXPECT_FALSE(m.matched);
}

TEST(BinopMatcherTest, CompoundAssignIsExcluded) {
    // `q += 1` is a CompoundAssignOperator (which inherits from
    // BinaryOperator). It must NOT be matched by BinopMatcher;
    // AssignMatcher owns that case (Pattern 8).
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int q = 0;\n"
        "void f(void) {\n"
        "    q += 1;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Stmt *cao = findFirstStmt(
        findFunction(unit.get(), "f"),
        [](const clang::Stmt *st) {
            return clang::isa<clang::CompoundAssignOperator>(st);
        });
    ASSERT_NE(cao, nullptr);

    qct::BinopMatch m = qct::matchBinop(clang::dyn_cast<clang::Expr>(cao));
    EXPECT_FALSE(m.matched);
}

TEST(BinopMatcherTest, NullExprIsNotMatched) {
    qct::BinopMatch m = qct::matchBinop(nullptr);
    EXPECT_FALSE(m.matched);
}
