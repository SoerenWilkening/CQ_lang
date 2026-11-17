/* Rule 20: a global lives at its host address on the one bus; an access at a quantum index is a bus access at an
 * address rail, one at a classical index a bus access at its classical address. The global persists across calls: its
 * cells are program state, never freed. */
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
