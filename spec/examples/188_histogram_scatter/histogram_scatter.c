/* Quantum-offset memory traffic in classical loops: a histogram (read-modify-write at a quantum bucket: QRAM), a gather
 * from a constant table (QROM) and a scatter of classical values to quantum offsets (QRAM stores). */
static const int t[8] = {3, 1, 4, 1, 5, 9, 2, 6};
int histogram(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    int h[4] = {0};
    for (int i = 0; i < 4; i++)
        h[(x >> 2 * i) & 3]++;
    return cq_measure(h[0] | h[1] << 4 | h[2] << 8 | h[3] << 12);
}
int gather_scatter(unsigned x0, double th, int v0) {
    unsigned x = x0;
    cq_theta(&x, th);
    int s = 0, out[4] = {0};
    for (int i = 0; i < 4; i++) {
        s += t[(x >> 3 * i) & 7];
        out[(x >> 2 * i) & 3] = v0 + i;
    }
    return cq_measure(s) + cq_measure(out[0] | out[1] << 8 | out[2] << 16 | out[3] << 24);
}
