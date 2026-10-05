/* slice_control_multiexit_musttail.c — bd test_C_libtooling-dm7f.5. A `musttail` early
   return under a quantum condition. `clang -O1` keeps a `ret` per arm (a `musttail`
   call must be immediately followed by `ret`), and on main 7b4e6359 the module declined
   `non-reconverging value exit under quantum control` (measured). `unifyTaintedReturns`
   (ir-pass/src/ReturnMerge.cpp) demotes the `musttail` to `tail` (`k` cannot reach `f`
   again, `f` is not variadic, no `preallocated` operand), merges the two `ret`s, and the
   module is then the IR clang emits for the same source without the attribute —
   slice_control_multiexit_musttail_twin.c — so the two goldens are byte-identical
   (`e2e-control-multiexit-musttail-twin-identical`). The arm is the 6.5 classical-call
   arm: `k(u, a)` runs once, classically, and its result is XOR-copied into a fresh |0>
   rail under the flag [q > 3], 5 under its negation. `f`'s quantum result is unused by
   `main` (a USED quantum return is bd 6gqw's separate gap). `m` comes from argv
   (argc + 4, bd 46oo). */
__attribute__((noinline)) int k(int u, int a) { return a + 100; }

__attribute__((noinline)) int f(int u, int a) {
    int q = u; cq_theta(&q, 0.5);
    if (q > 3) __attribute__((musttail)) return k(u, a);
    return 5;
}

int main(int argc, char **argv) {
    (void)argv;
    int m = argc + 4;
    f(m, m);
    return 0;
}
