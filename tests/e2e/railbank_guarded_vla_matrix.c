/* railbank_guarded_vla_matrix.c — C-level clang -O1 admission matrix for bd
 * xdu2.8: a CLASSICAL runtime-VLA read under quantum control whose in-bounds
 * proof holds only under a CLASSICAL conjunct of the arm's own condition.
 *
 * Each CASE is compiled independently by run_railbank_dynamic_matrix.py against
 * the JSON sidecar next to this file. No row is a rail bank (the VLA is classical
 * data), so every accept row sets `require_railbank: false`. Every extent, index
 * and trip bound is derived from argc/argv so clang -O1 cannot const-fold the
 * guard away (bd 46oo).
 *
 * THE MECHANISM (PredMuxFlatten E4 (1d), GuardedClassicalRead): PredMux
 * speculates the arm's load to the region entry, where the arm-local guard is
 * not in force. The load is ADMITTED only if a classical conjunct of the arm's
 * path condition proves the index in bounds, and it is EMITTED through
 * `select (freeze idx <u freeze extent), &p[idx], &cq.guarded.read.zero`, so the
 * speculated read is in bounds on every path by construction.
 *
 * ⚠ THE ACCEPT ROWS ALL MERGE INTO `_Bool` PHIS, AND THAT IS NOT A CHOICE. A
 * guard that is a classical conjunct of the arm's condition makes that condition
 * a HYBRID classical∧quantum tree. PredMux's boolean-algebra path lowers an i1
 * merge over it (the classical leaf occupies an `_hl` literal slot); the 4.4 DATA
 * select does NOT — `classifySelectRegion` declines an untainted leaf ("a hybrid
 * classical∧quantum conjunction is out of scope", SelectClassify.cpp). So the
 * bead's own program (CASE_ROW13, `a += p[i]` into an `int`) still declines, at
 * THAT wall and no longer at E4 — same diagnostic string, different owner; the
 * lit fixture predmux_guarded_vla_reject_row13_hybrid_select.ll tells them apart.
 */
#include "CQ.h"
#include <stdlib.h>

#define CASE_IDX_GUARD 1          /* `q && k < m`, loop-free, unsigned index */
#define CASE_IDX_GUARD_FLIPPED 2  /* `m > k && q`: swapped predicate + order */
#define CASE_IDX_GUARD_QADD 3     /* the loaded value feeds a quantum add */
#define CASE_TRIP_EQ_GUARD 4      /* in a loop: `q && m == n`, per-trip bools */
#define CASE_TRIP_GE_GUARD 5      /* in a loop: `q && m >= n` */
#define CASE_ROW13 6              /* the bead's program: `int` accumulators */
#define CASE_NO_GUARD 7           /* no classical bound at all */
#define CASE_SIGNED_INDEX 8       /* `k < m` with k signed: k < 0 is OOB */
#define CASE_NONSTRICT_GUARD 9    /* `k <= m`: k == m is OOB */
#define CASE_WRONG_DIRECTION 10   /* `m < k` */
#define CASE_NE_GUARD 11          /* `q && m != n` in the loop */
#define CASE_OFFSET_READ 12       /* guard bounds p[k], not p[k + 1] */
#define CASE_TRIP_WRONG_EQ 13     /* in a loop: `q && m + 1 == n` */
#define CASE_TAINTED_INDEX 14     /* the index is quantum */
#define CASE_IDX_GUARD_TWIN 15    /* CASE 1 with the guarded read written in C */
#define CASE_ELSE_ARM_READ 16     /* read on the arm the guard does NOT dominate */
#define CASE_SIGNED_GUARD_UIDX 17 /* signed `k < m` guarding an unsigned index */
#define CASE_NOT_AND_ARM 18       /* read under `!(q && k < m)` */

#ifndef CASE
#define CASE CASE_IDX_GUARD
#endif

