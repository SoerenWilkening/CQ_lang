/* A quantum function with a CQ_K line in its own TU. */
CQ_K(add_q, 9)
int add_q(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(x + c);
}
