// Unit tests for UnaryCodegen (Phase 3 M8). Pure string assembly — the
// emitter is Clang-free, so we hand it fully-populated UnaryEmitInput
// structs and compare against the byte-exact expected output documented
// in PRD §"Rewriter patterns" Pattern 9 and PLAN §6.4 (prefix-vs-postfix
// ordering rationale).
//
// Pure-unary goldens (no destination — emits an expression):
//   `-a`  →  `-a.val`
//   `~a`  →  `~a.val`
//   `!a`  →  `!a.val`
//
// Inc/dec multi-statement goldens (per PLAN §6.4):
//   `b = ++a;`  →  `a.val += 1; b.val = a.val;`   (modify-then-propagate)
//   `b = --a;`  →  `a.val -= 1; b.val = a.val;`   (modify-then-propagate)
//   `b = a++;`  →  `b.val = a.val; a.val += 1;`   (propagate-then-modify)
//   `b = a--;`  →  `b.val = a.val; a.val -= 1;`   (propagate-then-modify)
//
// Standalone inc/dec goldens (no value consumer):
//   `++a;` and `a++;`  →  `a.val += 1;`           (pre/post collapse)
//   `--a;` and `a--;`  →  `a.val -= 1;`
#include <gtest/gtest.h>

#include <string>

#include <clang/AST/OperationKinds.h>

#include "UnaryCodegen.h"

using qct::emitUnary;
using qct::UnaryEmitInput;

namespace {

// Build a UnaryEmitInput inline. `dest` defaults to the empty string
// for the cases that have no value consumer.
UnaryEmitInput input(clang::UnaryOperatorKind op,
                     const std::string &operandName,
                     const std::string &destExpr = "") {
    UnaryEmitInput in{};
    in.opcode = op;
    in.operandName = operandName;
    in.destExpr = destExpr;
    return in;
}

}  // namespace

// ---------------------------------------------------------------------------
// Pure-unary cases (UO_Minus, UO_Not, UO_LNot). The emitter returns an
// expression (no trailing semicolon); the caller splices the result
// into a surrounding assignment context.
// ---------------------------------------------------------------------------

TEST(UnaryCodegenTest, Pattern9MinusOperand) {
    EXPECT_EQ(emitUnary(input(clang::UO_Minus, "a")), "-a.val");
}

TEST(UnaryCodegenTest, Pattern9BitwiseNotOperand) {
    EXPECT_EQ(emitUnary(input(clang::UO_Not, "a")), "~a.val");
}

TEST(UnaryCodegenTest, Pattern9LogicalNotOperand) {
    EXPECT_EQ(emitUnary(input(clang::UO_LNot, "a")), "!a.val");
}

TEST(UnaryCodegenTest, Pattern9MinusOperandWithDestIgnored) {
    // Pure unaries ignore `destExpr` (the caller never sets it for
    // pure unaries, but the emitter must not crash if it's populated).
    EXPECT_EQ(emitUnary(input(clang::UO_Minus, "a", "b.val")), "-a.val");
}

TEST(UnaryCodegenTest, Pattern9MultiCharOperandName) {
    // Defensive: operand identifier with multiple characters splices
    // intact (no character-by-character handling).
    EXPECT_EQ(emitUnary(input(clang::UO_Minus, "alpha")), "-alpha.val");
}

// ---------------------------------------------------------------------------
// Inc/dec with destination — multi-statement expansion per PLAN §6.4.
//
// Prefix (++a / --a): modify operand FIRST, then propagate to dest.
//   The C semantics of `b = ++a` are "the value of `++a` is the new
//   value of a"; we reproduce that by writing the operand-modify
//   statement before the destination-propagate statement.
//
// Postfix (a++ / a--): propagate operand value FIRST, then modify
// operand. The C semantics of `b = a++` are "the value of `a++` is
// the prior value of a"; we reproduce that by writing the propagate
// statement first so it captures the original value.
// ---------------------------------------------------------------------------

TEST(UnaryCodegenTest, Pattern9PreIncWithDest) {
    // Canonical fixture from the issue:
    //   `b = ++a;` → `a.val += 1; b.val = a.val;`
    EXPECT_EQ(emitUnary(input(clang::UO_PreInc, "a", "b.val")),
              "a.val += 1; b.val = a.val;");
}

TEST(UnaryCodegenTest, Pattern9PostIncWithDest) {
    // Canonical fixture from the issue:
    //   `b = a++;` → `b.val = a.val; a.val += 1;`
    EXPECT_EQ(emitUnary(input(clang::UO_PostInc, "a", "b.val")),
              "b.val = a.val; a.val += 1;");
}

TEST(UnaryCodegenTest, Pattern9PreDecWithDest) {
    EXPECT_EQ(emitUnary(input(clang::UO_PreDec, "a", "b.val")),
              "a.val -= 1; b.val = a.val;");
}

TEST(UnaryCodegenTest, Pattern9PostDecWithDest) {
    EXPECT_EQ(emitUnary(input(clang::UO_PostDec, "a", "b.val")),
              "b.val = a.val; a.val -= 1;");
}

// ---------------------------------------------------------------------------
// Standalone inc/dec (no value consumer). The pre-vs-post distinction
// is irrelevant when the value is discarded; both shapes collapse to
// just the modification.
// ---------------------------------------------------------------------------

TEST(UnaryCodegenTest, Pattern9StandalonePreInc) {
    // `++a;` as a statement (no surrounding assignment / initializer).
    EXPECT_EQ(emitUnary(input(clang::UO_PreInc, "a")), "a.val += 1;");
}

TEST(UnaryCodegenTest, Pattern9StandalonePostInc) {
    // `a++;` — discarded value, same emission as the prefix form.
    EXPECT_EQ(emitUnary(input(clang::UO_PostInc, "a")), "a.val += 1;");
}

TEST(UnaryCodegenTest, Pattern9StandalonePreDec) {
    EXPECT_EQ(emitUnary(input(clang::UO_PreDec, "a")), "a.val -= 1;");
}

TEST(UnaryCodegenTest, Pattern9StandalonePostDec) {
    EXPECT_EQ(emitUnary(input(clang::UO_PostDec, "a")), "a.val -= 1;");
}

// ---------------------------------------------------------------------------
// Defensive: ordering invariants for inc/dec must hold. These tests
// pin the prefix/postfix ordering rule against accidental swap.
// ---------------------------------------------------------------------------

TEST(UnaryCodegenTest, Pattern9PrefixOrdering) {
    // Modify statement must come BEFORE the propagate statement for
    // any prefix opcode. PLAN §6.4 — "modify-first" semantics.
    const std::string out =
        emitUnary(input(clang::UO_PreInc, "a", "b.val"));
    const auto modify = out.find("a.val += 1;");
    const auto propagate = out.find("b.val = a.val;");
    ASSERT_NE(modify, std::string::npos);
    ASSERT_NE(propagate, std::string::npos);
    EXPECT_LT(modify, propagate);
}

TEST(UnaryCodegenTest, Pattern9PostfixOrdering) {
    // Propagate statement must come BEFORE the modify statement for
    // any postfix opcode. PLAN §6.4 — "propagate-first" semantics.
    const std::string out =
        emitUnary(input(clang::UO_PostInc, "a", "b.val"));
    const auto propagate = out.find("b.val = a.val;");
    const auto modify = out.find("a.val += 1;");
    ASSERT_NE(propagate, std::string::npos);
    ASSERT_NE(modify, std::string::npos);
    EXPECT_LT(propagate, modify);
}