/* ---- loop-free, guard bounds the index directly (proof (I)) ---- */
#if CASE == CASE_IDX_GUARD || CASE == CASE_NO_GUARD || \
    CASE == CASE_NONSTRICT_GUARD || CASE == CASE_WRONG_DIRECTION || \
    CASE == CASE_IDX_GUARD_FLIPPED || CASE == CASE_OFFSET_READ || \
    CASE == CASE_IDX_GUARD_QADD
#if CASE == CASE_IDX_GUARD
#define GUARD(q, k, m) ((q) && (k) < (m))
#elif CASE == CASE_IDX_GUARD_FLIPPED
#define GUARD(q, k, m) ((m) > (k) && (q))
#elif CASE == CASE_IDX_GUARD_QADD
#define GUARD(q, k, m) ((q) && (k) < (m))
#elif CASE == CASE_NO_GUARD
#define GUARD(q, k, m) (q)
#elif CASE == CASE_NONSTRICT_GUARD
#define GUARD(q, k, m) ((q) && (k) <= (m))
#elif CASE == CASE_WRONG_DIRECTION
#define GUARD(q, k, m) ((q) && (m) < (k))
#elif CASE == CASE_OFFSET_READ
#define GUARD(q, k, m) ((q) && (k) < (m))
#endif
__attribute__((noinline)) static int slice(int m, unsigned k) {
    if (m <= 0) return 0;
    int p[m];
    for (int i = 0; i < m; ++i) p[i] = i + 3;
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    (void)r;
    _Bool b = 0, c = 0;
#if CASE == CASE_OFFSET_READ
    if (GUARD(q, k, (unsigned)m)) { b = p[k] > 4; c = p[k + 1] < 9; }
#elif CASE == CASE_IDX_GUARD_QADD
    if (GUARD(q, k, (unsigned)m)) { b = p[k] + r > 4; c = p[k] < 9; }
#else
    if (GUARD(q, k, (unsigned)m)) { b = p[k] > 4; c = p[k] < 9; }
#endif
    return cq_measure(q) + cq_measure(r) + cq_measure(b) + cq_measure(c);
}
int main(int argc, char **argv) {
    (void)argv;
    return slice(argc + 2, (unsigned)atoi(argv[argc - 1]) + (unsigned)argc);
}

/* ---- the index is signed: `k < m` does not bound a negative k ---- */
#elif CASE == CASE_SIGNED_INDEX
__attribute__((noinline)) static int slice(int m, int k) {
    if (m <= 0) return 0;
    int p[m];
    for (int i = 0; i < m; ++i) p[i] = i + 3;
    int q = cq_theta(0, 0.25);
    _Bool b = 0, c = 0;
    if (q && k < m) { b = p[k] > 4; c = p[k] < 9; }
    return cq_measure(q) + cq_measure(b) + cq_measure(c);
}
int main(int argc, char **argv) { return slice(argc + 2, atoi(argv[argc - 1]) + argc); }

/* ---- the index is quantum ---- */
#elif CASE == CASE_TAINTED_INDEX
__attribute__((noinline)) static int slice(int m) {
    if (m <= 0) return 0;
    int p[m];
    for (int i = 0; i < m; ++i) p[i] = i + 3;
    int q = cq_theta(0, 0.25);
    unsigned k = (unsigned)cq_theta(0, 0.5);
    _Bool b = 0, c = 0;
    if (q && k < (unsigned)m) { b = p[k] > 4; c = p[k] < 9; }
    return cq_measure(q) + cq_measure(b) + cq_measure(c);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }

/* ---- in a loop, guard relates extent to trip count (proof (T)) ---- */
#elif CASE == CASE_TRIP_EQ_GUARD || CASE == CASE_TRIP_GE_GUARD || \
    CASE == CASE_NE_GUARD || CASE == CASE_TRIP_WRONG_EQ
