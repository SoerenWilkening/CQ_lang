// RUN: %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s
// RUN: not %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o /dev/null -DCQ_BAD_VALUE_FORM 2>&1 | %filecheck %s --check-prefix=VALUE
// RUN: not %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o /dev/null -DCQ_BAD_NO_ADDR 2>&1 | %filecheck %s --check-prefix=NOADDR
// RUN: not %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o /dev/null -DCQ_BAD_CONST 2>&1 | %filecheck %s --check-prefix=CONST
// RUN: not %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o /dev/null -DCQ_BAD_VOLATILE 2>&1 | %filecheck %s --check-prefix=VOLATILE
// RUN: not %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o /dev/null -DCQ_BAD_RVALUE 2>&1 | %filecheck %s --check-prefix=RVALUE
// RUN: not %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o /dev/null -DCQ_BAD_SIDE_EFFECT 2>&1 | %filecheck %s --check-prefix=SIDEFX
// RUN: not %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o /dev/null -DCQ_BAD_CQ_RY 2>&1 | %filecheck %s --check-prefix=CQRY

// cq_theta(&x, θ) — the in-place rotation is the ONLY spelling (bd
// test_C_libtooling-1501, owner decision 2026-10-03). It replaces
// tests/frontend/cq_ry_macro.c, which pinned the retired `cq_ry(x, θ)` macro.
//
// POSITIVE. `cq_theta(&x, θ)` must reach the IR pass as exactly the call the
// raw entry point gives, `%x2 = call @cq_theta_<sfx>(%x, θ)` with its result
// feeding the next use, so nothing downstream (taint, the stale-record fences,
// the control emitters) can tell the notation changed. Each pattern block is
// repeated against the in-place body AND the raw-entry-point body (`x =
// cq_theta_si32(x, θ)`, the IR the retired `x = cq_theta(x, θ)` produced): one
// block matching both is the statement that the bodies agree. The CHECK lines
// were derived from clang-19 output, never hand-written. Measured beyond what
// FileCheck asserts: the in-place and raw bodies are byte-identical at -O1 for
// every pair below, and the stage-1 IR of the migrated e2e corpus is
// byte-identical to the pre-migration corpus except where docs/frontend.md
// §3.2 records why.
//
// NEGATIVE. Every spelling the notation retires or forbids fails to COMPILE,
// before the pass runs: the value form (`y = cq_theta(&q, θ)`, a void
// expression), the pointer-free form, a const or volatile object, a non-lvalue,
// a pointer expression with side effects (the macro evaluates its pointer
// twice, so CQ.h raises clang's -Wassume to an error for that expansion), and
// the deleted `cq_ry`.
//
// It starts RED: on the pre-1501 header the positive run fails (`&x` has no
// generic association) and so do the negative runs whose diagnostics are new.

#include <stdbool.h>

int next_index(void);

#if defined(CQ_BAD_VALUE_FORM)
// VALUE: error: initializing 'int' with an expression of incompatible type 'void'
int bad(int q) { int y = cq_theta(&q, 0.1); return y; }
#elif defined(CQ_BAD_NO_ADDR)
// NOADDR: error: indirection requires pointer operand ('int' invalid)
int bad(int q) { cq_theta(q, 0.1); return q; }
#elif defined(CQ_BAD_CONST)
// CONST: error: controlling expression type 'const int *' not compatible with any generic association type
int bad(int q) { const int c = q; cq_theta(&c, 0.1); return c; }
#elif defined(CQ_BAD_VOLATILE)
// VOLATILE: error: controlling expression type 'volatile int *' not compatible with any generic association type
int bad(int q) { volatile int v = q; cq_theta(&v, 0.1); return v; }
#elif defined(CQ_BAD_RVALUE)
// RVALUE: error: cannot take the address of an rvalue of type 'int'
int bad(int q) { cq_theta(&5, 0.1); return q; }
#elif defined(CQ_BAD_SIDE_EFFECT)
// SIDEFX: error: assumption is ignored because it contains (potential) side-effects [-Werror,-Wassume]
int bad(int *a) { cq_theta(&a[next_index()], 0.1); return a[0]; }
#elif defined(CQ_BAD_CQ_RY)
// CQRY: error: call to undeclared function 'cq_ry'
int bad(int q) { cq_ry(q, 0.1); return q; }
#else

/* --- int: two chained rotations, the second consuming the first ---------- */

int inplace_i32(int x) {
    cq_theta(&x, 0.1);
    cq_theta(&x, 0.2);             // consumes the 1st rotation's result
    return cq_measure(x);
}
// CHECK-LABEL: define i32 @inplace_i32(
// CHECK-SAME:  i32 noundef [[X:%[0-9]+]])
// CHECK-NEXT:  [[A:%[0-9]+]] = tail call i32 @cq_theta_si32(i32 noundef [[X]], double noundef 1.000000e-01)
// CHECK-NEXT:  [[B:%[0-9]+]] = tail call i32 @cq_theta_si32(i32 noundef [[A]], double noundef 2.000000e-01)
// CHECK-NEXT:  [[C:%[0-9]+]] = tail call i32 @cq_measure_si32(i32 noundef [[B]])
// CHECK-NEXT:  ret i32 [[C]]

int raw_i32(int x) {
    x = cq_theta_si32(x, 0.1);
    x = cq_theta_si32(x, 0.2);
    return cq_measure(x);
}
// CHECK-LABEL: define i32 @raw_i32(
// CHECK-SAME:  i32 noundef [[X:%[0-9]+]])
// CHECK-NEXT:  [[A:%[0-9]+]] = tail call i32 @cq_theta_si32(i32 noundef [[X]], double noundef 1.000000e-01)
// CHECK-NEXT:  [[B:%[0-9]+]] = tail call i32 @cq_theta_si32(i32 noundef [[A]], double noundef 2.000000e-01)
// CHECK-NEXT:  [[C:%[0-9]+]] = tail call i32 @cq_measure_si32(i32 noundef [[B]])
// CHECK-NEXT:  ret i32 [[C]]

