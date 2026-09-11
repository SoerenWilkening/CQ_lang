int ext(int);
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int acc = 0;
    for (int i = 0; i < 3; ++i) {
        acc += cq_measure(q);
        q = q + 1;                 /* in-place candidate on the loop path */
        if (q > 5) cq_phi(0.3);
    }
    return acc;
}
int main(void){ (void) slice(2); return 0; }
