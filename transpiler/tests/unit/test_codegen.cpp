// Unit tests for Codegen. Pure string assembly — no Clang AST needed,
// so we just hand the renderer fully-populated VarRewriteInput structs
// and compare against the byte-exact expected output documented in the
// PRD "Supported source patterns (v1)" table and PLAN section 3.5.
//
// Per PLAN section 5.1: one test per Form (5) + a multi-decl case.
// We also pin down the empty-vector contract and a non-16 bit width
// (the formatter must pass any unsigned width through unchanged).
#include <gtest/gtest.h>

#include <vector>

#include "Codegen.h"

using qct::renderDeclStmt;
using qct::renderVar;
using qct::VarRewriteInput;

// ---------------------------------------------------------------------------
// One test per Form. The expected strings are byte-exact — spacing
// (`init_qint(0, 16)`, comma-space, etc.) is part of the contract and
// matches example_v1.expected.c at the project root.
// ---------------------------------------------------------------------------

TEST(CodegenTest, Uninit) {
    // Pattern 1: `quantum int x;` -> `qint_t x = init_qint(0, 16);`.
    // The `0` literal is hardcoded by the renderer (it's the canonical
    // zero-init value), so initText is intentionally left empty.
    VarRewriteInput in{};
    in.name = "x";
    in.numBits = 16;
    in.form = VarRewriteInput::Form::Uninit;
    EXPECT_EQ(renderVar(in), "qint_t x = init_qint(0, 16);");
}

TEST(CodegenTest, ClassicalInit) {
    // Pattern 2: classical expression survives verbatim inside
    // init_qint(...). Whitespace inside the user expression (here:
    // none — `3+f()`) is preserved exactly as it was spliced in.
    VarRewriteInput in{};
    in.name = "x";
    in.numBits = 16;
    in.form = VarRewriteInput::Form::ClassicalInit;
    in.initText = "3+f()";
    EXPECT_EQ(renderVar(in), "qint_t x = init_qint(3+f(), 16);");
}

TEST(CodegenTest, QuantumPlusQuantum) {
    // Pattern 3: both sides are already qint_t — pass through as
    // identifiers to add(...), no wrapping.
    VarRewriteInput in{};
    in.name = "c";
    in.numBits = 16;
    in.form = VarRewriteInput::Form::QuantumPlusQuantum;
    in.lhsName = "a";
    in.rhsName = "b";
    EXPECT_EQ(renderVar(in), "qint_t c = add(a, b);");
}

TEST(CodegenTest, QuantumPlusClassical) {
    // Pattern 4: only the classical (rhs) operand gets wrapped.
    VarRewriteInput in{};
    in.name = "c";
    in.numBits = 16;
    in.form = VarRewriteInput::Form::QuantumPlusClassical;
    in.lhsName = "a";
    in.rhsText = "5";
    EXPECT_EQ(renderVar(in), "qint_t c = add(a, init_qint(5, 16));");
}

TEST(CodegenTest, ClassicalPlusQuantum) {
    // Pattern 4 commuted: only the classical (lhs) operand gets wrapped.
    VarRewriteInput in{};
    in.name = "c";
    in.numBits = 16;
    in.form = VarRewriteInput::Form::ClassicalPlusQuantum;
    in.lhsText = "5";
    in.rhsName = "a";
    EXPECT_EQ(renderVar(in), "qint_t c = add(init_qint(5, 16), a);");
}

// ---------------------------------------------------------------------------
// Multi-decl + boundary cases.
// ---------------------------------------------------------------------------

TEST(CodegenTest, MultiDecl) {
    // PLAN 3.5 example: two-element vector joined with a single ASCII
    // space. This mirrors the multi-decl row of example_v1.expected.c:
    //   `quantum int a = 3, b = 2;`
    //     ->
    //   `qint_t a = init_qint(0, 16); qint_t b = init_qint(2, 16);`
    // (Here we test {Uninit a, ClassicalInit b=2}; the same join logic
    // would produce `init_qint(3, ...)` if `a` were ClassicalInit.)
    std::vector<VarRewriteInput> vars;
    {
        VarRewriteInput a{};
        a.name = "a";
        a.numBits = 16;
        a.form = VarRewriteInput::Form::Uninit;
        vars.push_back(a);
    }
    {
        VarRewriteInput b{};
        b.name = "b";
        b.numBits = 16;
        b.form = VarRewriteInput::Form::ClassicalInit;
        b.initText = "2";
        vars.push_back(b);
    }
    EXPECT_EQ(renderDeclStmt(vars),
              "qint_t a = init_qint(0, 16); qint_t b = init_qint(2, 16);");
}

TEST(CodegenTest, EmptyMultiDecl) {
    // Defensive contract: an empty input vector yields an empty
    // replacement (so the caller can no-op a DeclStmt that lost all
    // its quantum decls).
    EXPECT_EQ(renderDeclStmt({}), "");
}

// ---------------------------------------------------------------------------
// Bit-width variations. PRD's table calls for 1/8/16/32/64; the
// formatter must pass any unsigned width through unchanged as plain
// decimal with no leading zeros.
// ---------------------------------------------------------------------------

TEST(CodegenTest, BitWidthBool) {
    // `quantum bool b;` -> 1-bit init.
    VarRewriteInput in{};
    in.name = "b";
    in.numBits = 1;
    in.form = VarRewriteInput::Form::Uninit;
    EXPECT_EQ(renderVar(in), "qint_t b = init_qint(0, 1);");
}

TEST(CodegenTest, BitWidthLongLong) {
    // `quantum long long y = 7;` -> 64-bit init.
    VarRewriteInput in{};
    in.name = "y";
    in.numBits = 64;
    in.form = VarRewriteInput::Form::ClassicalInit;
    in.initText = "7";
    EXPECT_EQ(renderVar(in), "qint_t y = init_qint(7, 64);");
}

TEST(CodegenTest, BitWidthPropagatesIntoMixedAdd) {
    // The classical operand inside add() must be wrapped with the
    // result's bit width, not some hardcoded 16. Use 8 (char) to
    // confirm the formatter actually threads numBits into the wrapper.
    VarRewriteInput in{};
    in.name = "c";
    in.numBits = 8;
    in.form = VarRewriteInput::Form::QuantumPlusClassical;
    in.lhsName = "a";
    in.rhsText = "k";
    EXPECT_EQ(renderVar(in), "qint_t c = add(a, init_qint(k, 8));");
}