/* --- _Bool and double: the i1 width and an fp width; the angle stays a
       separate `double` operand at every width (Rule 3) -------------------- */

bool inplace_i1(bool b) {
    cq_theta(&b, 0.3);
    return cq_measure(b);
}
// CHECK-LABEL: define zeroext i1 @inplace_i1(
// CHECK-SAME:  i1 noundef zeroext [[X:%[0-9]+]])
// CHECK-NEXT:  [[A:%[0-9]+]] = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext [[X]], double noundef 3.000000e-01)
// CHECK-NEXT:  [[B:%[0-9]+]] = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext [[A]])
// CHECK-NEXT:  ret i1 [[B]]

double inplace_f64(double d) {
    cq_theta(&d, 0.4);
    return cq_measure(d);
}
// CHECK-LABEL: define double @inplace_f64(
// CHECK-SAME:  double noundef [[X:%[0-9]+]])
// CHECK-NEXT:  [[A:%[0-9]+]] = tail call double @cq_theta_f64(double noundef [[X]], double noundef 4.000000e-01)
// CHECK-NEXT:  [[B:%[0-9]+]] = tail call double @cq_measure_f64(double noundef [[A]])
// CHECK-NEXT:  ret double [[B]]

/* --- state prep goes through a variable: the seed reaches arg 0 as the
       literal, exactly as the raw `cq_theta_si32(5, θ)` ------------------- */

int inplace_prep(void) {
    int r = 5;
    cq_theta(&r, 0.5);
    return cq_measure(r);
}
// CHECK-LABEL: define i32 @inplace_prep(
// CHECK-NEXT:  [[A:%[0-9]+]] = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01)
// CHECK-NEXT:  [[B:%[0-9]+]] = tail call i32 @cq_measure_si32(i32 noundef [[A]])
// CHECK-NEXT:  ret i32 [[B]]

int raw_prep(void) {
    int r = cq_theta_si32(5, 0.5);
    return cq_measure(r);
}
// CHECK-LABEL: define i32 @raw_prep(
// CHECK-NEXT:  [[A:%[0-9]+]] = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01)
// CHECK-NEXT:  [[B:%[0-9]+]] = tail call i32 @cq_measure_si32(i32 noundef [[A]])
// CHECK-NEXT:  ret i32 [[B]]

/* --- a rotated COPY is an explicit copy: c is rotated, q keeps its value
       (the call reads %q, and %q stays live for its own measurement) ------- */

int inplace_copy(int q) {
    int c = q;
    cq_theta(&c, 0.8);
    return cq_measure(c) + cq_measure(q);
}
// CHECK-LABEL: define i32 @inplace_copy(
// CHECK-SAME:  i32 noundef [[Q:%[0-9]+]])
// CHECK-NEXT:  [[C:%[0-9]+]] = tail call i32 @cq_theta_si32(i32 noundef [[Q]], double noundef 8.000000e-01)
// CHECK-NEXT:  [[MC:%[0-9]+]] = tail call i32 @cq_measure_si32(i32 noundef [[C]])
// CHECK-NEXT:  [[MQ:%[0-9]+]] = tail call i32 @cq_measure_si32(i32 noundef [[Q]])

/* --- a memory cell and a pointer: one load, one call, one store — the
       pointer is evaluated twice by the macro and CSE'd to one address ---- */

int g[4];

void inplace_cell(int i) {
    cq_theta(&g[i], 0.6);
}
// CHECK-LABEL: define void @inplace_cell(
// CHECK:       [[P:%[0-9]+]] = getelementptr inbounds [4 x i32], ptr @g, i64 0, i64 %{{[0-9]+}}
// CHECK-NEXT:  [[V:%[0-9]+]] = load i32, ptr [[P]]
// CHECK-NEXT:  [[R:%[0-9]+]] = tail call i32 @cq_theta_si32(i32 noundef [[V]], double noundef 6.000000e-01)
// CHECK-NEXT:  store i32 [[R]], ptr [[P]]
// CHECK-NEXT:  ret void

void raw_cell(int i) {
    g[i] = cq_theta_si32(g[i], 0.6);
}
// CHECK-LABEL: define void @raw_cell(
// CHECK:       [[P:%[0-9]+]] = getelementptr inbounds [4 x i32], ptr @g, i64 0, i64 %{{[0-9]+}}
// CHECK-NEXT:  [[V:%[0-9]+]] = load i32, ptr [[P]]
// CHECK-NEXT:  [[R:%[0-9]+]] = tail call i32 @cq_theta_si32(i32 noundef [[V]], double noundef 6.000000e-01)
// CHECK-NEXT:  store i32 [[R]], ptr [[P]]
// CHECK-NEXT:  ret void

void inplace_ptr(long *p) {
    cq_theta(p, 0.7);
}
// CHECK-LABEL: define void @inplace_ptr(
// CHECK-SAME:  ptr nocapture noundef [[P:%[0-9]+]])
// CHECK-NEXT:  [[V:%[0-9]+]] = load i64, ptr [[P]]
// CHECK-NEXT:  [[R:%[0-9]+]] = tail call i64 @cq_theta_sl(i64 noundef [[V]], double noundef 0x3FE6666666666666)
// CHECK-NEXT:  store i64 [[R]], ptr [[P]]
// CHECK-NEXT:  ret void

#endif
