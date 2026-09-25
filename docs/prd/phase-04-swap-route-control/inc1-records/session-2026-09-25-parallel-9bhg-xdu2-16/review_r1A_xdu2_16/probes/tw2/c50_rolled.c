__attribute__((noinline)) static int slice(int n) {
    _Bool b[2]; b[0] = cq_theta((_Bool)0, 0.5); b[1] = cq_theta((_Bool)0, 0.7); int s = 0;
    for (int i = 0; i < n; ++i) { int t = (b[0] & b[1]) ? i : 55; s += cq_measure(t); }
    return cq_measure(b[0]) + cq_measure(b[1]) + s;
}
int main(void) { volatile int k = 3; return slice(k); }
