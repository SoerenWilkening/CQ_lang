// Unit tests for qct::numBitsForBuiltin. Table-driven over every kind
// listed in the PRD bit-width table, plus a few defensive negative
// cases.
#include <gtest/gtest.h>

#include "TypeMap.h"

using clang::BuiltinType;
using qct::numBitsForBuiltin;

TEST(TypeMapTest, BuiltinBitWidths) {
    struct Case {
        BuiltinType::Kind k;
        unsigned expected;
        const char *name;
    };
    const Case cases[] = {
        {BuiltinType::Bool, 1, "Bool"},
        {BuiltinType::Char_S, 8, "Char_S"},
        {BuiltinType::Char_U, 8, "Char_U"},
        {BuiltinType::SChar, 8, "SChar"},
        {BuiltinType::UChar, 8, "UChar"},
        {BuiltinType::Short, 16, "Short"},
        {BuiltinType::UShort, 16, "UShort"},
        {BuiltinType::Int, 16, "Int"},
        {BuiltinType::UInt, 16, "UInt"},
        {BuiltinType::Long, 32, "Long"},
        {BuiltinType::ULong, 32, "ULong"},
        {BuiltinType::LongLong, 64, "LongLong"},
        {BuiltinType::ULongLong, 64, "ULongLong"},
        {BuiltinType::Float, 0, "Float"},
        {BuiltinType::Double, 0, "Double"},
        {BuiltinType::LongDouble, 0, "LongDouble"},
    };
    for (const auto &c : cases) {
        EXPECT_EQ(numBitsForBuiltin(c.k), c.expected) << "kind = " << c.name;
    }
}

TEST(TypeMapTest, WideAndExoticKindsAreZero) {
    // Defensive: anything outside the PRD table should report 0 so the
    // caller can route unsupported types into a diagnostic later
    // without ever silently picking a wrong width.
    EXPECT_EQ(numBitsForBuiltin(BuiltinType::WChar_S), 0u);
    EXPECT_EQ(numBitsForBuiltin(BuiltinType::WChar_U), 0u);
    EXPECT_EQ(numBitsForBuiltin(BuiltinType::Char8), 0u);
    EXPECT_EQ(numBitsForBuiltin(BuiltinType::Char16), 0u);
    EXPECT_EQ(numBitsForBuiltin(BuiltinType::Char32), 0u);
    EXPECT_EQ(numBitsForBuiltin(BuiltinType::Void), 0u);
}
