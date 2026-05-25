// Compile-smoke test for runtime/cq_runtime.h (cq-p2-m04).
//
// The header declares 15 PRD-pinned runtime symbols (7 alloc + 7
// measure + cqrt_free) plus the internal helper cqrt_alloc_handle.
// Bodies for the 12 newly-added symbols (alloc/measure for i1, i8,
// i16, i64, f32, f64) land in M06; only the existing 3 bodies
// (cqrt_alloc_i32, cqrt_measure_i32, cqrt_free) and the helper body
// are linkable today.
//
// So this test must NOT take the address of any runtime symbol — that
// would force a relocation against symbols with no definition in the
// GTest binary and fail at link time. Strategy mirrors M02's
// test_cq_mid_compiles.cpp: `decltype(<name>)` queries the *declared*
// function type without producing a relocation, and `static_assert`
// pins each declaration's full signature to the PRD spec. A green
// compile of this TU IS the assertion that the header parses and
// every signature is byte-exact.
//
// Specs: phases/phase2/PRD.md §"Stub libcq_runtime" (lines 122-149);
// phases/phase2/PLAN.md §4.4 (lines 388-426).
#include <gtest/gtest.h>

#include <cstdint>
#include <type_traits>

#include "cq_runtime.h"

namespace {

// Lightweight signature matcher: `signature_is<F, R, Args...>` is true
// iff `F` is the function type `R(Args...)`. `decltype(name)` of a
// function declaration yields exactly that function type, so this is
// a pure compile-time identity check — no ODR-use, no relocation.
template <class F, class R, class... A>
inline constexpr bool signature_is = std::is_same_v<F, R(A...)>;

// ---------------------------------------------------------------------
// Allocation — 7 widths. PRD §"Stub libcq_runtime" lines 128-134:
//   int32_t cqrt_alloc_iW(<width-typed value>);
//   int32_t cqrt_alloc_fW(<width-typed value>);
// The runtime ABI is width-only: signedness lives in the IR-pass
// opcode at the call site, not in the symbol. So there are 5 integer
// widths (i1, i8, i16, i32, i64) and 2 float widths (f32, f64).
// ---------------------------------------------------------------------
static_assert(signature_is<decltype(cqrt_alloc_i1),  int32_t, bool>,    "cqrt_alloc_i1");
static_assert(signature_is<decltype(cqrt_alloc_i8),  int32_t, int8_t>,  "cqrt_alloc_i8");
static_assert(signature_is<decltype(cqrt_alloc_i16), int32_t, int16_t>, "cqrt_alloc_i16");
static_assert(signature_is<decltype(cqrt_alloc_i32), int32_t, int32_t>, "cqrt_alloc_i32");
static_assert(signature_is<decltype(cqrt_alloc_i64), int32_t, int64_t>, "cqrt_alloc_i64");
static_assert(signature_is<decltype(cqrt_alloc_f32), int32_t, float>,   "cqrt_alloc_f32");
static_assert(signature_is<decltype(cqrt_alloc_f64), int32_t, double>,  "cqrt_alloc_f64");

// ---------------------------------------------------------------------
// Measurement — 7 widths. PRD §"Stub libcq_runtime" lines 137-139:
//   <width-typed return> cqrt_measure_iW(int32_t handle);
//   <width-typed return> cqrt_measure_fW(int32_t handle);
// Return type mirrors the corresponding allocator's parameter type;
// in Phase 2 every body returns 0 (runtime is trace-only).
// ---------------------------------------------------------------------
static_assert(signature_is<decltype(cqrt_measure_i1),  bool,    int32_t>, "cqrt_measure_i1");
static_assert(signature_is<decltype(cqrt_measure_i8),  int8_t,  int32_t>, "cqrt_measure_i8");
static_assert(signature_is<decltype(cqrt_measure_i16), int16_t, int32_t>, "cqrt_measure_i16");
static_assert(signature_is<decltype(cqrt_measure_i32), int32_t, int32_t>, "cqrt_measure_i32");
static_assert(signature_is<decltype(cqrt_measure_i64), int64_t, int32_t>, "cqrt_measure_i64");
static_assert(signature_is<decltype(cqrt_measure_f32), float,   int32_t>, "cqrt_measure_f32");
static_assert(signature_is<decltype(cqrt_measure_f64), double,  int32_t>, "cqrt_measure_f64");

// ---------------------------------------------------------------------
// Free — width-irrelevant (handle-typed only). PRD line 142.
// ---------------------------------------------------------------------
static_assert(signature_is<decltype(cqrt_free), void, int32_t>, "cqrt_free");

// ---------------------------------------------------------------------
// Internal helper — not one of the 15 PRD symbols, but retained per
// PLAN.md §4.4 so cq_templates can stay handle-monotonic.
// ---------------------------------------------------------------------
static_assert(signature_is<decltype(cqrt_alloc_handle), int32_t>, "cqrt_alloc_handle");

}  // namespace

// Body is intentionally empty — all checks are static_asserts evaluated
// at compile time. A green build of this TU IS the assertion that the
// header is well-formed and all 15 PRD-pinned declarations (+ the
// retained cqrt_alloc_handle helper) are signature-correct.
TEST(CqRuntimeCompiles, HeaderCompilesStandalone) {
    SUCCEED();
}
