// RUN: %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s

// Smoke fixture for the cq_phi intrinsic surface.
//
// REWRITTEN 2026-09-05 for the REGISTER-FREE surface (bd
// test_C_libtooling-3qlq Inc 1, PRD `retire-swap-route-PRD.md` §4.1, owner
// decision D1). `cq_phi` is no longer a 15-width `_Generic` family over a
// register — it is ONE extern `void cq_phi(double)` meaning "multiply the
// amplitude of the CURRENT BRANCH by e^{i.theta}". The 14 per-type CHECK
// lines this file used to carry are GONE with the family they pinned; what
// survives -O1 to be pinned is the single void call.
//
// The two properties asserted here:
//   (1) `cq_phi(theta)` compiles as a REAL CALL to `@cq_phi(double)` — it is
//       an opaque extern, so -O1 cannot speculate, sink or delete it; the
//       IR pass is what deletes an uncontrolled one (D2), never clang.
//   (2) NO `@cq_phi_<sfx>` symbol is minted at any type. The old family is
//       removed from the header, so an old-spelling program is a COMPILE
//       error rather than a silently different lowering (there is no
//       migration shim, by design).

#include <stdbool.h>

void use(void) {
    cq_phi(0.1);           // CHECK: call void @cq_phi(double
    cq_phi(0.25);          // CHECK: call void @cq_phi(double
}

// The declaration itself is void(double) — not T(T, double).
// CHECK: declare void @cq_phi(double

// No per-type family survives anywhere in the module.
// CHECK-NOT: @cq_phi_
