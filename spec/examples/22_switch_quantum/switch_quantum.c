int switch_value(int x0, double th, int a, int b, int c) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    switch (x & 3) {
    case 0:  r = x + a; break;
    case 1:  r = x * b; break;
    case 2:  r = x - c; break;
    default: r = x; break;
    }
    return cq_measure(r);
}
int switch_phase(int x0, double th, double p0, double p1, double p2) {
    int x = x0;
    cq_theta(&x, th);
    switch (x & 3) {
    case 0: cq_phi(p0); break;
    case 1: cq_phi(p1); break;
    case 2: cq_phi(p2); break;
    default: break;
    }
    return cq_measure(x);
}
