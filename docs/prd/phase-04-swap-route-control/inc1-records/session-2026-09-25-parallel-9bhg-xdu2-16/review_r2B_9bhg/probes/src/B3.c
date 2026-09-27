int h(int a, int k); int g2(int a, int b);
int main(int c, char **v) { int q = cq_theta(c, .5); bool b[3]; for (int i = 0; i < 3; i++) b[i] = h(q, i) & 1; int s = 0; for (int i = 0; i < 3; i++) s += cq_measure(g2(b[i], q)); return s + cq_measure(q); }
