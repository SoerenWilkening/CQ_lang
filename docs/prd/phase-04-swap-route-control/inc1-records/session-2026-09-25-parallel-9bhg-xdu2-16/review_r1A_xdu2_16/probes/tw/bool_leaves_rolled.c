__attribute__((noinline)) static int slice(int n) {
    _Bool b = cq_theta((_Bool)0, 0.5); _Bool c = cq_theta((_Bool)0, 0.7); int s = 0;
    for (int i = 0; i < n; ++i) { { int t = (b & c) ? i : 55; s += cq_measure(t); } }
    return cq_measure(b) + cq_measure(c) + s;
}
int main(void) { volatile int k = 3; return slice(k); }
