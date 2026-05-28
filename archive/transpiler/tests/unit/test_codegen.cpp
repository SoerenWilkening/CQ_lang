// Unit tests for Codegen. Pure string assembly — no Clang AST needed,
// so we hand the renderer fully-populated VarRewriteInput structs and
// compare against the byte-exact expected output documented in PRD
// §"Rewriter patterns" and PLAN §4.4.2.
//
// M10 split: the Form enum is four-wide (Uninit / ClassicalInit /
// QuantumAdd / QuantumCopy), the suffix is `TypeMap::intrinsicSuffix`
// (signedness-bearing, e.g. "si32"), and the mid-struct typedef comes
// from `TypeMap::midStructName` (no `qint_mid_t` hardcode). The tests
// below sweep all 14 mid-struct types for Patterns 1/2 (init forms) and
// representative widths for Patterns 3/4 (QuantumAdd) and 6
// (QuantumCopy). Each input is a hand-built VarRewriteInput; we don't
// invoke TypeMap here (that's covered by test_type_map.cpp).
#include <gtest/gtest.h>

#include <string>
#include <vector>

#include "Codegen.h"

using qct::renderDeclStmt;
using qct::renderVar;
using qct::VarRewriteInput;

namespace {

// Build an Uninit input with the per-type (suffix, mid-struct) pair.
VarRewriteInput uninit(const std::string &name, const std::string &sfx,
                       const std::string &mid) {
    VarRewriteInput in{};
    in.name = name;
    in.widthSuffix = sfx;
    in.midStructName = mid;
    in.form = VarRewriteInput::Form::Uninit;
    return in;
}

// Build a ClassicalInit input spliced with the user expression text.
VarRewriteInput classicalInit(const std::string &name, const std::string &sfx,
                              const std::string &mid,
                              const std::string &initText) {
    VarRewriteInput in{};
    in.name = name;
    in.widthSuffix = sfx;
    in.midStructName = mid;
    in.form = VarRewriteInput::Form::ClassicalInit;
    in.initText = initText;
    return in;
}

// Build a QuantumAdd input. Operand strings already carry their
// decoration ("a.val" for quantum, raw text for classical) per
// DeclStmtRewrite's contract.
VarRewriteInput quantumAdd(const std::string &name, const std::string &sfx,
                           const std::string &mid, const std::string &lhs,
                           const std::string &rhs) {
    VarRewriteInput in{};
    in.name = name;
    in.widthSuffix = sfx;
    in.midStructName = mid;
    in.form = VarRewriteInput::Form::QuantumAdd;
    in.lhsExpr = lhs;
    in.rhsExpr = rhs;
    return in;
}

// Build a QuantumCopy (Pattern-6) input. No suffix needed — the form
// emits no intrinsic call (SROA erases the assignment).
VarRewriteInput quantumCopy(const std::string &name, const std::string &mid,
                            const std::string &source) {
    VarRewriteInput in{};
    in.name = name;
    in.midStructName = mid;
    in.form = VarRewriteInput::Form::QuantumCopy;
    in.sourceName = source;
    return in;
}

}  // namespace

// ---------------------------------------------------------------------------
// Pattern 1 (Uninit) per-type goldens. PRD §"Type map" pairs each of the
// 14 supported builtin types with one (suffix, mid-struct) row; the
// renderer threads both verbatim into the output. The 14 builtin rows
// plus 2 <stdint.h> typedef rows (int32_t → si32, uint64_t → ul on LP64)
// are exercised in a single table-driven test to keep this file under
// the 280-LOC budget (PLAN §2.4).
// ---------------------------------------------------------------------------

TEST(CodegenTest, UninitPerType) {
    struct Row {
        const char *sfx;
        const char *mid;
        const char *want;
    };
    // 14 builtin rows + 2 typedef rows. The typedef rows reuse the
    // suffix/mid-struct of their canonical-type target (int32_t → int,
    // uint64_t → unsigned long on LP64), because TypeMap canonicalises
    // before reaching Codegen — so the rendered output is byte-identical
    // to the corresponding builtin row.
    const Row rows[] = {
        {"i1",   "qbool_mid_t",       "qbool_mid_t x = cq_init_i1(0);"},
        {"c",    "qchar_mid_t",       "qchar_mid_t x = cq_init_c(0);"},
        {"si8",  "qschar_mid_t",      "qschar_mid_t x = cq_init_si8(0);"},
        {"ui8",  "quchar_mid_t",      "quchar_mid_t x = cq_init_ui8(0);"},
        {"si16", "qshort_mid_t",      "qshort_mid_t x = cq_init_si16(0);"},
        {"ui16", "qushort_mid_t",     "qushort_mid_t x = cq_init_ui16(0);"},
        {"si32", "qint_mid_t",        "qint_mid_t x = cq_init_si32(0);"},
        {"ui32", "quint_mid_t",       "quint_mid_t x = cq_init_ui32(0);"},
        {"sl",   "qlong_mid_t",       "qlong_mid_t x = cq_init_sl(0);"},
        {"ul",   "qulong_mid_t",      "qulong_mid_t x = cq_init_ul(0);"},
        {"sll",  "qlonglong_mid_t",   "qlonglong_mid_t x = cq_init_sll(0);"},
        {"ull",  "qulonglong_mid_t",  "qulonglong_mid_t x = cq_init_ull(0);"},
        {"f32",  "qfloat_mid_t",      "qfloat_mid_t x = cq_init_f32(0);"},
        {"f64",  "qdouble_mid_t",     "qdouble_mid_t x = cq_init_f64(0);"},
        // Typedef cases (PLAN §4.10): int32_t → int, uint64_t → ulong.
        {"si32", "qint_mid_t",        "qint_mid_t x = cq_init_si32(0);"},
        {"ul",   "qulong_mid_t",      "qulong_mid_t x = cq_init_ul(0);"},
    };
    for (const Row &r : rows) {
        SCOPED_TRACE(r.want);
        EXPECT_EQ(renderVar(uninit("x", r.sfx, r.mid)), r.want);
    }
}

