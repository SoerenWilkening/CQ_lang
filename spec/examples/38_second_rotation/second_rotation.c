int second_rotation(int x0, double t1, double t2) {
    int x = x0;
    cq_theta(&x, t1);
    cq_theta(&x, t2);
    return cq_measure(x);
}
int rotate_derived(int x0, double t1, double t2, int c) {
    int x = x0;
    cq_theta(&x, t1);
    int y = x + c;
    cq_theta(&y, t2);
    return cq_measure(y);
}
double rotate_double(double x0, double t1, double t2) {
    double x = x0;
    cq_theta(&x, t1);
    cq_theta(&x, t2);
    return cq_measure(x);
}
