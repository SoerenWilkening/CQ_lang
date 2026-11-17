static const int TABLE[8] = {3, 1, 4, 1, 5, 9, 2, 6};
int table_quantum_index(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    int v = TABLE[x & 7];
    return cq_measure(v);
}
