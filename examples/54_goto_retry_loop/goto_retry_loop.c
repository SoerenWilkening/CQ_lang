/* k_rem_pio2 shape: a goto-based loop with two back edges into one header. */
int goto_retry_loop(int x0, double th, int k, int c, int m) {
    int x = x0;
    cq_theta(&x, th);
    int y;
recompute:
    if (x > k) { x -= k; goto recompute; }
    y = x * c;
    if (y > m) { x = x >> 1; goto recompute; }
    return cq_measure(y);
}
