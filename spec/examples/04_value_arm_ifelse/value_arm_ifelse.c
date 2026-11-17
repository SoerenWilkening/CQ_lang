int value_arm_ifelse(int x0, double th, int k, int c, int s) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (x > k)
        r = x + c;
    else
        r = x * s;
    return cq_measure(r);
}