// ---------------------------------------------------------------------------
// Pattern 2 (ClassicalInit) — spot-check that the initializer source
// text is spliced verbatim inside `cq_init_<sfx>(...)`. Per-type
// coverage is redundant with Pattern 1 (same code path); we exercise
// one integer and one float to defend against accidental case-specific
// formatting drift.
// ---------------------------------------------------------------------------

TEST(CodegenTest, ClassicalInitInt) {
    // `quantum int x = 3+f();` — internal whitespace preserved exactly.
    EXPECT_EQ(renderVar(classicalInit("x", "si32", "qint_mid_t", "3+f()")),
              "qint_mid_t x = cq_init_si32(3+f());");
}

TEST(CodegenTest, ClassicalInitFloat) {
    EXPECT_EQ(renderVar(classicalInit("x", "f32", "qfloat_mid_t", "3.5f")),
              "qfloat_mid_t x = cq_init_f32(3.5f);");
}

// ---------------------------------------------------------------------------
// Patterns 3/4 (QuantumAdd) — representative widths (i32, i64-via-sl,
// f32, f64). The renderer doesn't branch on operand quantum-ness (the
// caller pre-decorates), so a Q+Q and a Q+C case is enough per width to
// confirm splicing.
// ---------------------------------------------------------------------------

TEST(CodegenTest, QuantumAddIntQQ) {
    EXPECT_EQ(renderVar(quantumAdd("c", "si32", "qint_mid_t", "a.val", "b.val")),
              "qint_mid_t c; c.val = a.val + b.val;");
}

TEST(CodegenTest, QuantumAddIntQC) {
    EXPECT_EQ(renderVar(quantumAdd("c", "si32", "qint_mid_t", "a.val", "5")),
              "qint_mid_t c; c.val = a.val + 5;");
}

TEST(CodegenTest, QuantumAddIntCQ) {
    // Commuted mixed-operand — same path, decorated operand on the right.
    EXPECT_EQ(renderVar(quantumAdd("c", "si32", "qint_mid_t", "5", "a.val")),
              "qint_mid_t c; c.val = 5 + a.val;");
}

TEST(CodegenTest, QuantumAddLongQQ) {
    EXPECT_EQ(renderVar(quantumAdd("c", "sl", "qlong_mid_t", "a.val", "b.val")),
              "qlong_mid_t c; c.val = a.val + b.val;");
}

TEST(CodegenTest, QuantumAddFloatQQ) {
    EXPECT_EQ(renderVar(quantumAdd("c", "f32", "qfloat_mid_t", "a.val", "b.val")),
              "qfloat_mid_t c; c.val = a.val + b.val;");
}

TEST(CodegenTest, QuantumAddFloatQC) {
    // `quantum float c = a + 1.5f;` — classical-rhs splice keeps the
    // float-literal suffix verbatim.
    EXPECT_EQ(renderVar(quantumAdd("c", "f32", "qfloat_mid_t", "a.val", "1.5f")),
              "qfloat_mid_t c; c.val = a.val + 1.5f;");
}

TEST(CodegenTest, QuantumAddDoubleQQ) {
    EXPECT_EQ(renderVar(quantumAdd("c", "f64", "qdouble_mid_t", "a.val", "b.val")),
              "qdouble_mid_t c; c.val = a.val + b.val;");
}

// ---------------------------------------------------------------------------
// Pattern 6 (QuantumCopy) — PRD §"On assignment and surviving
// operations". The split form emits no intrinsic call: the IR pass
// never sees the assignment because SROA collapses it to SSA aliasing.
// The mid-struct name must come from the input (per-type), so we sweep
// a representative integer + float.
// ---------------------------------------------------------------------------

