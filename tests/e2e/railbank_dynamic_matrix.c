/* railbank_dynamic_matrix.c — C-level clang -O1 admission matrix for xdu2.4.
 *
 * Each CASE is compiled independently by tools/railbank_dynamic_matrix.py.
 * The accepted rows are narrow witnesses; every off-pattern row must fail
 * loudly before mutation.  All extents and ordinary indices are classical
 * except CASE_TAINTED_EXTENT, whose rejection is the point.
 */
#include "CQ.h"
#include <stdlib.h>

#define CASE_RUNTIME_INT 1
#define CASE_FIXED_NONENTRY 2
#define CASE_MISMATCHED_READ_BOUND 3
#define CASE_PARTIAL_WRITE 4
#define CASE_EARLY_EXIT 5
#define CASE_ESCAPE 6
#define CASE_TAINTED_EXTENT 7
#define CASE_RUNTIME_BOOL 8
#define CASE_CLASSICAL_VLA_BOUND_MISMATCH 9
#define CASE_CALLOC_BOUNDARY 10
#define CASE_SEED_HOST_ARITH 11
#define CASE_GUARDED_EXTENT_MISMATCH 12
#define CASE_SPEC_GUARDED_BOUND 13
#define CASE_THETA_BEFORE_BRANCH 14
#define CASE_GUARDED_RUNTIME_INT 15
#define CASE_FIXED_THETA_BEFORE_BRANCH 16
#define CASE_THETA_BEFORE_BRANCH_TWIN 17
#define CASE_BOOL_THETA_BEFORE_BRANCH 18
#define CASE_THETA_BEFORE_NONEMPTY_ARM 19
#define CASE_LITERAL_CELL_RUNTIME 20
#define CASE_LITERAL_CELL_FIXED 21
#define CASE_TEMP_VLA_BETWEEN_LOOPS 22
#define CASE_LARGE_ACYCLIC_BODY 23
#define CASE_IRREDUCIBLE_REWALK 24
#define CASE_IRREDUCIBLE_REWALK_FIXED 25
#define CASE_SETJMP_REWALK 26
#define CASE_SETJMP_REWALK_FIXED 27

#ifndef CASE
#define CASE CASE_RUNTIME_INT
#endif

static int measure_bank(int *b, int n) {
    int sum = 0;
    for (int i = 0; i < n; ++i) sum += cq_measure(b[i]);
    return sum;
}

