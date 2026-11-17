/* Rule 13 + rule 8: a switch inside a case arm of another switch, both scrutinees quantum. Inner case flags are
 * conjoined with the outer edge flag. The phase arm inside the inner switch kicks back on the conjunction. */
int nested_switch(int x0, double tx, int y0, double ty, int c, double p) {
    int x = x0, y = y0, r = c;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    switch (x & 3) {
        case 0: r += 1; break;
        case 1:
            switch (y & 3) {
                case 0: r += 2; break;
                case 2: cq_phi(p); break;
                default: r += y; break;
            }
            break;
        default: r += x; break;
    }
    return cq_measure(r);
}
