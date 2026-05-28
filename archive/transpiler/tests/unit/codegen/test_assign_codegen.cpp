// Unit tests for AssignCodegen (Phase 3 M8). Pure string assembly —
// the emitter is Clang-free, so we hand it fully-populated
// AssignEmitInput structs and compare against the byte-exact expected
// output documented in PRD §"Rewriter patterns" Patterns 7 (plain
// assign) and 8 (compound assign), and PLAN §6.5 (compound preservation).
//
// Pattern 7 goldens:
//   `a = b + 1;` (a, b quantum)  →  `a.val = b.val + 1;`
//   `a = 5;`     (a quantum)      →  `a.val = 5;`
//   `a = b;`     (a, b quantum)   →  `a.val = b.val;`
//
// Pattern 8 goldens (PLAN §6.5 — compound preserved, not expanded):
//   `a += b;`  →  `a.val += b.val;`
//   `a -= 1;`  →  `a.val -= 1;`
//   `a *= 2;`  →  `a.val *= 2;`
//   `a /= 2;`  →  `a.val /= 2;`
//   `a %= 3;`  →  `a.val %= 3;`
//   `a &= 0xff;` → `a.val &= 0xff;`
//   `a |= 1;`  →  `a.val |= 1;`
//   `a ^= 1;`  →  `a.val ^= 1;`
//   `a <<= 1;` →  `a.val <<= 1;`
//   `a >>= 1;` →  `a.val >>= 1;`
#include <gtest/gtest.h>

#include <string>

#include <clang/AST/OperationKinds.h>

#include "AssignCodegen.h"

using qct::AssignEmitInput;
using qct::assignOperatorToken;
using qct::emitAssign;

namespace {

// Build an AssignEmitInput inline so each test reads as a single line of
// "input → expected".
AssignEmitInput input(const std::string &lhs, const std::string &rhs,
                      clang::BinaryOperatorKind op) {
    AssignEmitInput in{};
    in.lhsName = lhs;
    in.rhsExpr = rhs;
    in.opcode = op;
    return in;
}

}  // namespace

// ---------------------------------------------------------------------------
// assignOperatorToken — confirm every Phase 3 assignment opcode maps to
// the correct C operator spelling. Pure lookup; one row per opcode.
// ---------------------------------------------------------------------------

TEST(AssignCodegenTest, OperatorTokenAssign) {
    EXPECT_EQ(assignOperatorToken(clang::BO_Assign), "=");
}

TEST(AssignCodegenTest, OperatorTokenAddAssign) {
    EXPECT_EQ(assignOperatorToken(clang::BO_AddAssign), "+=");
}

TEST(AssignCodegenTest, OperatorTokenSubAssign) {
    EXPECT_EQ(assignOperatorToken(clang::BO_SubAssign), "-=");
}

TEST(AssignCodegenTest, OperatorTokenMulAssign) {
    EXPECT_EQ(assignOperatorToken(clang::BO_MulAssign), "*=");
}

TEST(AssignCodegenTest, OperatorTokenDivAssign) {
    EXPECT_EQ(assignOperatorToken(clang::BO_DivAssign), "/=");
}

TEST(AssignCodegenTest, OperatorTokenRemAssign) {
    EXPECT_EQ(assignOperatorToken(clang::BO_RemAssign), "%=");
}

TEST(AssignCodegenTest, OperatorTokenAndAssign) {
    EXPECT_EQ(assignOperatorToken(clang::BO_AndAssign), "&=");
}

TEST(AssignCodegenTest, OperatorTokenOrAssign) {
    EXPECT_EQ(assignOperatorToken(clang::BO_OrAssign), "|=");
}

TEST(AssignCodegenTest, OperatorTokenXorAssign) {
    EXPECT_EQ(assignOperatorToken(clang::BO_XorAssign), "^=");
}

TEST(AssignCodegenTest, OperatorTokenShlAssign) {
    EXPECT_EQ(assignOperatorToken(clang::BO_ShlAssign), "<<=");
}

TEST(AssignCodegenTest, OperatorTokenShrAssign) {
    EXPECT_EQ(assignOperatorToken(clang::BO_ShrAssign), ">>=");
}

// ---------------------------------------------------------------------------
// Pattern 7 (plain assign) — `a = ...;` becomes `a.val = ...;`.
// ---------------------------------------------------------------------------

TEST(AssignCodegenTest, Pattern7BinopRHS) {
    // The canonical Pattern 7 fixture from the issue: `a = b + 1;` ->
    // `a.val = b.val + 1;`. The RHS arrives pre-decorated from the
    // caller (AssignRewrite walks the binop, appends `.val` to the
    // quantum operand, and hands us "b.val + 1").
    EXPECT_EQ(emitAssign(input("a", "b.val + 1", clang::BO_Assign)),
              "a.val = b.val + 1;");
}

