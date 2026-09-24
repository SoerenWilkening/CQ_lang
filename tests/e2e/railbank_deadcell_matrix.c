/* railbank_deadcell_matrix.c — C-level clang -O1 admission matrix for bd
 * test_C_libtooling-xdu2.9: a bank cell whose conditional store is dead because
 * the zero seed makes the arm's own condition CONSTANT.
 *
 * Each CASE is compiled independently by run_railbank_dynamic_matrix.py; the
 * expectations are the JSON sidecar `railbank_deadcell_matrix.c.cases.json`.
 * Every entry point is `main(int argc, char **argv)` so `-O1` cannot
 * const-propagate a runtime extent or a classical condition away (bd 46oo).
 *
 * THE FIX UNDER TEST (RailBankPromote.cpp PASS H): the promoter's own forwarding
 * (PASS B) and constant fold (PASS F) turn `c[i] != 0` into a CONSTANT branch
 * condition. PASS H then folds the emptied arm's merge φ to the value the
 * constant selects — SimplifyCFG's fold, which `-O1` would have performed had it
 * seen the seed — instead of minting `select <const>, …`. When that value is the
 * seed literal the surviving store is CLASSICAL, the carve answers NotBank, no
 * `!cq.railbank` is minted and the measure loop reads classical memory: the
 * object is not a rail bank at all. The postcondition
 * `declineNonHandleBankStores` is untouched and still guards every MARKED bank.
 */
#include "CQ.h"

#define CASE_DEAD_FIXED 1
#define CASE_DEAD_FIXED_TWIN 2
#define CASE_DEAD_RUNTIME 3
#define CASE_DEAD_RUNTIME_TWIN 4
#define CASE_TAKEN_FIXED 5
#define CASE_TAKEN_FIXED_TWIN 6
#define CASE_ROW21_FIXED 7
#define CASE_ROW21_FIXED_TWIN 8
#define CASE_ROW20_RUNTIME 9
#define CASE_ROW20_RUNTIME_TWIN 10
#define CASE_SEED_NONZERO_CELL 11
#define CASE_CLASSICAL_COND 12
#define CASE_PARTLY_DEAD 13
#define CASE_DEAD_BOOL 14
#define CASE_DEAD_BOOL_TWIN 15
#define CASE_DEAD_FIXED_ROLLED_TWIN 16
#define CASE_DEAD_RUNTIME_ROLLED_TWIN 17
#define CASE_ROW21_ROLLED_TWIN 18
#define CASE_ROW20_ROLLED_TWIN 19
#define CASE_DEAD_BOOL_ROLLED_TWIN 20
#define CASE_INARM_DEAD_FIXED 21
#define CASE_INARM_DEAD_RUNTIME 22
#define CASE_INARM_DEAD_FLAT 23
#define CASE_LATE_CONST_BACKSTOP 24

#ifndef CASE
#define CASE CASE_DEAD_FIXED
#endif

#if CASE == CASE_DEAD_FIXED
/* The minimal dead cell: a zero-initialised FIXED bank whose store can never
 * fire. Every cell stays classical 0, so the program measures three classical
 * zeros; the three preparations still run (their results are dead). */
