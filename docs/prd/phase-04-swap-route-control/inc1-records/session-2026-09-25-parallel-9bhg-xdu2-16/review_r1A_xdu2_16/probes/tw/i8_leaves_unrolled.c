__attribute__((noinline)) static int slice(int n) {
    signed char q = cq_theta((signed char)0, 0.25); short r = cq_theta((short)1, 0.5); int s = 0;
    { { int t = ((q > 1) & (r < 5)) ? 0 : 55; s += cq_measure(t); } }
    { { int t = ((q > 1) & (r < 5)) ? 1 : 55; s += cq_measure(t); } }
    { { int t = ((q > 1) & (r < 5)) ? 2 : 55; s += cq_measure(t); } }
    return cq_measure(q) + cq_measure(r) + s;
}
int main(void) { volatile int k = 3; return slice(k); }
