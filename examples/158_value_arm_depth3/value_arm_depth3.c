/* Rule 9: value arms nested three deep on three quantum conditions; each level merges by select under its own flag,
 * flags conjoined per level. */
int value_arm_depth3(int x0, double tx, int y0, double ty, int z0, double tz, int a, int b, int c, int d) {
    int x = x0, y = y0, z = z0, r = a;
    cq_theta(&x, tx); cq_theta(&y, ty); cq_theta(&z, tz);
    if (x > a) {
        if (y > b) {
            if (z > c) r = x + y + z;
            else       r = x * y;
        } else {
            r = y - d;
        }
    } else {
        r = z + d;
    }
    return cq_measure(r);
}
