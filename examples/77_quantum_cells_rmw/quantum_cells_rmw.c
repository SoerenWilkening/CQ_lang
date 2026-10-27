unsigned quantum_cells_rmw(unsigned x0, unsigned y0, double tx, double ty) {
    unsigned x = x0, y = y0;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    unsigned a[4] = {y, y + 1, y + 2, y + 3};
    a[x & 3] += y;
    return cq_measure(a[0] ^ a[1] ^ a[2] ^ a[3]);
}