#if CASE == CASE_TRIP_EQ_GUARD
#define GUARD(q, m, n) ((q) && (m) == (n))
#elif CASE == CASE_TRIP_GE_GUARD
#define GUARD(q, m, n) ((q) && (m) >= (n))
#elif CASE == CASE_NE_GUARD
#define GUARD(q, m, n) ((q) && (m) != (n))
#elif CASE == CASE_TRIP_WRONG_EQ
#define GUARD(q, m, n) ((q) && (m) + 1 == (n))
#endif
__attribute__((noinline)) static int slice(int n, int m) {
    if (n <= 0 || m <= 0) return 0;
    int p[m];
    for (int i = 0; i < m; ++i) p[i] = i + 3;
    int q = cq_theta(0, 0.25);
    int s = 0;
    for (int i = 0; i < n; ++i) {
        _Bool b = 0, c = 0;
        if (GUARD(q, m, n)) { b = p[i] > 4; c = p[i] < 9; }
        s += cq_measure(b) + cq_measure(c);
    }
    return cq_measure(q) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1, argc + 1); }

/* ---- CASE 1's hand-written twin: the source performs the guarded read ---- */
#elif CASE == CASE_IDX_GUARD_TWIN
static const int zero_cell = 0;
__attribute__((noinline)) static int slice(int m, unsigned k) {
    if (m <= 0) return 0;
    int p[m];
    for (int i = 0; i < m; ++i) p[i] = i + 3;
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    (void)r;
    int v = *(k < (unsigned)m ? &p[k] : &zero_cell);
    _Bool b = 0, c = 0;
    if (q && k < (unsigned)m) { b = v > 4; c = v < 9; }
    /* `v` is read outside the arm too, so -O1 cannot sink the read into it:
     * the source's own guarded read stays in the predecessor and no
     * speculation (and no E4 admission) is involved. */
    return cq_measure(q) + cq_measure(r) + cq_measure(b) + cq_measure(c) +
           (v > 100);
}
int main(int argc, char **argv) {
    (void)argv;
    return slice(argc + 2, (unsigned)atoi(argv[argc - 1]) + (unsigned)argc);
}

/* ---- the guard is a conjunct of a branch whose taken edge does NOT reach
 *      the read: `k < m` holds on the THEN arm, the read is on the ELSE arm ---- */
#elif CASE == CASE_ELSE_ARM_READ || CASE == CASE_NOT_AND_ARM
__attribute__((noinline)) static int slice(int m, unsigned k) {
    if (m <= 0) return 0;
    int p[m];
    for (int i = 0; i < m; ++i) p[i] = i + 3;
    int q = cq_theta(0, 0.25);
    _Bool b = 0, c = 0;
#if CASE == CASE_ELSE_ARM_READ
    if (q && k < (unsigned)m) { b = 1; c = 0; } else { b = p[k] > 4; c = p[k] < 9; }
#else
    if (!(q && k < (unsigned)m)) { b = p[k] > 4; c = p[k] < 9; }
#endif
    return cq_measure(q) + cq_measure(b) + cq_measure(c);
}
int main(int argc, char **argv) {
    (void)argv;
    return slice(argc + 2, (unsigned)atoi(argv[argc - 1]) + (unsigned)argc);
}

/* ---- a SIGNED guard over an index used UNSIGNED: `k < m` is true for k < 0,
 *      and (unsigned)k is then huge ---- */
#elif CASE == CASE_SIGNED_GUARD_UIDX
__attribute__((noinline)) static int slice(int m, int k) {
    if (m <= 0) return 0;
    int p[m];
    for (int i = 0; i < m; ++i) p[i] = i + 3;
    int q = cq_theta(0, 0.25);
    _Bool b = 0, c = 0;
    if (q && k < m) { b = p[(unsigned)k] > 4; c = p[(unsigned)k] < 9; }
    return cq_measure(q) + cq_measure(b) + cq_measure(c);
}
int main(int argc, char **argv) { return slice(argc + 2, atoi(argv[argc - 1]) + argc); }

/* ---- the bead's own program (xdu2.4 matrix row 13) ---- */
#elif CASE == CASE_ROW13
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
#endif
