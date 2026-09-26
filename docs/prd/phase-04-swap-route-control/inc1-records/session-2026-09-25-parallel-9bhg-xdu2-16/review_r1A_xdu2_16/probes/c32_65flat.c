__attribute__((noinline, const)) int ext_f(int a) { return a * 3 + 1; }
__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(3, 0.5); int y = q;
    if (q > 5) y = ext_f(7);
    return cq_measure(y);
}
int main(void) { volatile int k = 3; return slice(k); }
