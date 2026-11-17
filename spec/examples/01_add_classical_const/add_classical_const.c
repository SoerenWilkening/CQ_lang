int add_classical(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    int y = x + c;
    return cq_measure(y);
}
