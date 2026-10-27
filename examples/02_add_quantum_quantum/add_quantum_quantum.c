int add_quantum_quantum(int x0, int y0, double tx, double ty) {
    int x = x0;
    int y = y0;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    int z = x + y;
    return cq_measure(z);
}
