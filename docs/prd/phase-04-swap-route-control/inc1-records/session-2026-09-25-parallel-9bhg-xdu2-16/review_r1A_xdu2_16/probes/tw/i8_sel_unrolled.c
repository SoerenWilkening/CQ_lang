__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0;
    { { signed char t = ((q > 1) & (r < 5)) ? (signed char)0 : (signed char)-3; s += cq_measure(t); } }
    { { signed char t = ((q > 1) & (r < 5)) ? (signed char)1 : (signed char)-3; s += cq_measure(t); } }
    { { signed char t = ((q > 1) & (r < 5)) ? (signed char)2 : (signed char)-3; s += cq_measure(t); } }
    return cq_measure(q) + cq_measure(r) + s;
}
int main(void) { volatile int k = 3; return slice(k); }
