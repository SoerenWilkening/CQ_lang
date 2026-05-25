// Unit tests for qct::TypeMap accessors — Phase 2 target-aware
// type-to-suffix / type-to-mid-struct resolver (PLAN §4.8, PRD
// §"Type map"). Coverage: 14-type table for each of `irWidthSuffix`
// (width-only), `intrinsicSuffix` (signedness-bearing), `midStructName`
// (typedef); 8 `<stdint.h>` typedef cases (canonical-type peeling);
// target-dependence of `long` (suffix platform-stable, width forks).
#include <gtest/gtest.h>

#include <memory>
#include <string>

#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/Type.h>
#include <clang/Basic/TargetInfo.h>
#include <clang/Frontend/ASTUnit.h>
#include <clang/Tooling/Tooling.h>
#include <llvm/ADT/StringRef.h>

#include "TypeMap.h"

using clang::BuiltinType;
using qct::intrinsicSuffix;
using qct::irWidthSuffix;
using qct::midStructName;
using qct::numBitsForBuiltin;
using qct::numBitsForType;

namespace {

std::unique_ptr<clang::ASTUnit> parseC11(
    const std::string &code,
    const std::string &triple = "x86_64-linux-gnu") {
    return clang::tooling::buildASTFromCodeWithArgs(
        code,
        /*Args=*/{"-std=c11", "--target=" + triple},
        /*FileName=*/"input.c");
}

clang::QualType qtypeOf(clang::ASTUnit *unit, const std::string &name) {
    for (auto it = unit->top_level_begin(); it != unit->top_level_end(); ++it) {
        if (const auto *vd = clang::dyn_cast<clang::VarDecl>(*it)) {
            if (vd->getNameAsString() == name) {
                return vd->getType();
            }
        }
    }
    return clang::QualType();
}

// One variable per PRD §"Type map" entry. Reused across the three
// accessor tests so the AST cost is amortized.
const char kAllFourteenTypesSource[] =
    "_Bool b;\n"
    "char c;\n"
    "signed char sc;\n"
    "unsigned char uc;\n"
    "short s;\n"
    "unsigned short us;\n"
    "int i;\n"
    "unsigned int ui;\n"
    "long l;\n"
    "unsigned long ul;\n"
    "long long ll;\n"
    "unsigned long long ull;\n"
    "float f;\n"
    "double d;\n";

}  // namespace

// ---------------------------------------------------------------------------
// irWidthSuffix: width-only, IR-pass facing. Phase 2 adds float/double
// (Phase 1 was int-family only) so all 14 PRD types resolve here too.
// ---------------------------------------------------------------------------

TEST(TypeMapTest, IrWidthSuffixAllFourteenTypesOnLinuxX86_64) {
    auto unit = parseC11(
        std::string(kAllFourteenTypesSource) +
        "typedef int my_int;\n"
        "my_int td;\n"
        "const int ci = 0;\n");
    ASSERT_NE(unit, nullptr);
    const clang::TargetInfo &ti = unit->getASTContext().getTargetInfo();

    struct Case { const char *var; const char *expected; };
    const Case cases[] = {
        {"b",   "i1"},
        {"c",   "i8"},  {"sc",  "i8"},  {"uc",  "i8"},
        {"s",   "i16"}, {"us",  "i16"},
        {"i",   "i32"}, {"ui",  "i32"},
        // LP64: `long` is 64-bit on x86_64-linux-gnu. ILP32 test below
        // pins the contrast.
        {"l",   "i64"}, {"ul",  "i64"},
        {"ll",  "i64"}, {"ull", "i64"},
        // Phase 2 widens beyond int family: floats route through the
        // same width-suffix path so the IR pass can look up
        // `cq_template_add_f32` / `_f64`.
        {"f",   "f32"}, {"d",   "f64"},
        // Typedef and const peel down to plain `int`.
        {"td",  "i32"}, {"ci",  "i32"},
    };
    for (const auto &c : cases) {
        const clang::QualType qt = qtypeOf(unit.get(), c.var);
        ASSERT_FALSE(qt.isNull()) << "var = " << c.var;
        EXPECT_EQ(irWidthSuffix(qt, ti), c.expected) << "var = " << c.var;
    }
}

// `long double` and pointer / void types remain out of scope in
// Phase 2 — empty string so callers route the case into a diagnostic.
TEST(TypeMapTest, IrWidthSuffixUnsupportedTypesAreEmpty) {
    auto unit = parseC11("long double ld;\nvoid *vp;\n");
    ASSERT_NE(unit, nullptr);
    const clang::TargetInfo &ti = unit->getASTContext().getTargetInfo();
    for (const char *name : {"ld", "vp"}) {
        const clang::QualType qt = qtypeOf(unit.get(), name);
        ASSERT_FALSE(qt.isNull()) << "var = " << name;
        EXPECT_EQ(irWidthSuffix(qt, ti), std::string()) << "var = " << name;
    }
}

