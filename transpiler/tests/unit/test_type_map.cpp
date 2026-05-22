// Unit tests for qct::irWidthSuffix — the Phase 1 target-aware width
// resolver. Spins up a real in-process Clang AST against an explicit
// target triple so QualTypes route through canonical TargetInfo widths
// (PLAN §4.4.1).
//
// Coverage policy (PLAN §6.6): Phase 1 only ever EMITS `i32`, but the
// function must be correct for the whole C int family — Bool / char /
// short / int / long / long long, signed + unsigned variants — so
// Phase 2 picks up no carry-forward debt. Floats and exotic kinds
// return the empty string ("unsupported in Phase 1").
//
// The legacy shims (numBitsForBuiltin / numBitsForType) keep being
// covered minimally so downstream callers in DeclStmtRewrite/Codegen
// stay green until issues -mit and -ldk migrate them off the shim.
#include <gtest/gtest.h>

#include <memory>
#include <string>
#include <vector>

#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/Type.h>
#include <clang/Basic/TargetInfo.h>
#include <clang/Frontend/ASTUnit.h>
#include <clang/Tooling/Tooling.h>

#include "TypeMap.h"

using clang::BuiltinType;
using qct::irWidthSuffix;
using qct::numBitsForBuiltin;
using qct::numBitsForType;

namespace {

// Parse a tiny TU against the canonical Phase 1 test target
// (x86_64-linux-gnu) so getIntWidth() / getLongWidth() / etc. resolve
// to the values the PRD §"Width resolution" examples assume.
std::unique_ptr<clang::ASTUnit> parseC11WithLinuxTarget(const std::string &code) {
    return clang::tooling::buildASTFromCodeWithArgs(
        code,
        /*Args=*/{"-std=c11", "--target=x86_64-linux-gnu"},
        /*FileName=*/"input.c");
}

// Pull the QualType off a top-level VarDecl named `varName`. Tests
// declare one variable per kind they want to probe and use the
// VarDecl's getType() as the QualType under test.
clang::QualType qualTypeOfVar(clang::ASTUnit *unit, const std::string &varName) {
    for (auto it = unit->top_level_begin(); it != unit->top_level_end(); ++it) {
        if (const auto *vd = clang::dyn_cast<clang::VarDecl>(*it)) {
            if (vd->getNameAsString() == varName) {
                return vd->getType();
            }
        }
    }
    return clang::QualType();
}

}  // namespace

// ---------------------------------------------------------------------------
// irWidthSuffix: the full C int family on x86_64-linux-gnu. Phase 1
// emission only exercises `int` -> "i32" today, but the function must
// be correct for every width per PLAN §6.6.
// ---------------------------------------------------------------------------

TEST(TypeMapTest, IrWidthSuffixIntFamilyOnLinuxX86_64) {
    // Cover signed + unsigned variants of every C int width plus _Bool,
    // and a few typedef / cv-qualified routes that should peel down to
    // the same builtin.
    auto unit = parseC11WithLinuxTarget(
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
        "typedef int my_int;\n"
        "my_int td;\n"
        "const int ci = 0;\n");
    ASSERT_NE(unit, nullptr);
    const clang::TargetInfo &ti = unit->getASTContext().getTargetInfo();

    struct Case {
        const char *var;
        const char *expected;
    };
    const Case cases[] = {
        {"b",   "i1"},
        {"c",   "i8"},
        {"sc",  "i8"},
        {"uc",  "i8"},
        {"s",   "i16"},
        {"us",  "i16"},
        // x86_64-linux-gnu has 32-bit int. Phase 1 lives entirely on
        // this width per PLAN §6.6.
        {"i",   "i32"},
        {"ui",  "i32"},
        // LP64: `long` is 64-bit on x86_64-linux-gnu (distinct from
        // Windows LLP64; the test pins the triple explicitly above).
        {"l",   "i64"},
        {"ul",  "i64"},
        {"ll",  "i64"},
        {"ull", "i64"},
        // Typedef and const peel down to plain `int`.
        {"td",  "i32"},
        {"ci",  "i32"},
    };
    for (const auto &c : cases) {
        const clang::QualType qt = qualTypeOfVar(unit.get(), c.var);
        ASSERT_FALSE(qt.isNull()) << "var = " << c.var;
        EXPECT_EQ(irWidthSuffix(qt, ti), c.expected) << "var = " << c.var;
    }
}

// Floats, doubles, and exotic kinds are not lowered in Phase 1 — the
// function returns the empty string so callers can route the case
// into a diagnostic rather than silently mis-emitting an intrinsic.
TEST(TypeMapTest, IrWidthSuffixUnsupportedTypesAreEmpty) {
    auto unit = parseC11WithLinuxTarget(
        "float f;\n"
        "double d;\n"
        "long double ld;\n"
        "void *vp;\n");
    ASSERT_NE(unit, nullptr);
    const clang::TargetInfo &ti = unit->getASTContext().getTargetInfo();

    for (const char *name : {"f", "d", "ld", "vp"}) {
        const clang::QualType qt = qualTypeOfVar(unit.get(), name);
        ASSERT_FALSE(qt.isNull()) << "var = " << name;
        EXPECT_EQ(irWidthSuffix(qt, ti), std::string()) << "var = " << name;
    }
}

// Defensive: a null QualType must not crash. The legitimate way to
// hit this is a caller passing in a sentinel (e.g. a getType() result
// in an error-recovery path); the function returns "" for the same
// reason as the unsupported-kind branch.
TEST(TypeMapTest, IrWidthSuffixNullQualTypeIsEmpty) {
    auto unit = parseC11WithLinuxTarget("int i;");
    ASSERT_NE(unit, nullptr);
    const clang::TargetInfo &ti = unit->getASTContext().getTargetInfo();
    EXPECT_EQ(irWidthSuffix(clang::QualType(), ti), std::string());
}

// ---------------------------------------------------------------------------
// Legacy shims: numBitsForBuiltin / numBitsForType still back the v1
// emission path (DeclStmtRewrite + Codegen) until issues -mit and -ldk
// land. Keep a smoke test on the shim so regressions on the deprecated
// API are caught locally, not via downstream test failure.
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
