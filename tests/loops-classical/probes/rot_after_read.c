/* tests/loops-classical probe (cq-wyu4): a carried register is read by a record the reverse loop would undo, and a
 * direct cq_theta rotates it later in the same trip (r_after), or earlier in the next trip (r_before). No point lies
 * between the record's last consumer and the gate (CR rule 5's scheduling invariant): the record is kept, never undone
 * against the rotated rail. r_after is the bead's control p9b.c. */
int r_after(int a, double t1, double t2, int n) {
    int r = a;
    cq_theta(&r, t1);
    int acc = 0;
    for (int i = 0; i < n; i++) {
        acc = (acc << 1) | (r & 1);
        cq_theta(&r, t2);
    }
    if (acc == 2) cq_phi(1.0);
    return cq_measure(r);
}
int r_before(int a, double t1, double t2, int n) {
    int r = a;
    cq_theta(&r, t1);
    int acc = 0;
    for (int i = 0; i < n; i++) {
        cq_theta(&r, t2);
        acc = (acc << 1) | (r & 1);
    }
    if (acc == 2) cq_phi(1.0);
    return cq_measure(r);
}
