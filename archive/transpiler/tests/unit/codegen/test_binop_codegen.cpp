// Unit tests for BinopCodegen (Phase 3 M8). The QuantumAdd emission was
// inlined inside Codegen.cpp in Phase 2; M8 hoisted it into a dedicated
// module. The extraction is mechanical — the function body is
// byte-identical to the Phase 2 helper — so these tests duplicate the
// QuantumAdd goldens from test_codegen.cpp and assert byte-exact output
// against the extracted module directly. (Codegen.cpp's tests confirm
// the multiplex still calls into BinopCodegen correctly; these tests
// confirm BinopCodegen itself.)
#include <gtest/gtest.h>

#include <string>

#include "BinopCodegen.h"

using qct::emitQuantumAdd;

TEST(BinopCodegenTest, IntQQ) {
    // `quantum int c = a + b;` (both quantum) — operand strings already
    // carry `.val` decoration from the caller.
    EXPECT_EQ(emitQuantumAdd("qint_mid_t", "c", "a.val", "b.val"),
              "qint_mid_t c; c.val = a.val + b.val;");
}

TEST(BinopCodegenTest, IntQC) {
    // `quantum int c = a + 5;` — RHS classical, spliced as raw text.
    EXPECT_EQ(emitQuantumAdd("qint_mid_t", "c", "a.val", "5"),
              "qint_mid_t c; c.val = a.val + 5;");
}

TEST(BinopCodegenTest, IntCQ) {
    // `quantum int c = 5 + a;` — commuted, classical-on-left.
    EXPECT_EQ(emitQuantumAdd("qint_mid_t", "c", "5", "a.val"),
              "qint_mid_t c; c.val = 5 + a.val;");
}

TEST(BinopCodegenTest, LongQQ) {
    // Per-type sweep — mid-struct name flows through unchanged.
    EXPECT_EQ(emitQuantumAdd("qlong_mid_t", "c", "a.val", "b.val"),
              "qlong_mid_t c; c.val = a.val + b.val;");
}

TEST(BinopCodegenTest, FloatQC) {
    // Float-suffixed literal preserves verbatim.
    EXPECT_EQ(emitQuantumAdd("qfloat_mid_t", "c", "a.val", "1.5f"),
              "qfloat_mid_t c; c.val = a.val + 1.5f;");
}

TEST(BinopCodegenTest, DoubleQQ) {
    EXPECT_EQ(emitQuantumAdd("qdouble_mid_t", "c", "a.val", "b.val"),
              "qdouble_mid_t c; c.val = a.val + b.val;");
}