TEST(TypeMapTest, IrWidthSuffixNullQualTypeIsEmpty) {
    auto unit = parseC11("int i;");
    ASSERT_NE(unit, nullptr);
    const clang::TargetInfo &ti = unit->getASTContext().getTargetInfo();
    EXPECT_EQ(irWidthSuffix(clang::QualType(), ti), std::string());
}

// ---------------------------------------------------------------------------
// intrinsicSuffix: signedness-bearing, platform-stable. PRD §"Type map"
// verbatim — 14 entries.
// ---------------------------------------------------------------------------

TEST(TypeMapTest, IntrinsicSuffixAllFourteenTypes) {
    auto unit = parseC11(kAllFourteenTypesSource);
    ASSERT_NE(unit, nullptr);
    struct Case { const char *var; const char *expected; };
    // `char` is "c" — distinct from signed/unsigned char (C's three-way
    // char split). `sl`/`ul` abstract over `long`'s target-dependent
    // width — the suffix is platform-stable; only `irWidthSuffix` forks.
    const Case cases[] = {
        {"b",   "i1"},   {"c",   "c"},
        {"sc",  "si8"},  {"uc",  "ui8"},
        {"s",   "si16"}, {"us",  "ui16"},
        {"i",   "si32"}, {"ui",  "ui32"},
        {"l",   "sl"},   {"ul",  "ul"},
        {"ll",  "sll"},  {"ull", "ull"},
        {"f",   "f32"},  {"d",   "f64"},
    };
    for (const auto &c : cases) {
        const clang::QualType qt = qtypeOf(unit.get(), c.var);
        ASSERT_FALSE(qt.isNull()) << "var = " << c.var;
        EXPECT_EQ(intrinsicSuffix(qt), llvm::StringRef(c.expected))
            << "var = " << c.var;
    }
}

TEST(TypeMapTest, NewAccessorsUnsupportedAndNullAreEmpty) {
    auto unit = parseC11("long double ld;\nvoid *vp;\n");
    ASSERT_NE(unit, nullptr);
    for (const char *name : {"ld", "vp"}) {
        const clang::QualType qt = qtypeOf(unit.get(), name);
        EXPECT_TRUE(intrinsicSuffix(qt).empty()) << "var = " << name;
        EXPECT_TRUE(midStructName(qt).empty())  << "var = " << name;
    }
    EXPECT_TRUE(intrinsicSuffix(clang::QualType()).empty());
    EXPECT_TRUE(midStructName(clang::QualType()).empty());
}

// ---------------------------------------------------------------------------
// midStructName: PRD §"Type map" typedef-name column. 14 entries.
// ---------------------------------------------------------------------------

TEST(TypeMapTest, MidStructNameAllFourteenTypes) {
    auto unit = parseC11(kAllFourteenTypesSource);
    ASSERT_NE(unit, nullptr);
    struct Case { const char *var; const char *expected; };
    const Case cases[] = {
        {"b",   "qbool_mid_t"},      {"c",   "qchar_mid_t"},
        {"sc",  "qschar_mid_t"},     {"uc",  "quchar_mid_t"},
        {"s",   "qshort_mid_t"},     {"us",  "qushort_mid_t"},
        {"i",   "qint_mid_t"},       {"ui",  "quint_mid_t"},
        {"l",   "qlong_mid_t"},      {"ul",  "qulong_mid_t"},
        {"ll",  "qlonglong_mid_t"},  {"ull", "qulonglong_mid_t"},
        {"f",   "qfloat_mid_t"},     {"d",   "qdouble_mid_t"},
    };
    for (const auto &c : cases) {
        const clang::QualType qt = qtypeOf(unit.get(), c.var);
        ASSERT_FALSE(qt.isNull()) << "var = " << c.var;
        EXPECT_EQ(midStructName(qt), llvm::StringRef(c.expected))
            << "var = " << c.var;
    }
}

// ---------------------------------------------------------------------------
// <stdint.h> typedefs route through getCanonicalType() to the underlying
// builtin. PRD §"<stdint.h> typedefs": `int8_t` -> `signed char` ->
// `qschar_mid_t`, etc. — no per-typedef enumeration in TypeMap. On
// x86_64-linux-gnu (LP64), int64_t/uint64_t canonicalize to long /
// unsigned long, so they land on `qlong_mid_t` / `qulong_mid_t`.
// ---------------------------------------------------------------------------

