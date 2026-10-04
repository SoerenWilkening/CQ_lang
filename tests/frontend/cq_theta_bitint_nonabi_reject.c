// RUN: not %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o /dev/null 2>&1 | %filecheck %s

// cq_theta_bitint_nonabi_reject.c — Phase 7.1 Increment D / R-D decline.
//
// A non-power-of-2 `_BitInt(N)` is NOT a directly-seedable taint source: C11
// `_Generic` matches concrete types and cannot enumerate arbitrary `_BitInt(N)`,
// so `cq_theta` on a `_BitInt(24)` has no matching association and clang errors
// at the C frontend — an acceptable, source-located loud decline BEFORE the pass
// runs. This is PERMANENT within 7.1: the cq_theta/cq_phi/cq_measure _Generic
// blocks deliberately carry NO `default:` arm (a default would silently route
// `_BitInt(24)` to a wrong-width symbol). Intermediate `_BitInt(N)` round+mask
// support is a tracked pre-freeze follow-up (D5), out of this increment.

_BitInt(24) seed_bitint(_BitInt(24) v) {
    // CHECK: error: controlling expression type '_BitInt(24) *' not compatible with any generic association type
    cq_theta(&v, 0.5);
    return v;
}
