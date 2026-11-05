/* Rule 2: a cq_theta of a loaded value that is not stored straight back rotates the load copy. */
int src = 3;
int dst;
int theta_of_load_copy(double th) {
    int v = src;                              /* a load */
    cq_theta(&v, th);                         /* the copy is rotated: a FROZEN register from here on */
    dst = v;                                  /* stored through another pointer: an ordinary kept store */
    return cq_measure(src);                   /* the cell src was never rotated */
}
