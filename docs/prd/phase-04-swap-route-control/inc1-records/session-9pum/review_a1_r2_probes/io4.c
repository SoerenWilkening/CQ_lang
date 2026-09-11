__attribute__((noinline)) void emit(int seed) {
    int r = cq_theta(seed, 0.25);
    int r2 = cq_theta(r, 0.9);
    if (r > 5) cq_phi(0.3);
    (void) cq_measure(r2);
}
int main(void){ emit(7); return 0; }
