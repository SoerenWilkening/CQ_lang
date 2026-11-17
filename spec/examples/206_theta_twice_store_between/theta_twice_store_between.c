/* Rule 5, Readers: two cq_theta of one cell with a store to another cell between them. */
int cell = 1;
int g;
int theta_twice_store_between(double t1, double t2) {
    cq_theta(&cell, t1);                      /* the first form: closed by its store */
    g++;                                      /* a memory version change at the classical address &g */
    cq_theta(&cell, t2);                      /* rotates the value -O1 forwarded from the first store */
    return cq_measure(cell);
}
/* The same shape through pointers: restrict lets -O1 forward as above. The driver also calls it with q == p. */
int theta_twice_store_between_ptr(int *restrict p, int *restrict q, double t1, double t2) {
    cq_theta(p, t1);                          /* the first form */
    (*q)++;                                   /* a memory version change at the classical address q */
    cq_theta(p, t2);                          /* rotates the forwarded value */
    return cq_measure(*p);
}
