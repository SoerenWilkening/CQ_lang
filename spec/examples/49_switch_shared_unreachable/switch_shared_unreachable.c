int switch_shared_unreachable(int x0, double th, int a, int b) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    switch (x & 3) {
    case 0:
    case 1:  r = x + a; break;          /* two cases share one arm */
    case 2:  r = x * b; break;
    case 3:  r = x - a; break;
    default: __builtin_unreachable();   /* compiler-known unreachable: not an abort arm */
    }
    return cq_measure(r);
}
