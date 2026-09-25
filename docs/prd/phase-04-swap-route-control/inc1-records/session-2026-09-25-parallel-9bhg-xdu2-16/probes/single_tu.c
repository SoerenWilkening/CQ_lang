__attribute__((noinline)) int h(int a, int k) { return k + 1; }

__attribute__((noinline)) int f(int m) {
    int q = cq_theta(m, .5);
    int t = h(q, m);
    return t + cq_measure(q);
}

int main(void) {
    int q2 = cq_theta(5, .25);
    int s = q2 + f(3);
    (void) cq_measure(s);
    return 0;
}
