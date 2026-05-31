// RUN: %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s

// Locks the _Generic resolution for the 11 stdint/stddef typedefs against
// the LP64 baseline (docs/frontend.md §3.1 notes; PRD §2.2, §2.8).
// _Generic matches by the C *standard* type the typedef resolves to, not
// by LLVM width — so e.g. size_t (→ unsigned long) dispatches to
// @cq_theta_ul.
//
// The 64-bit signed/unsigned typedefs are the one host-dependent case among
// the LP64 family: Linux x86_64 maps int64_t→long / uint64_t→unsigned long
// (→ @cq_theta_sl / @cq_theta_ul), while Darwin x86_64 maps them to
// long long / unsigned long long (→ @cq_theta_sll / @cq_theta_ull) even
// though both are LP64 (64-bit long). The CHECK lines for those two accept
// either spelling so the fixture is green on both hosts. On a non-LP64 host
// (e.g. LLP64 Windows, where long is 32-bit) the size_t / intptr_t / uintptr_t
// CHECK lines would still fail loudly — that failure is the intended signal
// pointing a porter at the documented known limitation, not a bug here.
//
// Exercises one family (cq_theta) only — the typedef→underlying-type
// resolution is identical across cq_phi/cq_measure, so one family suffices.
// No new header code is needed: this is green the moment the cq_theta
// slice (M03) is in place.

#include <stddef.h>
#include <stdint.h>

void use(void) {
    int8_t    a = 0;   (void) cq_theta(a, 0.1);   // CHECK: call {{.*}} @cq_theta_si8(
    int16_t   b = 0;   (void) cq_theta(b, 0.1);   // CHECK: call {{.*}} @cq_theta_si16(
    int32_t   c = 0;   (void) cq_theta(c, 0.1);   // CHECK: call {{.*}} @cq_theta_si32(
    int64_t   d = 0;   (void) cq_theta(d, 0.1);   // CHECK: call {{.*}} @cq_theta_{{sl|sll}}(
    uint8_t   e = 0;   (void) cq_theta(e, 0.1);   // CHECK: call {{.*}} @cq_theta_ui8(
    uint16_t  f = 0;   (void) cq_theta(f, 0.1);   // CHECK: call {{.*}} @cq_theta_ui16(
    uint32_t  g = 0;   (void) cq_theta(g, 0.1);   // CHECK: call {{.*}} @cq_theta_ui32(
    uint64_t  h = 0;   (void) cq_theta(h, 0.1);   // CHECK: call {{.*}} @cq_theta_{{ul|ull}}(
    size_t    i = 0;   (void) cq_theta(i, 0.1);   // CHECK: call {{.*}} @cq_theta_ul(
    intptr_t  j = 0;   (void) cq_theta(j, 0.1);   // CHECK: call {{.*}} @cq_theta_sl(
    uintptr_t k = 0;   (void) cq_theta(k, 0.1);   // CHECK: call {{.*}} @cq_theta_ul(
}
