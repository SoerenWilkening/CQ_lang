/* railbank_readorder_matrix.c — C-level clang -O1 matrix for bd xdu2.10.
 *
 * C6's read-order question — "does every execution of a bank read follow a
 * complete write-loop activation?" — used to be answered by DOMINANCE of the
 * write-loop header, which `-O1` defeats on the plainest runtime bank: without
 * an explicit `if (n <= 0) return`, each loop gets its OWN `n > 0` guard and the
 * read guard is reached from the write guard's FALSE edge as well as from the
 * write loop's exit. The rows below pin the semantic answer
 * (`readFollowsLoopOnEveryPath`, QramLowering.cpp) in both directions.
 *
 * Every bound is argc-derived so `-O1` cannot const-fold it and delete the
 * guards under test (bd 46oo: `main(){return slice(4);}` does exactly that).
 * Expectations: railbank_readorder_matrix.c.cases.json.
 */
#include "CQ.h"

#define CASE_UNGUARDED 1
#define CASE_OR_GUARD 2
#define CASE_LARGE_BODY 3
#define CASE_UNGUARDED_TWIN 4
#define CASE_MISMATCHED_READ_BOUND 5
#define CASE_PARTIAL_WRITE 6
#define CASE_EARLY_EXIT 7
#define CASE_GUARD_OTHER_VAR 8
#define CASE_GUARD_FALSE_REACHES_READ 9
#define CASE_READ_BOUND_OTHER_VAR 10
#define CASE_STRONGER_READ_GUARD 11
#define CASE_OR_GUARD_UNGUARDED_M 12
#define CASE_GOTO_AROUND_WRITE 13
#define CASE_UNSIGNED_READ_BOUND 14
#define CASE_MERGED_TAINTED_DIAMOND 15
#define CASE_MERGED_TAINTED_DIAMOND_TWIN 16
#define CASE_FIXED_TAINTED_DIAMOND_PRE 17
#define CASE_FIXED_TAINTED_DIAMOND_MID 18
#define CASE_MEASURED_GUARD 19
#define CASE_MEASURED_GUARD_SUM 20

#ifndef CASE
#define CASE CASE_UNGUARDED
#endif

#if CASE == CASE_UNGUARDED
/* The bead's exhibit: no explicit guard. Run with argc=3 (n=3), its trace is
 * byte-identical to CASE 4, the hand-unrolled twin. */
