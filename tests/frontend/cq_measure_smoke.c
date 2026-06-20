// RUN: %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s

// Smoke fixture for the cq_measure intrinsic surface.
//
// Exercises the full 14-type generic-selection table from docs/frontend.md
// §3.1: one call of cq_measure(<var>) per C type. Unlike cq_theta/cq_phi,
// cq_measure takes ONLY the operand (no angle argument) — it is the sole
// measurement sink. Each call asserts the _Generic dispatch lowers to the
// type-suffixed extern @cq_measure_<sfx>. The (void) casts suppress
// -Wall -Wextra unused-result warnings; the 14 CHECK directives match in
// source order (extern returns survive -O1, so no CHECK-DAG is needed).
// This is a TEST-FIRST (RED) fixture: until the matching header slice
// declares cq_measure, clang-19 errors with "call to undeclared function
// 'cq_measure'", which is the expected failure.

#include <stdbool.h>

void use(void) {
    bool                v_i1  = 0;
    char                v_c   = 0;
    signed char         v_si8 = 0;
    unsigned char       v_ui8 = 0;
    short               v_si16 = 0;
    unsigned short      v_ui16 = 0;
    int                 v_si32 = 0;
    unsigned int        v_ui32 = 0;
    long                v_sl  = 0;
    unsigned long       v_ul  = 0;
    long long           v_sll = 0;
    unsigned long long  v_ull = 0;
    float               v_f32 = 0;
    double              v_f64 = 0;
    _Float16            v_f16 = 0;   // Phase 7.1 Increment D

    (void) cq_measure(v_i1);    // CHECK: call {{.*}} @cq_measure_i1(
    (void) cq_measure(v_c);     // CHECK: call {{.*}} @cq_measure_c(
    (void) cq_measure(v_si8);   // CHECK: call {{.*}} @cq_measure_si8(
    (void) cq_measure(v_ui8);   // CHECK: call {{.*}} @cq_measure_ui8(
    (void) cq_measure(v_si16);  // CHECK: call {{.*}} @cq_measure_si16(
    (void) cq_measure(v_ui16);  // CHECK: call {{.*}} @cq_measure_ui16(
    (void) cq_measure(v_si32);  // CHECK: call {{.*}} @cq_measure_si32(
    (void) cq_measure(v_ui32);  // CHECK: call {{.*}} @cq_measure_ui32(
    (void) cq_measure(v_sl);    // CHECK: call {{.*}} @cq_measure_sl(
    (void) cq_measure(v_ul);    // CHECK: call {{.*}} @cq_measure_ul(
    (void) cq_measure(v_sll);   // CHECK: call {{.*}} @cq_measure_sll(
    (void) cq_measure(v_ull);   // CHECK: call {{.*}} @cq_measure_ull(
    (void) cq_measure(v_f32);   // CHECK: call {{.*}} @cq_measure_f32(
    (void) cq_measure(v_f64);   // CHECK: call {{.*}} @cq_measure_f64(
    (void) cq_measure(v_f16);   // CHECK: call {{.*}} @cq_measure_f16(
}
