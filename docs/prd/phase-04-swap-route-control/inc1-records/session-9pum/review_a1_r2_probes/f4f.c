/* in-place XOR on the loop path, measure names the PRE-op register, compare the POST-op one */
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int acc = 0;
    for (int i = 0; i < 3; ++i) {
        acc += cq_measure(q);
        q = q ^ 9;
        if (q > 5) cq_phi(0.3);
    }
    return acc;
}
int main(void){ (void) slice(2); return 0; }
