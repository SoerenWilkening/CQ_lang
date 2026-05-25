// Unit tests for Codegen. Pure string assembly — no Clang AST needed,
// so we just hand the renderer fully-populated VarRewriteInput structs
// and compare against the byte-exact expected output documented in
// PLAN §4.4.2.
//
// Phase 1's Form enum collapses to three values: Uninit, ClassicalInit,
// QuantumAdd. The tests below cover one byte-exact emission per Form
// (with a mixed-operand QuantumAdd to exercise that the renderer
// splices both sides verbatim regardless of quantum-ness), plus the
// multi-decl join, an empty-vector defensive contract, and a non-si32
// width to defend against accidental hard-coding of the suffix.
#include <gtest/gtest.h>

#include <vector>

#include "Codegen.h"

using qct::renderDeclStmt;
using qct::renderVar;
using qct::VarRewriteInput;

// ---------------------------------------------------------------------------
// One test per Form. The expected strings are byte-exact — spacing,
// the `qint_mid_t` type name, and the `cq_init_<W>` / `.val` shapes
// are all part of the contract (PLAN §4.4.2).
// ---------------------------------------------------------------------------

TEST(CodegenTest, Uninit) {
    // `quantum int x;` -> `qint_mid_t x = cq_init_si32(0);`.
    // The literal `0` is hardcoded by the renderer (it's the canonical
    // zero-init value), so initText is intentionally left empty.
    VarRewriteInput in{};
    in.name = "x";
    in.widthSuffix = "si32";
    in.form = VarRewriteInput::Form::Uninit;
    EXPECT_EQ(renderVar(in), "qint_mid_t x = cq_init_si32(0);");
}

TEST(CodegenTest, ClassicalInit) {
    // `quantum int x = 3+f();` -> the classical expression survives
    // verbatim inside cq_init_<W>(...). Whitespace inside the user
    // expression (here: none — `3+f()`) is preserved exactly as it
    // was spliced in by the caller.
    VarRewriteInput in{};
    in.name = "x";
    in.widthSuffix = "si32";
    in.form = VarRewriteInput::Form::ClassicalInit;
    in.initText = "3+f()";
    EXPECT_EQ(renderVar(in), "qint_mid_t x = cq_init_si32(3+f());");
}

TEST(CodegenTest, QuantumAddBothQuantum) {
    // `quantum int c = a + b;` where both a and b are quantum.
    // DeclStmtRewrite decorates the operands as "a.val" / "b.val"
    // before handing them to Codegen, which splices both verbatim.
    VarRewriteInput in{};
    in.name = "c";
    in.widthSuffix = "si32";
    in.form = VarRewriteInput::Form::QuantumAdd;
    in.lhsExpr = "a.val";
    in.rhsExpr = "b.val";
    EXPECT_EQ(renderVar(in),
              "qint_mid_t c; c.val = a.val + b.val;");
}

TEST(CodegenTest, QuantumAddQuantumPlusClassical) {
    // `quantum int c = a + 5;` — quantum lhs, classical rhs. The lhs
    // is already decorated; the rhs is the raw classical source text.
    // Codegen does NOT branch on operand quantum-ness — both sides go
    // through the same splicing path.
    VarRewriteInput in{};
    in.name = "c";
    in.widthSuffix = "si32";
    in.form = VarRewriteInput::Form::QuantumAdd;
    in.lhsExpr = "a.val";
    in.rhsExpr = "5";
    EXPECT_EQ(renderVar(in),
              "qint_mid_t c; c.val = a.val + 5;");
}

TEST(CodegenTest, QuantumAddClassicalPlusQuantum) {
    // `quantum int c = 5 + a;` — commuted mixed-operand. Same path,
    // just with the decorated operand on the right.
    VarRewriteInput in{};
    in.name = "c";
    in.widthSuffix = "si32";
    in.form = VarRewriteInput::Form::QuantumAdd;
    in.lhsExpr = "5";
    in.rhsExpr = "a.val";
    EXPECT_EQ(renderVar(in),
              "qint_mid_t c; c.val = 5 + a.val;");
}

