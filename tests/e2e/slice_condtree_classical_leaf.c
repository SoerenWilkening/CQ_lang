/* slice_condtree_classical_leaf.c — bd test_C_libtooling-xdu2.13 e2e slice.
 *
 * A 4.4 DATA select whose condition mixes a quantum compare with a CLASSICAL
 * one: `q && m == n` (an `and` node) and `q || m == n` (an `or` node). The
 * classical leaf is the LITERAL of `cq_template_{and,or}_i1_hl`; the select's
 * controlled copies run on that rail; the strip is the `_unc` with the SAME
 * literal, then one proven-|0> free per rail. Two activations so the golden
 * pins the literal at BOTH values: argc == argc (1) and argc != argc + 1 (0).
 * Every classical operand derives from argc (bd 46oo). The harness runs with
 * argc = 1 and STRICT stage 2b.
 */
#include "CQ.h"

__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25);
    int a = 7, b = 5;
    if (q && m == n) a += 3;
    if (q || m == n) b -= 2;
    return cq_measure(q) + cq_measure(a) + cq_measure(b);
}

int main(int argc, char **argv) {
    (void)argv;
    return slice(argc, argc) + slice(argc, argc + 1);
}
