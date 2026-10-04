// RUN: %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s

// bd test_C_libtooling-fmt3 (owner ruling 2026-09-28, option B): every
// `cq_theta_*` declaration in CQ.h carries `nomerge`, so `-O1` can no longer MERGE
// two DIRECT `cq_theta` calls that CQ reads as DIFFERENT registers. ⚠ Direct calls
// only: clang puts `nomerge` on the call site, so a call through a function pointer
// still merges (bd `4e4p`), and the arg-0 `select` fold needs no merge (bd `uw5u`) —
// both open, PRE-EXISTING. This file pins only `cq_theta_si32`'s token;
// `cq_theta_nomerge_widths.c` pins all 16.
//
// WHY. IPSCCP substitutes a register pinned on an edge (`t := 5` under `t == 5`)
// into the arm's `cq_theta`; if the other arm is `cq_theta(5, θ)` the two calls
// became IDENTICAL and the late SimplifyCFG hoisted them and DELETED THE BRANCH.
// A second route sinks two calls that differ in ONE operand and folds the φ's
// `select (q == 20), t, 5` to `5` (InstSimplify simplifyWithOpReplaced). Either
// way the module that reached cq-lowering was the stage-1 IR of a DIFFERENT,
// legitimate program (`r = cq_theta(5, θ)` with `t` untouched) and was compiled
// as that — silently (TRACK_FMT3.md §1). With `nomerge` the branch survives and
// the pass declines the shape; the lit fixtures
// `control_inplace_ry_reject_stateprep_nomerge_*.ll` pin THAT half (this suite
// has clang but no cq-opt, `ir-pass/test` has cq-opt but no clang — the two
// halves are pinned where each tool lives).
//
// RED on the pre-fmt3 header (each merged function has one call and no inner
// branch), GREEN with the attribute — measured both ways.

// a6: the fmt3 exhibit — nested literal prep, the pin on the ERASED inner edge.
int a6(int m) {
    int q = m; cq_theta(&q, .5); int t = q / 4; int q2 = 7; cq_theta(&q2, .4); int r = 5;
    if (q2 > 3) { if (t == 5) { r = t; cq_theta(&r, .9); } else { r = 5; cq_theta(&r, .9); } }
    return cq_measure(r) + cq_measure(t) + cq_measure(q2);
}
// CHECK-LABEL: define {{.*}} @a6(
// CHECK:       br i1
// CHECK:       br i1
// CHECK-COUNT-2: call i32 @cq_theta_si32(i32 noundef 5, double noundef 9.000000e-01)
// CHECK:       ret i32

// n13: the SECOND route — the rotated register `t` is NOT the compare's operand.
int n13(int m) {
    int q = m; cq_theta(&q, .5); int t = q / 4; int q2 = 7; cq_theta(&q2, .4); int r = 5;
    if (q2 > 3) { if (q == 20) { r = t; cq_theta(&r, .9); } else { r = 5; cq_theta(&r, .9); } }
    return cq_measure(r) + cq_measure(t) + cq_measure(q2);
}
// CHECK-LABEL: define {{.*}} @n13(
// CHECK:       br i1
// CHECK:       br i1
// CHECK:       call i32 @cq_theta_si32(i32 noundef %{{[0-9]+}}, double noundef 9.000000e-01)
// CHECK:       call i32 @cq_theta_si32(i32 noundef 5, double noundef 9.000000e-01)
// CHECK:       ret i32

// n9: NO enclosing region — the merge used to leave an UNCONDITIONAL prep.
int n9(int m) {
    int q = m; cq_theta(&q, .5); int t = q / 4; int r;
    if (t == 5) { r = t; cq_theta(&r, .9); } else { r = 5; cq_theta(&r, .9); }
    return cq_measure(r) + cq_measure(t);
}
// CHECK-LABEL: define {{.*}} @n9(
// CHECK:       br i1
// CHECK-COUNT-2: call i32 @cq_theta_si32(i32 noundef 5, double noundef 9.000000e-01)
// CHECK:       ret i32

// n17f: no region, the second route (`W = q + 1`, compare on `q`).
int n17f(int m) {
    int q = m; cq_theta(&q, .5); int W = q + 1; int r;
    if (q == 5) { r = W; cq_theta(&r, .9); } else { r = 6; cq_theta(&r, .9); }
    return cq_measure(r) + cq_measure(W) + cq_measure(q);
}
// CHECK-LABEL: define {{.*}} @n17f(
// CHECK:       br i1
// CHECK:       call i32 @cq_theta_si32(i32 noundef %{{[0-9]+}}, double noundef 9.000000e-01)
// CHECK:       call i32 @cq_theta_si32(i32 noundef 6, double noundef 9.000000e-01)
// CHECK:       ret i32

// THE ACCEPTED COST, pinned so it cannot change silently: the if/else over ONE
// register is no longer folded into one call with a SELECTED ANGLE (the Ry stem
// of AngleSelectEmit is reached from C by the TERNARY spelling, below).
int ry_ifelse(int m, int c) {
    int q = m; cq_theta(&q, .5); int r = 3; cq_theta(&r, .2);
    if (q > c) cq_theta(&r, .9); else cq_theta(&r, .3);
    return cq_measure(r) + cq_measure(q);
}
// CHECK-LABEL: define {{.*}} @ry_ifelse(
// CHECK-NOT:   select
// CHECK:       br i1
// CHECK:       call i32 @cq_theta_si32(i32 noundef %{{[0-9]+}}, double noundef 9.000000e-01)
// CHECK:       call i32 @cq_theta_si32(i32 noundef %{{[0-9]+}}, double noundef 3.000000e-01)
// CHECK:       ret i32

int ry_ternary(int m, int c) {
    int q = m; cq_theta(&q, .5); int r = 3; cq_theta(&r, .2);
    cq_theta(&r, (q > c) ? .9 : .3);
    return cq_measure(r) + cq_measure(q);
}
// CHECK-LABEL: define {{.*}} @ry_ternary(
// CHECK:       [[SEL:%[0-9]+]] = select i1 %{{[0-9]+}}, double 9.000000e-01, double 3.000000e-01
// CHECK:       call i32 @cq_theta_si32(i32 noundef %{{[0-9]+}}, double noundef [[SEL]])
// CHECK:       ret i32

// `cq_phi` does NOT carry `nomerge` (TRACK_FMT3.md §9.6): a branch phase has no
// register, so there is no register identity a merge could confuse, and its
// if/else STILL folds to one call with a selected angle — the Rz stem of
// AngleSelectEmit keeps its C spelling.
void rz_ifelse(int m, int c) {
    int q = m; cq_theta(&q, .5);
    if (q > c) cq_phi(.9); else cq_phi(.3);
    (void) cq_measure(q);
}
// CHECK-LABEL: define {{.*}} @rz_ifelse(
// CHECK:       [[PSEL:%[0-9]+]] = select i1 %{{[0-9]+}}, double 9.000000e-01, double 3.000000e-01
// CHECK:       call void @cq_phi(double noundef [[PSEL]])
// CHECK-NOT:   call void @cq_phi(
// CHECK:       ret void
