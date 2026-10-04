/* slice_loop_condtree_select_hoisted_literal.c — bd `test_C_libtooling-xdu2.16`:
   the bd xdu2.13 CLASSICAL-LEAF LITERAL in a compound 4.4 select condition,
   inside a ROLLED loop.

       for (i < n) { int t = ((q > 1) | (m == n)) ? i : 55; s += cq_measure(t); }

   `clang -O1` fuses the condition into `or i1 (icmp sgt q, 1), (icmp eq m, n)` and
   LICM-hoists all three into the preheader. On the pre-change ORACLE
   (`438c77bf45c02e3e`) this DECLINED at the loop layer's round-2 grant re-ask (the
   hoisted `or` was a round-1 root the 4.4 emitter erased). bd xdu2.16 re-derives
   the grant under FINAL taint (the body reads only the root mint `q`), and the
   classical `m == n` — hoisted, untainted, never a root — is the `zeroext`
   LITERAL of `cq_template_or_i1_hl` at the forward AND the `_unc`, the SAME SSA
   value at both (bd xdu2.13), so `cqrt_free(gl)` is a proven-|0> free.

   `main` passes `n == m == argc + 2` (= 3 under the harness, which runs with no
   arguments), so the literal is 1 on every trip. Both operands derive from `argc`
   so `-O1` cannot const-fold the leaf away (bd `46oo`); they are the SAME SSA
   value at the call, which IPSCCP does not turn into an equality inside `slice`.

   THE WITNESS: `e2e-loop-condtree-select-hoisted-literal-twin-identical` — byte
   identity with the hand-unrolled `..._literal_unrolled.c`, which the ORACLE
   already lowers. */
__attribute__((noinline)) static int slice(int n, int m) {
    int q = 0; cq_theta(&q, 0.25);
    int s = 0;
    for (int i = 0; i < n; ++i) {
        int t = ((q > 1) | (m == n)) ? i : 55;
        s += cq_measure(t);
    }
    return cq_measure(q) + s;
}
int main(int argc, char **argv) { (void) argv; return slice(argc + 2, argc + 2); }
