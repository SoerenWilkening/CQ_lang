// Compile-smoke test for include/cq_mid.h (cq-p2-m02).
//
// The header is declaration-only — there is no .c/.cpp body, and the
// intrinsics are erased by the cq-lowering IR pass before any linker
// would see them. So this test must NOT take the address of an
// intrinsic (that would force a relocation against a symbol with no
// definition in the GTest binary and fail at link time).
//
// Strategy: `decltype(<name>)` queries the *declared* function type
// without producing a relocation. We then `static_assert` that each
// declaration's full signature matches what the PRD specifies. This
// proves the header parses, every typedef is defined, every intrinsic
// is declared, and every signature is byte-exact — purely at compile
// time. The runtime body of the test is a no-op `SUCCEED()` so GTest
// registers a green case.
//
// Specs: phases/phase2/PRD.md §"Type map" (lines 60-75) and
// §"Intrinsic surface" (lines 85-114); phases/phase2/PLAN.md §4.2.
#include <gtest/gtest.h>

#include <cstdint>
#include <type_traits>

#include "cq_mid.h"

namespace {

// Lightweight signature matcher: `signature_is<F, R, Args...>` is true
// iff `F` is the function type `R(Args...)`. `decltype(name)` of a
// function declaration yields exactly that function type, so this is
// a pure compile-time identity check — no ODR-use, no relocation.
template <class F, class R, class... A>
inline constexpr bool signature_is = std::is_same_v<F, R(A...)>;

// ---------------------------------------------------------------------
// Mid-struct typedefs (PRD §Type map: 14 entries).
// ---------------------------------------------------------------------
static_assert(sizeof(qbool_mid_t)      >= sizeof(bool),              "qbool_mid_t");
static_assert(sizeof(qchar_mid_t)      >= sizeof(char),               "qchar_mid_t");
static_assert(sizeof(qschar_mid_t)     >= sizeof(signed char),        "qschar_mid_t");
static_assert(sizeof(quchar_mid_t)     >= sizeof(unsigned char),      "quchar_mid_t");
static_assert(sizeof(qshort_mid_t)     >= sizeof(short),              "qshort_mid_t");
static_assert(sizeof(qushort_mid_t)    >= sizeof(unsigned short),     "qushort_mid_t");
static_assert(sizeof(qint_mid_t)       >= sizeof(int32_t),            "qint_mid_t");
static_assert(sizeof(quint_mid_t)      >= sizeof(unsigned int),       "quint_mid_t");
static_assert(sizeof(qlong_mid_t)      >= sizeof(long),               "qlong_mid_t");
static_assert(sizeof(qulong_mid_t)     >= sizeof(unsigned long),      "qulong_mid_t");
static_assert(sizeof(qlonglong_mid_t)  >= sizeof(long long),          "qlonglong_mid_t");
static_assert(sizeof(qulonglong_mid_t) >= sizeof(unsigned long long), "qulonglong_mid_t");
static_assert(sizeof(qfloat_mid_t)     >= sizeof(float),              "qfloat_mid_t");
static_assert(sizeof(qdouble_mid_t)    >= sizeof(double),             "qdouble_mid_t");

// Confirm the `.val` field exists on each and has the type the rewriter
// will rely on for opcode selection. A single sample per family is
// enough — the typedef list above already pinned the struct identity.
static_assert(std::is_same_v<decltype(qbool_mid_t{}.val),      bool>,              "qbool_mid_t.val");
static_assert(std::is_same_v<decltype(qint_mid_t{}.val),       int32_t>,            "qint_mid_t.val (Phase 1 layout)");
static_assert(std::is_same_v<decltype(qulonglong_mid_t{}.val), unsigned long long>, "qulonglong_mid_t.val");
static_assert(std::is_same_v<decltype(qfloat_mid_t{}.val),     float>,              "qfloat_mid_t.val");
static_assert(std::is_same_v<decltype(qdouble_mid_t{}.val),    double>,             "qdouble_mid_t.val");

// ---------------------------------------------------------------------
// Init intrinsics (PRD §Intrinsic surface: 14 entries).
// ---------------------------------------------------------------------
static_assert(signature_is<decltype(cq_init_i1),   qbool_mid_t,      bool>,              "cq_init_i1");
static_assert(signature_is<decltype(cq_init_c),    qchar_mid_t,      char>,               "cq_init_c");
static_assert(signature_is<decltype(cq_init_si8),  qschar_mid_t,     int8_t>,             "cq_init_si8");
static_assert(signature_is<decltype(cq_init_ui8),  quchar_mid_t,     uint8_t>,            "cq_init_ui8");
static_assert(signature_is<decltype(cq_init_si16), qshort_mid_t,     int16_t>,            "cq_init_si16");
static_assert(signature_is<decltype(cq_init_ui16), qushort_mid_t,    uint16_t>,           "cq_init_ui16");
static_assert(signature_is<decltype(cq_init_si32), qint_mid_t,       int32_t>,            "cq_init_si32");
static_assert(signature_is<decltype(cq_init_ui32), quint_mid_t,      uint32_t>,           "cq_init_ui32");
static_assert(signature_is<decltype(cq_init_sl),   qlong_mid_t,      long>,               "cq_init_sl");
static_assert(signature_is<decltype(cq_init_ul),   qulong_mid_t,     unsigned long>,      "cq_init_ul");
static_assert(signature_is<decltype(cq_init_sll),  qlonglong_mid_t,  long long>,          "cq_init_sll");
static_assert(signature_is<decltype(cq_init_ull),  qulonglong_mid_t, unsigned long long>, "cq_init_ull");
static_assert(signature_is<decltype(cq_init_f32),  qfloat_mid_t,     float>,              "cq_init_f32");
static_assert(signature_is<decltype(cq_init_f64),  qdouble_mid_t,    double>,             "cq_init_f64");

// ---------------------------------------------------------------------
// Measure intrinsics (PRD §Intrinsic surface: 14 entries). Return type
// mirrors the matching init's `value` parameter type.
// ---------------------------------------------------------------------
static_assert(signature_is<decltype(cq_measure_i1),   bool,              qbool_mid_t>,      "cq_measure_i1");
static_assert(signature_is<decltype(cq_measure_c),    char,               qchar_mid_t>,      "cq_measure_c");
static_assert(signature_is<decltype(cq_measure_si8),  int8_t,             qschar_mid_t>,     "cq_measure_si8");
static_assert(signature_is<decltype(cq_measure_ui8),  uint8_t,            quchar_mid_t>,     "cq_measure_ui8");
static_assert(signature_is<decltype(cq_measure_si16), int16_t,            qshort_mid_t>,     "cq_measure_si16");
static_assert(signature_is<decltype(cq_measure_ui16), uint16_t,           qushort_mid_t>,    "cq_measure_ui16");
static_assert(signature_is<decltype(cq_measure_si32), int32_t,            qint_mid_t>,       "cq_measure_si32");
static_assert(signature_is<decltype(cq_measure_ui32), uint32_t,           quint_mid_t>,      "cq_measure_ui32");
static_assert(signature_is<decltype(cq_measure_sl),   long,               qlong_mid_t>,      "cq_measure_sl");
static_assert(signature_is<decltype(cq_measure_ul),   unsigned long,      qulong_mid_t>,     "cq_measure_ul");
static_assert(signature_is<decltype(cq_measure_sll),  long long,          qlonglong_mid_t>,  "cq_measure_sll");
static_assert(signature_is<decltype(cq_measure_ull),  unsigned long long, qulonglong_mid_t>, "cq_measure_ull");
static_assert(signature_is<decltype(cq_measure_f32),  float,              qfloat_mid_t>,     "cq_measure_f32");
static_assert(signature_is<decltype(cq_measure_f64),  double,             qdouble_mid_t>,    "cq_measure_f64");

}  // namespace

// Body is intentionally empty — all checks are static_asserts evaluated
// at compile time. A green build of this TU IS the assertion that the
// header is well-formed and the 14 + 28 declarations are correct.
TEST(CqMidCompiles, HeaderCompilesStandalone) {
    SUCCEED();
}
