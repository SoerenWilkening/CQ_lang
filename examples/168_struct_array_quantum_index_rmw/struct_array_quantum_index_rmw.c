/* Rules 20, 26: an array of structs written AND read at a quantum index (a QRAM of struct cells, one QRAM per field),
 * with a read-modify-write of one field. */
struct cell { int v; int w; };
int struct_array_quantum_index_rmw(unsigned i0, double ti, int c) {
    struct cell arr[4] = { {1, 2}, {3, 4}, {5, 6}, {7, 8} };
    unsigned i = i0;
    cq_theta(&i, ti);
    arr[i & 3].v += c;
    arr[(i + 1) & 3].w = arr[i & 3].v;
    return cq_measure(arr[(i + 2) & 3].v + arr[(i + 1) & 3].w);
}
