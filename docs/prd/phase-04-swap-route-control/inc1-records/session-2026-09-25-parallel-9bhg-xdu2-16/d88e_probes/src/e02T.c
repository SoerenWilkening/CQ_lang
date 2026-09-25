
int main(int c, char **v) { int m = c + 4; int q = cq_theta(m, .5); int t = m + 1; int r = q; if (m > 3) r = cq_theta(q, .2); return cq_measure(r) + t; }
