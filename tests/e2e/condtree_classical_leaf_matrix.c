/* condtree_classical_leaf_matrix.c — bd test_C_libtooling-xdu2.13: a CLASSICAL
 * leaf of a mixed `and`/`or` node in a 4.4 DATA select's condition tree is the
 * LITERAL of the existing `cq_template_{and,or}_i1_hl` (ir-pass/include/
 * CondLiteral.h). Each CASE is compiled independently at clang -O1 by
 * run_railbank_dynamic_matrix.py; expectations are in the .cases.json sidecar.
 * No row is a rail bank. Every classical operand derives from argv (bd 46oo:
 * a constant-propagated guard is deleted before the pass sees it).
 */
#include "CQ.h"
#include <stdlib.h>

#define CASE_AND 1                /* if (q && m == n) a += 3 */
#define CASE_AND_CLASSICAL_FIRST 2 /* if (m == n && q) */
#define CASE_OR 3                 /* if (q || m == n) */
#define CASE_ROW13 4              /* railbank_dynamic_matrix.c row 13, verbatim */
#define CASE_SUBTREE 5            /* q > 2 && m == n && n > 3: one literal subtree */
#define CASE_TABLE_LOOP 6         /* q && m == n, int accumulators, fixed table, invariant q */
#define CASE_PHASE 7              /* the same tree at the branch phase */
#define CASE_BOOL_RAIL 8          /* _Bool b && m == n: rail sibling */
#define CASE_XOR 9                /* (q > 2) != (m == n) */
#define CASE_PERTRIP_ACC 10       /* per-trip theta, q && m == n, a += 3 (rolled) */
#define CASE_PERTRIP_ACC_TWIN 11  /* CASE 10 hand-unrolled for n == 3 */
#define CASE_VARYING_LEAF 12      /* per-trip theta, q > 1 && i < m (the literal varies) */
#define CASE_VARYING_LEAF_TWIN 13 /* CASE 12 hand-unrolled for n == 3 */
#define CASE_ROUND2 14            /* the literal reads a 6.5 classical-call merge */
#define CASE_TERNARY 15           /* a = (q && m == n) ? a + 3 : a - 1 */
#define CASE_VALUE_ARM_BR 16      /* per-trip theta, a += tbl[i]: a `br` value arm, not a select */
#define CASE_OR_LOOP 17           /* per-trip theta, q > 1 || m == n (an `or` literal, invariant) */
#define CASE_OR_LOOP_TWIN 18      /* CASE 17 hand-unrolled for n == 3 */

#ifndef CASE
#define CASE CASE_AND
#endif

static const int tbl[8] = {3, 1, 4, 1, 5, 9, 2, 6};

#if CASE == CASE_AND || CASE == CASE_AND_CLASSICAL_FIRST || CASE == CASE_OR || \
    CASE == CASE_SUBTREE || CASE == CASE_XOR || CASE == CASE_TERNARY
__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25);
    int a = 7;
#if CASE == CASE_AND
    if (q && m == n) a += 3;
#elif CASE == CASE_AND_CLASSICAL_FIRST
    if (m == n && q) a += 3;
#elif CASE == CASE_OR
    if (q || m == n) a += 3;
#elif CASE == CASE_SUBTREE
    if (q > 2 && m == n && n > 3) a += 3;
#elif CASE == CASE_XOR
    if ((q > 2) != (m == n)) a += 3;
#elif CASE == CASE_TERNARY
    a = (q && m == n) ? a + 3 : a - 1;
#endif
    return cq_measure(q) + cq_measure(a);
}
int main(int argc, char **argv) {
    return slice(argc, argc > 1 ? atoi(argv[1]) : 0);
}

#elif CASE == CASE_ROW13
/* Verbatim railbank_dynamic_matrix.c CASE_SPEC_GUARDED_BOUND. The select lowers
 * (xdu2.13); the loop layer's round-2 grant re-ask, which declined here on the
 * NULLED root of the erased LICM-hoisted `and` (TRACK_E_xdu2_13.md §4), re-derives
 * the grant under FINAL taint since bd xdu2.16, and the row ACCEPTS. */
__attribute__((noinline)) static int slice(int n, int m) {
    if (n <= 0 || m <= 0) return 0;
    int p[m];
    for (int i = 0; i < m; ++i) p[i] = i + 3;
    int q = cq_theta(0, 0.25);
    int a = 0, z = 0;
    for (int i = 0; i < n; ++i)
        if (q && m == n) { a += p[i]; z -= p[i]; }
    return cq_measure(q) + cq_measure(a) + cq_measure(z);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1, argc); }

#elif CASE == CASE_TABLE_LOOP
__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25);
    int a = 0, z = 0;
    for (int i = 0; i < n && i < 8; ++i)
        if (q && m == n) { a += tbl[i]; z -= tbl[i]; }
    return cq_measure(q) + cq_measure(a) + cq_measure(z);
}
int main(int argc, char **argv) {
    return slice(argc, argc > 1 ? atoi(argv[1]) : 0);
}

#elif CASE == CASE_PHASE
__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25);
    if (q && m == n) cq_phi(0.5);
    return cq_measure(q);
}
int main(int argc, char **argv) {
    return slice(argc, argc > 1 ? atoi(argv[1]) : 0);
}

