int h(int a, int k); int g(int a);
int main(int c, char **v) {
    int q = cq_theta(c, .5);
    int t = h(q, c);
    int a = g(t);
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a) + cq_measure(q);
}