TEST(AssignCodegenTest, Pattern7ClassicalRHS) {
    // `a = 5;` (a quantum, RHS is a literal). The decorated RHS has
    // nothing to do here — the caller just hands us the literal text.
    EXPECT_EQ(emitAssign(input("a", "5", clang::BO_Assign)),
              "a.val = 5;");
}

TEST(AssignCodegenTest, Pattern7QuantumOnlyRHS) {
    // `a = b;` (both quantum, no binop). The caller decorates "b" to
    // "b.val" before handing us the RHS.
    EXPECT_EQ(emitAssign(input("a", "b.val", clang::BO_Assign)),
              "a.val = b.val;");
}

TEST(AssignCodegenTest, Pattern7QuantumMinusQuantum) {
    // `a = b - c;` exercises a non-Add binop on the RHS — confirms the
    // emitter doesn't hardcode `+` (the operator token comes from the
    // RHS text the caller hands us).
    EXPECT_EQ(emitAssign(input("a", "b.val - c.val", clang::BO_Assign)),
              "a.val = b.val - c.val;");
}

TEST(AssignCodegenTest, Pattern7ComplexClassicalRHS) {
    // `a = (3 + foo()) * 2;` — confirms the RHS is spliced verbatim,
    // preserving precedence-bearing parens and call syntax. Same code
    // path as the literal case but with a more interesting decoration.
    EXPECT_EQ(emitAssign(input("a", "(3 + foo()) * 2", clang::BO_Assign)),
              "a.val = (3 + foo()) * 2;");
}

// ---------------------------------------------------------------------------
// Pattern 8 (compound assign) — `a += b;` becomes `a.val += b.val;`.
// PLAN §6.5: the compound operator is preserved; the emitter does NOT
// expand `a += b` into `a = a + b`.
// ---------------------------------------------------------------------------

TEST(AssignCodegenTest, Pattern8AddAssignQQ) {
    // The canonical Pattern 8 fixture from the issue: `a += b;` ->
    // `a.val += b.val;`. Compound operator preserved.
    EXPECT_EQ(emitAssign(input("a", "b.val", clang::BO_AddAssign)),
              "a.val += b.val;");
}

TEST(AssignCodegenTest, Pattern8AddAssignQC) {
    // `a += 1;` — quantum LHS, classical RHS.
    EXPECT_EQ(emitAssign(input("a", "1", clang::BO_AddAssign)),
              "a.val += 1;");
}

TEST(AssignCodegenTest, Pattern8SubAssign) {
    EXPECT_EQ(emitAssign(input("a", "b.val", clang::BO_SubAssign)),
              "a.val -= b.val;");
}

TEST(AssignCodegenTest, Pattern8MulAssign) {
    EXPECT_EQ(emitAssign(input("a", "2", clang::BO_MulAssign)),
              "a.val *= 2;");
}

TEST(AssignCodegenTest, Pattern8DivAssign) {
    EXPECT_EQ(emitAssign(input("a", "2", clang::BO_DivAssign)),
              "a.val /= 2;");
}

TEST(AssignCodegenTest, Pattern8RemAssign) {
    EXPECT_EQ(emitAssign(input("a", "3", clang::BO_RemAssign)),
              "a.val %= 3;");
}

TEST(AssignCodegenTest, Pattern8AndAssign) {
    EXPECT_EQ(emitAssign(input("a", "0xff", clang::BO_AndAssign)),
              "a.val &= 0xff;");
}

TEST(AssignCodegenTest, Pattern8OrAssign) {
    EXPECT_EQ(emitAssign(input("a", "1", clang::BO_OrAssign)),
              "a.val |= 1;");
}

TEST(AssignCodegenTest, Pattern8XorAssign) {
    EXPECT_EQ(emitAssign(input("a", "1", clang::BO_XorAssign)),
              "a.val ^= 1;");
}

TEST(AssignCodegenTest, Pattern8ShlAssign) {
    EXPECT_EQ(emitAssign(input("a", "1", clang::BO_ShlAssign)),
              "a.val <<= 1;");
}

TEST(AssignCodegenTest, Pattern8ShrAssign) {
    EXPECT_EQ(emitAssign(input("a", "1", clang::BO_ShrAssign)),
              "a.val >>= 1;");
}

TEST(AssignCodegenTest, Pattern8DoesNotExpandCompound) {
    // Explicit guard against the `a += b` → `a = a + b` expansion. The
    // operator MUST be `+=`, not `=`, and the LHS must NOT appear on
    // the RHS — both checks fall out naturally from
    // assignOperatorToken's literal emission.
    const std::string out = emitAssign(input("a", "b.val",
                                             clang::BO_AddAssign));
    EXPECT_NE(out.find("+="), std::string::npos);
    EXPECT_EQ(out.find("a + b.val"), std::string::npos);
    EXPECT_EQ(out.find("a.val + b.val"), std::string::npos);
}
