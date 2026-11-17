/* One bus of 8-bit cells: one byte of an int object is read and written at an address rail, then the word is loaded. */
unsigned bus_byte_view(unsigned k0, double tk, unsigned x0, double tx, unsigned char c) {
    unsigned k = k0;
    cq_theta(&k, tk);
    unsigned x = x0;
    cq_theta(&x, tx);
    unsigned w = x;                           /* one i32 store: 4 cells, little-endian */
    unsigned char *b = (unsigned char *)&w;
    unsigned char lo = b[k & 3];              /* one i8 load of a cell of w at an address rail */
    b[(k >> 2) & 3] = c;                      /* one i8 store over a cell of w at an address rail */
    return cq_measure(w + lo);                /* one i32 load of the 4 cells */
}
