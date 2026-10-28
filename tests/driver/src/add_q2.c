int add_q2(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(x + c);
}
