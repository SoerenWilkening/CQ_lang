/* A pointer parameter: the driver passes a zeroed object of its own. */
int from_ptr(const int *p, double th) {
    int x = p[1];
    cq_theta(&x, th);
    return cq_measure(x + 7);
}
