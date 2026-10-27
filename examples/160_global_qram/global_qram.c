/* Rule 20: a GLOBAL array written and read at a quantum index is a QRAM; a global read only at classical indices is a
 * slot array. The global persists across calls: it is an output, never freed. */
static int table[8];
static int slots[4];
int global_qram(unsigned i0, double ti, int v, int c) {
    unsigned i = i0;
    cq_theta(&i, ti);
    table[i & 7] = v;
    slots[1] = c;
    int r = table[(i + 1) & 7] + slots[1];
    return cq_measure(r);
}
