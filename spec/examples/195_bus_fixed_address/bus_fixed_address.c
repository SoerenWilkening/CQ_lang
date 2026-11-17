/* One bus: a rail stored to and loaded from a CLASSICAL address (a global, an escaped local), and a cell rotated in place. */
int cell;
int reg = 2;
__attribute__((noinline)) static void bump(int *p) { *p += 1; }   /* load, add, store on one pointer: the in-place form */
int bus_global_cell(int x0, double tx, int y0, double ty) {
    int x = x0;
    cq_theta(&x, tx);
    cell = x;                                 /* a kept store of a rail at the classical address &cell */
    int y = y0;
    cq_theta(&y, ty);
    return cq_measure(cell + y);              /* a load at the same classical address: a rail */
}
int bus_escaped_local(int x0, double tx) {
    int x = x0;
    cq_theta(&x, tx);
    int w = x;
    bump(&w);                                 /* &w is a call argument: w is bus-resident, bump is its own symbol */
    return cq_measure(w);
}
int bus_rotate_cell(double tr) {
    cq_theta(&reg, tr);                       /* load, rotate, store straight back: the gate acts on the cell */
    return cq_measure(reg);                   /* a reader of the rotated cell: a load after the swap-in */
}
