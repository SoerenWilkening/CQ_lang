__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int arr[8] = {0}; int s = 0;
    for (int i = 0; i < n; ++i) { if ((q > 1) & (r < 5)) arr[i & 7] = i + 2; }
    for (int i = 0; i < 8; ++i) s += cq_measure(arr[i]);
    return cq_measure(q) + cq_measure(r) + s;
}
int main(void) { volatile int k = 3; return slice(k); }
