// RUN: %clang %cq_include -O0 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s
// RUN: %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s
// RUN: %clang %cq_include -O2 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s
// RUN: %clang %cq_include -O3 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s

// Inversion-bracket marker survival across the full -O matrix (docs/frontend.md
// §3.5; PRD §2.4, §7.2/§7.3). The cq_invert_begin()/cq_invert_end() macros
// lower to bare-extern calls @__cq_invert_begin()/@__cq_invert_end() that the
// IR pass detects at module scope. Those markers MUST survive dead-code
// elimination at every optimization level — LLVM cannot prove an unknown
// extern (guarded by an asm-volatile memory barrier) is side-effect-free, so
// the calls are never deleted. The four RUN lines exercise -O0/-O1/-O2/-O3.
//
// CHECK-LABEL pins the search to @use's body so that inlining at -O2/-O3
// cannot accidentally satisfy the assertions from a different caller.
//
// This is a TEST-FIRST (RED) fixture: until the matching header slice (M10)
// declares the markers and the wrapper macros, clang-19 errors with
// "call to undeclared function 'cq_invert_begin'" at all four -O levels.

void use(void) {
    cq_invert_begin();
    cq_invert_end();
}

// CHECK-LABEL: define {{.*}} @use
// CHECK:      call void @__cq_invert_begin()
// CHECK:      call void @__cq_invert_end()