__attribute__((noinline)) static int slice(int n) {
    int b[n];
    for (int i = 0; i < n; ++i) cq_theta(&b[i], 0.5);
    int s = 0;
    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_OR_GUARD
/* `if (n <= 0 || m <= 0) return;` — the guard mentions a second variable. */
__attribute__((noinline)) static int slice(int n, int m) {
    if (n <= 0 || m <= 0) return 0;
    int b[n];
    for (int i = 0; i < n; ++i) cq_theta(&b[i], 0.5);
    int s = 0;
    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
    return s + m;
}
int main(int argc, char **argv) { (void)argv; return slice(argc, argc - 1); }

#elif CASE == CASE_LARGE_BODY
/* Unguarded, with 22 acyclic diamonds BETWEEN the write and read loops: the
 * walk has no block budget. (The first spelling was QUADRATIC — Rule-13
 * round 1 P3-1 measured 7.7 s at 3000 diamonds; this row is a verdict pin,
 * NOT a timing test: complexity is guarded only by the note on ReadOrderCtx.) */
extern int g[64];
extern void f1(int); extern void f2(int);
__attribute__((noinline)) static int slice(int n) {
    int b[n];
    for (int i = 0; i < n; ++i) cq_theta(&b[i], 0.5);
    int s = 0;
#define C(k) if (g[k] > n) f1(k); else f2(k);
    C(0) C(1) C(2) C(3) C(4) C(5) C(6) C(7) C(8) C(9) C(10) C(11) C(12) C(13) C(14) C(15) C(16) C(17) C(18) C(19) C(20) C(21)
    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_UNGUARDED_TWIN
/* Hand-unrolled n=3 twin of CASE 1. */
__attribute__((noinline)) static int slice(void) {
    int b0 = 0; cq_theta(&b0, 0.5);
    int b1 = 0; cq_theta(&b1, 0.5);
    int b2 = 0; cq_theta(&b2, 0.5);
    int s = 0;
    s += cq_measure(b0); s += cq_measure(b1); s += cq_measure(b2);
    return s;
}
int main(void) { return slice(); }

#elif CASE == CASE_MISMATCHED_READ_BOUND
/* Copy of railbank_dynamic_matrix row 3, UNGUARDED: the read walks n-1 cells. */
__attribute__((noinline)) static int slice(int n) {
    int b[n];
    for (int i = 0; i < n; ++i) cq_theta(&b[i], 0.5);
    int s = 0;
    for (int i = 0; i < n - 1; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }

#elif CASE == CASE_PARTIAL_WRITE
/* Copy of railbank_dynamic_matrix row 4, UNGUARDED: the last cell is never written. */
__attribute__((noinline)) static int slice(int n) {
    int b[n];
    for (int i = 0; i < n; ++i)
        if (i + 1 != n) cq_theta(&b[i], 0.5);
    int s = 0;
    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }

#elif CASE == CASE_EARLY_EXIT
/* Copy of railbank_dynamic_matrix row 5, UNGUARDED: the write loop can exit early. */
__attribute__((noinline)) static int slice(int n, int k) {
    int b[n];
    for (int i = 0; i < n; ++i) {
        if (i == k) break;
        cq_theta(&b[i], 0.5);
    }
    int s = 0;
    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }

#elif CASE == CASE_GUARD_OTHER_VAR
/* The write loop runs only when an UNRELATED k is set; the read always runs. */
__attribute__((noinline)) static int slice(int n, int k) {
    int b[n];
    if (k)
        for (int i = 0; i < n; ++i) cq_theta(&b[i], 0.5);
    int s = 0;
    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc, argc & 1); }

#elif CASE == CASE_GUARD_FALSE_REACHES_READ
/* The write guard n > 2 is STRONGER than the read guard n > 0: for n in 1..2
 * the guard-false edge reaches a read of never-written cells. */
__attribute__((noinline)) static int slice(int n) {
    int b[n];
    if (n > 2)
        for (int i = 0; i < n; ++i) cq_theta(&b[i], 0.5);
    int s = 0;
    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_READ_BOUND_OTHER_VAR
/* Copy of railbank_dynamic_matrix row 12's axis, UNGUARDED: the read walks m cells
 * of an n-cell bank (m = n + 1 at run time). */
__attribute__((noinline)) static int slice(int n, int m) {
    int b[n];
    for (int i = 0; i < n; ++i) cq_theta(&b[i], 0.5);
    int s = 0;
    for (int i = 0; i < m; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc, argc + 1); }

#elif CASE == CASE_STRONGER_READ_GUARD
/* The read runs under n > 1, which IMPLIES the write guard n > 0: a read
 * implication that is not an equality of guards. */
__attribute__((noinline)) static int slice(int n) {
    int b[n];
    for (int i = 0; i < n; ++i) cq_theta(&b[i], 0.5);
    int s = 0;
    if (n > 1)
        for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_OR_GUARD_UNGUARDED_M
/* The early return names only m; each loop still gets its own n > 0 guard. */
__attribute__((noinline)) static int slice(int n, int m) {
    if (m <= 0) return 0;
    int b[n];
    for (int i = 0; i < n; ++i) cq_theta(&b[i], 0.5);
    int s = 0;
    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
    return s + m;
}
int main(int argc, char **argv) { (void)argv; return slice(argc, argc - 1); }

#elif CASE == CASE_GOTO_AROUND_WRITE
/* An explicit goto skips the write when n <= 0; the read loop's own n > 0 guard
 * refutes that edge exactly as it refutes -O1's guard-false edge. */
__attribute__((noinline)) static int slice(int n, int k) {
    int b[n];
    int s = k;
    if (n <= 0) goto R;
    for (int i = 0; i < n; ++i) cq_theta(&b[i], 0.5);
    s += 1;
R:
    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc, argc & 3); }

#elif CASE == CASE_UNSIGNED_READ_BOUND
/* The read walks (unsigned)n cells: its guard is n != 0, which n <= 0 (the
 * write's bypass) does NOT refute — for n < 0 the read would run over cells
 * nothing wrote. Must keep the C6 decline. */
__attribute__((noinline)) static int slice(int n) {
    int b[n];
    for (int i = 0; i < n; ++i) cq_theta(&b[i], 0.5);
    int s = 0;
    for (unsigned i = 0; i < (unsigned)n; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_MERGED_TAINTED_DIAMOND
/* Rule-13 round 3 F-1 (P2, the Grover shape): a tainted `if (c) cq_phi(pi);`
 * diamond that FULLY MERGES before an unguarded runtime bank. The read is not in
 * the tainted branch's region, so the classical guards decide. Run with argc=3
 * (n=2), its trace is byte-identical to CASE 16, the hand-unrolled twin. */
__attribute__((noinline)) static int slice(int n) {
    _Bool c = (_Bool)0; cq_theta(&c, 0.3);
    if (c) cq_phi(3.14159);
    int b[n];
    for (int i = 0; i < n; ++i) cq_theta(&b[i], 0.5);
    int s = cq_measure(c);
    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc - 1); }

#elif CASE == CASE_MERGED_TAINTED_DIAMOND_TWIN
/* Hand-unrolled n=2 twin of CASE 15. */
__attribute__((noinline)) static int slice(void) {
    _Bool c = (_Bool)0; cq_theta(&c, 0.3);
    if (c) cq_phi(3.14159);
    int b0 = 0; cq_theta(&b0, 0.5);
    int b1 = 0; cq_theta(&b1, 0.5);
    int s = cq_measure(c);
    s += cq_measure(b0);
    s += cq_measure(b1);
    return s;
}
int main(void) { return slice(); }

#elif CASE == CASE_FIXED_TAINTED_DIAMOND_PRE
/* Round 3 F-1, fixed bank: the merged tainted diamond BEFORE the guarded write;
 * the read runs under k > 1, which implies the write's k > 0. */
__attribute__((noinline)) static int slice(int k) {
    _Bool c = (_Bool)0; cq_theta(&c, 0.3);
    if (c) cq_phi(3.14159);
    int b[3];
    if (k > 0) for (int i = 0; i < 3; ++i) { int t = 0; cq_theta(&t, 0.5); b[i] = t; }
    int s = cq_measure(c);
    if (k > 1) for (int j = 0; j < 3; ++j) s += cq_measure(b[j]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc - 2); }

#elif CASE == CASE_FIXED_TAINTED_DIAMOND_MID
/* Round 3 F-1, fixed bank: the merged tainted diamond BETWEEN write and read. */
__attribute__((noinline)) static int slice(int k) {
    _Bool c = (_Bool)0; cq_theta(&c, 0.3);
    int b[3];
    if (k > 0) for (int i = 0; i < 3; ++i) { int t = 0; cq_theta(&t, 0.5); b[i] = t; }
    if (c) cq_phi(3.14159);
    int s = cq_measure(c);
    if (k > 1) for (int j = 0; j < 3; ++j) s += cq_measure(b[j]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc - 2); }

#elif CASE == CASE_MEASURED_GUARD
/* Round 3 F-2 (P3): guards built from a cq_measure RESULT, a classical value. */
__attribute__((noinline)) static int slice(int k) {
    int q = k; cq_theta(&q, 0.4);
    int r = cq_measure(q);
    int b[3];
    if (r > 0) for (int i = 0; i < 3; ++i) { int t = 0; cq_theta(&t, 0.5); b[i] = t; }
    int s = 0;
    if (r > 1) for (int j = 0; j < 3; ++j) s += cq_measure(b[j]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc - 2); }

#elif CASE == CASE_MEASURED_GUARD_SUM
/* Round 3 F-2, reviewer round-1 p12: a guard mixing a measurement and an argument. */
__attribute__((noinline)) static int slice(int k, int n) {
    (void)n;
    int c0 = 0; cq_theta(&c0, 1.0);
    int c = cq_measure(c0);
    int b[3];
    if (c + k > 1)
        for (int i = 0; i < 3; ++i) { int t = 0; cq_theta(&t, 0.5); b[i] = t; }
    int s = 0;
    if (c + k > 2) for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc, argc * 7); }
#endif