// ---------------------------------------------------------------------------
// Multi-decl + boundary cases.
// ---------------------------------------------------------------------------

TEST(CodegenTest, MultiDecl) {
    // PLAN §4.4.2 multi-decl example. Two VarRewriteInputs joined with
    // a single ASCII space; the result is a flat one-line replacement
    // that still parses as two C statements.
    //   `quantum int a = 3, b = 2;`
    //     -> `qint_mid_t a = cq_init_si32(3); qint_mid_t b = cq_init_si32(2);`
    std::vector<VarRewriteInput> vars;
    {
        VarRewriteInput a{};
        a.name = "a";
        a.widthSuffix = "si32";
        a.form = VarRewriteInput::Form::ClassicalInit;
        a.initText = "3";
        vars.push_back(a);
    }
    {
        VarRewriteInput b{};
        b.name = "b";
        b.widthSuffix = "si32";
        b.form = VarRewriteInput::Form::ClassicalInit;
        b.initText = "2";
        vars.push_back(b);
    }
    EXPECT_EQ(renderDeclStmt(vars),
              "qint_mid_t a = cq_init_si32(3); qint_mid_t b = cq_init_si32(2);");
}

TEST(CodegenTest, MultiDeclQuantumAddJoin) {
    // Two QuantumAdds joined: confirms the single-space join works
    // even when individual elements themselves contain spaces /
    // semicolons (the QuantumAdd shape has an internal semicolon
    // between the decl and the assignment).
    std::vector<VarRewriteInput> vars;
    {
        VarRewriteInput c{};
        c.name = "c";
        c.widthSuffix = "si32";
        c.form = VarRewriteInput::Form::QuantumAdd;
        c.lhsExpr = "a.val";
        c.rhsExpr = "b.val";
        vars.push_back(c);
    }
    {
        VarRewriteInput d{};
        d.name = "d";
        d.widthSuffix = "si32";
        d.form = VarRewriteInput::Form::QuantumAdd;
        d.lhsExpr = "a.val";
        d.rhsExpr = "5";
        vars.push_back(d);
    }
    EXPECT_EQ(renderDeclStmt(vars),
              "qint_mid_t c; c.val = a.val + b.val; "
              "qint_mid_t d; d.val = a.val + 5;");
}

TEST(CodegenTest, EmptyMultiDecl) {
    // Defensive contract: an empty input vector yields an empty
    // replacement (so the caller can no-op a DeclStmt that lost all
    // its quantum decls).
    EXPECT_EQ(renderDeclStmt({}), "");
}

// ---------------------------------------------------------------------------
// Width-suffix variation. Phase 1's tests only exercise i32 in
// integration, but the renderer is width-agnostic. The case below
// defends against accidental hard-coding of "i32" in the formatter.
// ---------------------------------------------------------------------------

TEST(CodegenTest, WidthSuffixI16) {
    // `quantum short x;` against a target with 16-bit short would
    // resolve to widthSuffix "i16"; the renderer must thread it into
    // the symbol name verbatim.
    VarRewriteInput in{};
    in.name = "x";
    in.widthSuffix = "i16";
    in.form = VarRewriteInput::Form::Uninit;
    EXPECT_EQ(renderVar(in), "qint_mid_t x = cq_init_i16(0);");
}

TEST(CodegenTest, WidthSuffixI8WithClassicalInit) {
    // `quantum char x = 7;` -> i8 suffix flows through ClassicalInit.
    VarRewriteInput in{};
    in.name = "x";
    in.widthSuffix = "i8";
    in.form = VarRewriteInput::Form::ClassicalInit;
    in.initText = "7";
    EXPECT_EQ(renderVar(in), "qint_mid_t x = cq_init_i8(7);");
}
