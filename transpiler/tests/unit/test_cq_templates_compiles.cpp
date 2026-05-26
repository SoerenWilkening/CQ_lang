// Compile-smoke test for runtime/cq_templates.h (cq-p2-m05).
//
// The header declares 14 PRD-pinned template stubs: 7 widths
// (i1, i8, i16, i32, i64, f32, f64) × 2 variants per width
// (Q+Q `_iW`/`_fW` and Q+C `_iW_hl`/`_fW_hl`). Bodies for the 12
// newly-added symbols (every width pair except i32) land in M07;
// only the existing 2 i32 bodies are linkable today.
//
// So this test must NOT take the address of any template symbol —
// that would force a relocation against symbols with no definition
// in the GTest binary and fail at link time. Strategy mirrors
// M02's test_cq_mid_compiles.cpp and M04's test_cq_runtime_compiles.cpp:
// `decltype(<name>)` queries the *declared* function type without
// producing a relocation, and `static_assert` pins each declaration's
// full signature to the PRD spec. A green compile of this TU IS the
// assertion that the header parses and every signature is byte-exact.
//
// Specs: phases/phase2/PRD.md §"Stub template library" (lines 153-176);
// phases/phase2/PLAN.md §4.5 (lines 430-452).
#include <gtest/gtest.h>

#include <cstdint>
#include <type_traits>

#include "cq_templates.h"

namespace {

// Lightweight signature matcher: `signature_is<F, R, Args...>` is true
// iff `F` is the function type `R(Args...)`. `decltype(name)` of a
// function declaration yields exactly that function type, so this is
// a pure compile-time identity check — no ODR-use, no relocation.
template <class F, class R, class... A>
inline constexpr bool signature_is = std::is_same_v<F, R(A...)>;

// ---------------------------------------------------------------------
// Add Q+Q — 7 widths. PRD §"Stub template library" lines 159-170:
//   int32_t cq_template_add_iW(int32_t a_handle, int32_t b_handle);
//   int32_t cq_template_add_fW(int32_t a_handle, int32_t b_handle);
// Both args are handles (int32_t), so every Q+Q signature collapses
// to the same `(int32_t, int32_t) -> int32_t` shape regardless of
// width — width lives in the symbol name, not the parameter type.
// ---------------------------------------------------------------------
static_assert(signature_is<decltype(cq_template_add_i1),  int32_t, int32_t, int32_t>, "cq_template_add_i1");
static_assert(signature_is<decltype(cq_template_add_i8),  int32_t, int32_t, int32_t>, "cq_template_add_i8");
static_assert(signature_is<decltype(cq_template_add_i16), int32_t, int32_t, int32_t>, "cq_template_add_i16");
static_assert(signature_is<decltype(cq_template_add_i32), int32_t, int32_t, int32_t>, "cq_template_add_i32");
static_assert(signature_is<decltype(cq_template_add_i64), int32_t, int32_t, int32_t>, "cq_template_add_i64");
static_assert(signature_is<decltype(cq_template_fadd_f32), int32_t, int32_t, int32_t>, "cq_template_fadd_f32");
static_assert(signature_is<decltype(cq_template_fadd_f64), int32_t, int32_t, int32_t>, "cq_template_fadd_f64");

// ---------------------------------------------------------------------
// Add Q+C — 7 widths. PRD §"Stub template library" lines 160-170:
//   int32_t cq_template_add_iW_hl(int32_t a_handle, <width-typed> b_classical);
//   int32_t cq_template_add_fW_hl(int32_t a_handle, <width-typed> b_classical);
// The `_hl` (handle/literal) suffix distinguishes the mixed Q+C variant
// — lhs is a tainted handle (int32_t), rhs is a width-typed classical
// literal (the same width family as the corresponding cqrt_alloc_*
// parameter). Return is always int32_t (a fresh handle from
// cqrt_alloc_handle).
// ---------------------------------------------------------------------
static_assert(signature_is<decltype(cq_template_add_i1_hl),  int32_t, int32_t, bool>,    "cq_template_add_i1_hl");
static_assert(signature_is<decltype(cq_template_add_i8_hl),  int32_t, int32_t, int8_t>,  "cq_template_add_i8_hl");
static_assert(signature_is<decltype(cq_template_add_i16_hl), int32_t, int32_t, int16_t>, "cq_template_add_i16_hl");
static_assert(signature_is<decltype(cq_template_add_i32_hl), int32_t, int32_t, int32_t>, "cq_template_add_i32_hl");
static_assert(signature_is<decltype(cq_template_add_i64_hl), int32_t, int32_t, int64_t>, "cq_template_add_i64_hl");
static_assert(signature_is<decltype(cq_template_fadd_f32_hl), int32_t, int32_t, float>,   "cq_template_fadd_f32_hl");
static_assert(signature_is<decltype(cq_template_fadd_f64_hl), int32_t, int32_t, double>,  "cq_template_fadd_f64_hl");

}  // namespace

// Body is intentionally empty — all checks are static_asserts evaluated
// at compile time. A green build of this TU IS the assertion that the
// header is well-formed and all 14 PRD-pinned declarations (7 widths ×
// 2 variants) are signature-correct.
TEST(CqTemplatesCompiles, HeaderCompilesStandalone) {
    SUCCEED();
}