TEST(TypeMapTest, StdintTypedefsResolveToUnderlyingEntry) {
    auto unit = parseC11(
        "#include <stdint.h>\n"
        "int8_t v_i8;  uint8_t v_u8;\n"
        "int16_t v_i16; uint16_t v_u16;\n"
        "int32_t v_i32; uint32_t v_u32;\n"
        "int64_t v_i64; uint64_t v_u64;\n");
    ASSERT_NE(unit, nullptr);
    struct Case { const char *var; const char *sfx; const char *mid; };
    const Case cases[] = {
        {"v_i8",  "si8",  "qschar_mid_t"},
        {"v_u8",  "ui8",  "quchar_mid_t"},
        {"v_i16", "si16", "qshort_mid_t"},
        {"v_u16", "ui16", "qushort_mid_t"},
        {"v_i32", "si32", "qint_mid_t"},
        {"v_u32", "ui32", "quint_mid_t"},
        {"v_i64", "sl",   "qlong_mid_t"},
        {"v_u64", "ul",   "qulong_mid_t"},
    };
    for (const auto &c : cases) {
        const clang::QualType qt = qtypeOf(unit.get(), c.var);
        ASSERT_FALSE(qt.isNull()) << "var = " << c.var;
        EXPECT_EQ(intrinsicSuffix(qt), llvm::StringRef(c.sfx))
            << c.var << " intrinsicSuffix";
        EXPECT_EQ(midStructName(qt), llvm::StringRef(c.mid))
            << c.var << " midStructName";
    }
}

// ---------------------------------------------------------------------------
// Target-dependence of `long`. PRD §"Target-dependence of `long`":
// on LP64 (x86_64-linux-gnu) it's 64 bits; on ILP32 (i686-linux) or
// LLP64 (Windows) it's 32 bits. The intrinsic suffix is platform-
// stable; only `irWidthSuffix` forks per target. The IR pass picks
// `cqrt_alloc_i64` vs `cqrt_alloc_i32` at lowering time from DataLayout.
// ---------------------------------------------------------------------------

// i686-unknown-linux-gnu is ILP32 (sizeof(long) == 4) — simplest
// available 32-bit target without external SDK; stands in for Windows
// LLP64 (also long==4) for the width-fork half of the test.
TEST(TypeMapTest, LongWidthForksByTargetSuffixIsStable) {
    struct TargetCase { const char *triple; const char *expectedWidth; };
    const TargetCase targets[] = {
        {"x86_64-linux-gnu",       "i64"},  // LP64
        {"i686-unknown-linux-gnu", "i32"},  // ILP32 (stands in for Win LLP64)
    };
    for (const auto &tc : targets) {
        auto unit = parseC11("long l;\nunsigned long ul;\n", tc.triple);
        ASSERT_NE(unit, nullptr) << "triple = " << tc.triple;
        const clang::TargetInfo &ti = unit->getASTContext().getTargetInfo();
        const clang::QualType lt  = qtypeOf(unit.get(), "l");
        const clang::QualType ult = qtypeOf(unit.get(), "ul");
        ASSERT_FALSE(lt.isNull());
        ASSERT_FALSE(ult.isNull());
        // Width forks per target.
        EXPECT_EQ(irWidthSuffix(lt, ti),  tc.expectedWidth) << tc.triple;
        EXPECT_EQ(irWidthSuffix(ult, ti), tc.expectedWidth) << tc.triple;
        // Suffix + mid-struct are platform-stable.
        EXPECT_EQ(intrinsicSuffix(lt),  llvm::StringRef("sl")) << tc.triple;
        EXPECT_EQ(intrinsicSuffix(ult), llvm::StringRef("ul")) << tc.triple;
        EXPECT_EQ(midStructName(lt),  llvm::StringRef("qlong_mid_t"))  << tc.triple;
        EXPECT_EQ(midStructName(ult), llvm::StringRef("qulong_mid_t")) << tc.triple;
    }
}

// ---------------------------------------------------------------------------
// Legacy shims (Phase 2 M9/M10/M11 will retire these).
// ---------------------------------------------------------------------------

TEST(TypeMapTest, LegacyNumBitsForBuiltinSmoke) {
    EXPECT_EQ(numBitsForBuiltin(BuiltinType::Bool), 1u);
    EXPECT_EQ(numBitsForBuiltin(BuiltinType::Char_S), 8u);
    EXPECT_EQ(numBitsForBuiltin(BuiltinType::Int), 16u);
    EXPECT_EQ(numBitsForBuiltin(BuiltinType::Long), 32u);
    EXPECT_EQ(numBitsForBuiltin(BuiltinType::LongLong), 64u);
    EXPECT_EQ(numBitsForBuiltin(BuiltinType::Float), 0u);
    EXPECT_EQ(numBitsForBuiltin(BuiltinType::Void), 0u);
}
