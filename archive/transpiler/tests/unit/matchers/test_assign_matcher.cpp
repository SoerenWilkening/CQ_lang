// Unit tests for AssignMatcher (Phase 3 M7). Covers PRD Patterns 7
// (plain assign with quantum LHS) and 8 (CompoundAssignOperator with
// quantum LHS).
//
// Cases:
//   - `a = a + 1` (quantum LHS, binop RHS) → matched, BO_Assign,
//     isCompound=false. The RHS-binop recognition is BinopMatcher's
//     job; AssignMatcher only reports the assignment itself.
//   - `b = c + 1` (classical LHS) → not matched.
//   - `a += 1`, `a *= 1` etc. (quantum LHS) → matched, isCompound=true,
//     opcode is the compound opcode, compoundUnderlyingOpcode is the
//     equivalent binop opcode.
//   - `c += 1` (classical LHS) → not matched.
//   - Null Stmt → not matched.
//
// Covers all ten Phase 3 compound-assign opcodes in a single
// parametrized check.
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

#include "AssignMatcher.h"
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

const clang::Stmt *firstAssignLike(const clang::FunctionDecl *fd) {
    return findFirstStmt(fd, [](const clang::Stmt *st) {
        if (clang::isa<clang::CompoundAssignOperator>(st)) return true;
        if (const auto *bo = clang::dyn_cast<clang::BinaryOperator>(st)) {
            return bo->getOpcode() == clang::BO_Assign;
        }
        return false;
    });
}

}  // namespace

// ---------------------------------------------------------------------------
// Pattern 7 — plain assignment (BO_Assign)
// ---------------------------------------------------------------------------

TEST(AssignMatcherTest, QuantumLHSPlainAssignAddIsMatched) {
    // `a = a + 1` — the assignment has a quantum LHS; the RHS happens
    // to be `a + 1` (which BinopMatcher would also pick up, but
    // AssignMatcher only reports the assignment).
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int a = 0;\n"
        "void f(void) {\n"
        "    a = a + 1;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Stmt *s = firstAssignLike(findFunction(unit.get(), "f"));
    ASSERT_NE(s, nullptr);

    qct::AssignMatch m = qct::matchAssign(s);
    EXPECT_TRUE(m.matched);
    EXPECT_FALSE(m.isCompound);
    EXPECT_EQ(m.opcode, clang::BO_Assign);
    EXPECT_EQ(m.lhs.kind, qct::OperandKind::Quantum);
}

