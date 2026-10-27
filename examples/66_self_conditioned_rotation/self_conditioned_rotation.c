int self_conditioned_rotation(int x0, double t1, int k, double t2) {
    int x = x0;
    cq_theta(&x, t1);
    if (x > k)
        cq_theta(&x, t2);     /* the condition reads the register the arm rotates */
    return cq_measure(x);
}
