int nested_value_arms(int x0, double th, int k1, int k2, int c, int s) {
    int x = x0;
    cq_theta(&x, th);
    int r = x;
    if (x > k1) {
        r = x + c;
        if (r < k2)
            r = r * s;
    }
    return cq_measure(r);
}
