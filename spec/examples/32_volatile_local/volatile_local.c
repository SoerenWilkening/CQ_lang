int volatile_local(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    volatile int tmp = x + c;
    int y = tmp * 2;
    return cq_measure(y);
}
