/* cq-9kcq (CR rules 2, 14 case 2): a quantum-exit loop whose exit value is rotated and measured after the loop. Under
 * CQ_K_ROLLED=1 the deferred reverse copies the exit rail out in the loop's exit block, which already holds the
 * rotation: the copy goes before it (was: the copy at the block's end, after its readers: "Instruction does not
 * dominate all uses"). Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h rolled_exit_copy.c */
int rx(int q0, double th, int n0) {
    int q = q0, n = n0;
    cq_theta(&q, th);
    cq_theta(&n, th);
    for (int i = 0; i < n; i++) q ^= i * i;
    cq_theta(&q, th);
    return cq_measure(q);
}
