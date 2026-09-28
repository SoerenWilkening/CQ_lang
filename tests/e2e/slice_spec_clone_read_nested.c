/* slice_spec_clone_read_nested.c — bd test_C_libtooling-rhk5 (2-TU,
   run_slice_multi.sh; library TU spec_clone_read_nested_lib.c: `h(a, k) = g(k) ^ k`,
   `g(k) = k * 5`, `g` noinline).

   Family member `f05`: slice_spec_clone_read_in_window.c with a NESTED clone. The
   call `h(m, q)` inside the chain's discharge window reaches `q` through the inner
   clone `__cq_q_g_1` and the inner twin `__cq_q_g_1_unc` — `cloneCallPreservesArg`
   proves the formal read-only through both (clause (B4)). ORACLE: the chain `3q`,
   `3q ^ q` left entangled across `Ry(0.7)`, warned.

   THE CORRECT CIRCUIT is slice_spec_clone_read_nested_twin.c (`s = (q * 5) ^ q`).
   `e2e-spec-clone-read-nested-twin-equivalent` compares the goldens; the inner clone
   contributes a SECOND Bennett block, a multi-template body the checker contracts
   one link at a time. `m = argc + 4 = 5` under the harness (bd 46oo). */
int h(int a, int k);

__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m & 7, 0.5);
    int p = q * 3;
    int u = p ^ q;
    int s = h(m, q);
    if (u == 10)
        cq_phi(3.14159);
    int ms = cq_measure(s);
    q = cq_theta(q, 0.7);
    return ms + cq_measure(q);
}

int main(int argc, char **argv) {
    (void)argv;
    (void)slice(argc + 4);
    return 0;
}
