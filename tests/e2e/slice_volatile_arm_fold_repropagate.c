/* slice_volatile_arm_fold_repropagate.c — bd test_C_libtooling-vsfp ROUND 3 / bd
   test_C_libtooling-otam (single TU; Rule-13 r2A F-WA-1, probe `stale3c`).

   The only thing in the `q > 3` arm is a write-only `volatile` local. The fenv store
   erasure empties the arm, and since bd vsfp round 2 its cone deletion folds the emptied
   diamond: the merge's two-entry φ `r` becomes `select (q > 3), 5, 9` — a NEW value,
   tainted through its condition. Round 2 ignored the stage's return and never
   re-propagated, so every later stage ran on a stale taint set: control detection still
   claimed the select and RAUW'd it to its `%out` rail HANDLE, while the specializer saw
   `f(r)` as a CLASSICAL call — `f` received the handle as data and the user's
   `cq_measure` was lowered as a never-quantum measure and VANISHED (exit 0, 0 bytes of
   stderr, 2b STRICT clean). Round 3 re-propagates after every volatile stage that changed
   the IR and checks the whole window with `declineStaleTaintSet`.

   Under the fenv ruling this program MEANS slice_volatile_arm_fold_repropagate_twin.c,
   and `e2e-volatile-arm-fold-repropagate-twin-identical` pins this golden byte-identical
   to the twin's: `f` lifted to a clone and the result measured.

   `m` is `slice`'s parameter, passed `argc + 4` (argc = 1 under the harness, m = 5);
   `noinline` keeps `clang -O1` from folding it (bd 46oo). */
__attribute__((noinline)) static int f(int x) { return x * 2 + 1; }

__attribute__((noinline)) int slice(int m) {
    int q = m & 7; cq_theta(&q, 0.5);
    int r;
    if (q > 3) {
        volatile int z = 1;
        r = 5;
    } else {
        r = 9;
    }
    return cq_measure(f(r));
}

int main(int argc, char **argv) {
    (void)argv;
    (void)slice(argc + 4);
    return 0;
}