#elif CASE == CASE_BOOL_RAIL
__attribute__((noinline)) static int slice(int n, int m) {
    _Bool b = cq_theta((_Bool)0, 0.5);
    int a = 7;
    if (b && m == n) a += 3;
    return cq_measure(b) + cq_measure(a);
}
int main(int argc, char **argv) {
    return slice(argc, argc > 1 ? atoi(argv[1]) : 0);
}

#elif CASE == CASE_PERTRIP_ACC
/* A fresh register per trip; the int accumulator is the loop-carried HANDLE
 * variable (bd zujr). NOT a byte-identical twin of CASE 11: the rolled form
 * promotes the classical seed to a handle before trip 1, while the unrolled
 * twin's trip-1 select has CLASSICAL arms — a pre-existing first-trip spelling
 * difference unrelated to the literal (later trips agree up to handle numbers,
 * measured, TRACK_E_xdu2_13.md §5). Both rows are accepts. */
__attribute__((noinline)) static int slice(int n, int m) {
    int a = 0;
    for (int i = 0; i < n; ++i) {
        int q = cq_theta(i, 0.25);
        if (q && m == n) a += 3;
    }
    return cq_measure(a);
}
int main(int argc, char **argv) {
    return slice(argc > 1 ? atoi(argv[1]) : 0, argc > 2 ? atoi(argv[2]) : 0);
}

#elif CASE == CASE_PERTRIP_ACC_TWIN
/* CASE 10 with n == 3 unrolled by hand (an accept row; see CASE 10). */
__attribute__((noinline)) static int slice(int n, int m) {
    int a = 0;
    int q0 = cq_theta(0, 0.25);
    if (q0 && m == n) a += 3;
    int q1 = cq_theta(1, 0.25);
    if (q1 && m == n) a += 3;
    int q2 = cq_theta(2, 0.25);
    if (q2 && m == n) a += 3;
    return cq_measure(a);
}
int main(int argc, char **argv) {
    return slice(argc > 1 ? atoi(argv[1]) : 0, argc > 2 ? atoi(argv[2]) : 0);
}

#elif CASE == CASE_VARYING_LEAF || CASE == CASE_OR_LOOP
/* The literal `i < m` changes every trip; each trip measures its own result. */
__attribute__((noinline)) static int slice(int n, int m) {
    int s = 0;
    for (int i = 0; i < n; ++i) {
        int q = cq_theta(i, 0.25);
        int a = 7;
#if CASE == CASE_VARYING_LEAF
        if (q > 1 && i < m) a += 3;
#else
        if (q > 1 || m == n) a += 3;
#endif
        s += cq_measure(a);
    }
    return s;
}
int main(int argc, char **argv) {
    return slice(argc > 1 ? atoi(argv[1]) : 0, argc > 2 ? atoi(argv[2]) : 0);
}

#elif CASE == CASE_VARYING_LEAF_TWIN || CASE == CASE_OR_LOOP_TWIN
#if CASE == CASE_VARYING_LEAF_TWIN
#define COND(q, i, m, n) ((q) > 1 && (i) < (m))
#else
#define COND(q, i, m, n) ((q) > 1 || (m) == (n))
#endif
/* CASE 12 / CASE 17 with n == 3 unrolled by hand (argv "3" "2": CASE 12's
 * literal is 1, 1, 0; CASE 17's `m == n` is 0 on every trip). */
__attribute__((noinline)) static int slice(int n, int m) {
    int s = 0;
    int q0 = cq_theta(0, 0.25);
    int a0 = 7;
    if (COND(q0, 0, m, n)) a0 += 3;
    s += cq_measure(a0);
    int q1 = cq_theta(1, 0.25);
    int a1 = 7;
    if (COND(q1, 1, m, n)) a1 += 3;
    s += cq_measure(a1);
    int q2 = cq_theta(2, 0.25);
    int a2 = 7;
    if (COND(q2, 2, m, n)) a2 += 3;
    s += cq_measure(a2);
    return s;
}
int main(int argc, char **argv) {
    return slice(argc > 1 ? atoi(argv[1]) : 0, argc > 2 ? atoi(argv[2]) : 0);
}

#elif CASE == CASE_ROUND2
/* `y` is a 6.5 classical-call merge: classical at round 1, the emitter's `%out`
 * rail after the round-2 fixpoint. The literal `y > 7` is then quantum — the
 * post-fixpoint re-ask declines it. */
__attribute__((noinline, const)) static int f(int a) { return a + 100; }
__attribute__((noinline)) static int slice(int u, int a) {
    int q = cq_theta(u, 0.5);
    int y = 5;
    if (q > 3) y = f(a);
    int z = 99;
    if (y > 7 && q) z = 1;
    return cq_measure(z) + cq_measure(y);  /* `y` live after: the compare stays in the merge */
}
int main(int argc, char **argv) {
    return slice(argc, argc > 1 ? atoi(argv[1]) : 0);
}
#elif CASE == CASE_VALUE_ARM_BR
/* The arm's table load keeps clang from if-converting: the tree reaches the
 * VALUE-ARM `br` consumer (`ArmClassify`), which does not take a literal in this
 * increment, and PredMux has no witness to flatten it (gate=W-witness). */
__attribute__((noinline)) static int slice(int n, int m) {
    int a = 0;
    for (int i = 0; i < n && i < 8; ++i) {
        int q = cq_theta(i, 0.25);
        if (q && m == n) a += tbl[i];
    }
    return cq_measure(a);
}
int main(int argc, char **argv) {
    return slice(argc > 1 ? atoi(argv[1]) : 0, argc > 2 ? atoi(argv[2]) : 0);
}
#endif
