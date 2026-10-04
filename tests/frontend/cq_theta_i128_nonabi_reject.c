// RUN: not %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o /dev/null 2>&1 | %filecheck %s

// cq_theta_i128_nonabi_reject.c — Phase 7.1 follow-up n0ui (the Tier-2 source/sink
// guard). i128 is supported as a Tier-1 INTERMEDIATE width (i64 theta -> zext
// i128 -> i128 arith -> trunc i64 -> i64 measure), but NOT as a quantum
// SOURCE/SINK: the C ABI shreds a `__int128` param/return into a {i64,i64}
// aggregate, so i128 source/sink is deferred (Tier-2). This fixture pins that a
// `__int128` directly as a `cq_theta` source is a SOURCE-LOCATED COMPILE ERROR at
// the C frontend — the cq_theta/cq_phi/cq_measure _Generic blocks carry NO i128
// arm and NO `default:` arm, so the realistic user-facing path cannot silently
// produce a classical no-op (the same deliberate block as _BitInt(N); cf.
// cq_theta_bitint_nonabi_reject.c). A manually-declared extern `cq_theta_si128`
// is, like any unrecognized suffix (cf. cq_measure_xyz999), passthrough by the
// documented collection-boundary design — never reachable through CQ.h.

unsigned __int128 seed_i128(unsigned __int128 v) {
    // CHECK: error: controlling expression type 'unsigned __int128 *' not compatible with any generic association type
    cq_theta(&v, 0.5);
    return v;
}
