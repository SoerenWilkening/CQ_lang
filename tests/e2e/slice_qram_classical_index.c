/* slice_qram_classical_index.c — bd test_C_libtooling-01po.9 e2e golden: CLASSICAL-index
 * accesses to a QRAM-backed local array (owner ruling 2026-10-05: the literal-index
 * `cqrt_qram_{load,store}_<W>_hl` forms). Once `arr[q & 7]` has a quantum index the
 * array's cells are quantum, so the classical-index WRITE `arr[k & 7] = 9` and the
 * classical-index READ `arr[(k + 1) & 7]` are QRAM operations at a literal index: no
 * rail is allocated for `k` (R13), the read's value is a register (it is measured),
 * and in this NON-main helper whose index source is never measured every store
 * reverses in strict LIFO, the literal-index store's `_hl_unc` last. The only layer
 * that LINKS: proves the four new symbols resolve and signature-match through a real
 * link, and that the literal index prints as a decimal. `noinline` keeps the helper a
 * separate function under clang -O1 (else it inlines into main, where nothing is
 * reversed); `argc` keeps its operands runtime values. */
#include "CQ.h"

__attribute__((noinline))
static int classical_index(int seed, int k) {
    int arr[8] = {0};
    arr[k & 7] = 9;                    /* classical-index store (before any quantum access) */
    int q = seed; cq_theta(&q, 0.5);
    arr[q & 7] = 5;                    /* quantum-index store */
    int v = arr[(k + 1) & 7];          /* classical-index read of quantum cells */
    return cq_measure(v);
}

int main(int argc, char **argv) {
    (void)argv;
    /* runtime operands (argc == 1 under the harness: seed 0, k 3), so the literal
     * index is a classical VALUE and not a constant clang folded into the helper */
    return classical_index(argc - 1, argc + 2);
}
