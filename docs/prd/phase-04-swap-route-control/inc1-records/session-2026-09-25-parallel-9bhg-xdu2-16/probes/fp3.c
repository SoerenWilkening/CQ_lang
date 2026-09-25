long double lpoly(long double x);
long double lmix(long double x, long double w);
long double slice(void) {
    long double q = cq_theta((long double)3.0L, 0.5);
    long double y = lpoly(q);
    long double q2 = cq_theta((long double)2.0L, 0.25);
    long double z = lmix(y, q2);
    return cq_measure(z);
}
int main(void) { (void) slice(); return 0; }
