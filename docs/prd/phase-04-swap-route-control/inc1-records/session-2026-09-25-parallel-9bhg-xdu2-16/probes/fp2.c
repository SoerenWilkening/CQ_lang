long double lpoly(long double x);
long double slice(void) {
    long double q = cq_theta((long double)3.0L, 0.5);
    long double y = lpoly(q);
    long double z = lpoly(y);
    return cq_measure(z);
}
int main(void) { (void) slice(); return 0; }
