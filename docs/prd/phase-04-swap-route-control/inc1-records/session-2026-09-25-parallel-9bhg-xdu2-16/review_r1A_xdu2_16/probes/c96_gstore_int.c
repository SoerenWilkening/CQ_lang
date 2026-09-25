__attribute__((noinline)) static int slice(int n, int *arr) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5);
    for (int i = 0; i < n; ++i) { if ((q > 1) & (r < 5)) arr[i] = i + 2; }
    return cq_measure(q) + cq_measure(r) + arr[0];
}
int main(void) { volatile int k = 3; int a[4] = {0}; return slice(k, a); }
