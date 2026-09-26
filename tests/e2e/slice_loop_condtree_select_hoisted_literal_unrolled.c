/* slice_loop_condtree_select_hoisted_literal_unrolled.c — the HAND-UNROLLED twin of
   `slice_loop_condtree_select_hoisted_literal.c` (bd `test_C_libtooling-xdu2.16`):
   three written-out copies for the harness's `n == 3`, `i` spelled 0, 1, 2. No
   loop, so no loop-layer grant; this half lowers on the pre-change ORACLE
   `438c77bf45c02e3e` too. The GATE,
   `e2e-loop-condtree-select-hoisted-literal-twin-identical`, compares the two
   committed goldens byte for byte. */
__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25);
    int s = 0;
    { int t = ((q > 1) | (m == n)) ? 0 : 55; s += cq_measure(t); }
    { int t = ((q > 1) | (m == n)) ? 1 : 55; s += cq_measure(t); }
    { int t = ((q > 1) | (m == n)) ? 2 : 55; s += cq_measure(t); }
    return cq_measure(q) + s;
}
int main(int argc, char **argv) { (void) argv; return slice(argc + 2, argc + 2); }
