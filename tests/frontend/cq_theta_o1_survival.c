// RUN: %clang %cq_include -O0 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s
// RUN: %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s
// RUN: %clang %cq_include -O2 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s
// RUN: %clang %cq_include -O3 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s

// cq_theta -O survival (PRD §2.12, §7.1). The externs carry no
// memory(...)/readonly/readnone attribute, so clang cannot CSE
// duplicate theta calls, DCE a dead-result theta, or break the chained
// data dependency at any -O level. A future CQ.h edit adding a purity
// attribute — silently dropping a qubit the user asked for — fails here.
//
// Lands green immediately (Phase 1 already shipped the cq_theta header
// slice); it is a standing regression guard, not a RED fixture.

int chained(int x) {
    cq_theta(&x, 0.1);
    cq_theta(&x, 0.2);             // consumes the 1st theta's result
    return cq_measure(x);
}
// CHECK-LABEL: define {{.*}} @chained
// CHECK:       call i32 @cq_theta_si32(
// CHECK:       call i32 @cq_theta_si32(

void dead_result(int x) {
    cq_theta(&x, 0.3);             // x is dead after it — must survive DCE
}
// CHECK-LABEL: define {{.*}} @dead_result
// CHECK:       call i32 @cq_theta_si32(

int duplicate(int x) {
    int a = x; cq_theta(&a, 0.4);
    int b = x; cq_theta(&b, 0.4);  // identical args — must NOT be CSE'd
    return cq_measure(a) + cq_measure(b);
}
// CHECK-LABEL: define {{.*}} @duplicate
// CHECK-COUNT-2: call i32 @cq_theta_si32(