__attribute__((noinline)) static int slice(int k) {
    int c[3] = {0};
    for (int i = 0; i < 3; ++i) {
        int t = cq_theta(c[i], 0.25);
        if (c[i] != 0) c[i] = t;
    }
    int s = k;
    for (int i = 0; i < 3; ++i) s += cq_measure(c[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_DEAD_FIXED_TWIN
/* Hand-unrolled flat twin of CASE 1: three scalars, no array anywhere. */
__attribute__((noinline)) static int slice(int k) {
    int c0 = 0, c1 = 0, c2 = 0;
    int t0 = cq_theta(c0, 0.25); if (c0 != 0) c0 = t0;
    int t1 = cq_theta(c1, 0.25); if (c1 != 0) c1 = t1;
    int t2 = cq_theta(c2, 0.25); if (c2 != 0) c2 = t2;
    return k + cq_measure(c0) + cq_measure(c1) + cq_measure(c2);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_DEAD_RUNTIME
/* The runtime-sized form (uninitialised VLA; owner ruling D1 reads the cell as
 * 0, exactly as the promoter's seed does). Run with argc = 3. */
__attribute__((noinline)) static int slice(int n) {
    if (n <= 0) return 0;
    int c[n];
    for (int i = 0; i < n; ++i) {
        int t = cq_theta(c[i], 0.25);
        if (c[i] != 0) c[i] = t;
    }
    int s = 0;
    for (int i = 0; i < n; ++i) s += cq_measure(c[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_DEAD_RUNTIME_TWIN
/* Hand-unrolled n = 3 twin of CASE 3. */
__attribute__((noinline)) static int slice(int n) {
    if (n <= 0) return 0;
    int c0 = 0, c1 = 0, c2 = 0;
    int t0 = cq_theta(c0, 0.25); if (c0 != 0) c0 = t0;
    int t1 = cq_theta(c1, 0.25); if (c1 != 0) c1 = t1;
    int t2 = cq_theta(c2, 0.25); if (c2 != 0) c2 = t2;
    return cq_measure(c0) + cq_measure(c1) + cq_measure(c2);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_TAKEN_FIXED
/* The OTHER constant: `c[i] == 0` is constant TRUE, so the store ALWAYS fires
 * and the bank is a real one — the unconditional-prep shape. The fold must pick
 * the ARM's value here, and the object must stay a `!cq.railbank`. */
__attribute__((noinline)) static int slice(int k) {
    int c[3] = {0};
    for (int i = 0; i < 3; ++i) {
        int t = cq_theta(c[i], 0.25);
        if (c[i] == 0) c[i] = t;
    }
    int s = k;
    for (int i = 0; i < 3; ++i) s += cq_measure(c[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_TAKEN_FIXED_TWIN
/* Hand-unrolled flat twin of CASE 5. */
__attribute__((noinline)) static int slice(int k) {
    int c0 = 0, c1 = 0, c2 = 0;
    int t0 = cq_theta(c0, 0.25); if (c0 == 0) c0 = t0;
    int t1 = cq_theta(c1, 0.25); if (c1 == 0) c1 = t1;
    int t2 = cq_theta(c2, 0.25); if (c2 == 0) c2 = t2;
    return k + cq_measure(c0) + cq_measure(c1) + cq_measure(c2);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_ROW21_FIXED
/* Copy of railbank_dynamic_matrix.c CASE 21 (CASE_LITERAL_CELL_FIXED), with
 * `main(argc, argv)`: the dead `c[]` beside a PredMux-claimed Grover arm on a
 * real `bool b[3]` bank in the SAME function — the composition that parked
 * literal handle 0 on the pre-xdu2.4 oracle. `b` must stay a bank; `c` must not
 * become one; no store may park literal 0. */
__attribute__((noinline)) static void run_bank(int k) {
    int p[3] = {3, 4, 5};
    int z[3] = {2, 3, 4};
    int c[3] = {0};
    for (int i = 0; i < 3; ++i) {
        int t = cq_theta(c[i], 0.25);
        if (c[i] != 0) c[i] = t;
    }
    bool b[3] = {0};
    int P = 0;
    int Z = 12 + k - k;
    for (int i = 0; i < 3; ++i) {
        if (Z >= z[i]) b[i] = cq_theta(b[i], 0.5);
        if (b[i]) { P += p[i]; Z -= z[i]; }
    }
    for (int i = 0; i < 3; ++i) (void)cq_measure(b[i]);
    for (int i = 0; i < 3; ++i) (void)cq_measure(c[i]);
    (void)cq_measure(P);
    (void)cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; run_bank(argc); return 0; }

#elif CASE == CASE_ROW21_FIXED_TWIN
/* CASE 7 with ONLY the dead `c[]` hand-unrolled: the `b[]` Grover loop is kept
 * rolled and byte-identical, so the pair isolates the dead-cell fold. */
__attribute__((noinline)) static void run_bank(int k) {
    int p[3] = {3, 4, 5};
    int z[3] = {2, 3, 4};
    int c0 = 0, c1 = 0, c2 = 0;
    int t0 = cq_theta(c0, 0.25); if (c0 != 0) c0 = t0;
    int t1 = cq_theta(c1, 0.25); if (c1 != 0) c1 = t1;
    int t2 = cq_theta(c2, 0.25); if (c2 != 0) c2 = t2;
    bool b[3] = {0};
    int P = 0;
    int Z = 12 + k - k;
    for (int i = 0; i < 3; ++i) {
        if (Z >= z[i]) b[i] = cq_theta(b[i], 0.5);
        if (b[i]) { P += p[i]; Z -= z[i]; }
    }
    for (int i = 0; i < 3; ++i) (void)cq_measure(b[i]);
    (void)cq_measure(c0); (void)cq_measure(c1); (void)cq_measure(c2);
    (void)cq_measure(P);
    (void)cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; run_bank(argc); return 0; }

#elif CASE == CASE_ROW20_RUNTIME
/* Copy of railbank_dynamic_matrix.c CASE 20 (CASE_LITERAL_CELL_RUNTIME). */
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

#elif CASE == CASE_ROW20_RUNTIME_TWIN
/* CASE 9 with ONLY the dead `c[]` hand-unrolled for n = 3 (run with argc = 3);
 * the runtime `b[n]` Grover loop is kept rolled and byte-identical. */
__attribute__((noinline)) static void run_bank(int n) {
    if (n <= 0) return;
    int p[n];
    int z[n];
    for (int i = 0; i < n; ++i) { p[i] = i + 3; z[i] = i + 2; }
    int c0 = 0, c1 = 0, c2 = 0;
    int t0 = cq_theta(c0, 0.25); if (c0 != 0) c0 = t0;
    int t1 = cq_theta(c1, 0.25); if (c1 != 0) c1 = t1;
    int t2 = cq_theta(c2, 0.25); if (c2 != 0) c2 = t2;
    int b[n];
    int P = 0;
    int Z = 4 * n;
    for (int i = 0; i < n; ++i) {
        if (Z >= z[i]) b[i] = cq_theta(b[i], 0.5);
        if (b[i]) { P += p[i]; Z -= z[i]; }
    }
    for (int i = 0; i < n; ++i) (void)cq_measure(b[i]);
    (void)cq_measure(c0); (void)cq_measure(c1); (void)cq_measure(c2);
    (void)cq_measure(P);
    (void)cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; run_bank(argc); return 0; }

#elif CASE == CASE_SEED_NONZERO_CELL
/* NEIGHBOUR, NOT DEAD: one cell's seed is nonzero, so c[1]'s store FIRES. The
 * promoter admits only an all-zero initializer, so nothing is folded and the
 * store keeps its generic owner. */
__attribute__((noinline)) static int slice(int k) {
    int c[3] = {0, 1, 0};
    for (int i = 0; i < 3; ++i) {
        int t = cq_theta(c[i], 0.25);
        if (c[i] != 0) c[i] = t;
    }
    int s = k;
    for (int i = 0; i < 3; ++i) s += cq_measure(c[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_CLASSICAL_COND
/* NEIGHBOUR, NOT DEAD: the store is gated by a CLASSICAL RUNTIME value, so it
 * may fire. The fold must not apply (the condition is not a constant) and the
 * classical-condition mux over tainted data keeps its decline. */
__attribute__((noinline)) static int slice(int k) {
    int c[3] = {0};
    for (int i = 0; i < 3; ++i) {
        int t = cq_theta(c[i], 0.25);
        if (k > 5) c[i] = t;
    }
    int s = 0;
    for (int i = 0; i < 3; ++i) s += cq_measure(c[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_PARTLY_DEAD
/* NEIGHBOUR, PARTLY DEAD: `c[i] != 0` is constant false but `i == 1` is not, so
 * c[1]'s store fires and c[0]/c[2]'s never do. The condition is not a constant
 * after forwarding, so the fold must not apply. */
__attribute__((noinline)) static int slice(int k) {
    int c[3] = {0};
    for (int i = 0; i < 3; ++i) {
        int t = cq_theta(c[i], 0.25);
        if (c[i] != 0 || i == 1) c[i] = t;
    }
    int s = k;
    for (int i = 0; i < 3; ++i) s += cq_measure(c[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_DEAD_BOOL
/* The `_Bool` cell spelling of CASE 1 (i8 storage, i1 rail: PASS G's subject). */
__attribute__((noinline)) static int slice(int k) {
    bool c[3] = {0};
    for (int i = 0; i < 3; ++i) {
        bool t = cq_theta(c[i], 0.25);
        if (c[i]) c[i] = t;
    }
    int s = k;
    for (int i = 0; i < 3; ++i) s += cq_measure(c[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_DEAD_BOOL_TWIN
/* Hand-unrolled flat twin of CASE 14. */
__attribute__((noinline)) static int slice(int k) {
    bool c0 = 0, c1 = 0, c2 = 0;
    bool t0 = cq_theta(c0, 0.25); if (c0) c0 = t0;
    bool t1 = cq_theta(c1, 0.25); if (c1) c1 = t1;
    bool t2 = cq_theta(c2, 0.25); if (c2) c2 = t2;
    return k + cq_measure(c0) + cq_measure(c1) + cq_measure(c2);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_DEAD_FIXED_ROLLED_TWIN
/* THE TWIN OF RECORD for CASE 1: the SAME loop with NO ARRAY ANYWHERE — the
 * program the fold says CASE 1 denotes. Byte-identical is the witness. (The
 * flat twin, CASE 2, emits the same gate multiset but uncomputes the three dead
 * preparations LIFO at function end instead of per trip; that reorders
 * operations on DISJOINT rails and is the uncompute spine's schedule for any
 * rolled dead preparation, bank or not — measured, see TRACK_D.md.) */
__attribute__((noinline)) static int slice(int k) {
    int s = k;
    for (int i = 0; i < 3; ++i) {
        int ci = 0;
        int t = cq_theta(ci, 0.25);
        if (ci != 0) ci = t;
        s += cq_measure(ci);
    }
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_DEAD_RUNTIME_ROLLED_TWIN
/* Array-free rolled twin of CASE 3 (run with argc = 3). */
__attribute__((noinline)) static int slice(int n) {
    if (n <= 0) return 0;
    int s = 0;
    for (int i = 0; i < n; ++i) {
        int ci = 0;
        int t = cq_theta(ci, 0.25);
        if (ci != 0) ci = t;
        s += cq_measure(ci);
    }
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_ROW21_ROLLED_TWIN
/* CASE 7 with ONLY `c[]` replaced by an array-free rolled scalar; the `b[]`
 * Grover loop is byte-identical source. */
__attribute__((noinline)) static void run_bank(int k) {
    int p[3] = {3, 4, 5};
    int z[3] = {2, 3, 4};
    int cs = 0;
    for (int i = 0; i < 3; ++i) {
        int ci = 0;
        int t = cq_theta(ci, 0.25);
        if (ci != 0) ci = t;
        cs += ci;
    }
    bool b[3] = {0};
    int P = 0;
    int Z = 12 + k - k;
    for (int i = 0; i < 3; ++i) {
        if (Z >= z[i]) b[i] = cq_theta(b[i], 0.5);
        if (b[i]) { P += p[i]; Z -= z[i]; }
    }
    for (int i = 0; i < 3; ++i) (void)cq_measure(b[i]);
    (void)cq_measure(cs);
    (void)cq_measure(P);
    (void)cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; run_bank(argc); return 0; }

#elif CASE == CASE_ROW20_ROLLED_TWIN
/* CASE 9 with ONLY `c[n]` replaced by an array-free rolled scalar (argc = 3). */
__attribute__((noinline)) static void run_bank(int n) {
    if (n <= 0) return;
    int p[n];
    int z[n];
    for (int i = 0; i < n; ++i) { p[i] = i + 3; z[i] = i + 2; }
    int cs = 0;
    for (int i = 0; i < n; ++i) {
        int ci = 0;
        int t = cq_theta(ci, 0.25);
        if (ci != 0) ci = t;
        cs += ci;
    }
    int b[n];
    int P = 0;
    int Z = 4 * n;
    for (int i = 0; i < n; ++i) {
        if (Z >= z[i]) b[i] = cq_theta(b[i], 0.5);
        if (b[i]) { P += p[i]; Z -= z[i]; }
    }
    for (int i = 0; i < n; ++i) (void)cq_measure(b[i]);
    (void)cq_measure(cs);
    (void)cq_measure(P);
    (void)cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; run_bank(argc); return 0; }

#elif CASE == CASE_DEAD_BOOL_ROLLED_TWIN
/* Array-free rolled twin of CASE 14. */
__attribute__((noinline)) static int slice(int k) {
    int s = k;
    for (int i = 0; i < 3; ++i) {
        bool ci = 0;
        bool t = cq_theta(ci, 0.25);
        if (ci) ci = t;
        s += cq_measure(ci);
    }
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_INARM_DEAD_FIXED
/* RESIDUAL OVER-DECLINE, OUT OF xdu2.9's SCOPE (measured, filed in TRACK_D.md):
 * the preparation is INSIDE the dead arm, so the arm does not empty, PASS H
 * never runs, and the promoter's constant `br` is left for the control layer,
 * which declines. The flat twin (CASE 23) compiles: -O1 deletes the dead arm.
 * RETIREMENT TRIGGER: when the promoter (or anything before detection) folds a
 * constant-condition diamond whose dead arm holds the prep, this row must
 * ACCEPT with no `!cq.railbank` and no gate at all — flip it, do not delete it. */
__attribute__((noinline)) static int slice(int k) {
    int c[3] = {0};
    for (int i = 0; i < 3; ++i)
        if (c[i] != 0) c[i] = cq_theta(c[i], 0.25);
    int s = k;
    for (int i = 0; i < 3; ++i) s += cq_measure(c[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_INARM_DEAD_RUNTIME
/* The runtime-sized form of CASE 21: declines at the generic store owner (the
 * conditional-runtime-prep plan needs the seed load to feed only the theta,
 * and here it also feeds the condition). Same retirement trigger as CASE 21. */
__attribute__((noinline)) static int slice(int n) {
    if (n <= 0) return 0;
    int c[n];
    for (int i = 0; i < n; ++i)
        if (c[i] != 0) c[i] = cq_theta(c[i], 0.25);
    int s = 0;
    for (int i = 0; i < n; ++i) s += cq_measure(c[i]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_INARM_DEAD_FLAT
/* Flat twin of CASE 21: compiles, and emits no gate at all. */
__attribute__((noinline)) static int slice(int k) {
    int c0 = 0, c1 = 0, c2 = 0;
    if (c0 != 0) c0 = cq_theta(c0, 0.25);
    if (c1 != 0) c1 = cq_theta(c1, 0.25);
    if (c2 != 0) c2 = cq_theta(c2, 0.25);
    return k + cq_measure(c0) + cq_measure(c1) + cq_measure(c2);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }

#elif CASE == CASE_LATE_CONST_BACKSTOP
/* THE BACKSTOP, REACHED FROM C (Rule-13 round 2, reviewer probe q45). The
 * condition compares the cell with a `volatile const` local, so it is NOT a
 * constant when the promoter runs (PASS H keeps `select c, t, 0`, the carve
 * MARKS the bank); a later stage folds the volatile const to 0, and the PredMux
 * residue fold that the Grover `b[]` triggers in the same function then reduces
 * the select to the literal. Only `declineNonHandleBankStores` stands between
 * that and a parked handle 0 — this row pins its string from C. It is an
 * over-decline of well-defined C (every c[i] stays 0), deliberately left:
 * resolving it means asking the constant question AFTER the late fold, not in
 * the promoter. */
__attribute__((noinline)) static void run_bank(int k) {
    int p[3] = {3, 4, 5}; int z[3] = {2, 3, 4};
    bool b[3] = {0}; int P = 0; int Z = 12 + k - k;
    for (int i = 0; i < 3; ++i) {
        if (Z >= z[i]) b[i] = cq_theta(b[i], 0.5);
        if (b[i]) { P += p[i]; Z -= z[i]; }
    }
    int c[3] = {0}; volatile int zv = 0;
    for (int i = 0; i < 3; ++i) { int t = cq_theta(c[i], 0.25); int zz = zv; if (c[i] != zz) c[i] = t; }
    for (int i = 0; i < 3; ++i) (void)cq_measure(b[i]);
    for (int i = 0; i < 3; ++i) (void)cq_measure(c[i]);
    (void)cq_measure(P); (void)cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; run_bank(argc); return 0; }
#endif
