// RUN: %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s

// Smoke fixture for the cq_theta intrinsic surface.
//
// Exercises the full 14-type generic-selection table from docs/frontend.md
// §3.1: one in-place cq_theta(&<var>, 0.1) per C type, asserting that the
// _Generic dispatch on the POINTER type lowers to the type-suffixed extern
// @cq_theta_<sfx>. Each variable is dead after its rotation, so each call's
// result is unused; the CHECK directives match in source order (extern
// returns survive -O1, so no CHECK-DAG is needed). This is a TEST-FIRST (RED) fixture: until the
// matching header slice declares cq_theta, clang-19 errors with
// "call to undeclared function 'cq_theta'", which is the expected failure.

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

    cq_theta(&v_i1,   0.1);       // CHECK: call {{.*}} @cq_theta_i1(
    cq_theta(&v_c,    0.1);       // CHECK: call {{.*}} @cq_theta_c(
    cq_theta(&v_si8,  0.1);       // CHECK: call {{.*}} @cq_theta_si8(
    cq_theta(&v_ui8,  0.1);       // CHECK: call {{.*}} @cq_theta_ui8(
    cq_theta(&v_si16, 0.1);       // CHECK: call {{.*}} @cq_theta_si16(
    cq_theta(&v_ui16, 0.1);       // CHECK: call {{.*}} @cq_theta_ui16(
    cq_theta(&v_si32, 0.1);       // CHECK: call {{.*}} @cq_theta_si32(
    cq_theta(&v_ui32, 0.1);       // CHECK: call {{.*}} @cq_theta_ui32(
    cq_theta(&v_sl,   0.1);       // CHECK: call {{.*}} @cq_theta_sl(
    cq_theta(&v_ul,   0.1);       // CHECK: call {{.*}} @cq_theta_ul(
    cq_theta(&v_sll,  0.1);       // CHECK: call {{.*}} @cq_theta_sll(
    cq_theta(&v_ull,  0.1);       // CHECK: call {{.*}} @cq_theta_ull(
    cq_theta(&v_f32,  0.1);       // CHECK: call {{.*}} @cq_theta_f32(
    cq_theta(&v_f64,  0.1);       // CHECK: call {{.*}} @cq_theta_f64(
    cq_theta(&v_f16,  0.1);       // CHECK: call {{.*}} @cq_theta_f16(
}
