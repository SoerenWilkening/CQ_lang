/* Rule 14: a multi-exit K-loop whose early `return` carries a value: the exit flag of each trip selects the returned
 * value; the fall-through exit after K trips returns the final i. */
int return_in_kloop(unsigned x0, double tx, unsigned k) {
    unsigned x = x0;
    int i = 0;
    cq_theta(&x, tx);
    for (;;) {                /* [K] */
        if (x == k) return cq_measure(i);
        x = x / 2;
        i++;
    }
}