TEST(CodegenTest, QuantumCopyInt) {
    // PLAN §4.10 explicit golden: `(QuantumCopy {name: "b", source:
    // "a", type: "int"})` -> `qint_mid_t b; b.val = a.val;`.
    EXPECT_EQ(renderVar(quantumCopy("b", "qint_mid_t", "a")),
              "qint_mid_t b; b.val = a.val;");
}

TEST(CodegenTest, QuantumCopyFloat) {
    EXPECT_EQ(renderVar(quantumCopy("b", "qfloat_mid_t", "a")),
              "qfloat_mid_t b; b.val = a.val;");
}

TEST(CodegenTest, QuantumCopyBool) {
    EXPECT_EQ(renderVar(quantumCopy("b", "qbool_mid_t", "a")),
              "qbool_mid_t b; b.val = a.val;");
}

// ---------------------------------------------------------------------------
// Multi-decl join + empty-vector boundary. The single-space join is
// part of the contract (PLAN §4.4.2 multi-decl example).
// ---------------------------------------------------------------------------

TEST(CodegenTest, MultiDecl) {
    // `quantum int a = 3, b = 2;`
    std::vector<VarRewriteInput> vars{
        classicalInit("a", "si32", "qint_mid_t", "3"),
        classicalInit("b", "si32", "qint_mid_t", "2"),
    };
    EXPECT_EQ(renderDeclStmt(vars),
              "qint_mid_t a = cq_init_si32(3); qint_mid_t b = cq_init_si32(2);");
}

TEST(CodegenTest, MultiDeclQuantumAddJoin) {
    // Two QuantumAdds joined: confirms the single-space join works
    // even when individual elements contain internal semicolons.
    std::vector<VarRewriteInput> vars{
        quantumAdd("c", "si32", "qint_mid_t", "a.val", "b.val"),
        quantumAdd("d", "si32", "qint_mid_t", "a.val", "5"),
    };
    EXPECT_EQ(renderDeclStmt(vars),
              "qint_mid_t c; c.val = a.val + b.val; "
              "qint_mid_t d; d.val = a.val + 5;");
}

TEST(CodegenTest, MultiDeclMixedTypes) {
    // Each VarDecl carries its own mid-struct name, so a heterogeneous
    // multi-decl (rare but legal in C: `quantum int a; quantum float b;`
    // — well, two adjacent DeclStmts) renders each row with its own
    // typedef. Exercises the per-type lookup directly.
    std::vector<VarRewriteInput> vars{
        uninit("a", "si32", "qint_mid_t"),
        uninit("b", "f32", "qfloat_mid_t"),
    };
    EXPECT_EQ(renderDeclStmt(vars),
              "qint_mid_t a = cq_init_si32(0); qfloat_mid_t b = cq_init_f32(0);");
}

TEST(CodegenTest, EmptyMultiDecl) {
    // Defensive contract: empty vector yields empty replacement, so the
    // caller can no-op a DeclStmt that lost all its quantum decls.
    EXPECT_EQ(renderDeclStmt({}), "");
}

// ---------------------------------------------------------------------------
// Pattern 10/11 (QuantumCrossCopy) — Phase 3 M9. Cross-width Q→Q init
// emits a stock C cast on `.val`. The cast type name comes from the
// destination VarDecl's type (e.g. "long" for `quantum long b = q_int;`).
// ---------------------------------------------------------------------------

namespace {

VarRewriteInput quantumCrossCopy(const std::string &name,
                                 const std::string &mid,
                                 const std::string &source,
                                 const std::string &castType) {
    VarRewriteInput in{};
    in.name = name;
    in.midStructName = mid;
    in.form = VarRewriteInput::Form::QuantumCrossCopy;
    in.sourceName = source;
    in.castTypeName = castType;
    return in;
}

}  // namespace

TEST(CodegenTest, QuantumCrossCopyIntToLong) {
    EXPECT_EQ(renderVar(quantumCrossCopy("b", "qlong_mid_t", "a", "long")),
              "qlong_mid_t b; b.val = (long) a.val;");
}

TEST(CodegenTest, QuantumCrossCopyLongToInt) {
    EXPECT_EQ(renderVar(quantumCrossCopy("b", "qint_mid_t", "a", "int")),
              "qint_mid_t b; b.val = (int) a.val;");
}

TEST(CodegenTest, QuantumCrossCopyIntToFloat) {
    EXPECT_EQ(renderVar(quantumCrossCopy("b", "qfloat_mid_t", "a", "float")),
              "qfloat_mid_t b; b.val = (float) a.val;");
}

TEST(CodegenTest, QuantumCrossCopyIntToUnsignedLong) {
    EXPECT_EQ(
        renderVar(quantumCrossCopy("b", "qulong_mid_t", "a", "unsigned long")),
        "qulong_mid_t b; b.val = (unsigned long) a.val;");
}
