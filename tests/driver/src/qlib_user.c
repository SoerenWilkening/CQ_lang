/* A program of the rule 27 test: triple has no body here and is on the root list. */
int triple(int);
int use(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(triple(x) + 1);
}
