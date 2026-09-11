/* f4f control: the in-place XOR is there, but a DIFFERENT register is measured */
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int r = cq_theta(u + 1, 0.25);
    int acc = 0;
    for (int i = 0; i < 3; ++i) {
        acc += cq_measure(r);
        q = q ^ 9;
        if (q > 5) cq_phi(0.3);
    }
    return acc + cq_measure(q);
}
int main(void){ (void) slice(2); return 0; }
