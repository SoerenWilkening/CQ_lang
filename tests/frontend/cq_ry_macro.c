// RUN: %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s

// cq_ry(x, θ) — the statement surface for an in-place Ry (PRD
// `retire-swap-route-PRD.md` §4.2, owner decision D5; bd 3qlq Inc 0).
//
// `cq_ry(x, θ)` is defined as `((x) = cq_theta((x), (θ)))`, so it is not a new
// primitive and it is NOT a new taint source: it is the assignment made
// syntactically explicit, because a rotation CONSUMES the old name (the linear
// rule, docs/frontend.md §3.2). This fixture pins that the two spellings reach
// the IR pass as the SAME construct at -O1 — the same `@cq_theta_<sfx>` call,
// with its result feeding the next use — so nothing downstream (taint, the
// stale-record fences, the control emitters) can tell them apart.
//
// The assertion is made by repeating ONE pattern block per width against BOTH
// the macro and the spelled-out function: a pattern that matches both bodies is
// a statement that the bodies agree. Every CHECK line below was DERIVED from
// the clang-19 output, never hand-written (the Inc-4 handle-name lesson).
//
// It starts RED: against the pre-Inc-0 header clang-19 exits 1 with
// "call to undeclared function 'cq_ry'" (measured, 2026-09-05). Thereafter it
// is a standing regression guard.
//
// The pattern-block assertion is weaker than what was MEASURED: with the three
// pairs extracted from the -O1 module and the function name normalised, the
// macro and spelled-out bodies are byte-IDENTICAL at all three widths (6 / 5 / 5
// lines) —
//   clang -Iinclude -include CQ.h -O1 -emit-llvm -S <this file> -o fix.ll
//   sed -n '/^define .*@macro_i32(/,/^}/p'   fix.ll | sed s/@macro_i32/@FN/   > m
//   sed -n '/^define .*@spelled_i32(/,/^}/p' fix.ll | sed s/@spelled_i32/@FN/ > s
//   cmp m s
// That is not spelled as a RUN line because it needs two streams and a temp
// file; the CHECK blocks below assert the part FileCheck can assert alone.
//
// Widths: `int` (`@cq_theta_si32`, chained twice so the linear chain is
// visible), `_Bool` (`@cq_theta_i1`) and `double` (`@cq_theta_f64`).

#include <stdbool.h>

/* --- int: two chained rotations, the second consuming the first ---------- */

int macro_i32(int x) {
    cq_ry(x, 0.1);
    cq_ry(x, 0.2);                 // consumes the 1st rotation's result
    return cq_measure(x);
}
// CHECK-LABEL: define i32 @macro_i32(
// CHECK-SAME:  i32 noundef [[X:%[0-9]+]])
// CHECK-NEXT:  [[A:%[0-9]+]] = tail call i32 @cq_theta_si32(i32 noundef [[X]], double noundef 1.000000e-01)
// CHECK-NEXT:  [[B:%[0-9]+]] = tail call i32 @cq_theta_si32(i32 noundef [[A]], double noundef 2.000000e-01)
// CHECK-NEXT:  [[C:%[0-9]+]] = tail call i32 @cq_measure_si32(i32 noundef [[B]])
// CHECK-NEXT:  ret i32 [[C]]

int spelled_i32(int x) {
    x = cq_theta(x, 0.1);
    x = cq_theta(x, 0.2);
    return cq_measure(x);
}
// CHECK-LABEL: define i32 @spelled_i32(
// CHECK-SAME:  i32 noundef [[X:%[0-9]+]])
// CHECK-NEXT:  [[A:%[0-9]+]] = tail call i32 @cq_theta_si32(i32 noundef [[X]], double noundef 1.000000e-01)
// CHECK-NEXT:  [[B:%[0-9]+]] = tail call i32 @cq_theta_si32(i32 noundef [[A]], double noundef 2.000000e-01)
// CHECK-NEXT:  [[C:%[0-9]+]] = tail call i32 @cq_measure_si32(i32 noundef [[B]])
// CHECK-NEXT:  ret i32 [[C]]

/* --- _Bool: the i1 width ------------------------------------------------- */

bool macro_i1(bool b) {
    cq_ry(b, 0.3);
    return cq_measure(b);
}
// CHECK-LABEL: define zeroext i1 @macro_i1(
// CHECK-SAME:  i1 noundef zeroext [[X:%[0-9]+]])
// CHECK-NEXT:  [[A:%[0-9]+]] = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext [[X]], double noundef 3.000000e-01)
// CHECK-NEXT:  [[B:%[0-9]+]] = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext [[A]])
// CHECK-NEXT:  ret i1 [[B]]

bool spelled_i1(bool b) {
    b = cq_theta(b, 0.3);
    return cq_measure(b);
}
// CHECK-LABEL: define zeroext i1 @spelled_i1(
// CHECK-SAME:  i1 noundef zeroext [[X:%[0-9]+]])
// CHECK-NEXT:  [[A:%[0-9]+]] = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext [[X]], double noundef 3.000000e-01)
// CHECK-NEXT:  [[B:%[0-9]+]] = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext [[A]])
// CHECK-NEXT:  ret i1 [[B]]

/* --- double: an fp width, and the angle stays a separate `double` operand
       (Rule 3: arg-1 is classical at every width) -------------------------- */

double macro_f64(double d) {
    cq_ry(d, 0.4);
    return cq_measure(d);
}
// CHECK-LABEL: define double @macro_f64(
// CHECK-SAME:  double noundef [[X:%[0-9]+]])
// CHECK-NEXT:  [[A:%[0-9]+]] = tail call double @cq_theta_f64(double noundef [[X]], double noundef 4.000000e-01)
// CHECK-NEXT:  [[B:%[0-9]+]] = tail call double @cq_measure_f64(double noundef [[A]])
// CHECK-NEXT:  ret double [[B]]

double spelled_f64(double d) {
    d = cq_theta(d, 0.4);
    return cq_measure(d);
}
// CHECK-LABEL: define double @spelled_f64(
// CHECK-SAME:  double noundef [[X:%[0-9]+]])
// CHECK-NEXT:  [[A:%[0-9]+]] = tail call double @cq_theta_f64(double noundef [[X]], double noundef 4.000000e-01)
// CHECK-NEXT:  [[B:%[0-9]+]] = tail call double @cq_measure_f64(double noundef [[A]])
// CHECK-NEXT:  ret double [[B]]

// The macro takes an lvalue and assigns to it, so it is a STATEMENT, not an
// expression to be nested; `cq_theta` stays the expression form and is how
// state prep is written (`r = cq_theta(5, θ)` — a fresh register seeded with 5,
// which has no in-place spelling). No CHECK is owed for that; it is why the
// header keeps both.