#if CASE == CASE_RUNTIME_INT
__attribute__((noinline)) static int slice(int n) {
    if (n <= 0) return 0;
    int b[n];
    for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
    return measure_bank(b, n);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_FIXED_NONENTRY
int main(void) {
    int n = 3;
    int prefix[n];
    int sum = 0;
    for (int i = 0; i < n; ++i) prefix[i] = i;
    for (int i = 0; i < n; ++i) sum += prefix[i];
    int b[n];
    for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
    return sum + measure_bank(b, n);
}

#elif CASE == CASE_MISMATCHED_READ_BOUND
int main(int argc, char **argv) {
    (void)argv;
    int n = argc + 2;
    int b[n];
    for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
    return measure_bank(b, n - 1);
}

#elif CASE == CASE_PARTIAL_WRITE
int main(int argc, char **argv) {
    (void)argv;
    int n = argc + 2;
    int b[n];
    for (int i = 0; i < n; ++i)
        if (i + 1 != n) b[i] = cq_theta(b[i], 0.5);
    return measure_bank(b, n);
}

#elif CASE == CASE_EARLY_EXIT
int main(int argc, char **argv) {
    (void)argv;
    int n = argc + 2;
    int b[n];
    for (int i = 0; i < n; ++i) {
        if (i == 1) break;
        b[i] = cq_theta(b[i], 0.5);
    }
    return measure_bank(b, n);
}

#elif CASE == CASE_ESCAPE
extern void opaque(int *);
int main(int argc, char **argv) {
    (void)argv;
    int n = argc + 2;
    int b[n];
    for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
    opaque(b);
    return measure_bank(b, n);
}

#elif CASE == CASE_TAINTED_EXTENT
int main(int argc, char **argv) {
    (void)argv;
    int n = cq_theta(argc + 2, 0.5);
    int b[n];
    for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
    return measure_bank(b, n);
}

#elif CASE == CASE_RUNTIME_BOOL
int main(int argc, char **argv) {
    (void)argv;
    int n = argc + 2;
    bool b[n];
    for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
    int sum = 0;
    for (int i = 0; i < n; ++i) sum += cq_measure(b[i]);
    return sum;
}

#elif CASE == CASE_CLASSICAL_VLA_BOUND_MISMATCH
__attribute__((noinline)) static int slice(int n) {
    if (n <= 0) return 0;
    int p[n + 1];
    for (int i = 0; i < n + 1; ++i) p[i] = i + 3;
    int b[n];
    int P = 0;
    int Z = 4 * n;
    for (int i = 0; i < n; ++i) {
        if (Z >= 2) b[i] = cq_theta(b[i], 0.5);
        if (b[i]) {
            P += p[i];
            Z -= 2;
        }
    }
    for (int i = 0; i < n; ++i) (void)cq_measure(b[i]);
    return cq_measure(P) + cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_CALLOC_BOUNDARY
int main(int argc, char **argv) {
    (void)argv;
    int n = argc + 2;
    int *b = calloc((size_t)n, sizeof(*b));
    for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
    return measure_bank(b, n);
}

#elif CASE == CASE_SEED_HOST_ARITH
/* Rule-13 xdu2.4 finding 1: the seed read also feeds host arithmetic. A minted
 * |0> seed would replace the classical cell value with an opaque handle. */
__attribute__((noinline)) static int slice(int n) {
    if (n <= 0) return 0;
    int b[n];
    int q = cq_theta(0, 0.25);
    int leaked = 0;
    for (int i = 0; i < n; ++i) {
        int old = b[i];
        leaked += old;
        if (q) b[i] = cq_theta(old, 0.5);
    }
    for (int i = 0; i < n; ++i) (void)cq_measure(b[i]);
    return leaked;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_GUARDED_EXTENT_MISMATCH
/* Rule-13 xdu2.4 finding 2: m == n holds only at the guarded store, not at the
 * latch where the promoted store executes. */
__attribute__((noinline)) static int slice(int n, int m) {
    if (n <= 0 || m <= 0) return 0;
    int b[m];
    for (int i = 0; i < n; ++i)
        if (m == n) b[i] = cq_theta(b[i], 0.5);
    int out = 0;
    for (int i = 0; i < m; ++i) out += cq_measure(b[i]);
    return out;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1, argc); }

#elif CASE == CASE_SPEC_GUARDED_BOUND
/* Rule-13 xdu2.4 finding 2, PredMux half: m == n guards the classical p[i] read
 * only on the arm; flattening would execute it at the region entry. */
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

#elif CASE == CASE_THETA_BEFORE_BRANCH
/* The preparation runs on BOTH paths; only its store is conditional. Adopting a
 * minted seed rail in place would rotate the cell the source leaves unprepared
 * (why the seed path requires the theta IN the arm). Instead the promoter folds
 * the emptied arm to `select c, t, 0` (PASS H) — the flat twin's 4.4 data select.
 * Run with argc=3 (n=3), its trace is byte-identical to CASE 17, the hand-
 * unrolled twin, once the twin's identity `cqrt_ry_i32(h0, 0x0p+0)` is dropped. */
__attribute__((noinline)) static int slice(int n) {
    if (n <= 0) return 0;
    int b[n];
    int Z = 4 * n;
    for (int i = 0; i < n; ++i) {
        int t = cq_theta(b[i], 0.5);
        if (Z >= 2) b[i] = t;
        if (b[i]) Z -= 2;
    }
    for (int i = 0; i < n; ++i) (void)cq_measure(b[i]);
    return cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_GUARDED_RUNTIME_INT
/* The positive twin of GUARDED_EXTENT_MISMATCH: the guard is outside the loop,
 * so the extent/trip relation holds at the latch as well. */
__attribute__((noinline)) static int slice(int n, int m) {
    if (n <= 0 || m != n) return 0;
    int b[m];
    int Z = 4 * n;
    for (int i = 0; i < n; ++i) {
        if (Z >= 2) b[i] = cq_theta(b[i], 0.5);
        if (b[i]) Z -= 2;
    }
    for (int i = 0; i < m; ++i) (void)cq_measure(b[i]);
    return cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; return slice(argc, argc); }

#elif CASE == CASE_FIXED_THETA_BEFORE_BRANCH
/* The fixed-size twin of CASE 14: the same emptied arm, a constant bank. */
__attribute__((noinline)) static int slice(void) {
    int b[3];
    int Z = 12;
    for (int i = 0; i < 3; ++i) {
        int t = cq_theta(b[i], 0.5);
        if (Z >= 2) b[i] = t;
        if (b[i]) Z -= 2;
    }
    for (int i = 0; i < 3; ++i) (void)cq_measure(b[i]);
    return cq_measure(Z);
}
int main(void) { return slice(); }

#elif CASE == CASE_THETA_BEFORE_BRANCH_TWIN
/* Hand-unrolled n=3 twin of CASE 14. Z is made quantum from the start with an
 * identity Ry(0) because the rolled form carries Z as a loop-carried handle; the
 * runner drops that one identity line before the byte comparison. */
__attribute__((noinline)) static int slice(int n) {
    int Z = cq_theta(4 * n, 0.0);
    int t0 = cq_theta(0, 0.5); int b0 = 0; if (Z >= 2) b0 = t0; if (b0) Z -= 2;
    int t1 = cq_theta(0, 0.5); int b1 = 0; if (Z >= 2) b1 = t1; if (b1) Z -= 2;
    int t2 = cq_theta(0, 0.5); int b2 = 0; if (Z >= 2) b2 = t2; if (b2) Z -= 2;
    (void)cq_measure(b0); (void)cq_measure(b1); (void)cq_measure(b2);
    return cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_BOOL_THETA_BEFORE_BRANCH
/* `bool` cells, same shape as CASE 16. PASS H folds the arm (hoisting the
 * storage zext PASS G would sink). The module then declines `control flow under
 * quantum control`, anchored (CQ_CTRL_DBG) at the Z data select whose i1
 * condition is the folded bank select — and its hand-unrolled FLAT twin declines
 * with the same string at the same select shape. So the wall is the control
 * emitters' (an i1 select used as a data-select condition), NOT a rail-bank
 * one; which bd owns it was not established.
 * RETIREMENT TRIGGER: when the flat bool twin accepts, this row must accept
 * and gain a TWINS entry. */
__attribute__((noinline)) static int slice(void) {
    bool b[3];
    int Z = 12;
    for (int i = 0; i < 3; ++i) {
        bool t = cq_theta(b[i], 0.5);
        if (Z >= 2) b[i] = t;
        if (b[i]) Z -= 2;
    }
    for (int i = 0; i < 3; ++i) (void)cq_measure(b[i]);
    return cq_measure(Z);
}
int main(void) { return slice(); }

#elif CASE == CASE_THETA_BEFORE_NONEMPTY_ARM
/* CASE 14 with a side effect beside the store (a branch phase), so the arm does
 * NOT empty and PASS H cannot fold it. This is the only shape that reaches the
 * seed path with the prep theta OUTSIDE the storing arm; minting and adopting a
 * seed there would rotate the skipped path's cell in place, so the promoter
 * must refuse it (the store-block conjunct) and the store keeps its decline. */
__attribute__((noinline)) static int slice(int n) {
    if (n <= 0) return 0;
    int b[n];
    int Z = 4 * n;
    for (int i = 0; i < n; ++i) {
        int t = cq_theta(b[i], 0.5);
        if (Z >= 2) { b[i] = t; cq_phi(0.3); }
        if (b[i]) Z -= 2;
    }
    for (int i = 0; i < n; ++i) (void)cq_measure(b[i]);
    return cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_LITERAL_CELL_RUNTIME
/* Rule-13 xdu2.4 review A F-1 (P1). The zero seed makes `c[i] != 0` constant
 * false; PASS H folds the emptied arm to `select true, 0, t`, a PredMux residue
 * fold in the SAME function (the b[] Grover arm) folds that to the literal, and
 * the bank parked `store i32 0` — handle 0, a live then FREED rail — measured n
 * times, exit 0, 2b clean. The bank-store postcondition then declined it (safe);
 * since bd xdu2.9 PASS H resolves the CONSTANT condition to its taken edge, so
 * c[] is no rail bank at all (classical zeros) and the row ACCEPTS with no
 * literal handle parked (runner: `literal_bank_stores`). */
__attribute__((noinline)) static void run_bank(int n) {
    if (n <= 0) return;
    int p[n];
    int z[n];
    for (int i = 0; i < n; ++i) { p[i] = i + 3; z[i] = i + 2; }
    int c[n];
    for (int i = 0; i < n; ++i) {
        int t = cq_theta(c[i], 0.25);
        if (c[i] != 0) c[i] = t;
    }
    int b[n];
    int P = 0;
    int Z = 4 * n;
    for (int i = 0; i < n; ++i) {
        if (Z >= z[i]) b[i] = cq_theta(b[i], 0.5);
        if (b[i]) { P += p[i]; Z -= z[i]; }
    }
    for (int i = 0; i < n; ++i) (void)cq_measure(b[i]);
    for (int i = 0; i < n; ++i) (void)cq_measure(c[i]);
    (void)cq_measure(P);
    (void)cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; run_bank(argc); return 0; }

#elif CASE == CASE_LITERAL_CELL_FIXED
/* The FIXED-size form of CASE 20, well-defined C. The HEAD oracle ACCEPTED it
 * with the same `store i32 0` and three measurements of a freed h0 (pre-existing
 * P1). It then declined (safe direction, an over-decline filed as bd xdu2.9);
 * since the xdu2.9 PASS H constant-condition fold it ACCEPTS, like its flat
 * twin: the dead store folds away and c[] stays classical. */
__attribute__((noinline)) static void run_bank(void) {
    int p[3] = {3, 4, 5};
    int z[3] = {2, 3, 4};
    int c[3] = {0};
    for (int i = 0; i < 3; ++i) {
        int t = cq_theta(c[i], 0.25);
        if (c[i] != 0) c[i] = t;
    }
    bool b[3] = {0};
    int P = 0;
    int Z = 12;
    for (int i = 0; i < 3; ++i) {
        if (Z >= z[i]) b[i] = cq_theta(b[i], 0.5);
        if (b[i]) { P += p[i]; Z -= z[i]; }
    }
    for (int i = 0; i < 3; ++i) (void)cq_measure(b[i]);
    for (int i = 0; i < 3; ++i) (void)cq_measure(c[i]);
    (void)cq_measure(P);
    (void)cq_measure(Z);
}
int main(void) { run_bank(); return 0; }

#elif CASE == CASE_TEMP_VLA_BETWEEN_LOOPS
/* Rule-13 review B F-B3 (P2 over-decline, now ACCEPTS): an unrelated scoped
 * `int t[k]` between the bank's write and read loops. Its stackrestore returns
 * to a save taken AFTER the bank's alloca, so it cannot free the bank. */
extern void use(int *, int);
__attribute__((noinline)) static int slice(int n) {
    if (n <= 0) return 0;
    int b[n];
    for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
    int s = 0;
    for (int k = 1; k < 3; ++k) { int t[k]; use(t, k); s += t[0]; }
    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_LARGE_ACYCLIC_BODY
/* Rule-13 review B F-B2 (P2 over-decline, now ACCEPTS): 22 acyclic diamonds
 * after the bank. LLVM's 32-block reachability budget used to answer "cycle"
 * and emit a false `re-executed by an enclosing cycle` diagnostic. */
extern int g[64];
extern void f1(int); extern void f2(int);
__attribute__((noinline)) static int slice(int n) {
    if (n <= 0) return 0;
    int b[n];
    for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
    int s = 0;
    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
#define C(k) if (g[k] > s) f1(k); else f2(k);
    C(0) C(1) C(2) C(3) C(4) C(5) C(6) C(7) C(8) C(9) C(10) C(11) C(12) C(13) C(14) C(15) C(16) C(17) C(18) C(19) C(20) C(21)
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_IRREDUCIBLE_REWALK
/* Rule-13 review B F-B1 (P1, now DECLINES): a goto re-enters the write
 * do-while through an IRREDUCIBLE cycle LoopInfo gives no parent. The second
 * walk's theta reads the rail the first stored; the promoter used to forward a
 * fresh |0> seed instead (Ry on a new rail where the source means Ry·Ry on
 * one), exit 0, 2b clean. Re-executed walks are increment C (bd xdu2.6). */
extern void side(int);
__attribute__((noinline)) static int slice(int n, int e) {
    if (n <= 0) return 0;
    int b[n];
    int k = 0;
    if (e & 1) goto A;
H: ;
    int i = 0;
    do { b[i] = cq_theta(b[i], 0.5); } while (++i != n);
    if (k++ < 1) goto A; else goto R;
A:
    side(k);
    goto H;
R: ;
    int s = 0;
    int j = 0;
    do { s += cq_measure(b[j]); } while (++j != n);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc, argc + 1); }

#elif CASE == CASE_IRREDUCIBLE_REWALK_FIXED
/* The FIXED-size form of CASE 24 — accepted and miscompiled on the HEAD oracle
 * (pre-existing P1); now declines at the same fence. */
extern void side(int);
__attribute__((noinline)) static int slice(int e) {
    int b[4] = {0};
    int k = 0;
    if (e & 1) goto A;
H: ;
    for (int i = 0; i < 4; ++i) b[i] = cq_theta(b[i], 0.5);
    if (k++ < 1) goto A; else goto R;
A:
    side(k);
    goto H;
R: ;
    int s = 0;
    for (int j = 0; j < 4; ++j) s += cq_measure(b[j]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }

#elif CASE == CASE_SETJMP_REWALK
/* Rule-13 round-2 review B F-R2B-2 (pre-existing for fixed banks): longjmp
 * re-runs the write walk with NO CFG edge, so the exit-reaches-header clause
 * cannot see it; the second walk's theta reads the rail the first stored. Any
 * function calling a returns_twice function now declines. */
#include <setjmp.h>
static jmp_buf env;
__attribute__((noinline)) static int slice(int n) {
    if (n <= 0) return 0;
    int b[n];
    int r = setjmp(env);
    for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
    if (r == 0) longjmp(env, 1);
    int s = 0;
    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc+1); }

#elif CASE == CASE_SETJMP_REWALK_FIXED
/* The FIXED-size form of CASE 26, accepted with a wrong unitary by the HEAD
 * oracle; now declines at the same fence. */
#include <setjmp.h>
static jmp_buf env;
__attribute__((noinline)) static int slice(int n) {
    if (n <= 0) return 0;
    int b[2]; n = 2;
    int r = setjmp(env);
    for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
    if (r == 0) longjmp(env, 1);
    int s = 0;
    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc+1); }
#endif
