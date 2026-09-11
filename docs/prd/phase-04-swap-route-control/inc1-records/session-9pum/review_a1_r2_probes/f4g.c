/* in-place XOR, compare reads the POST-op name, measure AFTER (accept control) */
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int acc = 0;
    for (int i = 0; i < 3; ++i) {
        q = q ^ 9;
        if (q > 5) cq_phi(0.3);
        acc += cq_measure(q);
    }
    return acc;
}
int main(void){ (void) slice(2); return 0; }