TEST(AssignMatcherTest, ClassicalLHSPlainAssignIsNotMatched) {
    // `b = c + 1` — classical LHS, must not match.
    auto unit = parseC11(
        "void f(void) {\n"
        "    int b = 0; int c = 0;\n"
        "    b = c + 1;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Stmt *s = firstAssignLike(findFunction(unit.get(), "f"));
    ASSERT_NE(s, nullptr);

    qct::AssignMatch m = qct::matchAssign(s);
    EXPECT_FALSE(m.matched);
}

TEST(AssignMatcherTest, QuantumLHSPlainAssignWithClassicalRHSIsMatched) {
    // `a = 5` — quantum LHS, classical RHS. Still a Pattern 7 rewrite
    // candidate: `a.val = 5;`.
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int a = 0;\n"
        "void f(void) {\n"
        "    a = 5;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Stmt *s = firstAssignLike(findFunction(unit.get(), "f"));
    ASSERT_NE(s, nullptr);

    qct::AssignMatch m = qct::matchAssign(s);
    EXPECT_TRUE(m.matched);
    EXPECT_FALSE(m.isCompound);
    EXPECT_EQ(m.opcode, clang::BO_Assign);
    EXPECT_EQ(m.lhs.kind, qct::OperandKind::Quantum);
    EXPECT_EQ(m.rhs.kind, qct::OperandKind::Classical);
}

// ---------------------------------------------------------------------------
// Pattern 8 — compound assignment (CompoundAssignOperator)
// ---------------------------------------------------------------------------

TEST(AssignMatcherTest, QuantumLHSCompoundAddAssignIsMatched) {
    // `a += 1` — the canonical Pattern 8 fixture from the issue.
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int a = 0;\n"
        "void f(void) {\n"
        "    a += 1;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Stmt *s = firstAssignLike(findFunction(unit.get(), "f"));
    ASSERT_NE(s, nullptr);

    qct::AssignMatch m = qct::matchAssign(s);
    EXPECT_TRUE(m.matched);
    EXPECT_TRUE(m.isCompound);
    EXPECT_EQ(m.opcode, clang::BO_AddAssign);
    EXPECT_EQ(m.compoundUnderlyingOpcode, clang::BO_Add);
    EXPECT_EQ(m.lhs.kind, qct::OperandKind::Quantum);
}

TEST(AssignMatcherTest, QuantumLHSCompoundMulAssignIsMatched) {
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int a = 0;\n"
        "void f(void) {\n"
        "    a *= 2;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Stmt *s = firstAssignLike(findFunction(unit.get(), "f"));
    ASSERT_NE(s, nullptr);

    qct::AssignMatch m = qct::matchAssign(s);
    EXPECT_TRUE(m.matched);
    EXPECT_TRUE(m.isCompound);
    EXPECT_EQ(m.opcode, clang::BO_MulAssign);
    EXPECT_EQ(m.compoundUnderlyingOpcode, clang::BO_Mul);
}

TEST(AssignMatcherTest, QuantumLHSCompoundShlAssignIsMatched) {
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int a = 0;\n"
        "void f(void) {\n"
        "    a <<= 1;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Stmt *s = firstAssignLike(findFunction(unit.get(), "f"));
    ASSERT_NE(s, nullptr);

    qct::AssignMatch m = qct::matchAssign(s);
    EXPECT_TRUE(m.matched);
    EXPECT_TRUE(m.isCompound);
    EXPECT_EQ(m.opcode, clang::BO_ShlAssign);
    EXPECT_EQ(m.compoundUnderlyingOpcode, clang::BO_Shl);
}

TEST(AssignMatcherTest, QuantumLHSCompoundAndAssignIsMatched) {
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int a = 0;\n"
        "void f(void) {\n"
        "    a &= 0xff;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Stmt *s = firstAssignLike(findFunction(unit.get(), "f"));
    ASSERT_NE(s, nullptr);

    qct::AssignMatch m = qct::matchAssign(s);
    EXPECT_TRUE(m.matched);
    EXPECT_TRUE(m.isCompound);
    EXPECT_EQ(m.opcode, clang::BO_AndAssign);
    EXPECT_EQ(m.compoundUnderlyingOpcode, clang::BO_And);
}

TEST(AssignMatcherTest, ClassicalLHSCompoundAssignIsNotMatched) {
    // `c += 1` — classical LHS, must not match.
    auto unit = parseC11(
        "void f(void) {\n"
        "    int c = 0;\n"
        "    c += 1;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Stmt *s = firstAssignLike(findFunction(unit.get(), "f"));
    ASSERT_NE(s, nullptr);

    qct::AssignMatch m = qct::matchAssign(s);
    EXPECT_FALSE(m.matched);
}

// ---------------------------------------------------------------------------
// Negative shapes
// ---------------------------------------------------------------------------

TEST(AssignMatcherTest, BareBinopIsNotMatched) {
    // `a + 1` (no assignment) — must not be matched by AssignMatcher.
    // BinopMatcher's territory.
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int a = 0;\n"
        "void f(void) {\n"
        "    int r = a + 1;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::Stmt *s = findFirstStmt(
        findFunction(unit.get(), "f"),
        [](const clang::Stmt *st) {
            const auto *bo = clang::dyn_cast<clang::BinaryOperator>(st);
            return bo != nullptr && bo->getOpcode() == clang::BO_Add;
        });
    ASSERT_NE(s, nullptr);

    qct::AssignMatch m = qct::matchAssign(s);
    EXPECT_FALSE(m.matched);
}

TEST(AssignMatcherTest, NullStmtIsNotMatched) {
    qct::AssignMatch m = qct::matchAssign(nullptr);
    EXPECT_FALSE(m.matched);
}
