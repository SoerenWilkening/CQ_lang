// Unit tests for UnaryMatcher (Phase 3 M7). Covers PRD Pattern 9: the
// seven unary opcodes that may appear on a quantum operand.
//
// Cases per opcode (operand is `q` declared quantum):
//   - UO_Minus   `-q`
//   - UO_Not     `~q`
//   - UO_LNot    `!q`
//   - UO_PreInc  `++q`
//   - UO_PostInc `q++`
//   - UO_PreDec  `--q`
//   - UO_PostDec `q--`
//
// Negative cases:
//   - Classical operand (`-c` where `c` is classical) → not matched
//   - UO_Plus (`+q`) → not matched (clang folds, but if it appears, we
//     deliberately exclude it from Phase 3's surface)
//   - Non-UnaryOperator Stmt → not matched
//   - Null Stmt → not matched
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

#include "OperandClass.h"
#include "UnaryMatcher.h"

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

const clang::UnaryOperator *firstUnaryOp(const clang::FunctionDecl *fd) {
    const clang::Stmt *s = findFirstStmt(fd, [](const clang::Stmt *st) {
        return clang::isa<clang::UnaryOperator>(st);
    });
    return clang::dyn_cast_or_null<clang::UnaryOperator>(s);
}

// Run a single positive-case test: parse `body`, find the first unary
// op, assert it matched with the expected opcode. Defined here to keep
// each per-opcode TEST short.
void expectMatchedWithOpcode(const std::string &body,
                             clang::UnaryOperatorKind expected) {
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int q = 0;\n"
        "void f(void) {\n" +
        body +
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::UnaryOperator *uo = firstUnaryOp(findFunction(unit.get(), "f"));
    ASSERT_NE(uo, nullptr);
    qct::UnaryMatch m = qct::matchUnary(uo);
    EXPECT_TRUE(m.matched);
    EXPECT_EQ(m.opcode, expected);
    EXPECT_EQ(m.operand.kind, qct::OperandKind::Quantum);
}

}  // namespace

// ---------------------------------------------------------------------------
// Per-opcode positive cases (quantum operand)
// ---------------------------------------------------------------------------

TEST(UnaryMatcherTest, MinusOnQuantumIsMatched) {
    expectMatchedWithOpcode("    int r = -q;\n", clang::UO_Minus);
}

TEST(UnaryMatcherTest, BitwiseNotOnQuantumIsMatched) {
    expectMatchedWithOpcode("    int r = ~q;\n", clang::UO_Not);
}

TEST(UnaryMatcherTest, LogicalNotOnQuantumIsMatched) {
    expectMatchedWithOpcode("    int r = !q;\n", clang::UO_LNot);
}

TEST(UnaryMatcherTest, PreIncOnQuantumIsMatched) {
    expectMatchedWithOpcode("    ++q;\n", clang::UO_PreInc);
}

TEST(UnaryMatcherTest, PostIncOnQuantumIsMatched) {
    expectMatchedWithOpcode("    q++;\n", clang::UO_PostInc);
}

TEST(UnaryMatcherTest, PreDecOnQuantumIsMatched) {
    expectMatchedWithOpcode("    --q;\n", clang::UO_PreDec);
}

TEST(UnaryMatcherTest, PostDecOnQuantumIsMatched) {
    expectMatchedWithOpcode("    q--;\n", clang::UO_PostDec);
}

// ---------------------------------------------------------------------------
// Negative cases
// ---------------------------------------------------------------------------

TEST(UnaryMatcherTest, MinusOnClassicalIsNotMatched) {
    auto unit = parseC11(
        "void f(void) {\n"
        "    int c = 0;\n"
        "    int r = -c;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::UnaryOperator *uo = firstUnaryOp(findFunction(unit.get(), "f"));
    ASSERT_NE(uo, nullptr);

    qct::UnaryMatch m = qct::matchUnary(uo);
    EXPECT_FALSE(m.matched);
}

TEST(UnaryMatcherTest, UnaryPlusIsExcluded) {
    // UO_Plus is not in Phase 3's set. Confirm we don't accidentally
    // recognize it even on a quantum operand. Clang generally folds
    // `+q` to a no-op but the UnaryOperator node still appears
    // pre-fold, so this test forces the matcher to be explicit.
    auto unit = parseC11(
        "__attribute__((annotate(\"quantum\"))) int q = 0;\n"
        "void f(void) {\n"
        "    int r = +q;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::UnaryOperator *uo = firstUnaryOp(findFunction(unit.get(), "f"));
    if (uo == nullptr) {
        // Some clang builds fold +q away before the AST settles. If
        // that happens, the test is vacuous — there is no UnaryOperator
        // to inspect, so PASS.
        SUCCEED() << "clang folded UO_Plus before AST stabilised";
        return;
    }
    qct::UnaryMatch m = qct::matchUnary(uo);
    EXPECT_FALSE(m.matched);
}

TEST(UnaryMatcherTest, NonUnaryStmtIsNotMatched) {
    auto unit = parseC11(
        "void f(void) {\n"
        "    int r = 5;\n"
        "}\n");
    ASSERT_NE(unit, nullptr);
    const clang::FunctionDecl *fd = findFunction(unit.get(), "f");
    ASSERT_NE(fd, nullptr);
    // Hand the matcher a DeclStmt — not a UnaryOperator.
    const clang::Stmt *body = fd->getBody();
    ASSERT_NE(body, nullptr);

    qct::UnaryMatch m = qct::matchUnary(body);
    EXPECT_FALSE(m.matched);
}

TEST(UnaryMatcherTest, NullStmtIsNotMatched) {
    qct::UnaryMatch m = qct::matchUnary(nullptr);
    EXPECT_FALSE(m.matched);
}
